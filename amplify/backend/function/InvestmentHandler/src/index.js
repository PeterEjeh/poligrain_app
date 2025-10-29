const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient();

// Environment variables
const INVESTMENTS_TABLE = process.env.INVESTMENTS_TABLE || "Investments";
const CAMPAIGNS_TABLE = process.env.LOAN_REQUESTS_TABLE || "LoanRequests";
const TRANSACTIONS_TABLE = process.env.TRANSACTIONS_TABLE || "Transactions";

// CORS headers
const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
  "Access-Control-Allow-Methods": "*",
};

// Helper function to generate investment ID
function generateInvestmentId() {
  return `inv_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

// Helper function to validate investment data
function validateInvestmentData(data) {
  const required = ["campaignId", "amount", "tenure"];
  const missing = required.filter((field) => !data[field]);

  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(", ")}`);
  }

  if (typeof data.amount !== "number" || data.amount <= 0) {
    throw new Error("Investment amount must be a positive number");
  }

  if (typeof data.tenure !== "string" || !data.tenure.includes("months")) {
    throw new Error(
      'Invalid tenure format. Expected format: "12months", "24months", etc.'
    );
  }
}

// Helper function to get campaign data
async function getCampaignData(campaignId) {
  const params = {
    TableName: CAMPAIGNS_TABLE,
    Key: { id: campaignId },
  };

  const result = await ddb.get(params).promise();
  const item = result.Item;
  if (
    !item ||
    !(
      item.isStructuredLoan ||
      (item.type === "structured" && item.canBeInvested !== false)
    )
  ) {
    return null;
  }
  return item;
}

// Helper function to calculate expected return
function calculateExpectedReturn(amount, tenure, campaign) {
  // Extract tenure in months
  const tenureMonths = parseInt(tenure.replace("months", ""));

  // Get return rate based on tenure (example rates)
  let annualReturnRate;
  if (tenureMonths <= 6) {
    annualReturnRate = 0.12; // 12% annual
  } else if (tenureMonths <= 12) {
    annualReturnRate = 0.15; // 15% annual
  } else if (tenureMonths <= 24) {
    annualReturnRate = 0.18; // 18% annual
  } else {
    annualReturnRate = 0.2; // 20% annual
  }

  // You can also use campaign-specific return rates if available
  if (campaign.returnRates && campaign.returnRates[tenure]) {
    annualReturnRate = campaign.returnRates[tenure] / 100;
  }

  // Calculate return using compound interest
  const monthlyRate = annualReturnRate / 12;
  const totalReturn = amount * Math.pow(1 + monthlyRate, tenureMonths);

  return Math.round(totalReturn * 100) / 100;
}

// Helper function to update campaign statistics
async function updateCampaignStats(campaignId) {
  // Get all active investments for this campaign
  const params = {
    TableName: INVESTMENTS_TABLE,
    IndexName: "CampaignIndex",
    KeyConditionExpression: "campaignId = :campaignId",
    FilterExpression: "#status IN (:active, :completed)",
    ExpressionAttributeNames: {
      "#status": "status",
    },
    ExpressionAttributeValues: {
      ":campaignId": campaignId,
      ":active": "Active",
      ":completed": "Completed",
    },
  };

  const result = await ddb.query(params).promise();
  const investments = result.Items || [];

  // Calculate totals
  const totalRaised = investments.reduce(
    (sum, inv) => sum + (inv.amount || 0),
    0
  );
  const totalInvestors = new Set(investments.map((inv) => inv.userId)).size;

  // Update campaign
  const updateParams = {
    TableName: CAMPAIGNS_TABLE,
    Key: { id: campaignId },
    UpdateExpression:
      "SET totalRaised = :totalRaised, totalInvestors = :totalInvestors, updatedAt = :updatedAt",
    ExpressionAttributeValues: {
      ":totalRaised": totalRaised,
      ":totalInvestors": totalInvestors,
      ":updatedAt": new Date().toISOString(),
    },
  };

  await ddb.update(updateParams).promise();
}

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  // Handle OPTIONS requests for CORS
  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ message: "OK" }),
    };
  }

  try {
    const method = event.httpMethod;
    const path = event.path || event.resource;

    // Extract user ID from request context (Cognito)
    const userId =
      event.requestContext?.authorizer?.claims?.sub ||
      event.requestContext?.identity?.cognitoIdentityId ||
      "anonymous";

    // GET /investments - List user investments with filters
    if (
      method === "GET" &&
      (path === "/investments" || path === "/investments/")
    ) {
      const queryParams = event.queryStringParameters || {};
      const limit = Math.min(parseInt(queryParams.limit) || 20, 100);
      const lastKey = queryParams.lastKey
        ? JSON.parse(decodeURIComponent(queryParams.lastKey))
        : null;

      let params = {
        TableName: INVESTMENTS_TABLE,
        IndexName: "UserIndex",
        KeyConditionExpression: "userId = :userId",
        ExpressionAttributeValues: {
          ":userId": userId,
        },
        Limit: limit,
      };

      if (lastKey) {
        params.ExclusiveStartKey = lastKey;
      }

      // Add filters
      const filterExpressions = [];
      const expressionAttributeNames = {};

      if (queryParams.status) {
        filterExpressions.push("#status = :status");
        expressionAttributeNames["#status"] = "status";
        params.ExpressionAttributeValues[":status"] = queryParams.status;
      }

      if (queryParams.campaignId) {
        filterExpressions.push("campaignId = :campaignId");
        params.ExpressionAttributeValues[":campaignId"] =
          queryParams.campaignId;
      }

      if (filterExpressions.length > 0) {
        params.FilterExpression = filterExpressions.join(" AND ");
        if (Object.keys(expressionAttributeNames).length > 0) {
          params.ExpressionAttributeNames = expressionAttributeNames;
        }
      }

      const result = await ddb.query(params).promise();

      const response = {
        investments: result.Items || [],
        pagination: {
          count: result.Items?.length || 0,
          hasMore: !!result.LastEvaluatedKey,
        },
      };

      if (result.LastEvaluatedKey) {
        response.pagination.lastKey = encodeURIComponent(
          JSON.stringify(result.LastEvaluatedKey)
        );
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(response),
      };
    }

    // GET /investments/{id} - Get specific investment details
    if (
      method === "GET" &&
      path.startsWith("/investments/") &&
      path !== "/investments/" &&
      !path.includes("/summary")
    ) {
      const investmentId = path.split("/")[2];

      const params = {
        TableName: INVESTMENTS_TABLE,
        Key: { id: investmentId },
      };

      const result = await ddb.get(params).promise();

      if (!result.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Investment not found" }),
        };
      }

      // Verify ownership
      if (result.Item.userId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Item),
      };
    }

    // POST /investments - Create new investment
    if (
      method === "POST" &&
      (path === "/investments" || path === "/investments/")
    ) {
      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const investmentData = JSON.parse(event.body);

      // Validate investment data
      try {
        validateInvestmentData(investmentData);
      } catch (validationError) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: validationError.message }),
        };
      }

      // Get campaign data
      const campaign = await getCampaignData(investmentData.campaignId);

      if (!campaign) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Campaign not found" }),
        };
      }

      // Validate campaign status and investment amount
      if (campaign.status !== "Active") {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Campaign is not available for investment",
          }),
        };
      }

      if (investmentData.amount < campaign.minimumInvestment) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: `Investment amount must be at least ${campaign.minimumInvestment}`,
          }),
        };
      }

      // Check if campaign end date has passed
      if (new Date(campaign.endDate) < new Date()) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Campaign has ended" }),
        };
      }

      // Check remaining funding capacity
      const currentRaised = campaign.totalRaised || 0;
      const remainingAmount = campaign.targetAmount - currentRaised;

      if (investmentData.amount > remainingAmount) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: `Investment amount exceeds remaining funding needed (${remainingAmount})`,
          }),
        };
      }

      // Validate tenure option
      if (!campaign.tenureOptions.includes(investmentData.tenure)) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Invalid tenure option selected" }),
        };
      }

      const investmentId = generateInvestmentId();
      const currentTime = new Date().toISOString();

      // Calculate expected return and maturity date
      const expectedReturn = calculateExpectedReturn(
        investmentData.amount,
        investmentData.tenure,
        campaign
      );
      const tenureMonths = parseInt(
        investmentData.tenure.replace("months", "")
      );
      const expectedMaturityDate = new Date(
        Date.now() + tenureMonths * 30 * 24 * 60 * 60 * 1000
      ).toISOString();

      const investment = {
        id: investmentId,
        userId: userId,
        campaignId: investmentData.campaignId,
        campaignTitle: campaign.title,
        amount: investmentData.amount,
        tenure: investmentData.tenure,
        status: "Pending", // Will be updated after payment confirmation
        expectedReturn: expectedReturn,
        actualReturn: null,
        expectedMaturityDate: expectedMaturityDate,
        actualMaturityDate: null,
        paymentReference: investmentData.paymentReference || null,
        metadata: investmentData.metadata || {},
        createdAt: currentTime,
        updatedAt: currentTime,
        statusHistory: [
          {
            status: "Pending",
            timestamp: currentTime,
            notes: "Investment created, awaiting payment confirmation",
            updatedBy: "system",
          },
        ],
      };

      // Save investment
      await ddb
        .put({
          TableName: INVESTMENTS_TABLE,
          Item: investment,
        })
        .promise();

      // Create transaction record for the investment
      if (investmentData.paymentReference) {
        const transactionData = {
          id: `txn_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
          userId: userId,
          investmentId: investmentId,
          type: "Investment",
          status: "Processing",
          amount: investmentData.amount,
          currency: "USD",
          paymentMethod: "Investment Payment",
          paymentReference: investmentData.paymentReference,
          description: `Investment in ${campaign.title}`,
          metadata: {
            campaignId: investmentData.campaignId,
            tenure: investmentData.tenure,
          },
          createdAt: currentTime,
          statusHistory: [
            {
              status: "Processing",
              timestamp: currentTime,
              notes: "Investment payment processing",
              updatedBy: "system",
            },
          ],
        };

        await ddb
          .put({
            TableName: TRANSACTIONS_TABLE,
            Item: transactionData,
          })
          .promise();
      }

      // Update campaign stats
      await updateCampaignStats(investmentData.campaignId);

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify(investment),
      };
    }

    // PUT /investments/{id}/status - Update investment status
    if (
      method === "PUT" &&
      path.includes("/investments/") &&
      path.endsWith("/status")
    ) {
      const investmentId = path.split("/")[2];

      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const { status, actualReturn, actualMaturityDate, notes } = JSON.parse(
        event.body
      );

      if (!status) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Status is required" }),
        };
      }

      // Valid status values
      const validStatuses = [
        "Pending",
        "Active",
        "Completed",
        "Cancelled",
        "Failed",
      ];
      if (!validStatuses.includes(status)) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Invalid status value" }),
        };
      }

      // Get current investment
      const getParams = {
        TableName: INVESTMENTS_TABLE,
        Key: { id: investmentId },
      };

      const currentInvestment = await ddb.get(getParams).promise();

      if (!currentInvestment.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Investment not found" }),
        };
      }

      // For user requests, only allow checking status of own investments
      // For admin requests, you might want to add additional authorization
      if (currentInvestment.Item.userId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      const currentTime = new Date().toISOString();

      // Build update expression
      let updateExpression = "SET #status = :status, updatedAt = :updatedAt";
      let expressionAttributeNames = { "#status": "status" };
      let expressionAttributeValues = {
        ":status": status,
        ":updatedAt": currentTime,
      };

      // Add optional fields
      if (actualReturn !== undefined) {
        updateExpression += ", actualReturn = :actualReturn";
        expressionAttributeValues[":actualReturn"] = actualReturn;
      }

      if (actualMaturityDate) {
        updateExpression += ", actualMaturityDate = :actualMaturityDate";
        expressionAttributeValues[":actualMaturityDate"] = actualMaturityDate;
      }
      if (notes) {
        updateExpression +=
          ", #notes = list_append(if_not_exists(#notes, :emptyList), :note)";
        expressionAttributeNames["#notes"] = "statusHistory";
        expressionAttributeValues[":note"] = [
          {
            status: status,
            timestamp: currentTime,
            notes: notes || "",
            updatedBy: "user",
          },
        ];
        expressionAttributeValues[":emptyList"] = [];
      }
      const updateParams = {
        TableName: INVESTMENTS_TABLE,
        Key: { id: investmentId },
        UpdateExpression: updateExpression,
        ExpressionAttributeNames: expressionAttributeNames,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: "ALL_NEW",
      };
      const result = await ddb.update(updateParams).promise();
      console.log(
        "Investment updated:",
        JSON.stringify(result.Attributes, null, 2)
      );
      // Update campaign stats if investment status changed to active, completed, or cancelled
      if (
        status === "Active" ||
        status === "Completed" ||
        status === "Cancelled"
      ) {
        await updateCampaignStats(currentInvestment.Item.campaignId);
      }
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Attributes),
      };
    }
    // DELETE /investments/{id} - Delete investment
    if (
      method === "DELETE" &&
      path.startsWith("/investments/") &&
      path !== "/investments/"
    ) {
      const investmentId = path.split("/")[2];

      const getParams = {
        TableName: INVESTMENTS_TABLE,
        Key: { id: investmentId },
      };

      const currentInvestment = await ddb.get(getParams).promise();

      if (!currentInvestment.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Investment not found" }),
        };
      }

      // Verify ownership
      if (currentInvestment.Item.userId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      // Delete investment
      const deleteParams = {
        TableName: INVESTMENTS_TABLE,
        Key: { id: investmentId },
      };

      await ddb.delete(deleteParams).promise();

      // Update campaign stats
      await updateCampaignStats(currentInvestment.Item.campaignId);

      return {
        statusCode: 204,
        headers,
        body: null,
      };
    }
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: `Method ${method} not allowed` }),
    };
  } catch (error) {
    console.error("Error processing request:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
    };
  }
};

const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.LOAN_REQUESTS_TABLE || "LoanRequests";
const USER_PROFILES_TABLE = process.env.USER_PROFILES_TABLE || "UserProfiles";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
};

/**
 * Creates a structured loan entry with campaign-like properties
 * @param {object} loanData - The loan request data
 * @param {string} ownerId - The owner ID
 * @param {string} role - The user role
 * @returns {object} - The created structured loan
 */
function createStructuredLoanEntry(loanData, ownerId, role) {
  const currentTime = new Date().toISOString();

  return {
    id: Date.now().toString(),
    owner: ownerId,
    type: "structured",
    loanType: "structured",
    status: "Active", // Structured loans start active for campaign-like behavior
    createdAt: currentTime,
    role: role,

    // Campaign-like properties for structured loans
    title:
      loanData.title || `${loanData.category || "Agricultural"} Loan Campaign`,
    description:
      loanData.description || loanData.purpose || "Agricultural loan campaign",
    targetAmount: loanData.amount || loanData.targetAmount,
    minimumInvestment: (loanData.amount || loanData.targetAmount) * 0.1,
    category: loanData.category || "Agriculture",
    unit: loanData.unit || "units",
    quantity: loanData.quantity || 1,
    gestationPeriod: loanData.gestationPeriod || loanData.tenure || "6 months",
    tenureOptions: loanData.tenureOptions || [loanData.tenure || "6 months"],
    averageCostPerUnit: loanData.averageCostPerUnit || 0,
    totalLoanIncludingFeePerUnit:
      loanData.totalLoanIncludingFeePerUnit ||
      loanData.amount ||
      loanData.targetAmount,
    startDate: currentTime,
    endDate:
      loanData.endDate ||
      new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
    imageUrls: loanData.imageUrls || [],
    documentUrls: loanData.documentUrls || [],

    // Metadata for identification
    isStructuredLoan: true,
    canBeInvested: true,
    requiresCampaignMigration: true,

    // Copy all original loan data
    ...loanData,
  };
}

/**
 * Creates a structured loan as a campaign (used for POST /loan-requests with structured type)
 * @param {object} loanData - The loan request data
 * @param {string} ownerId - The owner ID
 * @param {string} role - The user role
 * @param {object} event - The API Gateway event
 * @returns {Promise<object>} - The created campaign
 */
async function createStructuredLoanAsCampaign(loanData, ownerId, role, event) {
  const structuredLoan = createStructuredLoanEntry(loanData, ownerId, role);

  // Put to DynamoDB
  await ddb.put({ TableName: TABLE_NAME, Item: structuredLoan }).promise();

  return structuredLoan;
}

/**
 * Gets user info based on API Gateway's AWS_IAM authorization context.
 * This function no longer parses JWTs directly.
 * It relies on information provided by Cognito Identity Pools via API Gateway's event.requestContext.identity.
 * @param {object} event The API Gateway event object.
 * @returns {Promise<{username: string|null, ownerId: string|null, role: string|null}>}
 */
async function getUserInfo(event) {
  const cognitoIdentityId = event.requestContext?.identity?.cognitoIdentityId;

  if (!cognitoIdentityId) {
    console.log(
      "No Cognito Identity ID found in requestContext.identity. This request might not be authenticated via Cognito Identity Pools with AWS_IAM."
    );
    return { username: null, ownerId: null, role: null };
  }

  const ownerId = cognitoIdentityId;
  console.log(`Determined ownerId (Cognito Identity ID): ${ownerId}`);

  let username = null;
  let role = null;

  try {
    // *** MODIFIED CODE STARTS HERE ***
    // The original ddb.get() call failed because 'cognitoIdentityId' is not the primary key.
    // We now use ddb.query() on a Global Secondary Index (GSI) named 'byCognitoIdentityId'.
    // Ensure this GSI exists on your UserProfiles table.

    const profileParams = {
      TableName: USER_PROFILES_TABLE,
      IndexName: "byCognitoIdentityId", // Query using the GSI
      KeyConditionExpression: "cognitoIdentityId = :cognitoIdentityId",
      ExpressionAttributeValues: {
        ":cognitoIdentityId": ownerId,
      },
    };

    const userProfileData = await ddb.query(profileParams).promise();

    if (userProfileData.Items && userProfileData.Items.length > 0) {
      // A query returns an array of items; we take the first one.
      const userProfile = userProfileData.Items[0];
      username = userProfile.username || userProfile.email; // Assuming email is stored as 'username' or 'email'
      role = userProfile.role || null;
      console.log(`User profile found for ${username} with role: ${role}`);
    } else {
      console.warn(
        `User profile not found in ${USER_PROFILES_TABLE} for Cognito Identity ID: ${ownerId}`
      );
      role = null;
    }
    // *** MODIFIED CODE ENDS HERE ***

    // Map group names to roles and handle fallback
    if (role) {
      // Normalize role name
      if (role.toLowerCase() === "farmers") role = "Farmer";
      if (role.toLowerCase() === "investors") role = "Investor";
    } else {
      // Try to determine role from Cognito groups in the event context
      const claims = event.requestContext?.authorizer?.claims || {};
      const groups = claims["cognito:groups"] || [];

      if (groups.includes("Farmers")) {
        role = "Farmer";
        console.log(
          `Role determined from Cognito group: Farmer for user ${ownerId}`
        );
      } else if (groups.includes("Investors")) {
        role = "Investor";
        console.log(
          `Role determined from Cognito group: Investor for user ${ownerId}`
        );
      } else {
        console.warn(
          `Role not determined for user: ${ownerId} (groups: ${groups}). Defaulting to 'guest'.`
        );
        role = "guest";
      }
    }

    return { username, ownerId, role };
  } catch (error) {
    console.error(
      "Error determining user info from AWS_IAM context or fetching profile:",
      error
    );
    // This will now catch errors from the ddb.query call, including if the GSI doesn't exist.
    return { username: null, ownerId: null, role: null };
  }
}

exports.handler = async (event) => {
  console.log("Event received:", JSON.stringify(event, null, 2));

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  const userInfo = await getUserInfo(event);
  const { ownerId, role } = userInfo;

  if (!ownerId) {
    return {
      statusCode: 401,
      headers,
      body: JSON.stringify({
        message:
          "Unauthorized: User identity could not be determined from AWS_IAM context.",
      }),
    };
  }

  const isInvestor =
    role?.toLowerCase() === "investor" || role?.toLowerCase() === "investors";
  console.log(`User ${ownerId} (role: ${role}) is an investor: ${isInvestor}`);

  const queryParams = event.queryStringParameters || {};
  const loanType = queryParams.type || "flexible"; // Default to flexible if not specified

  // --- GET /loan-requests or /loan-requests/{id} ---
  if (event.resource === "/loan-requests" && event.httpMethod === "GET") {
    try {
      let loans = [];
      const activeOnly = queryParams.activeOnly === "true";
      const limit = parseInt(queryParams.limit) || 10;
      const ownerIdQuery = queryParams.ownerId;

      let filterExpression;
      let expressionAttributeValues = {};
      let expressionAttributeNames = { "#type": "type" };

      if (loanType === "structured") {
        filterExpression = activeOnly
          ? "#status = :activeStatus AND (#type = :structuredType OR loanType = :structuredType OR isStructuredLoan = :isStructured)"
          : "#type = :structuredType OR loanType = :structuredType OR isStructuredLoan = :isStructured";
        expressionAttributeValues = {
          ":structuredType": "structured",
          ":isStructured": true,
          ...(activeOnly && { ":activeStatus": "Active" }),
        };
        if (activeOnly) {
          expressionAttributeNames["#status"] = "status";
        }
      } else {
        filterExpression = activeOnly
          ? "#status = :pendingStatus AND (#type = :flexibleType OR (attribute_not_exists(#type) AND attribute_not_exists(loanType)) OR loanType = :flexibleType)"
          : "#type = :flexibleType OR (attribute_not_exists(#type) AND attribute_not_exists(loanType)) OR loanType = :flexibleType";
        expressionAttributeValues = {
          ":flexibleType": "flexible",
          ...(activeOnly && { ":pendingStatus": "Pending" }),
        };
        if (activeOnly) {
          expressionAttributeNames["#status"] = "status";
        }
      }

      if (isInvestor || ownerIdQuery === "current_user") {
        // For investors or explicit query, scan all (but filter by owner if specified)
        const params = {
          TableName: TABLE_NAME,
          FilterExpression: filterExpression,
          ExpressionAttributeNames: expressionAttributeNames,
          ExpressionAttributeValues: expressionAttributeValues,
          Limit: limit,
        };
        if (ownerIdQuery === "current_user") {
          params.FilterExpression += " AND #owner = :ownerId";
          expressionAttributeNames["#owner"] = "owner";
          expressionAttributeValues[":ownerId"] = ownerId;
        }
        const data = await ddb.scan(params).promise();
        loans = data.Items || [];
      } else {
        // For farmers, query their own OR all campaigns by farmers (role = 'Farmer')
        let params;
        if (ownerIdQuery === "current_user") {
          // Show only current user's campaigns
          params = {
            TableName: TABLE_NAME,
            IndexName: "byOwner",
            KeyConditionExpression: "#owner = :ownerId",
            FilterExpression: filterExpression,
            ExpressionAttributeNames: {
              ...expressionAttributeNames,
              "#owner": "owner",
            },
            ExpressionAttributeValues: {
              ":ownerId": ownerId,
              ...expressionAttributeValues,
            },
            Limit: limit,
          };
        } else {
          // Show all campaigns created by farmers (role = 'Farmer')
          params = {
            TableName: TABLE_NAME,
            FilterExpression: `${filterExpression} AND #role = :farmerRole`,
            ExpressionAttributeNames: {
              ...expressionAttributeNames,
              "#role": "role",
            },
            ExpressionAttributeValues: {
              ...expressionAttributeValues,
              ":farmerRole": "Farmer",
            },
            Limit: limit,
          };
        }
        const data = await ddb.scan(params).promise();
        loans = data.Items || [];
      }

      // Sort by createdAt descending
      loans.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      const responseType = loanType === "structured" ? "campaigns" : "loans";
      const message = `${loanType.charAt(0).toUpperCase() + loanType.slice(1)} ${responseType} retrieved successfully.`;

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          [responseType]: loans,
          type: loanType,
          message: message,
          meta: {
            count: loans.length,
            ...(loanType === "flexible" && {
              structuredLoansLocation: "/loan-requests?type=structured",
            }),
            ...(loanType === "structured" && {
              flexibleLoansLocation: "/loan-requests",
            }),
          },
        }),
      };
    } catch (error) {
      console.error("Error fetching loans:", error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          message: "Failed to fetch loans.",
          error: error.message,
        }),
      };
    }
  }

  // --- GET /loan-requests/{id} ---
  if (event.resource === "/loan-requests/{id}" && event.httpMethod === "GET") {
    try {
      const loanId = event.pathParameters.id;
      if (!loanId) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ message: "Loan ID is required." }),
        };
      }

      const params = {
        TableName: TABLE_NAME,
        Key: { id: loanId },
      };
      const data = await ddb.get(params).promise();

      if (!data.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ message: "Loan not found." }),
        };
      }

      // Determine type
      const itemType =
        data.Item.type ||
        data.Item.loanType ||
        (data.Item.isStructuredLoan ? "structured" : "flexible");
      const responseType = itemType === "structured" ? "campaign" : "loan";

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          [responseType]: data.Item,
          type: itemType,
          message: `${responseType} retrieved successfully.`,
        }),
      };
    } catch (error) {
      console.error("Error fetching specific loan:", error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          message: "Failed to fetch loan.",
          error: error.message,
        }),
      };
    }
  }

  // --- POST /loan-requests ---
  if (event.resource === "/loan-requests" && event.httpMethod === "POST") {
    try {
      const requestBody = JSON.parse(event.body);

      const itemType = requestBody.type || requestBody.loanType || "flexible";

      if (itemType === "structured") {
        // Create structured loan (campaign)
        const structuredLoan = createStructuredLoanEntry(
          requestBody,
          ownerId,
          role
        );
        await ddb
          .put({ TableName: TABLE_NAME, Item: structuredLoan })
          .promise();

        return {
          statusCode: 201,
          headers,
          body: JSON.stringify({
            ...structuredLoan,
            message: "Structured loan campaign created successfully.",
            type: "structured",
            routedTo: "campaigns",
          }),
        };
      } else {
        // Handle flexible loans
        const item = {
          id: Date.now().toString(),
          owner: ownerId,
          status: "Pending",
          createdAt: new Date().toISOString(),
          role: role,
          type: "flexible",
          loanType: "flexible",
          ...requestBody,
        };

        await ddb.put({ TableName: TABLE_NAME, Item: item }).promise();

        return {
          statusCode: 201,
          headers,
          body: JSON.stringify({
            ...item,
            message: "Flexible loan request created successfully.",
            type: "flexible",
            routedTo: "loan-requests",
          }),
        };
      }
    } catch (error) {
      console.error("Error creating loan request:", error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          message: "Failed to create loan request.",
          error: error.message,
        }),
      };
    }
  }

  // --- Other methods (PUT, DELETE, etc.) can be added similarly ---

  return {
    statusCode: 405,
    headers,
    body: JSON.stringify({
      message: `Method ${event.httpMethod} not allowed for resource ${event.resource}.`,
    }),
  };

  // --- POST /loan-requests ---
  if (event.resource === "/loan-requests" && event.httpMethod === "POST") {
    try {
      const requestBody = JSON.parse(event.body);

      // Handle only flexible loans here; structured go to /campaigns
      if (
        requestBody.type === "structured" ||
        requestBody.loanType === "structured"
      ) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            message:
              "Structured loans must be created via /campaigns endpoint.",
            redirectTo: "/campaigns",
          }),
        };
      }

      // Handle flexible loans normally
      console.log("Processing flexible loan request");

      const item = {
        id: Date.now().toString(),
        owner: ownerId, // ownerId is the Cognito Identity ID
        status: "Pending",
        createdAt: new Date().toISOString(),
        role: role, // Store the creator's role
        type: "flexible", // Ensure it's marked as flexible
        loanType: "flexible", // For backward compatibility
        ...requestBody,
      };

      await ddb.put({ TableName: TABLE_NAME, Item: item }).promise();

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify({
          ...item,
          message: "Flexible loan request created",
          routedTo: "loan-requests",
        }),
      };
    } catch (error) {
      console.error("Error creating loan request:", error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          message: "Failed to create loan request.",
          error: error.message,
        }),
      };
    }
  }

  // --- Other methods (PUT, DELETE, etc.) for both /loan-requests and /campaigns can be added similarly ---
  // For now, return 405 for unhandled routes/methods

  return {
    statusCode: 405,
    headers,
    body: JSON.stringify({
      message: `Method ${event.httpMethod} not allowed for resource ${event.resource}.`,
    }),
  };
};

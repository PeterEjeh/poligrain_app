// A complete, production-ready AWS Lambda function for handling transactions.
//
// Features:
// - CRUD operations for transactions (Create, Read, Update).
// - Secure: Operations are scoped to the authenticated user.
// - Advanced Filtering: List transactions with filters for status, type, and date range.
// - Pagination: Supports paginated responses for large datasets.
// - Summaries: Provides an endpoint for transaction summaries.
// - Payment Processing: Simulates integration with a payment gateway.
// - Refunds: Logic for processing refunds against original transactions.
// - Robust Error Handling: Catches and formats errors gracefully.
//
// Prerequisites:
// 1. IAM Role with permissions for DynamoDB:
//    - dynamodb:Query
//    - dynamodb:GetItem
//    - dynamodb:PutItem
//    - dynamodb:UpdateItem
// 2. Environment Variables set in the Lambda configuration:
//    - TRANSACTIONS_TABLE: The name of the DynamoDB table for transactions.
//    - ORDERS_TABLE: The name of the DynamoDB table for orders.
// 3. API Gateway with a Lambda authorizer (e.g., Cognito) that provides the user's ID
//    in `event.requestContext.authorizer.claims.sub`.
// 4. DynamoDB `TRANSACTIONS_TABLE` with a Global Secondary Index (GSI) for querying by user:
//    - Index Name: `userId-createdAt-index`
//    - Partition Key: `userId` (String)
//    - Sort Key: `createdAt` (String)

// Import required AWS SDK clients and Node.js modules
const AWS = require("aws-sdk");
const crypto = require("crypto"); // For generating unique IDs

// Initialize DynamoDB Document Client (using AWS SDK v2 as implied by .promise())
const ddb = new AWS.DynamoDB.DocumentClient();

// Get table names from environment variables
const { TRANSACTIONS_TABLE, ORDERS_TABLE } = process.env;

// CORS headers for API Gateway responses
const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*", // IMPORTANT: For production, lock this to your frontend domain
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// --- Helper Functions ---

/**
 * Generates a unique, prefixed transaction ID.
 * @returns {string} A unique transaction ID (e.g., "txn_...")
 */
const generateTransactionId = () => `txn_${crypto.randomUUID()}`;

/**
 * MOCK: Simulates a call to a payment gateway (e.g., Stripe, PayPal).
 * In a real application, this would involve secure API calls to a third-party service.
 * @param {object} paymentDetails - Details for the payment.
 * @param {number} paymentDetails.amount - The amount to charge.
 * @param {string} paymentDetails.paymentMethod - The payment method identifier.
 * @returns {Promise<object>} A promise that resolves with the payment result.
 */
const processPayment = async ({ amount, paymentMethod }) => {
  console.log(
    `Simulating payment processing for ${amount} via ${paymentMethod}`
  );
  // Simulate a network delay
  await new Promise((resolve) => setTimeout(resolve, 1000));

  // Simulate a 90% success rate for demonstration
  if (Math.random() < 0.9) {
    return {
      success: true,
      gatewayTransactionId: `gw_success_${crypto.randomUUID()}`,
      gatewayResponse: JSON.stringify({
        message: "Payment processed successfully by mock gateway.",
      }),
    };
  } else {
    return {
      success: false,
      failureReason: "Insufficient funds",
      gatewayTransactionId: `gw_fail_${crypto.randomUUID()}`,
      gatewayResponse: JSON.stringify({
        message: "Payment declined by mock bank.",
      }),
    };
  }
};

/**
 * Calculates a summary of transactions for a user within a date range.
 * @param {string} userId - The ID of the user.
 * @param {string} startDate - The start date in ISO format.
 * @param {string} endDate - The end date in ISO format.
 * @returns {Promise<object>} A summary object.
 */
const calculateTransactionSummary = async (userId, startDate, endDate) => {
  const summary = {
    totalVolume: 0,
    totalTransactions: 0,
    successfulTransactions: 0,
    failedTransactions: 0,
    breakdownByType: {},
    breakdownByStatus: {},
  };

  let lastEvaluatedKey;
  do {
    const params = {
      TableName: TRANSACTIONS_TABLE,
      IndexName: "userId-createdAt-index", // Querying the GSI
      KeyConditionExpression:
        "userId = :userId AND createdAt BETWEEN :startDate AND :endDate",
      ExpressionAttributeValues: {
        ":userId": userId,
        ":startDate": startDate,
        ":endDate": endDate,
      },
      ExclusiveStartKey: lastEvaluatedKey,
    };

    const result = await ddb.query(params).promise();

    for (const item of result.Items) {
      summary.totalTransactions++;

      if (item.status === "Completed") {
        summary.totalVolume += item.amount;
        summary.successfulTransactions++;
      }
      if (item.status === "Failed") {
        summary.failedTransactions++;
      }

      // Group by type (Payment, Refund, etc.)
      summary.breakdownByType[item.type] =
        (summary.breakdownByType[item.type] || 0) + 1;
      // Group by status
      summary.breakdownByStatus[item.status] =
        (summary.breakdownByStatus[item.status] || 0) + 1;
    }

    lastEvaluatedKey = result.LastEvaluatedKey;
  } while (lastEvaluatedKey);

  return summary;
};

// --- Main Lambda Handler ---
exports.handler = async (event) => {
  console.log("Event received:", JSON.stringify(event, null, 2));

  const { httpMethod: method, path, queryStringParameters } = event;

  // Handle CORS preflight requests
  if (method === "OPTIONS") {
    return {
      statusCode: 204,
      headers,
      body: "",
    };
  }

  try {
    // --- Authentication & Authorization ---
    // Extract user ID from the authorizer context provided by API Gateway (e.g., from a Cognito token)
    const userId = event.requestContext.authorizer?.claims?.sub;
    if (!userId) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({
          error: "Unauthorized: User ID not found in token.",
        }),
      };
    }

    // --- Routing Logic ---

    // GET /transactions - List user's transactions with filtering and pagination
    if (
      method === "GET" &&
      (path === "/transactions" || path === "/transactions/")
    ) {
      const queryParams = queryStringParameters || {};
      const limit = parseInt(queryParams.limit, 10) || 20;
      const lastKey = queryParams.lastKey
        ? JSON.parse(decodeURIComponent(queryParams.lastKey))
        : null;

      const params = {
        TableName: TRANSACTIONS_TABLE,
        IndexName: "userId-createdAt-index", // Use the GSI to query by user
        KeyConditionExpression: "userId = :userId",
        ExpressionAttributeValues: {
          ":userId": userId,
        },
        Limit: limit,
        ScanIndexForward: false, // Return newest transactions first
        ExclusiveStartKey: lastKey,
      };

      const filterExpressions = [];

      // Add filters based on query parameters
      if (queryParams.status) {
        filterExpressions.push("#status = :status");
        params.ExpressionAttributeNames = {
          ...(params.ExpressionAttributeNames || {}),
          "#status": "status",
        };
        params.ExpressionAttributeValues[":status"] = queryParams.status;
      }
      if (queryParams.type) {
        filterExpressions.push("#type = :type");
        params.ExpressionAttributeNames = {
          ...(params.ExpressionAttributeNames || {}),
          "#type": "type",
        };
        params.ExpressionAttributeValues[":type"] = queryParams.type;
      }
      if (queryParams.startDate) {
        const startDate = new Date(queryParams.startDate).toISOString();
        // Modify KeyConditionExpression for date range if start date is provided
        params.KeyConditionExpression += " AND createdAt >= :startDate";
        params.ExpressionAttributeValues[":startDate"] = startDate;
      }
      if (queryParams.endDate) {
        const endDate = new Date(queryParams.endDate).toISOString();
        params.KeyConditionExpression = params.KeyConditionExpression.replace(
          "createdAt >=",
          "createdAt BETWEEN :startDate AND "
        );
        params.ExpressionAttributeValues[":endDate"] = endDate;
      }

      if (filterExpressions.length > 0) {
        params.FilterExpression = filterExpressions.join(" AND ");
      }

      const result = await ddb.query(params).promise();

      const response = {
        transactions: result.Items || [],
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

    // GET /transactions/{id} - Get specific transaction details
    if (
      method === "GET" &&
      path.startsWith("/transactions/") &&
      path !== "/transactions/" &&
      !path.endsWith("summary")
    ) {
      const transactionId = path.split("/")[2];

      const params = {
        TableName: TRANSACTIONS_TABLE,
        Key: { id: transactionId },
      };

      const result = await ddb.get(params).promise();

      if (!result.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Transaction not found" }),
        };
      }

      // Verify transaction belongs to user
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

    // GET /transactions/summary - Get transaction summary
    if (method === "GET" && path === "/transactions/summary") {
      const queryParams = event.queryStringParameters || {};
      const startDate =
        queryParams.startDate ||
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(); // Default to last 30 days
      const endDate = queryParams.endDate || new Date().toISOString();

      const summary = await calculateTransactionSummary(
        userId,
        startDate,
        endDate
      );

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(summary),
      };
    }

    // POST /transactions - Create new transaction (payment)
    if (
      method === "POST" &&
      (path === "/transactions" || path === "/transactions/")
    ) {
      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const transactionData = JSON.parse(event.body);

      // Validate required fields
      const requiredFields = ["amount", "paymentMethod", "description"];
      for (const field of requiredFields) {
        if (!transactionData[field]) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: `Missing required field: ${field}` }),
          };
        }
      }

      if (transactionData.amount <= 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Amount must be greater than 0" }),
        };
      }

      // If orderId is provided, verify order exists and belongs to user
      if (transactionData.orderId) {
        const orderParams = {
          TableName: ORDERS_TABLE,
          Key: { id: transactionData.orderId },
        };

        const orderResult = await ddb.get(orderParams).promise();

        if (!orderResult.Item) {
          return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: "Order not found" }),
          };
        }

        if (orderResult.Item.customerId !== userId) {
          return {
            statusCode: 403,
            headers,
            body: JSON.stringify({ error: "Access denied to order" }),
          };
        }
      }

      const transactionId = generateTransactionId();
      const currentTime = new Date().toISOString();

      // Create initial transaction record
      const transaction = {
        id: transactionId,
        userId: userId,
        orderId: transactionData.orderId || null,
        type: transactionData.type || "Payment",
        status: "Processing",
        amount: transactionData.amount,
        currency: transactionData.currency || "USD",
        paymentMethod: transactionData.paymentMethod,
        paymentReference: transactionData.paymentReference || null,
        description: transactionData.description,
        metadata: transactionData.metadata || null,
        createdAt: currentTime,
        statusHistory: [
          {
            status: "Processing",
            timestamp: currentTime,
            notes: "Transaction initiated",
            updatedBy: "system",
          },
        ],
      };

      // Save initial transaction
      await ddb
        .put({
          TableName: TRANSACTIONS_TABLE,
          Item: transaction,
        })
        .promise();

      // Process payment
      try {
        const paymentResult = await processPayment({
          amount: transactionData.amount,
          paymentMethod: transactionData.paymentMethod,
          paymentReference: transactionData.paymentReference,
        });

        const updateTime = new Date().toISOString();
        let updateExpression =
          "SET #status = :status, updatedAt = :updatedAt, gatewayTransactionId = :gatewayTransactionId, gatewayResponse = :gatewayResponse";
        let expressionAttributeNames = { "#status": "status" };
        let expressionAttributeValues = {
          ":status": paymentResult.success ? "Completed" : "Failed",
          ":updatedAt": updateTime,
          ":gatewayTransactionId": paymentResult.gatewayTransactionId,
          ":gatewayResponse": paymentResult.gatewayResponse,
        };

        if (!paymentResult.success) {
          updateExpression += ", failureReason = :failureReason";
          expressionAttributeValues[":failureReason"] =
            paymentResult.failureReason;
        } else {
          updateExpression += ", completedAt = :completedAt";
          expressionAttributeValues[":completedAt"] = updateTime;
        }

        // Update status history
        const newStatusHistory = [
          ...transaction.statusHistory,
          {
            status: paymentResult.success ? "Completed" : "Failed",
            timestamp: updateTime,
            notes: paymentResult.success
              ? "Payment processed successfully"
              : paymentResult.failureReason,
            updatedBy: "payment-gateway",
          },
        ];

        updateExpression += ", statusHistory = :statusHistory";
        expressionAttributeValues[":statusHistory"] = newStatusHistory;

        // Update transaction with payment result
        const updateParams = {
          TableName: TRANSACTIONS_TABLE,
          Key: { id: transactionId },
          UpdateExpression: updateExpression,
          ExpressionAttributeNames: expressionAttributeNames,
          ExpressionAttributeValues: expressionAttributeValues,
          ReturnValues: "ALL_NEW",
        };

        const updatedTransaction = await ddb.update(updateParams).promise();

        // If payment successful and linked to order, update order payment status
        if (paymentResult.success && transactionData.orderId) {
          const orderUpdateParams = {
            TableName: ORDERS_TABLE,
            Key: { id: transactionData.orderId },
            UpdateExpression:
              "SET paymentStatus = :paymentStatus, transactionId = :transactionId, updatedAt = :updatedAt",
            ExpressionAttributeValues: {
              ":paymentStatus": "Paid",
              ":transactionId": transactionId,
              ":updatedAt": updateTime,
            },
          };

          await ddb.update(orderUpdateParams).promise();
        }

        return {
          statusCode: paymentResult.success ? 201 : 402, // 402 Payment Required for failures
          headers,
          body: JSON.stringify(updatedTransaction.Attributes),
        };
      } catch (paymentError) {
        console.error("Payment processing error:", paymentError);

        // Update transaction with error status
        const errorTime = new Date().toISOString();
        const errorStatusHistory = [
          ...transaction.statusHistory,
          {
            status: "Failed",
            timestamp: errorTime,
            notes: `Payment processing error: ${paymentError.message}`,
            updatedBy: "system",
          },
        ];

        const errorUpdateParams = {
          TableName: TRANSACTIONS_TABLE,
          Key: { id: transactionId },
          UpdateExpression:
            "SET #status = :status, updatedAt = :updatedAt, failureReason = :failureReason, statusHistory = :statusHistory",
          ExpressionAttributeNames: { "#status": "status" },
          ExpressionAttributeValues: {
            ":status": "Failed",
            ":updatedAt": errorTime,
            ":failureReason": `Payment processing error: ${paymentError.message}`,
            ":statusHistory": errorStatusHistory,
          },
          ReturnValues: "ALL_NEW",
        };

        const failedTransaction = await ddb.update(errorUpdateParams).promise();

        return {
          statusCode: 500,
          headers,
          body: JSON.stringify(failedTransaction.Attributes),
        };
      }
    }

    // PUT /transactions/{id}/status - Update transaction status (for admin use or specific cases)
    if (
      method === "PUT" &&
      path.includes("/transactions/") &&
      path.endsWith("/status")
    ) {
      const transactionId = path.split("/")[2];

      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const { status, notes } = JSON.parse(event.body);

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
        "Processing",
        "Completed",
        "Failed",
        "Cancelled",
        "Refunded",
      ];
      if (!validStatuses.includes(status)) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Invalid status value" }),
        };
      }

      // Get current transaction
      const getParams = {
        TableName: TRANSACTIONS_TABLE,
        Key: { id: transactionId },
      };

      const currentTransaction = await ddb.get(getParams).promise();

      if (!currentTransaction.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Transaction not found" }),
        };
      }

      // For a real app, you might add an admin check here.
      // For now, we only check if the user owns the transaction.
      if (currentTransaction.Item.userId !== userId) {
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

      // Add completion timestamp if status is 'Completed' and it's not already set
      if (status === "Completed" && !currentTransaction.Item.completedAt) {
        updateExpression += ", completedAt = :completedAt";
        expressionAttributeValues[":completedAt"] = currentTime;
      }

      // Add to status history
      const newStatusHistory = [
        ...(currentTransaction.Item.statusHistory || []),
        {
          status: status,
          timestamp: currentTime,
          notes: notes || `Status manually updated to ${status}.`,
          updatedBy: userId, // The user who made the change
        },
      ];

      updateExpression += ", statusHistory = :statusHistory";
      expressionAttributeValues[":statusHistory"] = newStatusHistory;

      const updateParams = {
        TableName: TRANSACTIONS_TABLE,
        Key: { id: transactionId },
        UpdateExpression: updateExpression,
        ExpressionAttributeNames: expressionAttributeNames,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: "ALL_NEW",
      };

      const result = await ddb.update(updateParams).promise();

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Attributes),
      };
    }

    // POST /transactions/{id}/refund - Process a refund for a transaction
    if (
      method === "POST" &&
      path.includes("/transactions/") &&
      path.endsWith("/refund")
    ) {
      const originalTransactionId = path.split("/")[2];

      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const { amount, reason } = JSON.parse(event.body);

      // Get original transaction
      const getParams = {
        TableName: TRANSACTIONS_TABLE,
        Key: { id: originalTransactionId },
      };

      const originalTransaction = await ddb.get(getParams).promise();

      if (!originalTransaction.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Original transaction not found" }),
        };
      }

      // Verify transaction belongs to user
      if (originalTransaction.Item.userId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      // Validate refund conditions
      if (originalTransaction.Item.status !== "Completed") {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Can only refund completed transactions",
          }),
        };
      }

      const refundAmount = amount || originalTransaction.Item.amount; // Full refund if amount not specified

      if (refundAmount <= 0 || refundAmount > originalTransaction.Item.amount) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Invalid refund amount" }),
        };
      }

      // In a real app, you would call the payment gateway's refund API here.
      // We'll just create a 'Refund' transaction record.
      const refundTransactionId = generateTransactionId();
      const currentTime = new Date().toISOString();

      const refundTransaction = {
        id: refundTransactionId,
        userId: userId,
        orderId: originalTransaction.Item.orderId,
        type: "Refund",
        status: "Completed", // Assuming refunds are processed immediately
        amount: refundAmount,
        currency: originalTransaction.Item.currency,
        paymentMethod: originalTransaction.Item.paymentMethod,
        description: `Refund for transaction ${originalTransactionId}${reason ? `: ${reason}` : ""}`,
        metadata: {
          originalTransactionId: originalTransactionId,
          refundReason: reason || "No reason provided.",
        },
        createdAt: currentTime,
        updatedAt: currentTime,
        completedAt: currentTime,
        gatewayTransactionId: `ref_gw_${crypto.randomUUID()}`,
        gatewayResponse: JSON.stringify({
          status: "refunded",
          amount: refundAmount,
        }),
        statusHistory: [
          {
            status: "Completed",
            timestamp: currentTime,
            notes: "Refund processed",
            updatedBy: "system",
          },
        ],
      };

      // Save refund transaction
      await ddb
        .put({
          TableName: TRANSACTIONS_TABLE,
          Item: refundTransaction,
        })
        .promise();

      // Update original transaction status if fully refunded
      // For partial refunds, you might add refund details to the original transaction's metadata.
      if (refundAmount === originalTransaction.Item.amount) {
        const updateParams = {
          TableName: TRANSACTIONS_TABLE,
          Key: { id: originalTransactionId },
          UpdateExpression: "SET #status = :status, updatedAt = :updatedAt",
          ExpressionAttributeNames: { "#status": "status" },
          ExpressionAttributeValues: {
            ":status": "Refunded",
            ":updatedAt": currentTime,
          },
        };
        await ddb.update(updateParams).promise();
      }

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify(refundTransaction),
      };
    }

    // If no route matches, return 404 Not Found
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({
        error: `Route not found: Cannot ${method} ${path}`,
      }),
    };
  } catch (error) {
    console.error("An error occurred:", error);

    // Handle specific AWS SDK errors for clearer client feedback
    if (error.code === "ConditionalCheckFailedException") {
      return {
        statusCode: 409, // Conflict
        headers,
        body: JSON.stringify({
          error:
            "Conflict: The resource state may have changed since you last retrieved it.",
          details: error.message,
        }),
      };
    }

    if (error.code === "ValidationException") {
      return {
        statusCode: 400, // Bad Request
        headers,
        body: JSON.stringify({
          error: "Invalid request: A parameter is not valid.",
          details: error.message,
        }),
      };
    }

    // Generic internal server error for all other cases
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: "Internal Server Error",
        details: error.message,
      }),
    };
  }
};

const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient();

// Environment variables
const DOCUMENTS_TABLE = process.env.DOCUMENTS_TABLE || "Documents";
const STORAGE_BUCKET = process.env.STORAGE_BUCKET || "poligrain-storage";

// CORS headers
const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "*",
  "Access-Control-Allow-Methods": "*",
};

// Helper function to generate document ID
function generateDocumentId() {
  return `doc_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

// Helper function to validate document data
function validateDocumentData(data) {
  const required = [
    "type",
    "name",
    "fileName",
    "fileUrl",
    "mimeType",
    "fileSize",
  ];
  const missing = required.filter((field) => !data[field]);

  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(", ")}`);
  }

  // Validate file size (10MB limit)
  const maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
  if (data.fileSize > maxFileSize) {
    throw new Error(`File size exceeds maximum limit of 10MB`);
  }

  // Validate supported file types
  const supportedMimeTypes = [
    "application/pdf",
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/gif",
    "image/webp",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ];

  if (!supportedMimeTypes.includes(data.mimeType)) {
    throw new Error(`Unsupported file type: ${data.mimeType}`);
  }
}

// Helper function to determine document status based on type
function getInitialDocumentStatus(documentType) {
  // Some document types might need automatic verification
  const autoVerifyTypes = ["profile_picture", "campaign_image"];
  return autoVerifyTypes.includes(documentType) ? "Verified" : "Pending";
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

    // GET /documents - List documents with filters and pagination
    if (method === "GET" && (path === "/documents" || path === "/documents/")) {
      const queryParams = event.queryStringParameters || {};
      const limit = Math.min(parseInt(queryParams.limit) || 20, 100);
      const lastKey = queryParams.lastKey
        ? JSON.parse(decodeURIComponent(queryParams.lastKey))
        : null;

      let params = {
        TableName: DOCUMENTS_TABLE,
        Limit: limit,
      };

      if (lastKey) {
        params.ExclusiveStartKey = lastKey;
      }

      // Add filters
      const filterExpressions = [];
      const expressionAttributeNames = {};
      const expressionAttributeValues = {};

      // Filter by owner (default to current user unless specified)
      const ownerId =
        queryParams.ownerId === "current_user" || !queryParams.ownerId
          ? userId
          : queryParams.ownerId;
      filterExpressions.push("ownerId = :ownerId");
      expressionAttributeValues[":ownerId"] = ownerId;

      if (queryParams.type) {
        filterExpressions.push("#type = :type");
        expressionAttributeNames["#type"] = "type";
        expressionAttributeValues[":type"] = queryParams.type;
      }

      if (queryParams.status) {
        filterExpressions.push("#status = :status");
        expressionAttributeNames["#status"] = "status";
        expressionAttributeValues[":status"] = queryParams.status;
      }

      if (queryParams.campaignId) {
        filterExpressions.push("campaignId = :campaignId");
        expressionAttributeValues[":campaignId"] = queryParams.campaignId;
      }

      if (filterExpressions.length > 0) {
        params.FilterExpression = filterExpressions.join(" AND ");
        params.ExpressionAttributeValues = expressionAttributeValues;
        if (Object.keys(expressionAttributeNames).length > 0) {
          params.ExpressionAttributeNames = expressionAttributeNames;
        }
      }

      const result = await ddb.scan(params).promise();

      const response = {
        documents: result.Items || [],
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
    // GET /documents/{id} - Get specific document details
    if (
      method === "GET" &&
      path.startsWith("/documents/") &&
      path !== "/documents/"
    ) {
      const documentId = path.split("/")[2];

      const params = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
      };

      const result = await ddb.get(params).promise();

      if (!result.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Document not found" }),
        };
      }

      // Verify document belongs to user (or is publicly accessible)
      if (
        result.Item.ownerId !== userId &&
        result.Item.accessLevel !== "public"
      ) {
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

    // POST /documents - Create/upload new document
    if (
      method === "POST" &&
      (path === "/documents" || path === "/documents/")
    ) {
      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const documentData = JSON.parse(event.body);

      // Validate required fields
      try {
        validateDocumentData(documentData);
      } catch (error) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: error.message }),
        };
      }

      const documentId = generateDocumentId();
      const currentTime = new Date().toISOString();
      const document = {
        id: documentId,
        ownerId: userId,
        ownerName: documentData.ownerName || "Unknown User",
        campaignId: documentData.campaignId || null,
        type: documentData.type,
        name: documentData.name,
        fileName: documentData.fileName,
        fileUrl: documentData.fileUrl,
        mimeType: documentData.mimeType,
        fileSize: documentData.fileSize,
        status: getInitialDocumentStatus(documentData.type),
        accessLevel: documentData.accessLevel || "private",
        rejectionReason: null,
        verifiedBy: null,
        verifiedAt: null,
        expiryDate: documentData.expiryDate || null,
        uploadedAt: currentTime,
        updatedAt: currentTime,
        statusHistory: [
          {
            status: getInitialDocumentStatus(documentData.type),
            timestamp: currentTime,
            notes: "Document uploaded",
            updatedBy: userId,
          },
        ],
        metadata: documentData.metadata || {},
      };

      const params = {
        TableName: DOCUMENTS_TABLE,
        Item: document,
      };

      await ddb.put(params).promise();

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify(document),
      };
    }
    // DELETE /documents/{id} - Delete document
    if (
      method === "DELETE" &&
      path.startsWith("/documents/") &&
      path !== "/documents/"
    ) {
      const documentId = path.split("/")[2];

      // Get current document to verify ownership
      const getParams = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
      };

      const currentDocument = await ddb.get(getParams).promise();

      if (!currentDocument.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Document not found" }),
        };
      }

      // Verify ownership
      if (currentDocument.Item.ownerId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      // Soft delete - update status to Deleted
      const updateParams = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
        UpdateExpression: "SET #status = :status, updatedAt = :updatedAt",
        ExpressionAttributeNames: {
          "#status": "status",
        },
        ExpressionAttributeValues: {
          ":status": "Deleted",
          ":updatedAt": new Date().toISOString(),
        },
      };

      await ddb.update(updateParams).promise();

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ message: "Document deleted successfully" }),
      };
    }
    // PUT /documents/{id}/verification - Update document verification status
    if (method === "PUT" && path.includes("/verification")) {
      const documentId = path.split("/")[2];

      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const { status, rejectionReason, notes } = JSON.parse(event.body);

      if (!status || !["Verified", "Rejected", "Pending"].includes(status)) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Valid status (Verified/Rejected/Pending) is required",
          }),
        };
      }

      // Get current document
      const getParams = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
      };

      const currentDocument = await ddb.get(getParams).promise();

      if (!currentDocument.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Document not found" }),
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

      if (status === "Verified") {
        updateExpression +=
          ", verifiedAt = :verifiedAt, verifiedBy = :verifiedBy";
        expressionAttributeValues[":verifiedAt"] = currentTime;
        expressionAttributeValues[":verifiedBy"] = userId;
      }
      if (status === "Rejected" && rejectionReason) {
        updateExpression += ", rejectionReason = :rejectionReason";
        expressionAttributeValues[":rejectionReason"] = rejectionReason;
      }

      // Add to status history
      const statusHistory = currentDocument.Item.statusHistory || [];
      statusHistory.push({
        status: status,
        timestamp: currentTime,
        notes: notes || `Status changed to ${status}`,
        updatedBy: userId,
        rejectionReason: status === "Rejected" ? rejectionReason : undefined,
      });

      updateExpression += ", statusHistory = :statusHistory";
      expressionAttributeValues[":statusHistory"] = statusHistory;

      const updateParams = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
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

    // PUT /documents/{id} - Update document metadata
    if (
      method === "PUT" &&
      path.startsWith("/documents/") &&
      !path.includes("/verification")
    ) {
      const documentId = path.split("/")[2];

      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const updateData = JSON.parse(event.body);

      // Get current document to verify ownership
      const getParams = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
      };

      const currentDocument = await ddb.get(getParams).promise();

      if (!currentDocument.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Document not found" }),
        };
      }

      // Verify ownership
      if (currentDocument.Item.ownerId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      // Build update expression for allowed fields
      const allowedFields = ["name", "accessLevel", "metadata", "expiryDate"];
      const updateExpressions = [];
      const expressionAttributeNames = {};
      const expressionAttributeValues = {};

      allowedFields.forEach((field) => {
        if (updateData[field] !== undefined) {
          updateExpressions.push(`#${field} = :${field}`);
          expressionAttributeNames[`#${field}`] = field;
          expressionAttributeValues[`:${field}`] = updateData[field];
        }
      });

      if (updateExpressions.length === 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "No valid fields to update" }),
        };
      }

      updateExpressions.push("updatedAt = :updatedAt");
      expressionAttributeValues[":updatedAt"] = new Date().toISOString();

      const updateParams = {
        TableName: DOCUMENTS_TABLE,
        Key: { id: documentId },
        UpdateExpression: `SET ${updateExpressions.join(", ")}`,
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

    // Method not allowed
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: "Method not allowed" }),
    };
  } catch (error) {
    console.error("Error:", error);

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: "Internal server error",
        message: error.message,
      }),
    };
  }
};

const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient();
const TABLE = process.env.PRODUCTS_TABLE || "products"; // Ensure this matches your env var or table name

const headers = {
  "Access-Control-Allow-Origin": "*", // For development. Restrict in production.
  "Access-Control-Allow-Headers":
    "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS,PUT,DELETE", // Added PUT,DELETE for future
};

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));
  console.log("Environment variables:", {
    TABLE,
    REGION: process.env.REGION,
    ENV: process.env.ENV,
  });

  const method = event.httpMethod;
  const identityId = event.requestContext?.identity?.cognitoIdentityId;

  // Handle OPTIONS for CORS preflight
  if (method === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  // --- GET Handler (Fetch products with pagination) ---
  if (
    method === "GET" &&
    (event.path === "/products" || event.path === "/products/")
  ) {
    try {
      console.log("Attempting to fetch products with pagination");

      // Parse query parameters
      const queryParams = event.queryStringParameters || {};
      const limit = parseInt(queryParams.limit) || 10; // Default to 10 items per page
      const lastEvaluatedKey = queryParams.lastKey
        ? JSON.parse(decodeURIComponent(queryParams.lastKey))
        : undefined;

      // Validate limit
      if (limit < 1 || limit > 100) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Invalid limit. Must be between 1 and 100.",
          }),
        };
      }

      // Set up scan parameters
      const params = {
        TableName: TABLE,
        Limit: limit,
      };

      // Add LastEvaluatedKey if provided
      if (lastEvaluatedKey) {
        params.ExclusiveStartKey = lastEvaluatedKey;
      }

      console.log("Scan parameters:", JSON.stringify(params, null, 2));
      const data = await ddb.scan(params).promise();

      console.log(
        "DynamoDB scan successful. Items found:",
        (data.Items || []).length
      );

      // Process items and ensure consistent format with Product model
      const items = (data.Items || []).map((item) => ({
        id: item.id || "",
        name: item.name || "",
        description: item.description || "",
        category: item.category || "",
        price: item.price || 0,
        imageUrl:
          item.imageUrl ||
          (Array.isArray(item.imageUrls) && item.imageUrls.length > 0
            ? item.imageUrls[0]
            : ""),
        imageUrls: Array.isArray(item.imageUrls)
          ? item.imageUrls
          : item.imageUrl
            ? [item.imageUrl]
            : [],
        videoUrls: Array.isArray(item.videoUrls) ? item.videoUrls : [],
        unit: item.unit || null,
        owner: item.owner || null,
        sellerName: item.sellerName || null,
        location: item.location || "Unknown Location",
        quantity: item.quantity || 0,
        createdAt: item.createdAt || new Date().toISOString(),
        updatedAt: item.updatedAt || null,
        isActive: item.isActive !== undefined ? item.isActive : true,
        rating: item.rating || null,
        reviewCount: item.reviewCount || null,
      }));

      // Prepare pagination metadata
      const response = {
        items,
        pagination: {
          count: items.length,
          hasMore: !!data.LastEvaluatedKey,
        },
      };

      // Include the LastEvaluatedKey if there are more items
      if (data.LastEvaluatedKey) {
        response.pagination.lastKey = encodeURIComponent(
          JSON.stringify(data.LastEvaluatedKey)
        );
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(response),
      };
    } catch (error) {
      console.error("Detailed error fetching products:", error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: "Failed to fetch products",
          details: error.message,
        }),
      };
    }
  }

  // --- POST Handler (Create a new product) ---
  if (
    method === "POST" &&
    (event.path === "/products" || event.path === "/products/")
  ) {
    // --- Authentication Check (all authenticated users can proceed) ---
    if (!identityId) {
      console.error("POST /products attempt without valid AWS IAM identity.");
      return {
        statusCode: 401, // Unauthorized
        headers,
        body: JSON.stringify({
          error: "Unauthorized: AWS IAM identity not found.",
        }),
      };
    }
    const username = identityId; // Use this as the product owner

    try {
      if (!event.body) {
        return {
          statusCode: 400, // Bad Request
          headers,
          body: JSON.stringify({ error: "Request body is missing." }),
        };
      }
      const body = JSON.parse(event.body);

      // Validate required fields from the body
      const requiredFields = [
        "name",
        "category",
        "imageUrls", // Now required as array
        "price",
        "quantity",
        "description",
        "location", // Now required to match Product model
      ];
      for (const field of requiredFields) {
        if (
          body[field] === undefined ||
          body[field] === null ||
          (Array.isArray(body[field]) && body[field].length === 0) ||
          (typeof body[field] === "string" && body[field].trim() === "")
        ) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: `Missing required field: ${field}` }),
          };
        }
      }
      if (typeof body.price !== "number" || body.price < 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Price must be a non-negative number.",
          }),
        };
      }
      if (!Number.isInteger(body.quantity) || body.quantity < 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Quantity must be a non-negative integer.",
          }),
        };
      }
      if (!Array.isArray(body.imageUrls) || body.imageUrls.length === 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "imageUrls must be a non-empty array.",
          }),
        };
      }
      if (body.videoUrls && !Array.isArray(body.videoUrls)) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "videoUrls must be an array if provided.",
          }),
        };
      }

      const currentTime = new Date().toISOString();
      const item = {
        id: Date.now().toString(), // Simple unique ID, consider UUID
        owner: username, // Set by the authenticated user's username
        name: body.name,
        description: body.description || "",
        category: body.category,
        price: body.price,
        imageUrl: body.imageUrls[0] || null, // For backward compatibility
        imageUrls: body.imageUrls,
        videoUrls: body.videoUrls || [],
        unit: body.unit || null,
        sellerName: body.sellerName || null,
        location: body.location,
        quantity: body.quantity,
        createdAt: currentTime,
        updatedAt: null,
        isActive: body.isActive !== undefined ? body.isActive : true,
        rating: body.rating || null,
        reviewCount: body.reviewCount || null,
      };

      await ddb.put({ TableName: TABLE, Item: item }).promise();
      console.log(
        "Product created successfully by:",
        username,
        JSON.stringify(item)
      );
      return {
        statusCode: 201, // Created
        headers,
        body: JSON.stringify(item),
      };
    } catch (error) {
      console.error("Error creating product:", error);
      // Check for JSON parse error specifically
      if (error instanceof SyntaxError) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Invalid JSON format in request body.",
          }),
        };
      }
      return {
        statusCode: 500, // Internal Server Error
        headers,
        body: JSON.stringify({
          error: "Failed to create product",
          details: error.message,
        }),
      };
    }
  }

  // --- DELETE Handler (Delete a product by id and owner) ---
  if (method === "DELETE" && event.path.startsWith("/products/")) {
    const id = event.pathParameters?.id || event.path.split("/").pop();
    const owner = event.queryStringParameters?.owner;
    if (!id || !owner) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: "Product ID and owner are required for deletion.",
        }),
      };
    }
    try {
      await ddb.delete({ TableName: TABLE, Key: { id, owner } }).promise();
      return {
        statusCode: 204,
        headers,
        body: "",
      };
    } catch (error) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: "Failed to delete product",
          details: error.message,
        }),
      };
    }
  }

  // --- PUT Handler (Edit/update a product by id and owner) ---
  if (method === "PUT" && event.path.startsWith("/products/")) {
    const id = event.pathParameters?.id || event.path.split("/").pop();
    const owner = event.queryStringParameters?.owner;
    if (!id || !owner) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: "Product ID and owner are required for update.",
        }),
      };
    }
    if (!event.body) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Request body is missing." }),
      };
    }
    const body = JSON.parse(event.body);

    // Only allow updating certain fields
    const updatableFields = [
      "name",
      "description",
      "category",
      "imageUrls",
      "videoUrls",
      "price",
      "quantity",
      "unit",
      "sellerName",
      "location",
      "isActive",
      "rating",
      "reviewCount",
    ];

    const updateExpressions = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    for (const field of updatableFields) {
      if (body[field] !== undefined) {
        updateExpressions.push(`#${field} = :${field}`);
        expressionAttributeNames[`#${field}`] = field;
        expressionAttributeValues[`:${field}`] = body[field];
      }
    }

    // Always update the updatedAt timestamp
    updateExpressions.push(`#updatedAt = :updatedAt`);
    expressionAttributeNames[`#updatedAt`] = "updatedAt";
    expressionAttributeValues[":updatedAt"] = new Date().toISOString();

    // For backward compatibility, update imageUrl to first image if imageUrls is present
    if (
      body.imageUrls &&
      Array.isArray(body.imageUrls) &&
      body.imageUrls.length > 0
    ) {
      updateExpressions.push(`#imageUrl = :imageUrl`);
      expressionAttributeNames[`#imageUrl`] = "imageUrl";
      expressionAttributeValues[":imageUrl"] = body.imageUrls[0];
    }

    if (updateExpressions.length === 1) {
      // Only updatedAt was added
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "No valid fields to update." }),
      };
    }

    const updateParams = {
      TableName: TABLE,
      Key: { id, owner },
      UpdateExpression: `SET ${updateExpressions.join(", ")}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: "ALL_NEW",
    };

    // Add detailed logging for debugging
    console.log("Attempting to update product:", { id, owner, body });
    console.log(
      "DynamoDB update params:",
      JSON.stringify(updateParams, null, 2)
    );

    try {
      const result = await ddb.update(updateParams).promise();

      // Ensure returned item has all required fields for Product model
      const updatedItem = {
        id: result.Attributes.id || "",
        name: result.Attributes.name || "",
        description: result.Attributes.description || "",
        category: result.Attributes.category || "",
        price: result.Attributes.price || 0,
        imageUrl:
          result.Attributes.imageUrl ||
          (Array.isArray(result.Attributes.imageUrls) &&
          result.Attributes.imageUrls.length > 0
            ? result.Attributes.imageUrls[0]
            : ""),
        imageUrls: Array.isArray(result.Attributes.imageUrls)
          ? result.Attributes.imageUrls
          : result.Attributes.imageUrl
            ? [result.Attributes.imageUrl]
            : [],
        videoUrls: Array.isArray(result.Attributes.videoUrls)
          ? result.Attributes.videoUrls
          : [],
        unit: result.Attributes.unit || null,
        owner: result.Attributes.owner || null,
        sellerName: result.Attributes.sellerName || null,
        location: result.Attributes.location || "Unknown Location",
        quantity: result.Attributes.quantity || 0,
        createdAt: result.Attributes.createdAt || new Date().toISOString(),
        updatedAt: result.Attributes.updatedAt || null,
        isActive:
          result.Attributes.isActive !== undefined
            ? result.Attributes.isActive
            : true,
        rating: result.Attributes.rating || null,
        reviewCount: result.Attributes.reviewCount || null,
      };

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(updatedItem),
      };
    } catch (error) {
      console.error("DynamoDB update error:", error);
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          error: "Failed to update product",
          details: error.message,
        }),
      };
    }
  }

  // --- Default Response for unhandled paths/methods ---
  console.warn("Method/path not allowed or not found:", method, event.path);
  return {
    statusCode: 404, // Changed to 404 Not Found for unhandled paths
    headers,
    body: JSON.stringify({ error: `Cannot ${method} ${event.path}` }),
  };
};

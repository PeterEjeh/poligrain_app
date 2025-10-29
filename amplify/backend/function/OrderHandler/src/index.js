const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient();

const ORDERS_TABLE = process.env.ORDERS_TABLE || "Orders";
const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE || "products";
const USER_PROFILES_TABLE = process.env.USER_PROFILES_TABLE || "UserProfiles";
const RESERVATIONS_TABLE = process.env.RESERVATIONS_TABLE || "InventoryReservations";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS,PUT,DELETE",
};

/**
 * Generate unique order ID
 */
function generateOrderId() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 1000);
  return `ORD-${timestamp}-${random.toString().padStart(3, "0")}`;
}

/**
 * Get user information from Cognito Identity
 */
async function getUserInfo(event) {
  const cognitoIdentityId = event.requestContext?.identity?.cognitoIdentityId;

  if (!cognitoIdentityId) {
    console.log("No Cognito Identity ID found");
    return { userId: null, userProfile: null };
  }

  try {
    // Query user profile using GSI
    const profileParams = {
      TableName: USER_PROFILES_TABLE,
      IndexName: "byCognitoIdentityId",
      KeyConditionExpression: "cognitoIdentityId = :cognitoIdentityId",
      ExpressionAttributeValues: {
        ":cognitoIdentityId": cognitoIdentityId,
      },
    };

    const userProfileData = await ddb.query(profileParams).promise();
    const userProfile = userProfileData.Items?.[0] || null;

    return {
      userId: cognitoIdentityId,
      userProfile: userProfile,
    };
  } catch (error) {
    console.error("Error fetching user profile:", error);
    return { userId: cognitoIdentityId, userProfile: null };
  }
}

/**
 * Validate product availability and stock considering reservations
 */
async function validateOrderItems(items, reservationIds = {}) {
  const validationResults = [];

  for (const item of items) {
    try {
      const productParams = {
        TableName: PRODUCTS_TABLE,
        Key: { id: item.productId },
      };

      const productData = await ddb.get(productParams).promise();
      const product = productData.Item;

      if (!product) {
        validationResults.push({
          productId: item.productId,
          valid: false,
          error: "Product not found",
        });
        continue;
      }

      if (!product.isActive) {
        validationResults.push({
          productId: item.productId,
          valid: false,
          error: "Product is no longer active",
        });
        continue;
      }

      // If we have a reservation ID for this product, validate it
      const reservationId = reservationIds[item.productId];
      if (reservationId) {
        const reservationParams = {
          TableName: RESERVATIONS_TABLE,
          Key: { id: reservationId },
        };

        const reservationData = await ddb.get(reservationParams).promise();
        const reservation = reservationData.Item;

        if (!reservation || reservation.status !== "active") {
          validationResults.push({
            productId: item.productId,
            valid: false,
            error: "Invalid or expired reservation",
          });
          continue;
        }

        if (reservation.quantity < item.quantity) {
          validationResults.push({
            productId: item.productId,
            valid: false,
            error: `Reserved quantity (${reservation.quantity}) is less than requested (${item.quantity})`,
          });
          continue;
        }
      } else {
        // No reservation - check available quantity
        const availableQuantity = product.quantity - (product.reservedQuantity || 0);
        if (availableQuantity < item.quantity) {
          validationResults.push({
            productId: item.productId,
            valid: false,
            error: `Insufficient available stock. Available: ${availableQuantity}, Requested: ${item.quantity}`,
          });
          continue;
        }
      }

      validationResults.push({
        productId: item.productId,
        valid: true,
        product: product,
        reservationId: reservationId,
      });
    } catch (error) {
      console.error(`Error validating product ${item.productId}:`, error);
      validationResults.push({
        productId: item.productId,
        valid: false,
        error: "Error validating product",
      });
    }
  }

  return validationResults;
}

/**
 * Update product quantities and confirm reservations after order creation
 */
async function updateProductQuantitiesWithReservations(orderItems, validationResults) {
  const updatePromises = orderItems.map(async (item) => {
    try {
      const validationResult = validationResults.find(v => v.productId === item.productId);
      const reservationId = validationResult?.reservationId;

      if (reservationId) {
        // Confirm the reservation
        const confirmParams = {
          TableName: RESERVATIONS_TABLE,
          Key: { id: reservationId },
          UpdateExpression: "SET #status = :status, confirmedAt = :confirmedAt, updatedAt = :updatedAt",
          ExpressionAttributeNames: { "#status": "status" },
          ExpressionAttributeValues: {
            ":status": "confirmed",
            ":confirmedAt": new Date().toISOString(),
            ":updatedAt": new Date().toISOString(),
          },
        };

        await ddb.update(confirmParams).promise();

        // Reduce actual inventory and reserved quantity
        const updateParams = {
          TableName: PRODUCTS_TABLE,
          Key: { id: item.productId },
          UpdateExpression:
            "ADD quantity :quantityDecrement, reservedQuantity :reservedDecrement SET updatedAt = :updatedAt",
          ExpressionAttributeValues: {
            ":quantityDecrement": -item.quantity,
            ":reservedDecrement": -item.quantity,
            ":updatedAt": new Date().toISOString(),
          },
        };

        await ddb.update(updateParams).promise();
      } else {
        // No reservation - directly reduce inventory
        const updateParams = {
          TableName: PRODUCTS_TABLE,
          Key: { id: item.productId },
          UpdateExpression:
            "ADD quantity :quantityDecrement SET updatedAt = :updatedAt",
          ExpressionAttributeValues: {
            ":quantityDecrement": -item.quantity,
            ":updatedAt": new Date().toISOString(),
          },
          ConditionExpression: "quantity >= :requestedQuantity",
          ExpressionAttributeValues: {
            ":quantityDecrement": -item.quantity,
            ":updatedAt": new Date().toISOString(),
            ":requestedQuantity": item.quantity,
          },
        };

        await ddb.update(updateParams).promise();
      }

      return { productId: item.productId, success: true };
    } catch (error) {
      console.error(
        `Error updating quantity for product ${item.productId}:`,
        error
      );
      return {
        productId: item.productId,
        success: false,
        error: error.message,
      };
    }
  });

  return await Promise.all(updatePromises);
}

/**
 * Calculate order totals
 */
function calculateOrderTotals(items, taxRate = 0.08, shippingRate = 5.0) {
  const subtotal = items.reduce(
    (sum, item) => sum + item.unitPrice * item.quantity,
    0
  );
  const tax = subtotal * taxRate;
  const shippingCost = subtotal > 50 ? 0 : shippingRate; // Free shipping over $50
  const totalAmount = subtotal + tax + shippingCost;

  return {
    subtotal: Math.round(subtotal * 100) / 100,
    tax: Math.round(tax * 100) / 100,
    shippingCost: Math.round(shippingCost * 100) / 100,
    totalAmount: Math.round(totalAmount * 100) / 100,
  };
}

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  const method = event.httpMethod;
  const path = event.path;

  // Handle CORS preflight
  if (method === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  const { userId, userProfile } = await getUserInfo(event);

  if (!userId) {
    return {
      statusCode: 401,
      headers,
      body: JSON.stringify({
        error: "Unauthorized: User identity could not be determined",
      }),
    };
  }

  try {
    // GET /orders - Get user's order history
    if (method === "GET" && (path === "/orders" || path === "/orders/")) {
      const queryParams = event.queryStringParameters || {};
      const limit = parseInt(queryParams.limit) || 20;
      const lastKey = queryParams.lastKey
        ? JSON.parse(decodeURIComponent(queryParams.lastKey))
        : null;
      const status = queryParams.status;

      let params = {
        TableName: ORDERS_TABLE,
        IndexName: "byCustomerId",
        KeyConditionExpression: "customerId = :customerId",
        ExpressionAttributeValues: {
          ":customerId": userId,
        },
        Limit: limit,
        ScanIndexForward: false, // Most recent first
      };

      if (lastKey) {
        params.ExclusiveStartKey = lastKey;
      }

      if (status) {
        params.FilterExpression = "#status = :status";
        params.ExpressionAttributeNames = { "#status": "status" };
        params.ExpressionAttributeValues[":status"] = status;
      }

      const result = await ddb.query(params).promise();

      const response = {
        orders: result.Items || [],
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

    // GET /orders/{id} - Get specific order details
    if (
      method === "GET" &&
      path.startsWith("/orders/") &&
      path !== "/orders/"
    ) {
      const orderId = path.split("/")[2];

      const params = {
        TableName: ORDERS_TABLE,
        Key: { id: orderId },
      };

      const result = await ddb.get(params).promise();

      if (!result.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Order not found" }),
        };
      }

      // Verify order belongs to user
      if (result.Item.customerId !== userId) {
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

    // POST /orders - Create new order
    if (method === "POST" && (path === "/orders" || path === "/orders/")) {
      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const orderData = JSON.parse(event.body);

      // Validate required fields
      const requiredFields = ["items", "shippingAddress"];
      for (const field of requiredFields) {
        if (!orderData[field]) {
          return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: `Missing required field: ${field}` }),
          };
        }
      }

      if (!Array.isArray(orderData.items) || orderData.items.length === 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Order must contain at least one item",
          }),
        };
      }

      // Extract reservation IDs if provided
      const reservationIds = orderData.reservationIds || {};

      // Validate product availability with reservations
      const validationResults = await validateOrderItems(orderData.items, reservationIds);
      const invalidItems = validationResults.filter((result) => !result.valid);

      if (invalidItems.length > 0) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Invalid order items",
            details: invalidItems,
          }),
        };
      }

      // Calculate totals
      const totals = calculateOrderTotals(orderData.items);

      // Create order
      const orderId = generateOrderId();
      const currentTime = new Date().toISOString();

      const order = {
        id: orderId,
        customerId: userId,
        customerName: userProfile?.name || orderData.shippingAddress.fullName,
        customerEmail:
          userProfile?.email ||
          orderData.customerEmail ||
          "unknown@example.com",
        items: orderData.items.map((item) => {
          const validProduct = validationResults.find(
            (v) => v.productId === item.productId
          )?.product;
          return {
            productId: item.productId,
            productName: validProduct?.name || item.productName,
            productImageUrl:
              validProduct?.imageUrl || validProduct?.imageUrls?.[0] || "",
            category: validProduct?.category || "",
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            unit: validProduct?.unit || null,
            sellerId: validProduct?.owner || "",
            sellerName: validProduct?.sellerName || "Unknown Seller",
            totalPrice: item.unitPrice * item.quantity,
          };
        }),
        subtotal: totals.subtotal,
        tax: totals.tax,
        shippingCost: totals.shippingCost,
        totalAmount: totals.totalAmount,
        status: "Pending",
        paymentStatus: "Pending",
        paymentMethod: orderData.paymentMethod || null,
        shippingAddress: orderData.shippingAddress,
        billingAddress: orderData.billingAddress || null,
        notes: orderData.notes || null,
        createdAt: currentTime,
        updatedAt: null,
        statusHistory: [
          {
            status: "Pending",
            timestamp: currentTime,
            notes: "Order created",
            updatedBy: "system",
          },
        ],
      };

      // Save order to database
      await ddb
        .put({
          TableName: ORDERS_TABLE,
          Item: order,
        })
        .promise();

      // Update product quantities and confirm reservations
      const quantityUpdates = await updateProductQuantitiesWithReservations(orderData.items, validationResults);
      const failedUpdates = quantityUpdates.filter((update) => !update.success);

      if (failedUpdates.length > 0) {
        console.warn(
          "Some product quantities failed to update:",
          failedUpdates
        );
        // In a production system, you might want to implement compensation logic here
      }

      return {
        statusCode: 201,
        headers,
        body: JSON.stringify(order),
      };
    }

    // PUT /orders/{id}/status - Update order status
    if (
      method === "PUT" &&
      path.includes("/orders/") &&
      path.endsWith("/status")
    ) {
      const orderId = path.split("/")[2];

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
        "Confirmed",
        "Processing",
        "Shipped",
        "Delivered",
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

      const currentTime = new Date().toISOString();

      // Get current order
      const getParams = {
        TableName: ORDERS_TABLE,
        Key: { id: orderId },
      };

      const currentOrder = await ddb.get(getParams).promise();

      if (!currentOrder.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Order not found" }),
        };
      }

      // Build update expression
      let updateExpression = "SET #status = :status, updatedAt = :updatedAt";
      let expressionAttributeNames = { "#status": "status" };
      let expressionAttributeValues = {
        ":status": status,
        ":updatedAt": currentTime,
      };

      // Add status-specific timestamp fields
      if (status === "Confirmed") {
        updateExpression += ", confirmedAt = :confirmedAt";
        expressionAttributeValues[":confirmedAt"] = currentTime;
      } else if (status === "Shipped") {
        updateExpression += ", shippedAt = :shippedAt";
        expressionAttributeValues[":shippedAt"] = currentTime;
      } else if (status === "Delivered") {
        updateExpression += ", deliveredAt = :deliveredAt";
        expressionAttributeValues[":deliveredAt"] = currentTime;
      }

      // Add to status history
      const newStatusHistory = [
        ...(currentOrder.Item.statusHistory || []),
        {
          status: status,
          timestamp: currentTime,
          notes: notes || null,
          updatedBy: userId,
        },
      ];

      updateExpression += ", statusHistory = :statusHistory";
      expressionAttributeValues[":statusHistory"] = newStatusHistory;

      const updateParams = {
        TableName: ORDERS_TABLE,
        Key: { id: orderId },
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

    // PUT /orders/{id}/tracking - Update tracking information
    if (
      method === "PUT" &&
      path.includes("/orders/") &&
      path.endsWith("/tracking")
    ) {
      const orderId = path.split("/")[2];

      if (!event.body) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Request body is required" }),
        };
      }

      const { trackingNumber } = JSON.parse(event.body);

      if (!trackingNumber) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: "Tracking number is required" }),
        };
      }

      const updateParams = {
        TableName: ORDERS_TABLE,
        Key: { id: orderId },
        UpdateExpression:
          "SET trackingNumber = :trackingNumber, updatedAt = :updatedAt",
        ExpressionAttributeValues: {
          ":trackingNumber": trackingNumber,
          ":updatedAt": new Date().toISOString(),
        },
        ReturnValues: "ALL_NEW",
      };

      const result = await ddb.update(updateParams).promise();

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Attributes),
      };
    }

    // DELETE /orders/{id} - Cancel order (soft delete)
    if (
      method === "DELETE" &&
      path.startsWith("/orders/") &&
      path !== "/orders/"
    ) {
      const orderId = path.split("/")[2];

      // Get current order
      const getParams = {
        TableName: ORDERS_TABLE,
        Key: { id: orderId },
      };

      const currentOrder = await ddb.get(getParams).promise();

      if (!currentOrder.Item) {
        return {
          statusCode: 404,
          headers,
          body: JSON.stringify({ error: "Order not found" }),
        };
      }

      // Verify order belongs to user
      if (currentOrder.Item.customerId !== userId) {
        return {
          statusCode: 403,
          headers,
          body: JSON.stringify({ error: "Access denied" }),
        };
      }

      // Check if order can be cancelled
      const cancellableStatuses = ["Pending", "Confirmed"];
      if (!cancellableStatuses.includes(currentOrder.Item.status)) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({
            error: "Order cannot be cancelled in current status",
            currentStatus: currentOrder.Item.status,
          }),
        };
      }

      const currentTime = new Date().toISOString();

      // Update order status to cancelled
      const newStatusHistory = [
        ...(currentOrder.Item.statusHistory || []),
        {
          status: "Cancelled",
          timestamp: currentTime,
          notes: "Order cancelled by customer",
          updatedBy: userId,
        },
      ];

      const updateParams = {
        TableName: ORDERS_TABLE,
        Key: { id: orderId },
        UpdateExpression:
          "SET #status = :status, updatedAt = :updatedAt, statusHistory = :statusHistory",
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: {
          ":status": "Cancelled",
          ":updatedAt": currentTime,
          ":statusHistory": newStatusHistory,
        },
        ReturnValues: "ALL_NEW",
      };

      const result = await ddb.update(updateParams).promise();

      // Restore product quantities
      try {
        const restorePromises = currentOrder.Item.items.map(async (item) => {
          const restoreParams = {
            TableName: PRODUCTS_TABLE,
            Key: { id: item.productId },
            UpdateExpression:
              "ADD quantity :quantityIncrement SET updatedAt = :updatedAt",
            ExpressionAttributeValues: {
              ":quantityIncrement": item.quantity,
              ":updatedAt": currentTime,
            },
          };

          return await ddb.update(restoreParams).promise();
        });

        await Promise.all(restorePromises);
      } catch (error) {
        console.error("Error restoring product quantities:", error);
        // Continue even if quantity restoration fails
      }

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Attributes),
      };
    }

    // If no route matches
    return {
      statusCode: 404,
      headers,
      body: JSON.stringify({
        error: `Cannot ${method} ${path}`,
      }),
    };
  } catch (error) {
    console.error("Error processing order request:", error);

    // Handle specific AWS errors
    if (error.code === "ConditionalCheckFailedException") {
      return {
        statusCode: 409,
        headers,
        body: JSON.stringify({
          error: "Conflict: Resource state has changed",
          details: error.message,
        }),
      };
    }

    if (error.code === "ValidationException") {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: "Validation error",
          details: error.message,
        }),
      };
    }

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

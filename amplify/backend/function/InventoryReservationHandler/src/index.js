const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
  TransactWriteCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require("uuid");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE || "Products";
const RESERVATIONS_TABLE =
  process.env.RESERVATIONS_TABLE || "InventoryReservations";

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  const { httpMethod, path, pathParameters, body, requestContext } = event;
  const userId = requestContext?.authorizer?.claims?.sub || "anonymous";

  try {
    // Parse request body if present
    const requestBody = body ? JSON.parse(body) : {};

    // Route handlers
    switch (httpMethod) {
      case "POST":
        if (path === "/inventory/reserve") {
          return await createReservation(userId, requestBody);
        } else if (path === "/inventory/reserve/bulk") {
          return await createBulkReservations(userId, requestBody);
        } else if (path.includes("/confirm")) {
          const reservationId = pathParameters?.reservationId;
          return await confirmReservation(userId, reservationId, requestBody);
        } else if (path.includes("/extend")) {
          const reservationId = pathParameters?.reservationId;
          return await extendReservation(userId, reservationId, requestBody);
        }
        break;

      case "GET":
        if (path.includes("/availability/")) {
          const productId = pathParameters?.productId;
          return await getProductAvailability(productId);
        } else if (path.includes("/reserve/user/")) {
          const targetUserId = pathParameters?.userId;
          return await getUserReservations(targetUserId);
        }
        break;

      case "DELETE":
        if (path.includes("/reserve/user/")) {
          const targetUserId = pathParameters?.userId;
          return await releaseAllUserReservations(targetUserId);
        } else if (path.includes("/reserve/")) {
          const reservationId = pathParameters?.reservationId;
          return await releaseReservation(userId, reservationId);
        }
        break;

      default:
        return createResponse(405, { error: "Method not allowed" });
    }

    return createResponse(404, { error: "Not found" });
  } catch (error) {
    console.error("Handler error:", error);
    return createResponse(500, {
      error: "Internal server error",
      details: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

async function createReservation(userId, request) {
  const {
    productId,
    quantity,
    sessionId,
    durationMinutes = 15,
    metadata,
  } = request;

  if (!productId || !quantity || quantity <= 0) {
    return createResponse(400, { error: "Invalid request parameters" });
  }

  try {
    // Check product availability
    const availability = await checkProductAvailability(productId, quantity);
    if (!availability.available) {
      return createResponse(400, {
        success: false,
        error: availability.error || "Insufficient stock",
      });
    }

    // Create reservation
    const reservationId = uuidv4();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + durationMinutes * 60000);

    const reservation = {
      id: reservationId,
      productId,
      userId,
      sessionId,
      quantity,
      status: "active",
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      metadata,
    };

    // Use transaction to reserve inventory atomically
    const transactItems = [
      {
        Put: {
          TableName: RESERVATIONS_TABLE,
          Item: reservation,
          ConditionExpression: "attribute_not_exists(id)",
        },
      },
      {
        Update: {
          TableName: PRODUCTS_TABLE,
          Key: { id: productId },
          UpdateExpression: "ADD reservedQuantity :quantity",
          ExpressionAttributeValues: {
            ":quantity": quantity,
            ":maxReserved": availability.product.quantity,
          },
          ConditionExpression: "reservedQuantity + :quantity <= quantity",
        },
      },
    ];

    await docClient.send(
      new TransactWriteCommand({
        TransactItems: transactItems,
      })
    );

    return createResponse(201, {
      success: true,
      reservation,
    });
  } catch (error) {
    console.error("Create reservation error:", error);

    if (error.name === "TransactionCanceledException") {
      return createResponse(400, {
        success: false,
        error: "Insufficient stock or reservation conflict",
      });
    }

    return createResponse(500, {
      success: false,
      error: "Failed to create reservation",
    });
  }
}

async function createBulkReservations(userId, request) {
  const { reservations } = request;

  if (
    !reservations ||
    !Array.isArray(reservations) ||
    reservations.length === 0
  ) {
    return createResponse(400, { error: "Invalid reservations array" });
  }

  const results = {};
  const transactItems = [];

  try {
    // Check availability for all products first
    for (const reservation of reservations) {
      const availability = await checkProductAvailability(
        reservation.productId,
        reservation.quantity
      );

      if (!availability.available) {
        results[reservation.productId] = {
          success: false,
          error: availability.error || "Insufficient stock",
        };
        continue;
      }

      // Create reservation object
      const reservationId = uuidv4();
      const now = new Date();
      const expiresAt = new Date(
        now.getTime() + (reservation.durationMinutes || 15) * 60000
      );

      const reservationObj = {
        id: reservationId,
        productId: reservation.productId,
        userId,
        sessionId: reservation.sessionId,
        quantity: reservation.quantity,
        status: "active",
        createdAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        metadata: reservation.metadata,
      };

      // Add to transaction
      transactItems.push(
        {
          Put: {
            TableName: RESERVATIONS_TABLE,
            Item: reservationObj,
            ConditionExpression: "attribute_not_exists(id)",
          },
        },
        {
          Update: {
            TableName: PRODUCTS_TABLE,
            Key: { id: reservation.productId },
            UpdateExpression: "ADD reservedQuantity :quantity",
            ExpressionAttributeValues: {
              ":quantity": reservation.quantity,
            },
            ConditionExpression: "reservedQuantity + :quantity <= quantity",
          },
        }
      );

      results[reservation.productId] = {
        success: true,
        reservation: reservationObj,
      };
    }

    // If all reservations are successful, execute transaction
    if (
      transactItems.length > 0 &&
      Object.values(results).every((r) => r.success)
    ) {
      await docClient.send(
        new TransactWriteCommand({
          TransactItems: transactItems,
        })
      );
    }

    return createResponse(200, {
      success: true,
      reservations: results,
    });
  } catch (error) {
    console.error("Bulk reservation error:", error);

    // If transaction fails, mark all as failed
    for (const productId in results) {
      if (results[productId].success) {
        results[productId] = {
          success: false,
          error: "Transaction failed",
        };
      }
    }

    return createResponse(400, {
      success: false,
      reservations: results,
    });
  }
}

async function confirmReservation(userId, reservationId, request) {
  const { orderId } = request;

  if (!reservationId) {
    return createResponse(400, { error: "Reservation ID is required" });
  }

  try {
    // Get the reservation
    const getResult = await docClient.send(
      new GetCommand({
        TableName: RESERVATIONS_TABLE,
        Key: { id: reservationId },
      })
    );

    if (!getResult.Item) {
      return createResponse(404, { error: "Reservation not found" });
    }

    const reservation = getResult.Item;

    // Check if user owns the reservation
    if (reservation.userId !== userId) {
      return createResponse(403, { error: "Unauthorized" });
    }

    // Check if reservation is still active
    if (reservation.status !== "active") {
      return createResponse(400, { error: "Reservation is not active" });
    }

    // Check if reservation has expired
    if (new Date() > new Date(reservation.expiresAt)) {
      return createResponse(400, { error: "Reservation has expired" });
    }

    // Update reservation status to confirmed
    const updateResult = await docClient.send(
      new UpdateCommand({
        TableName: RESERVATIONS_TABLE,
        Key: { id: reservationId },
        UpdateExpression:
          "SET #status = :status, confirmedAt = :confirmedAt, orderId = :orderId",
        ExpressionAttributeNames: {
          "#status": "status",
        },
        ExpressionAttributeValues: {
          ":status": "confirmed",
          ":confirmedAt": new Date().toISOString(),
          ":orderId": orderId,
        },
        ConditionExpression: "#status = :activeStatus",
        ExpressionAttributeValues: {
          ...{
            ":status": "confirmed",
            ":confirmedAt": new Date().toISOString(),
            ":orderId": orderId,
          },
          ":activeStatus": "active",
        },
        ReturnValues: "ALL_NEW",
      })
    );

    return createResponse(200, {
      success: true,
      reservation: updateResult.Attributes,
    });
  } catch (error) {
    console.error("Confirm reservation error:", error);

    if (error.name === "ConditionalCheckFailedException") {
      return createResponse(400, {
        success: false,
        error: "Reservation is no longer active",
      });
    }

    return createResponse(500, {
      success: false,
      error: "Failed to confirm reservation",
    });
  }
}

async function extendReservation(userId, reservationId, request) {
  const { additionalMinutes = 15 } = request;

  if (!reservationId) {
    return createResponse(400, { error: "Reservation ID is required" });
  }

  try {
    // Get the reservation
    const getResult = await docClient.send(
      new GetCommand({
        TableName: RESERVATIONS_TABLE,
        Key: { id: reservationId },
      })
    );

    if (!getResult.Item) {
      return createResponse(404, { error: "Reservation not found" });
    }

    const reservation = getResult.Item;

    // Check if user owns the reservation
    if (reservation.userId !== userId) {
      return createResponse(403, { error: "Unauthorized" });
    }

    // Check if reservation is still active
    if (reservation.status !== "active") {
      return createResponse(400, { error: "Reservation is not active" });
    }

    // Calculate new expiration time
    const currentExpiry = new Date(reservation.expiresAt);
    const newExpiry = new Date(
      currentExpiry.getTime() + additionalMinutes * 60000
    );

    // Update reservation expiration
    const updateResult = await docClient.send(
      new UpdateCommand({
        TableName: RESERVATIONS_TABLE,
        Key: { id: reservationId },
        UpdateExpression: "SET expiresAt = :newExpiry",
        ExpressionAttributeValues: {
          ":newExpiry": newExpiry.toISOString(),
          ":activeStatus": "active",
        },
        ConditionExpression: "#status = :activeStatus",
        ExpressionAttributeNames: {
          "#status": "status",
        },
        ReturnValues: "ALL_NEW",
      })
    );

    return createResponse(200, {
      success: true,
      reservation: updateResult.Attributes,
    });
  } catch (error) {
    console.error("Extend reservation error:", error);

    if (error.name === "ConditionalCheckFailedException") {
      return createResponse(400, {
        success: false,
        error: "Reservation is no longer active",
      });
    }

    return createResponse(500, {
      success: false,
      error: "Failed to extend reservation",
    });
  }
}

async function getProductAvailability(productId) {
  if (!productId) {
    return createResponse(400, { error: "Product ID is required" });
  }

  try {
    // Get product details
    const productResult = await docClient.send(
      new GetCommand({
        TableName: PRODUCTS_TABLE,
        Key: { id: productId },
      })
    );

    if (!productResult.Item) {
      return createResponse(404, { error: "Product not found" });
    }

    const product = productResult.Item;
    const totalQuantity = product.quantity || 0;
    const reservedQuantity = product.reservedQuantity || 0;
    const availableQuantity = totalQuantity - reservedQuantity;

    // Get active reservations for this product
    const reservationsResult = await docClient.send(
      new QueryCommand({
        TableName: RESERVATIONS_TABLE,
        IndexName: "ProductIdIndex", // Assuming you have a GSI on productId
        KeyConditionExpression: "productId = :productId",
        FilterExpression: "#status = :status AND expiresAt > :now",
        ExpressionAttributeNames: {
          "#status": "status",
        },
        ExpressionAttributeValues: {
          ":productId": productId,
          ":status": "active",
          ":now": new Date().toISOString(),
        },
      })
    );

    return createResponse(200, {
      productId,
      totalQuantity,
      reservedQuantity,
      availableQuantity,
      activeReservations: reservationsResult.Items?.length || 0,
    });
  } catch (error) {
    console.error("Get availability error:", error);
    return createResponse(500, {
      error: "Failed to get product availability",
    });
  }
}

async function getUserReservations(targetUserId) {
  if (!targetUserId) {
    return createResponse(400, { error: "User ID is required" });
  }

  try {
    const result = await docClient.send(
      new QueryCommand({
        TableName: RESERVATIONS_TABLE,
        IndexName: "UserIdIndex", // Assuming you have a GSI on userId
        KeyConditionExpression: "userId = :userId",
        ExpressionAttributeValues: {
          ":userId": targetUserId,
        },
      })
    );

    return createResponse(200, {
      reservations: result.Items || [],
    });
  } catch (error) {
    console.error("Get user reservations error:", error);
    return createResponse(500, {
      error: "Failed to get user reservations",
    });
  }
}

async function releaseReservation(userId, reservationId) {
  if (!reservationId) {
    return createResponse(400, { error: "Reservation ID is required" });
  }

  try {
    // Get the reservation first
    const getResult = await docClient.send(
      new GetCommand({
        TableName: RESERVATIONS_TABLE,
        Key: { id: reservationId },
      })
    );
    if (!getResult.Item) {
      return createResponse(404, { error: "Reservation not found" });
    }

    // Check if the user is authorized to release this reservation
    if (getResult.Item.userId !== userId) {
      return createResponse(403, { error: "Unauthorized" });
    }

    // Release the reservation
    await docClient.send(
      new DeleteCommand({
        TableName: RESERVATIONS_TABLE,
        Key: { id: reservationId },
      })
    );

    return createResponse(200, { success: true });
  } catch (error) {
    console.error("Release reservation error:", error);
    return createResponse(500, {
      success: false,
      error: "Failed to release reservation",
    });
  }
}
async function releaseAllUserReservations(targetUserId) {
  if (!targetUserId) {
    return createResponse(400, { error: "User ID is required" });
  }

  try {
    // Scan for all reservations of the user
    const scanResult = await docClient.send(
      new ScanCommand({
        TableName: RESERVATIONS_TABLE,
        FilterExpression: "userId = :userId",
        ExpressionAttributeValues: {
          ":userId": targetUserId,
        },
      })
    );

    if (scanResult.Items.length === 0) {
      return createResponse(404, {
        error: "No reservations found for this user",
      });
    }

    // Prepare batch delete requests
    const deleteRequests = scanResult.Items.map((item) => ({
      Delete: {
        TableName: RESERVATIONS_TABLE,
        Key: { id: item.id },
      },
    }));

    // Execute batch delete
    for (const request of deleteRequests) {
      await docClient.send(new DeleteCommand(request));
    }

    return createResponse(200, { success: true });
  } catch (error) {
    console.error("Release all user reservations error:", error);
    return createResponse(500, {
      success: false,
      error: "Failed to release all reservations",
    });
  }
}
function createResponse(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(body),
  };
}

module.exports = { handler: exports.handler };
exports.createResponse = createResponse;
exports.checkProductAvailability = checkProductAvailability;
exports.createReservation = createReservation;

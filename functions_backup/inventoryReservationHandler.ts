import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
  TransactWriteCommand,
  ScanCommand
} from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE || 'Products';
const RESERVATIONS_TABLE = process.env.RESERVATIONS_TABLE || 'InventoryReservations';

interface ReservationRequest {
  productId: string;
  quantity: number;
  sessionId?: string;
  durationMinutes?: number;
  metadata?: Record<string, any>;
}

interface InventoryReservation {
  id: string;
  productId: string;
  userId: string;
  sessionId?: string;
  quantity: number;
  status: 'active' | 'expired' | 'confirmed' | 'cancelled';
  createdAt: string;
  expiresAt: string;
  confirmedAt?: string;
  cancelledAt?: string;
  orderId?: string;
  metadata?: Record<string, any>;
}

export const handler = async (event: any) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const { httpMethod, path, pathParameters, body, requestContext } = event;
  const userId = requestContext?.authorizer?.claims?.sub || 'anonymous';

  try {
    // Parse request body if present
    const requestBody = body ? JSON.parse(body) : {};

    // Route handlers
    switch (httpMethod) {
      case 'POST':
        if (path === '/inventory/reserve') {
          return await createReservation(userId, requestBody);
        } else if (path === '/inventory/reserve/bulk') {
          return await createBulkReservations(userId, requestBody);
        } else if (path.includes('/confirm')) {
          const reservationId = pathParameters?.reservationId;
          return await confirmReservation(userId, reservationId, requestBody);
        } else if (path.includes('/extend')) {
          const reservationId = pathParameters?.reservationId;
          return await extendReservation(userId, reservationId, requestBody);
        }
        break;

      case 'GET':
        if (path.includes('/availability/')) {
          const productId = pathParameters?.productId;
          return await getProductAvailability(productId);
        } else if (path.includes('/reserve/user/')) {
          const targetUserId = pathParameters?.userId;
          return await getUserReservations(targetUserId);
        }
        break;

      case 'DELETE':
        if (path.includes('/reserve/user/')) {
          const targetUserId = pathParameters?.userId;
          return await releaseAllUserReservations(targetUserId);
        } else if (path.includes('/reserve/')) {
          const reservationId = pathParameters?.reservationId;
          return await releaseReservation(userId, reservationId);
        }
        break;

      default:
        return createResponse(405, { error: 'Method not allowed' });
    }

    return createResponse(404, { error: 'Not found' });
  } catch (error) {
    console.error('Handler error:', error);
    return createResponse(500, {
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
};

async function createReservation(userId: string, request: ReservationRequest) {
  const { productId, quantity, sessionId, durationMinutes = 15, metadata } = request;

  if (!productId || !quantity || quantity <= 0) {
    return createResponse(400, { error: 'Invalid request parameters' });
  }

  try {
    // Check product availability
    const availability = await checkProductAvailability(productId, quantity);
    if (!availability.available) {
      return createResponse(400, {
        success: false,
        error: availability.error || 'Insufficient stock'
      });
    }

    // Create reservation
    const reservationId = uuidv4();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + durationMinutes * 60000);

    const reservation: InventoryReservation = {
      id: reservationId,
      productId,
      userId,
      sessionId,
      quantity,
      status: 'active',
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      metadata
    };

    // Use transaction to reserve inventory atomically
    const transactItems = [
      {
        Put: {
          TableName: RESERVATIONS_TABLE,
          Item: reservation,
          ConditionExpression: 'attribute_not_exists(id)'
        }
      },
      {
        Update: {
          TableName: PRODUCTS_TABLE,
          Key: { id: productId },
          UpdateExpression: 'ADD reservedQuantity :quantity',
          ExpressionAttributeValues: {
            ':quantity': quantity,
            ':maxReserved': availability.product.quantity
          },
          ConditionExpression: 'reservedQuantity + :quantity <= quantity'
        }
      }
    ];

    await docClient.send(new TransactWriteCommand({
      TransactItems: transactItems
    }));

    return createResponse(201, {
      success: true,
      reservation
    });

  } catch (error: any) {
    console.error('Create reservation error:', error);
    
    if (error.name === 'TransactionCanceledException') {
      return createResponse(400, {
        success: false,
        error: 'Insufficient stock or reservation conflict'
      });
    }

    return createResponse(500, {
      success: false,
      error: 'Failed to create reservation'
    });
  }
}

async function createBulkReservations(userId: string, request: { reservations: ReservationRequest[] }) {
  const { reservations } = request;

  if (!reservations || !Array.isArray(reservations) || reservations.length === 0) {
    return createResponse(400, { error: 'Invalid reservations array' });
  }

  const results: Record<string, any> = {};
  const transactItems: any[] = [];

  try {
    // Check availability for all products first
    for (const reservation of reservations) {
      const availability = await checkProductAvailability(reservation.productId, reservation.quantity);
      
      if (!availability.available) {
        results[reservation.productId] = {
          success: false,
          error: availability.error || 'Insufficient stock'
        };
        continue;
      }

      // Create reservation object
      const reservationId = uuidv4();
      const now = new Date();
      const expiresAt = new Date(now.getTime() + (reservation.durationMinutes || 15) * 60000);

      const reservationObj: InventoryReservation = {
        id: reservationId,
        productId: reservation.productId,
        userId,
        sessionId: reservation.sessionId,
        quantity: reservation.quantity,
        status: 'active',
        createdAt: now.toISOString(),
        expiresAt: expiresAt.toISOString(),
        metadata: reservation.metadata
      };

      // Add to transaction
      transactItems.push(
        {
          Put: {
            TableName: RESERVATIONS_TABLE,
            Item: reservationObj,
            ConditionExpression: 'attribute_not_exists(id)'
          }
        },
        {
          Update: {
            TableName: PRODUCTS_TABLE,
            Key: { id: reservation.productId },
            UpdateExpression: 'ADD reservedQuantity :quantity',
            ExpressionAttributeValues: {
              ':quantity': reservation.quantity
            },
            ConditionExpression: 'reservedQuantity + :quantity <= quantity'
          }
        }
      );

      results[reservation.productId] = {
        success: true,
        reservation: reservationObj
      };
    }

    // If all reservations are successful, execute transaction
    if (transactItems.length > 0 && Object.values(results).every((r: any) => r.success)) {
      await docClient.send(new TransactWriteCommand({
        TransactItems: transactItems
      }));
    }

    return createResponse(200, {
      success: true,
      reservations: results
    });

  } catch (error: any) {
    console.error('Bulk reservation error:', error);
    
    // If transaction fails, mark all as failed
    for (const productId in results) {
      if (results[productId].success) {
        results[productId] = {
          success: false,
          error: 'Transaction failed'
        };
      }
    }

    return createResponse(400, {
      success: false,
      reservations: results
    });
  }
}      return createResponse(404, {
        success: false,
        error: 'Reservation not found'
      });
    }

    const reservation = getResponse.Item as InventoryReservation;

    // Check if user owns this reservation
    if (reservation.userId !== userId) {
      return createResponse(403, {
        success: false,
        error: 'Access denied'
      });
    }

    // Only confirm active reservations
    if (reservation.status !== 'active') {
      return createResponse(400, {
        success: false,
        error: 'Reservation is not active'
      });
    }

    // Update reservation status and subtract from actual inventory
    const transactItems = [
      {
        Update: {
          TableName: RESERVATIONS_TABLE,
          Key: { id: reservationId },
          UpdateExpression: 'SET #status = :status, confirmedAt = :confirmedAt, orderId = :orderId',
          ExpressionAttributeNames: {
            '#status': 'status'
          },
          ExpressionAttributeValues: {
            ':status': 'confirmed',
            ':confirmedAt': new Date().toISOString(),
            ':orderId': orderId
          }
        }
      },
      {
        Update: {
          TableName: PRODUCTS_TABLE,
          Key: { id: reservation.productId },
          UpdateExpression: 'ADD quantity :negativeQuantity, reservedQuantity :negativeReserved',
          ExpressionAttributeValues: {
            ':negativeQuantity': -reservation.quantity,
            ':negativeReserved': -reservation.quantity
          },
          ConditionExpression: 'quantity >= :requiredQuantity AND reservedQuantity >= :requiredReserved',
          ExpressionAttributeNames: {
            ':requiredQuantity': reservation.quantity,
            ':requiredReserved': reservation.quantity
          }
        }
      }
    ];

    await docClient.send(new TransactWriteCommand({
      TransactItems: transactItems
    }));

    return createResponse(200, {
      success: true,
      message: 'Reservation confirmed successfully'
    });

  } catch (error: any) {
    console.error('Confirm reservation error:', error);
    
    if (error.name === 'TransactionCanceledException') {
      return createResponse(400, {
        success: false,
        error: 'Insufficient inventory to confirm reservation'
      });
    }

    return createResponse(500, {
      success: false,
      error: 'Failed to confirm reservation'
    });
  }
}

async function extendReservation(userId: string, reservationId: string, request: { extensionMinutes: number }) {
  const { extensionMinutes } = request;

  if (!extensionMinutes || extensionMinutes <= 0) {
    return createResponse(400, { error: 'Valid extension minutes required' });
  }

  try {
    // Get reservation first
    const getResponse = await docClient.send(new GetCommand({
      TableName: RESERVATIONS_TABLE,
      Key: { id: reservationId }
    }));

    if (!getResponse.Item) {
      return createResponse(404, {
        success: false,
        error: 'Reservation not found'
      });
    }

    const reservation = getResponse.Item as InventoryReservation;

    // Check if user owns this reservation
    if (reservation.userId !== userId) {
      return createResponse(403, {
        success: false,
        error: 'Access denied'
      });
    }

    // Only extend active reservations
    if (reservation.status !== 'active') {
      return createResponse(400, {
        success: false,
        error: 'Reservation is not active'
      });
    }

    // Calculate new expiry time
    const currentExpiry = new Date(reservation.expiresAt);
    const newExpiry = new Date(currentExpiry.getTime() + extensionMinutes * 60000);

    // Update expiry time
    await docClient.send(new UpdateCommand({
      TableName: RESERVATIONS_TABLE,
      Key: { id: reservationId },
      UpdateExpression: 'SET expiresAt = :newExpiry',
      ExpressionAttributeValues: {
        ':newExpiry': newExpiry.toISOString()
      },
      ConditionExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': 'active'
      }
    }));

    return createResponse(200, {
      success: true,
      message: 'Reservation extended successfully',
      newExpiryTime: newExpiry.toISOString()
    });

  } catch (error: any) {
    console.error('Extend reservation error:', error);
    return createResponse(500, {
      success: false,
      error: 'Failed to extend reservation'
    });
  }
}

async function getProductAvailability(productId: string) {
  if (!productId) {
    return createResponse(400, { error: 'Product ID is required' });
  }

  try {
    const response = await docClient.send(new GetCommand({
      TableName: PRODUCTS_TABLE,
      Key: { id: productId }
    }));

    if (!response.Item) {
      return createResponse(404, {
        success: false,
        error: 'Product not found'
      });
    }

    const product = response.Item;
    const totalQuantity = product.quantity || 0;
    const reservedQuantity = product.reservedQuantity || 0;
    const availableQuantity = Math.max(0, totalQuantity - reservedQuantity);

    return createResponse(200, {
      success: true,
      productId,
      totalQuantity,
      reservedQuantity,
      availableQuantity
    });

  } catch (error: any) {
    console.error('Get availability error:', error);
    return createResponse(500, {
      success: false,
      error: 'Failed to get product availability'
    });
  }
}

async function getUserReservations(userId: string) {
  try {
    const response = await docClient.send(new QueryCommand({
      TableName: RESERVATIONS_TABLE,
      IndexName: 'userIdIndex',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: {
        ':userId': userId
      },
      ScanIndexForward: false // Most recent first
    }));

    const reservations = response.Items as InventoryReservation[];

    return createResponse(200, {
      success: true,
      reservations: reservations || []
    });

  } catch (error: any) {
    console.error('Get user reservations error:', error);
    return createResponse(500, {
      success: false,
      error: 'Failed to get user reservations'
    });
  }
}

async function checkProductAvailability(productId: string, requestedQuantity: number) {
  try {
    const response = await docClient.send(new GetCommand({
      TableName: PRODUCTS_TABLE,
      Key: { id: productId }
    }));

    if (!response.Item) {
      return {
        available: false,
        error: 'Product not found'
      };
    }

    const product = response.Item;
    
    if (!product.isActive) {
      return {
        available: false,
        error: 'Product is not active'
      };
    }

    const totalQuantity = product.quantity || 0;
    const reservedQuantity = product.reservedQuantity || 0;
    const availableQuantity = totalQuantity - reservedQuantity;

    if (requestedQuantity > availableQuantity) {
      return {
        available: false,
        error: `Insufficient stock. Available: ${availableQuantity}, Requested: ${requestedQuantity}`,
        availableQuantity
      };
    }

    return {
      available: true,
      product,
      availableQuantity
    };

  } catch (error: any) {
    console.error('Check availability error:', error);
    return {
      available: false,
      error: 'Failed to check product availability'
    };
  }
}

function createResponse(statusCode: number, body: any) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    },
    body: JSON.stringify(body)
  };
}

// Background cleanup function (can be triggered by CloudWatch Events)
export const cleanupExpiredReservations = async () => {
  try {
    console.log('Starting cleanup of expired reservations');

    // Scan for expired reservations
    const scanResponse = await docClient.send(new ScanCommand({
      TableName: RESERVATIONS_TABLE,
      FilterExpression: '#status = :activeStatus AND expiresAt < :now',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':activeStatus': 'active',
        ':now': new Date().toISOString()
      }
    }));

    const expiredReservations = scanResponse.Items as InventoryReservation[];

    if (!expiredReservations || expiredReservations.length === 0) {
      console.log('No expired reservations found');
      return;
    }

    console.log(`Found ${expiredReservations.length} expired reservations`);

    // Process in batches
    const batchSize = 12; // 2 operations per reservation
    for (let i = 0; i < expiredReservations.length; i += batchSize) {
      const batch = expiredReservations.slice(i, i + batchSize);
      const transactItems: any[] = [];

      for (const reservation of batch) {
        transactItems.push(
          {
            Update: {
              TableName: RESERVATIONS_TABLE,
              Key: { id: reservation.id },
              UpdateExpression: 'SET #status = :status, cancelledAt = :cancelledAt',
              ExpressionAttributeNames: {
                '#status': 'status'
              },
              ExpressionAttributeValues: {
                ':status': 'expired',
                ':cancelledAt': new Date().toISOString()
              }
            }
          },
          {
            Update: {
              TableName: PRODUCTS_TABLE,
              Key: { id: reservation.productId },
              UpdateExpression: 'ADD reservedQuantity :quantity',
              ExpressionAttributeValues: {
                ':quantity': -reservation.quantity
              }
            }
          }
        );
      }

      await docClient.send(new TransactWriteCommand({
        TransactItems: transactItems
      }));

      console.log(`Processed batch of ${batch.length} expired reservations`);
    }

    console.log('Cleanup completed successfully');

  } catch (error) {
    console.error('Cleanup error:', error);
    throw error;
  }
};

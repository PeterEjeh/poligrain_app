# Database Schema for Poligrain App

## Required DynamoDB Tables

### 1. Products Table
```json
{
  "TableName": "Products",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "category", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "CategoryIndex",
      "KeySchema": [
        { "AttributeName": "category", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

### 2. InventoryReservations Table (NEW)
```json
{
  "TableName": "InventoryReservations",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "productId", "AttributeType": "S" },
    { "AttributeName": "userId", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "productIdIndex",
      "KeySchema": [
        { "AttributeName": "productId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    },
    {
      "IndexName": "userIdIndex", 
      "KeySchema": [
        { "AttributeName": "userId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

### 2. Orders Table
```json
{
  "TableName": "Orders",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "userId", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "UserIdIndex",
      "KeySchema": [
        { "AttributeName": "userId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

### 3. Transactions Table
```json
{
  "TableName": "Transactions",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "userId", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "UserIdIndex",
      "KeySchema": [
        { "AttributeName": "userId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

### 4. Campaigns Table
```json
{
  "TableName": "Campaigns",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "ownerId", "AttributeType": "S" },
    { "AttributeName": "status", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "OwnerIdIndex",
      "KeySchema": [
        { "AttributeName": "ownerId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    },
    {
      "IndexName": "StatusIndex",
      "KeySchema": [
        { "AttributeName": "status", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

### 5. Investments Table
```json
{
  "TableName": "Investments",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "userId", "AttributeType": "S" },
    { "AttributeName": "campaignId", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "UserIdIndex",
      "KeySchema": [
        { "AttributeName": "userId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    },
    {
      "IndexName": "CampaignIdIndex",
      "KeySchema": [
        { "AttributeName": "campaignId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

### 6. Documents Table
```json
{
  "TableName": "Documents",
  "KeySchema": [
    { "AttributeName": "id", "KeyType": "HASH" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "id", "AttributeType": "S" },
    { "AttributeName": "ownerId", "AttributeType": "S" },
    { "AttributeName": "campaignId", "AttributeType": "S" },
    { "AttributeName": "createdAt", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "OwnerIdIndex",
      "KeySchema": [
        { "AttributeName": "ownerId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    },
    {
      "IndexName": "CampaignIdIndex",
      "KeySchema": [
        { "AttributeName": "campaignId", "KeyType": "HASH" },
        { "AttributeName": "createdAt", "KeyType": "RANGE" }
      ]
    }
  ]
}
```

## Sample Data Structures

### Product Document (Updated with Inventory Reservations)
```json
{
  "id": "prod-123",
  "name": "Organic Tomatoes",
  "description": "Fresh organic tomatoes",
  "category": "Vegetables",
  "price": 4.99,
  "quantity": 100,
  "reservedQuantity": 15,
  "unit": "kg",
  "isActive": true,
  "ownerId": "user-456",
  "location": "Lagos, Nigeria",
  "imageUrls": ["https://example.com/image1.jpg"],
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### Inventory Reservation Document (NEW)
```json
{
  "id": "RES-1705318200000-001",
  "productId": "prod-123",
  "userId": "user-456",
  "sessionId": "session-abc123",
  "quantity": 5,
  "status": "active",
  "createdAt": "2024-01-15T11:30:00Z",
  "expiresAt": "2024-01-15T11:45:00Z",
  "confirmedAt": null,
  "cancelledAt": null,
  "orderId": null,
  "metadata": {
    "source": "cart_checkout",
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.1"
  }
}
```

### Order Document
```json
{
  "id": "order-789",
  "userId": "user-456",
  "status": "pending",
  "items": [
    {
      "productId": "prod-123",
      "name": "Organic Tomatoes",
      "price": 4.99,
      "quantity": 5,
      "totalPrice": 24.95
    }
  ],
  "totalAmount": 24.95,
  "deliveryAddress": {
    "street": "123 Main St",
    "city": "Lagos",
    "state": "Lagos",
    "country": "Nigeria",
    "postalCode": "100001"
  },
  "customerEmail": "user@example.com",
  "notes": "Please deliver in the morning",
  "statusHistory": [
    {
      "status": "pending",
      "timestamp": "2024-01-15T11:00:00Z",
      "notes": "Order created"
    }
  ],
  "createdAt": "2024-01-15T11:00:00Z",
  "updatedAt": "2024-01-15T11:00:00Z"
}
```

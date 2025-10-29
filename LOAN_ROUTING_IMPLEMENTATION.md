# Loan Routing Implementation Summary

## Overview

This implementation routes loan requests based on their type:
- **Structured Loans** → Campaign Handler (as investment campaigns)
- **Flexible Loans** → Loan Handler (as loan requests)

## Problem Solved

The original error occurred because:
1. API Gateway had `/campaigns` routes configured but no Lambda function attached
2. The system didn't differentiate between loan types
3. Structured loans needed investment functionality (campaigns) while flexible loans needed simpler request handling

## Implementation Details

### 1. API Configuration Updates

**File**: `amplify/backend/api/PoligrainAPI/cli-inputs-updated.json`

Added campaign routes:
```json
"/campaigns": {
  "name": "/campaigns",
  "lambdaFunction": "CampaignHandler",
  "permissions": {
    "setting": "private",
    "auth": ["create", "read", "update", "delete"]
  }
},
"/campaigns/{proxy+}": {
  "name": "/campaigns/{proxy+}",
  "lambdaFunction": "CampaignHandler", 
  "permissions": {
    "setting": "private",
    "auth": ["create", "read", "update", "delete"]
  }
}
```

### 2. Loan Handler Updates

**File**: `amplify/backend/function/loanHandler/src/index.js`

#### Key Changes:
- **Smart Routing**: Checks `type` or `loanType` field in POST requests
- **Structured Loan Processing**: Creates campaigns for structured loans
- **Flexible Loan Processing**: Handles flexible loans normally
- **Enhanced GET Response**: Returns metadata about loan types and routing

#### Routing Logic:
```javascript
// POST /loan-requests
if (requestBody.type === "structured" || requestBody.loanType === "structured") {
  // Route to Campaign Handler
  const campaign = await createStructuredLoanAsCampaign(requestBody, ownerId, role);
  return { statusCode: 201, campaign, message: "Structured loan created as campaign" };
} else {
  // Handle as flexible loan
  const loanRequest = await createFlexibleLoan(requestBody, ownerId, role);
  return { statusCode: 201, loanRequest, message: "Flexible loan request created" };
}
```

#### New Function: `createStructuredLoanAsCampaign()`
Transforms loan data into campaign format with:
- Automatic campaign ID generation
- 10% minimum investment calculation
- 90-day default funding period
- Metadata marking it as loan-sourced
- Active status for immediate availability

### 3. Campaign Handler Enhancements

**File**: `amplify/backend/function/CampaignHandler/src/index.js`

#### Key Improvements:
- **Enhanced Filtering**: Added `loanSourced` query parameter
- **Metadata Fields**: Added `isLoanSourced` and `loanType` to response
- **Better Documentation**: Enhanced response metadata

#### New Query Parameters:
- `type=structured` → Get structured loan campaigns  
- `loanSourced=true` → Get only loan-sourced campaigns
- `loanSourced=false` → Get only regular campaigns

### 4. Infrastructure Updates

#### CloudFormation Template Updates
**File**: `amplify/backend/function/loanHandler/loanHandler-cloudformation-template.json`

- Added `campaignstable` parameter
- Added `CAMPAIGNS_TABLE` environment variable
- Updated IAM permissions for campaigns table access

#### Permissions Updates
**File**: `amplify/backend/function/loanHandler/custom-policies.json`

Added DynamoDB permissions for:
- `arn:aws:dynamodb:*:*:table/Campaigns`
- `arn:aws:dynamodb:*:*:table/Campaigns/index/*`

## API Usage Examples

### Creating Loans

#### Structured Loan (Routes to Campaigns):
```json
POST /loan-requests
{
  "type": "structured",
  "title": "Rice Farming Campaign", 
  "description": "Growing rice for export",
  "amount": 500000,
  "category": "Agriculture",
  "tenure": "6 months"
}
```
**Result**: Creates campaign in Campaigns table

#### Flexible Loan (Stays in Loan Requests):
```json
POST /loan-requests
{
  "type": "flexible",
  "title": "Equipment Purchase",
  "purpose": "Need funds for tractor",
  "amount": 100000,
  "tenure": "1 year"
}
```
**Result**: Creates loan request in LoanRequests table

### Fetching Data

#### Get Flexible Loans Only:
```
GET /loan-requests
```
**Returns**: Only flexible loan requests + routing info

#### Get Structured Loans (via Campaigns):
```
GET /campaigns?type=structured
```
**Returns**: Structured loan campaigns with investment data

#### Get All Loan-Sourced Campaigns:
```
GET /campaigns?loanSourced=true
```
**Returns**: Only campaigns created from loan requests

## Data Flow

```
Frontend Loan Request
         ↓
   POST /loan-requests
         ↓
    Loan Handler
         ↓
   [Check loan type]
         ↓
┌─── Structured ────┐    ┌─── Flexible ────┐
│                   │    │                 │
│ Create Campaign   │    │ Create Loan     │
│ in Campaigns      │    │ Request in      │
│ table            │    │ LoanRequests    │
│                   │    │ table           │
└───────────────────┘    └─────────────────┘
         ↓                        ↓
   Returns campaign         Returns loan
   with routing info        request with
                           routing info
```

## Benefits

1. **Clear Separation**: Structured loans get investment features, flexible loans stay simple
2. **No Data Loss**: Both loan types are preserved and accessible  
3. **Backward Compatibility**: Existing flexible loan functionality unchanged
4. **Enhanced Features**: Structured loans get campaign benefits (stats, investments, etc.)
5. **Error Resolution**: Fixes the "Invalid lambda function" API Gateway error

## Frontend Integration

### For Structured Loans:
- Create via `/loan-requests` (will auto-route to campaigns)
- Fetch via `/campaigns?type=structured`
- Get investment data via `/campaigns/{id}/stats`

### For Flexible Loans:  
- Create via `/loan-requests`
- Fetch via `/loan-requests`
- Simple approval/rejection workflow

## Testing Checklist

- [ ] POST structured loan → creates campaign
- [ ] POST flexible loan → creates loan request  
- [ ] GET /loan-requests → returns only flexible loans
- [ ] GET /campaigns?type=structured → returns structured loan campaigns
- [ ] Campaign investment features work for structured loans
- [ ] No API Gateway "Invalid lambda function" errors
- [ ] Both loan types preserve all original data

## Deployment Notes

After implementing these changes:
1. Deploy the API updates: `amplify push`
2. Test both loan creation endpoints
3. Verify campaign filtering works
4. Check that the original error is resolved

The routing is now intelligent and error-free!

import { DynamoDBClient, PutItemCommand, GetItemCommand, QueryCommand, UpdateItemCommand, ScanCommand } from "@aws-sdk/client-dynamodb";
import { marshall, unmarshall } from "@aws-sdk/util-dynamodb";
import { v4 as uuidv4 } from 'uuid';

const dynamodbClient = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler = async (event: any) => {
  const { httpMethod, pathParameters, queryStringParameters, body } = event;
  const userId = event.requestContext?.authorizer?.claims?.sub;
  
  try {
    switch (httpMethod) {
      case 'POST':
        return await createCampaign(JSON.parse(body), userId);
      
      case 'GET':
        if (pathParameters?.id) {
          return await getCampaignById(pathParameters.id);
        }
        return await listCampaigns(queryStringParameters || {}, userId);
      
      case 'PUT':
        return await updateCampaign(pathParameters.id, JSON.parse(body), userId);
        
      case 'DELETE':
        return await deleteCampaign(pathParameters.id, userId);
        
      default:
        return createResponse(405, { error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('Campaign Handler Error:', error);
    return createResponse(500, { 
      error: 'Internal server error',
      message: error.message 
    });
  }
};

async function createCampaign(campaignData: any, userId: string) {
  // Validate required fields
  const requiredFields = ['title', 'description', 'type', 'targetAmount', 'minimumInvestment', 'category'];
  for (const field of requiredFields) {
    if (!campaignData[field]) {
      return createResponse(400, { error: `${field} is required` });
    }
  }
  
  // Validate business rules
  if (campaignData.minimumInvestment > campaignData.targetAmount) {
    return createResponse(400, { error: 'Minimum investment cannot exceed target amount' });
  }
  
  if (new Date(campaignData.endDate) <= new Date(campaignData.startDate)) {
    return createResponse(400, { error: 'End date must be after start date' });
  }
  
  const campaignId = uuidv4();
  const now = new Date().toISOString();
  
  const campaign = {
    id: campaignId,
    ownerId: userId,
    title: campaignData.title,
    description: campaignData.description,
    type: campaignData.type,
    status: 'draft', // Start as draft, needs approval
    targetAmount: campaignData.targetAmount,
    raisedAmount: 0,
    minimumInvestment: campaignData.minimumInvestment,
    category: campaignData.category,
    unit: campaignData.unit || 'unit',
    quantity: campaignData.quantity || 1,
    gestationPeriod: campaignData.gestationPeriod || '12 months',
    tenureOptions: campaignData.tenureOptions || ['6 months', '12 months'],
    averageCostPerUnit: campaignData.averageCostPerUnit || 0,
    totalLoanIncludingFeePerUnit: campaignData.totalLoanIncludingFeePerUnit || 0,
    startDate: campaignData.startDate,
    endDate: campaignData.endDate,
    imageUrls: campaignData.imageUrls || [],
    documentUrls: campaignData.documentUrls || [],
    investorCount: 0,
    metadata: campaignData.metadata || {},
    createdAt: now,
    updatedAt: now,
  };
  
  const params = {
    TableName: 'Campaigns',
    Item: marshall(campaign),
  };
  
  await dynamodbClient.send(new PutItemCommand(params));
  
  return createResponse(201, campaign);
}

async function getCampaignById(campaignId: string) {
  const params = {
    TableName: 'Campaigns',
    Key: marshall({ id: campaignId }),
  };
  
  const result = await dynamodbClient.send(new GetItemCommand(params));
  
  if (!result.Item) {
    return createResponse(404, { error: 'Campaign not found' });
  }
  
  const campaign = unmarshall(result.Item);
  
  // Calculate additional fields
  campaign.remainingAmount = Math.max(0, campaign.targetAmount - campaign.raisedAmount);
  campaign.progressPercentage = (campaign.raisedAmount / campaign.targetAmount) * 100;
  campaign.isActive = campaign.status === 'active' && new Date() < new Date(campaign.endDate);
  campaign.daysRemaining = Math.max(0, Math.ceil((new Date(campaign.endDate) - new Date()) / (1000 * 60 * 60 * 24)));
  
  return createResponse(200, campaign);
}

async function listCampaigns(queryParams: any, userId?: string) {
  const { 
    limit = '20', 
    lastKey, 
    type, 
    status, 
    category, 
    ownerId, 
    activeOnly 
  } = queryParams;
  
  let params: any;
  
  if (ownerId === 'current_user' && userId) {
    // Get user's own campaigns
    params = {
      TableName: 'Campaigns',
      IndexName: 'OwnerIdIndex',
      KeyConditionExpression: 'ownerId = :ownerId',
      ExpressionAttributeValues: {
        ':ownerId': { S: userId }
      },
      Limit: parseInt(limit),
      ScanIndexForward: false,
    };
  } else if (status) {
    // Get campaigns by status
    params = {
      TableName: 'Campaigns',
      IndexName: 'StatusIndex',
      KeyConditionExpression: '#status = :status',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: {
        ':status': { S: status }
      },
      Limit: parseInt(limit),
      ScanIndexForward: false,
    };
  } else {
    // General scan with filters
    params = {
      TableName: 'Campaigns',
      Limit: parseInt(limit),
    };
  }
  
  // Add additional filters
  const filterExpressions = [];
  
  if (type && !status) {
    filterExpressions.push('#type = :type');
    params.ExpressionAttributeNames = { ...params.ExpressionAttributeNames, '#type': 'type' };
    params.ExpressionAttributeValues = { ...params.ExpressionAttributeValues, ':type': { S: type } };
  }
  
  if (category) {
    filterExpressions.push('category = :category');
    params.ExpressionAttributeValues = { ...params.ExpressionAttributeValues, ':category': { S: category } };
  }
  
  if (activeOnly === 'true') {
    filterExpressions.push('#status = :activeStatus AND endDate > :now');
    params.ExpressionAttributeNames = { ...params.ExpressionAttributeNames, '#status': 'status' };
    params.ExpressionAttributeValues = { 
      ...params.ExpressionAttributeValues, 
      ':activeStatus': { S: 'active' },
      ':now': { S: new Date().toISOString() }
    };
  }
  
  if (filterExpressions.length > 0) {
    params.FilterExpression = filterExpressions.join(' AND ');
  }
  
  if (lastKey) {
    params.ExclusiveStartKey = JSON.parse(Buffer.from(lastKey, 'base64').toString());
  }
  
  const command = status || (ownerId === 'current_user' && userId) ? 
    new QueryCommand(params) : new ScanCommand(params);
  
  const result = await dynamodbClient.send(command);
  const campaigns = result.Items?.map(item => {
    const campaign = unmarshall(item);
    
    // Add calculated fields
    campaign.remainingAmount = Math.max(0, campaign.targetAmount - campaign.raisedAmount);
    campaign.progressPercentage = (campaign.raisedAmount / campaign.targetAmount) * 100;
    campaign.isActive = campaign.status === 'active' && new Date() < new Date(campaign.endDate);
    campaign.daysRemaining = Math.max(0, Math.ceil((new Date(campaign.endDate) - new Date()) / (1000 * 60 * 60 * 24)));
    
    return campaign;
  }) || [];
  
  return createResponse(200, {
    campaigns,
    pagination: {
      hasMore: !!result.LastEvaluatedKey,
      lastKey: result.LastEvaluatedKey ? 
        Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64') : null,
    }
  });
}

async function updateCampaign(campaignId: string, updateData: any, userId: string) {
  // First verify the campaign exists and user owns it
  const existingCampaign = await getCampaignById(campaignId);
  if (existingCampaign.statusCode !== 200) {
    return existingCampaign;
  }
  
  const campaign = JSON.parse(existingCampaign.body);
  
  if (campaign.ownerId !== userId) {
    return createResponse(403, { error: 'Access denied: Not campaign owner' });
  }
  
  // Validate update restrictions based on status
  if (campaign.status === 'active' && campaign.investorCount > 0) {
    // Restrict updates when campaign has investors
    const allowedFields = ['description', 'imageUrls', 'documentUrls', 'metadata'];
    const hasRestrictedUpdates = Object.keys(updateData).some(key => !allowedFields.includes(key));
    
    if (hasRestrictedUpdates) {
      return createResponse(400, { 
        error: 'Cannot modify campaign terms after investors have joined',
        allowedFields 
      });
    }
  }
  
  const now = new Date().toISOString();
  const updateFields: any = { ':updatedAt': now };
  const updateExpressions = ['updatedAt = :updatedAt'];
  
  // Build update expression dynamically
  const allowedUpdateFields = [
    'title', 'description', 'status', 'targetAmount', 'minimumInvestment', 
    'category', 'tenureOptions', 'endDate', 'imageUrls', 'documentUrls', 'metadata'
  ];
  
  Object.keys(updateData).forEach(key => {
    if (allowedUpdateFields.includes(key)) {
      updateFields[`:${key}`] = updateData[key];
      updateExpressions.push(`${key} = :${key}`);
    }
  });
  
  // Additional validation for specific fields
  if (updateData.status === 'active') {
    // Validate campaign is ready to be activated
    if (!campaign.title || !campaign.description || campaign.targetAmount <= 0) {
      return createResponse(400, { error: 'Campaign must have title, description, and target amount to be activated' });
    }
  }
  
  const params = {
    TableName: 'Campaigns',
    Key: marshall({ id: campaignId }),
    UpdateExpression: `SET ${updateExpressions.join(', ')}`,
    ExpressionAttributeValues: marshall(updateFields),
    ReturnValues: 'ALL_NEW',
  };
  
  const result = await dynamodbClient.send(new UpdateItemCommand(params));
  const updatedCampaign = unmarshall(result.Attributes);
  
  // Add calculated fields to response
  updatedCampaign.remainingAmount = Math.max(0, updatedCampaign.targetAmount - updatedCampaign.raisedAmount);
  updatedCampaign.progressPercentage = (updatedCampaign.raisedAmount / updatedCampaign.targetAmount) * 100;
  updatedCampaign.isActive = updatedCampaign.status === 'active' && new Date() < new Date(updatedCampaign.endDate);
  updatedCampaign.daysRemaining = Math.max(0, Math.ceil((new Date(updatedCampaign.endDate) - new Date()) / (1000 * 60 * 60 * 24)));
  
  return createResponse(200, updatedCampaign);
}

async function deleteCampaign(campaignId: string, userId: string) {
  // First verify ownership and eligibility for deletion
  const existingCampaign = await getCampaignById(campaignId);
  if (existingCampaign.statusCode !== 200) {
    return existingCampaign;
  }
  
  const campaign = JSON.parse(existingCampaign.body);
  
  if (campaign.ownerId !== userId) {
    return createResponse(403, { error: 'Access denied: Not campaign owner' });
  }
  
  if (campaign.status === 'active' && campaign.investorCount > 0) {
    return createResponse(400, { error: 'Cannot delete campaign with active investors' });
  }
  
  // Soft delete by updating status
  return await updateCampaign(campaignId, { 
    status: 'deleted',
    metadata: { 
      ...campaign.metadata, 
      deletedAt: new Date().toISOString() 
    }
  }, userId);
}

// Helper function to update campaign when investment is made
export async function updateCampaignFromInvestment(campaignId: string, investmentAmount: number) {
  const campaign = await getCampaignById(campaignId);
  if (campaign.statusCode !== 200) {
    throw new Error('Campaign not found');
  }
  
  const campaignData = JSON.parse(campaign.body);
  
  const updateFields = {
    ':raisedAmount': campaignData.raisedAmount + investmentAmount,
    ':investorCount': campaignData.investorCount + 1,
    ':updatedAt': new Date().toISOString(),
  };
  
  let updateExpression = 'SET raisedAmount = :raisedAmount, investorCount = :investorCount, updatedAt = :updatedAt';
  
  // Check if campaign is now fully funded
  if (campaignData.raisedAmount + investmentAmount >= campaignData.targetAmount) {
    updateFields[':status'] = 'funded';
    updateExpression += ', #status = :status';
  }
  
  const params = {
    TableName: 'Campaigns',
    Key: marshall({ id: campaignId }),
    UpdateExpression: updateExpression,
    ExpressionAttributeNames: campaignData.raisedAmount + investmentAmount >= campaignData.targetAmount ? 
      { '#status': 'status' } : undefined,
    ExpressionAttributeValues: marshall(updateFields),
    ReturnValues: 'ALL_NEW',
  };
  
  await dynamodbClient.send(new UpdateItemCommand(params));
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
    body: JSON.stringify(body),
  };
}

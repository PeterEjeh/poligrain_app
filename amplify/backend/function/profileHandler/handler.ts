import { DynamoDBClient, PutItemCommand, GetItemCommand } from "@aws-sdk/client-dynamodb";

const dynamodbClient = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));
  const { httpMethod, body } = event;

  if (httpMethod === "POST") {
    try {
      const data = JSON.parse(body);
      console.log("Parsed data:", JSON.stringify(data, null, 2));
      
      if (!data.username) {
        return {
          statusCode: 400,
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ message: "Username is required" }),
        };
      }

      const params = {
        TableName: "UserProfiles", // Make sure this matches the table name in AWS
        Item: {
          username: { S: data.username },
          name: { S: data.name || "" },
          phone: { S: data.phone || "" },
          gender: { S: data.gender || "" },
          state: { S: data.state || "" },
          lga: { S: data.lga || "" },
          address: { S: data.address || "" },
          role: { S: data.role || "" },
          profile_complete: { BOOL: data.profile_complete || false },
        },
      };

      console.log("DynamoDB params:", JSON.stringify(params, null, 2));
      await dynamodbClient.send(new PutItemCommand(params));
      
      return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: "Profile saved successfully" }),
      };
    } catch (error) {
      console.error("Error processing POST request:", error);
      return {
        statusCode: 500,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          message: "Error saving profile", 
          error: error.message,
          stack: error.stack
        }),
      };
    }
  } else if (httpMethod === "GET") {
    try {
      const queryParams = event.queryStringParameters || {};
      const username = queryParams.username;
      
      if (!username) {
        return {
          statusCode: 400,
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ message: "Username parameter is required" }),
        };
      }
      
      const params = {
        TableName: "UserProfiles",
        Key: {
          username: { S: username },
        },
      };

      const result = await dynamodbClient.send(new GetItemCommand(params));
      return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(result.Item || {}),
      };
    } catch (error) {
      console.error("Error processing GET request:", error);
      return {
        statusCode: 500,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          message: "Error fetching profile", 
          error: error.message 
        }),
      };
    }
  }

  return {
    statusCode: 400,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message: "Method not supported" }),
  };
};
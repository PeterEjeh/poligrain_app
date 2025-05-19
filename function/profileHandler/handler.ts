    import { DynamoDBClient, PutItemCommand, GetItemCommand } from "@aws-sdk/client-dynamodb";

    const dynamodbClient = new DynamoDBClient({ region: process.env.AWS_REGION });

    export const handler = async (event) => {
      const { httpMethod, body } = event;

      if (httpMethod === "POST") {
        const data = JSON.parse(body);
        const params = {
          TableName: "UserProfileTable",
          Item: {
            username: { S: data.username },
            name: { S: data.name },
            phone: { S: data.phone },
            location: { S: data.location },
            role: { S: data.role },
            profile_complete: { BOOL: data.profile_complete },
          },
        };

        try {
          await dynamodbClient.send(new PutItemCommand(params));
          return {
            statusCode: 200,
            body: JSON.stringify({ message: "Profile saved" }),
          };
        } catch (error) {
          return {
            statusCode: 500,
            body: JSON.stringify({ message: "Error saving profile", error: error.message }),
          };
        }
      } else if (httpMethod === "GET") {
        const { username } = JSON.parse(body);
        const params = {
          TableName: "UserProfileTable",
          Key: {
            username: { S: username },
          },
        };

        try {
          const result = await dynamodbClient.send(new GetItemCommand(params));
          return {
            statusCode: 200,
            body: JSON.stringify(result.Item || {}),
          };
        } catch (error) {
          return {
            statusCode: 500,
            body: JSON.stringify({ message: "Error fetching profile", error: error.message }),
          };
        }
      }

      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Method not supported" }),
      };
    };
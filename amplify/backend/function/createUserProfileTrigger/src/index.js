/* Amplify Params - DO NOT EDIT
	ENV
	REGION
	STORAGE_POLIGRAINSTORAGE_BUCKETNAME // This will be present but we don't need it
	USER_PROFILES_TABLE
Amplify Params - DO NOT EDIT */

const AWS = require("aws-sdk");
const ddb = new AWS.DynamoDB.DocumentClient({
  apiVersion: "2012-08-10",
  region: process.env.REGION,
});

exports.handler = async (event) => {
  console.log(
    "Post-Confirmation Event Received:",
    JSON.stringify(event, null, 2)
  );

  const tableName = process.env.USER_PROFILES_TABLE;
  if (!tableName) {
    console.error("Error: USER_PROFILES_TABLE env var not set.");
    return event;
  }

  const { sub, email } = event.request.userAttributes;
  const newUserProfile = {
    username: email, // Primary Key
    email: email,
    userId: sub,
    role: "NewUser", // Set a temporary role for the app to check
    createdAt: new Date().toISOString(),
  };

  const params = {
    TableName: tableName,
    Item: newUserProfile,
    ConditionExpression: "attribute_not_exists(username)",
  };

  try {
    await ddb.put(params).promise();
    console.log(`Successfully created starter profile for user: ${email}`);
  } catch (error) {
    if (error.code === "ConditionalCheckFailedException") {
      console.warn(`Profile for ${email} already exists.`);
    } else {
      console.error("Error creating user profile:", error);
    }
  }

  return event;
};

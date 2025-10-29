/* Amplify Params - DO NOT EDIT
    // You'll see your Amplify-provided env vars here.
    // Make sure AUTH_POLIGRAINAPP..._USERPOOLID and STORAGE_POLIGRAINSTORAGE_NAME are listed.
Amplify Params - DO NOT EDIT */

const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();
// =======================================================
//  1. ADD THE COGNITO SERVICE PROVIDER CLIENT
// =======================================================
const cognito = new AWS.CognitoIdentityServiceProvider();

// A helper function for creating consistent responses
const createResponse = (statusCode, body, methods = "POST,GET,PUT,OPTIONS") => {
  return {
    statusCode: statusCode,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Allow-Methods": methods,
    },
    body: JSON.stringify(body),
  };
};

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  // =======================================================
  //  2. USE ENVIRONMENT VARIABLES (BEST PRACTICE)
  //     Hard-coding table names can cause issues between environments (dev, prod).
  //     Amplify provides these for you.
  // =======================================================
  const tableName = process.env.STORAGE_POLIGRAINSTORAGE_NAME;
  const userPoolId = process.env.AUTH_POLIGRAINAPP734E0E72_USERPOOLID; // <-- Add this

  const httpMethod = event.httpMethod;

  // Handle GET requests (No changes needed here)
  if (httpMethod === "GET") {
    const username = event.queryStringParameters
      ? event.queryStringParameters.username
      : null;
    if (!username) {
      return createResponse(400, {
        message: "Username query parameter is required.",
      });
    }
    const params = { TableName: tableName, Key: { username: username } };
    try {
      const data = await dynamodb.get(params).promise();
      if (data.Item) {
        return createResponse(200, data.Item);
      } else {
        return createResponse(404, { message: "Profile not found." });
      }
    } catch (dbError) {
      console.error("Error getting profile:", dbError);
      return createResponse(500, { message: "Failed to retrieve profile." });
    }
  }

  // Handle POST requests (No changes needed, but PUT is preferred for this action)
  if (httpMethod === "POST") {
    // Your existing POST logic can remain if you use it for other purposes.
    // For the "complete profile" action, we've enhanced the PUT handler.
    return createResponse(200, {
      message: "This endpoint now prefers PUT for profile updates.",
    });
  }

  // =======================================================
  //  3. ENHANCE THE PUT HANDLER
  // =======================================================
  if (httpMethod === "PUT") {
    let profileData;
    try {
      profileData = JSON.parse(event.body);
    } catch (error) {
      return createResponse(400, { message: "Invalid request body." });
    }

    // --- New ---
    // For security, get the username from the authenticated user's token, not the request body.
    // This ensures a user can only update their own profile.
    const username = event.requestContext.authorizer.claims.email;
    const chosenRole = profileData.role;

    if (!username) {
      return createResponse(401, {
        message: "Unauthorized: Could not identify user from token.",
      });
    }
    if (!chosenRole || (chosenRole !== "Investor" && chosenRole !== "Farmer")) {
      return createResponse(400, {
        message: `Invalid 'role' provided: ${chosenRole}`,
      });
    }

    // --- Task 1: Prepare the Cognito Group parameters ---
    const groupParams = {
      GroupName: chosenRole,
      UserPoolId: userPoolId,
      Username: username, // Use the secure username from the token
    };

    // --- Task 2: Prepare the DynamoDB update parameters (using your existing logic) ---
    // (Your dynamic update expression logic is great, so we'll reuse it)
    const allowedFields = [
      "first_name",
      "last_name",
      "phone",
      "gender",
      "state",
      "lga",
      "city",
      "address",
      "postal_code",
      "role",
      "profile_image",
      "profile_complete",
    ];
    let updateExp = "set ";
    let expAttrNames = {};
    let expAttrValues = {};
    let first = true;
    for (const field of allowedFields) {
      if (profileData[field] !== undefined) {
        if (!first) updateExp += ", ";
        const namePlaceholder = `#${field}`;
        const valuePlaceholder = `:${field}`;
        updateExp += `${namePlaceholder} = ${valuePlaceholder}`;
        expAttrNames[namePlaceholder] = field;
        expAttrValues[valuePlaceholder] = profileData[field];
        first = false;
      }
    }

    if (first) {
      return createResponse(400, { message: "No updatable fields provided." });
    }

    const dbParams = {
      TableName: tableName,
      Key: { username: username }, // Use secure username
      UpdateExpression: updateExp,
      ExpressionAttributeNames: expAttrNames,
      ExpressionAttributeValues: expAttrValues,
      ReturnValues: "ALL_NEW",
    };

    // --- Run both tasks in parallel for better performance ---
    try {
      console.log("Finalizing profile for:", username);
      console.log("Adding to Cognito Group:", chosenRole);
      console.log("Updating DynamoDB with:", JSON.stringify(dbParams));

      // This runs both the Cognito and DynamoDB operations at the same time.
      const [cognitoResult, dbResult] = await Promise.all([
        cognito.adminAddUserToGroup(groupParams).promise(),
        dynamodb.update(dbParams).promise(),
      ]);

      console.log(`Successfully added ${username} to ${chosenRole} group.`);
      console.log(`Successfully updated DynamoDB profile.`);

      return createResponse(200, {
        message: "Profile finalized successfully!",
        item: dbResult.Attributes,
      });
    } catch (error) {
      console.error("Error finalizing profile:", error);
      return createResponse(500, {
        message: "Failed to finalize profile.",
        error: error.message,
      });
    }
  }

  return createResponse(405, { message: `Unsupported method: ${httpMethod}` });
};

/* Amplify Params - DO NOT EDIT
	AUTH_POLIGRAINAPP734E0E72_USERPOOLID
	ENV
	REGION
	STORAGE_POLIGRAINSTORAGE_BUCKETNAME
Amplify Params - DO NOT EDIT */ const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();
// Add Cognito Identity Provider client for group management
const cognito = new AWS.CognitoIdentityServiceProvider();
// User Pool ID provided by Amplify env vars
const userPoolId = process.env.AUTH_POLIGRAINAPP734E0E72_USERPOOLID;

// Resolve the Cognito Username (required by admin* APIs) from an email address.
// When usernameAttributes includes 'email', Cognito generates an internal Username that is NOT the email.
// We must look it up via ListUsers with a filter on the email attribute.
async function resolveCognitoUsernameByEmail(userPoolId, email) {
  if (!email || !userPoolId) {
    throw new Error(
      "resolveCognitoUsernameByEmail: missing userPoolId or email"
    );
  }
  const list = await cognito
    .listUsers({
      UserPoolId: userPoolId,
      Filter: `email = "${email}"`,
      Limit: 1,
    })
    .promise();
  if (list.Users && list.Users.length > 0) {
    return list.Users[0].Username;
  }
  throw new Error(
    `resolveCognitoUsernameByEmail: No user found for email ${email}`
  );
}

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

  const httpMethod = event.httpMethod;
  const tableName = "UserProfiles";

  // =======================================================
  //  Handle GET requests to retrieve a profile
  // =======================================================
  if (httpMethod === "GET") {
    // Get the username from the query string (e.g., /profile?username=xxxx-xxxx)
    const username = event.queryStringParameters
      ? event.queryStringParameters.username
      : null;

    if (!username) {
      return createResponse(400, {
        message: "Username query parameter is required.",
      });
    }

    const params = {
      TableName: tableName,
      Key: {
        username: username,
      },
    };

    try {
      console.log(
        "Attempting to get item from DynamoDB with params:",
        JSON.stringify(params, null, 2)
      );
      const data = await dynamodb.get(params).promise();

      if (data.Item) {
        console.log("Successfully retrieved profile:", data.Item);
        // Return the profile data directly
        return createResponse(200, data.Item);
      } else {
        console.log("Profile not found for username:", username);
        return createResponse(404, { message: "Profile not found." });
      }
    } catch (dbError) {
      console.error("Error getting profile from DynamoDB:", dbError);
      return createResponse(500, {
        message: "Failed to retrieve profile due to a server error.",
        error: dbError.message,
      });
    }
  }

  // =======================================================
  //  Handle POST requests to save a profile
  // =======================================================
  if (httpMethod === "POST") {
    let profileData;
    try {
      profileData = JSON.parse(event.body);
    } catch (error) {
      console.error("Error parsing request body:", error);
      return createResponse(400, {
        message: "Invalid request body",
        error: error.message,
      });
    }

    if (!profileData || !profileData.username) {
      return createResponse(400, { message: "Missing required profile data" });
    }

    console.log("Parsed Profile Data for saving:", profileData);

    // Capture Cognito Identity ID (when request is signed using AWS_IAM via Identity Pool)
    const cognitoIdentityId =
      (event.requestContext &&
        event.requestContext.identity &&
        event.requestContext.identity.cognitoIdentityId) ||
      null;

    // Build params; use let so we can attach owner conditionally
    let params = {
      TableName: tableName,
      Item: {
        username: profileData.username,
        first_name: profileData.first_name || "",
        last_name: profileData.last_name || "",
        phone: profileData.phone || "",
        gender: profileData.gender || "",
        state: profileData.state || "",
        lga: profileData.lga || "",
        address: profileData.address || "",
        role: profileData.role || "",
        profile_image: profileData.profile_image || "",
        profile_complete:
          typeof profileData.profile_complete === "boolean"
            ? profileData.profile_complete
            : false,
      },
    };

    // If an Identity Pool identity is present, store it as 'owner' on the profile
    if (cognitoIdentityId) {
      params.Item.owner = cognitoIdentityId;
      console.log(
        `Attached owner (cognitoIdentityId)=${cognitoIdentityId} to profile item.`
      );
    }

    try {
      console.log(
        "Attempting to save to DynamoDB with params:",
        JSON.stringify(params, null, 2)
      );
      await dynamodb.put(params).promise();
      console.log("Successfully saved to DynamoDB.");
      return createResponse(200, {
        message: "Profile saved successfully!",
        item: params.Item,
      });
    } catch (dbError) {
      console.error("Error saving profile to DynamoDB:", dbError);
      return createResponse(500, {
        message: "Failed to save profile due to a server error.",
        error: dbError.message,
      });
    }
  }

  // =======================================================
  //  Handle PUT requests to update a profile
  // =======================================================
  if (httpMethod === "PUT") {
    let profileData;
    try {
      profileData = JSON.parse(event.body);
    } catch (error) {
      console.error("Error parsing request body:", error);
      return createResponse(400, {
        message: "Invalid request body",
        error: error.message,
      });
    }

    if (!profileData || !profileData.username) {
      return createResponse(400, {
        message: "Missing required profile data (username)",
      });
    }

    // Extract claims if present (JWT authorizer). With IAM auth, claims are usually not present.
    const claims =
      (event.requestContext &&
        event.requestContext.authorizer &&
        event.requestContext.authorizer.claims) ||
      {};
    // We collect the login identifier from the profile payload for lookup.
    const loginEmail = profileData.username; // our app stores email here

    const chosenRole = profileData.role;
    // Map app roles to Cognito group names used in the app ('Farmers' / 'Investors')
    const desiredGroup =
      chosenRole === "Farmer"
        ? "Farmers"
        : chosenRole === "Investor"
          ? "Investors"
          : null;

    // Build update expression dynamically
    const allowedFields = [
      "first_name",
      "last_name",
      "phone",
      "gender",
      "state",
      "lga",
      "address",
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
        // If field is a reserved word, use #field
        if (["state", "role"].includes(field)) {
          updateExp += `#${field} = :${field}`;
          expAttrNames[`#${field}`] = field;
        } else {
          updateExp += `${field} = :${field}`;
        }
        expAttrValues[`:${field}`] = profileData[field];
        first = false;
      }
    }
    if (first) {
      return createResponse(400, { message: "No updatable fields provided." });
    }

    // If the request was signed with AWS_IAM, API Gateway will populate
    // requestContext.identity.cognitoIdentityId. Capture it and store as 'owner'
    // on the profile when not explicitly provided by the client.
    const cognitoIdentityId =
      (event.requestContext &&
        event.requestContext.identity &&
        event.requestContext.identity.cognitoIdentityId) ||
      null;

    if (cognitoIdentityId && expAttrValues[":owner"] === undefined) {
      // append to update expression
      updateExp += `, #owner = :owner`;
      expAttrNames["#owner"] = "owner";
      expAttrValues[":owner"] = cognitoIdentityId;
    }

    const params = {
      TableName: tableName,
      Key: { username: profileData.username },
      UpdateExpression: updateExp,
      ExpressionAttributeValues: expAttrValues,
      ReturnValues: "ALL_NEW",
    };
    if (Object.keys(expAttrNames).length > 0) {
      params.ExpressionAttributeNames = expAttrNames;
    }

    try {
      console.log(
        "Attempting to update DynamoDB with params:",
        JSON.stringify(params, null, 2)
      );

      // Always update profile in DB
      const dbPromise = dynamodb.update(params).promise();

      // Optionally adjust Cognito group membership based on selected role
      let groupPromise = Promise.resolve();
      if (desiredGroup && userPoolId) {
        groupPromise = (async () => {
          try {
            // Resolve the actual Cognito Username to use with Admin* APIs.
            // Prefer JWT claim if present; otherwise resolve by email.
            let targetUsername =
              claims["cognito:username"] ||
              claims["username"] ||
              claims["sub"] ||
              null;
            if (!targetUsername) {
              targetUsername = await resolveCognitoUsernameByEmail(
                userPoolId,
                loginEmail
              );
            }
            console.log(
              `Preparing to set Cognito group for ${targetUsername} to ${desiredGroup}`
            );
            // Remove from the opposite role group if present
            const currentGroups = await cognito
              .adminListGroupsForUser({
                Username: targetUsername,
                UserPoolId: userPoolId,
              })
              .promise();

            const roleGroups = ["Farmers", "Investors"];
            const toRemove = (currentGroups.Groups || [])
              .map((g) => g.GroupName)
              .filter((g) => roleGroups.includes(g) && g !== desiredGroup);

            for (const g of toRemove) {
              console.log(`Removing ${targetUsername} from group ${g}`);
              await cognito
                .adminRemoveUserFromGroup({
                  GroupName: g,
                  UserPoolId: userPoolId,
                  Username: targetUsername,
                })
                .promise();
            }

            // Add to the desired group
            console.log(
              `Adding ${targetUsername} to desired group ${desiredGroup}`
            );
            await cognito
              .adminAddUserToGroup({
                GroupName: desiredGroup,
                UserPoolId: userPoolId,
                Username: targetUsername,
              })
              .promise();
          } catch (e) {
            console.error(
              "Cognito group management error (continuing with profile update):",
              e
            );
          }
        })();
      }

      const [dbResult] = await Promise.all([dbPromise, groupPromise]);

      console.log("Successfully updated profile (and group if applicable).");
      return createResponse(200, {
        message: "Profile updated successfully!",
        item: dbResult.Attributes,
      });
    } catch (dbError) {
      console.error("Error updating profile in DynamoDB:", dbError);
      return createResponse(500, {
        message: "Failed to update profile due to a server error.",
        error: dbError.message,
      });
    }
  }

  // =======================================================
  //  Fallback for other methods like PUT, DELETE, etc.
  // =======================================================
  return createResponse(405, { message: `Unsupported method: ${httpMethod}` });
};

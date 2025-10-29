/**
 * PostConfirmation trigger: add user to Cognito group based on a selected role.
 *
 * How it decides the role:
 * - Prefer custom user attribute 'custom:role' if present (e.g., set during signup).
 *   Expected values: 'Farmer' or 'Investor' (case-insensitive).
 * - If not present or invalid, do nothing here. The profile update API (profileHandler PUT)
 *   will add the user to the group when the user completes profile setup.
 */
const AWS = require("aws-sdk");
const cognito = new AWS.CognitoIdentityServiceProvider();

// Ensure a Cognito User Pool group exists; create if missing
async function ensureGroupExists(userPoolId, groupName) {
  try {
    await cognito
      .getGroup({
        GroupName: groupName,
        UserPoolId: userPoolId,
      })
      .promise();
  } catch (e) {
    if (e.code === "ResourceNotFoundException") {
      console.log(
        `Group ${groupName} not found. Creating in pool ${userPoolId}`
      );
      await cognito
        .createGroup({
          GroupName: groupName,
          UserPoolId: userPoolId,
        })
        .promise();
    } else {
      console.warn("getGroup error (non-not-found):", e);
      throw e;
    }
  }
}

exports.handler = async (event, context) => {
  try {
    const userPoolId = event.userPoolId;
    const username = event.userName;

    // Read potential role from custom attribute
    const attrs = (event.request && event.request.userAttributes) || {};
    const rawRole =
      attrs["custom:role"] || attrs["role"] || attrs["custom:appRole"] || "";

    const norm = String(rawRole || "")
      .trim()
      .toLowerCase();

    // Map application role to Cognito group name
    const desiredGroup =
      norm === "farmer"
        ? "Farmers"
        : norm === "investor"
          ? "Investors"
          : "Farmers"; // default to Farmers when no role present

    if (!desiredGroup) {
      console.log(
        "PostConfirmation: No valid role attribute found on user. Skipping group assignment."
      );
      return event;
    }

    // Remove from other role group if already assigned, then add to the desired one
    const roleGroups = ["Farmers", "Investors"];

    try {
      const current = await cognito
        .adminListGroupsForUser({
          UserPoolId: userPoolId,
          Username: username,
        })
        .promise();

      const toRemove = (current.Groups || [])
        .map((g) => g.GroupName)
        .filter((g) => roleGroups.includes(g) && g !== desiredGroup);

      for (const g of toRemove) {
        console.log(`Removing ${username} from group ${g}`);
        await cognito
          .adminRemoveUserFromGroup({
            GroupName: g,
            UserPoolId: userPoolId,
            Username: username,
          })
          .promise();
      }
    } catch (listErr) {
      console.warn("PostConfirmation: adminListGroupsForUser error:", listErr);
      // Continue; user may not be in any group yet
    }

    // Ensure target group exists before assignment
    await ensureGroupExists(userPoolId, desiredGroup);

    console.log(`Adding ${username} to group ${desiredGroup}`);
    await cognito
      .adminAddUserToGroup({
        GroupName: desiredGroup,
        UserPoolId: userPoolId,
        Username: username,
      })
      .promise();

    console.log(
      `PostConfirmation: Successfully added ${username} to ${desiredGroup}`
    );
  } catch (e) {
    console.error("PostConfirmation group assignment failed:", e);
    // Do not fail confirmation; just log
  }
  return event;
};

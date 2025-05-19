

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */
exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));

    // Parse incoming request body
    let profileData;
    try {
        profileData = JSON.parse(event.body);
    } catch (error) {
        console.error("Error parsing body:", error);
        return {
            statusCode: 400,
            body: JSON.stringify({ message: "Invalid request body" }),
        };
    }

    console.log("Profile Data:", profileData);

    // Optional: Validate fields here (e.g., check for name, phone, etc.)

    // Respond success
    return {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Origin": "*", // Allow from all domains
            "Access-Control-Allow-Headers": "*", // Allow any headers
            "Access-Control-Allow-Methods": "POST,OPTIONS", // Allow POST
        },
        body: JSON.stringify({ message: "Profile saved successfully!" }),
    };
};


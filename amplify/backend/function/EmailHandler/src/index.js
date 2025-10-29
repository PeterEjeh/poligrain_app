const { SESv2Client, SendEmailCommand } = require("@aws-sdk/client-sesv2");
const ses = new SESv2Client({ region: process.env.AWS_REGION });
const {
  buildOrderConfirmationEmail,
  buildOrderStatusUpdateEmail,
  buildReceiptOnlyEmail,
  buildShippingNotificationEmail,
  buildDeliveryConfirmationEmail,
} = require("./email-builder");
const { isValidEmail } = require("./validators");

exports.handler = async (event) => {
  console.log("Email Handler received event:", JSON.stringify(event, null, 2));

  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
  };

  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ message: "CORS preflight successful" }),
    };
  }

  try {
    const { httpMethod, path } = event;

    if (httpMethod === "POST" && path === "/emails/send") {
      return await handleSendEmail(event, corsHeaders);
    }

    return {
      statusCode: 404,
      headers: corsHeaders,
      body: JSON.stringify({ error: "Endpoint not found" }),
    };
  } catch (error) {
    console.error("Email Handler Error:", error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
    };
  }
};

async function handleSendEmail(event, corsHeaders) {
  try {
    const requestBody = JSON.parse(event.body);
    const { type, to, customerName } = requestBody;

    if (!type || !to || !customerName) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({
          error: "Missing required fields: type, to, customerName",
        }),
      };
    }

    if (!isValidEmail(to)) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({
          error: "Invalid email address format",
        }),
      };
    }

    let emailParams;

    switch (type) {
      case "order_confirmation":
        emailParams = await buildOrderConfirmationEmail(requestBody);
        break;
      case "order_status_update":
        emailParams = await buildOrderStatusUpdateEmail(requestBody);
        break;
      case "receipt_only":
        emailParams = await buildReceiptOnlyEmail(requestBody);
        break;
      case "shipping_notification":
        emailParams = await buildShippingNotificationEmail(requestBody);
        break;
      case "delivery_confirmation":
        emailParams = await buildDeliveryConfirmationEmail(requestBody);
        break;
      default:
        return {
          statusCode: 400,
          headers: corsHeaders,
          body: JSON.stringify({
            error: `Unsupported email type: ${type}`,
          }),
        };
    }

    const command = new SendEmailCommand(emailParams);
    const result = await ses.send(command);

    console.log("Email sent successfully:", result.MessageId);

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        messageId: result.MessageId,
        message: "Email sent successfully",
      }),
    };
  } catch (error) {
    console.error("Send Email Error:", error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: "Failed to send email",
        details: error.message,
      }),
    };
  }
}

async function buildOrderStatusUpdateEmail(data) {
  const {
    to,
    customerName,
    orderId,
    orderNumber,
    previousStatus,
    newStatus,
    statusMessage,
    trackingNumber,
  } = data;

  let trackingInfo = "";
  if (trackingNumber) {
    trackingInfo = `<p><strong>Tracking Number:</strong> ${trackingNumber}</p>`;
  }

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Order Status Update - Poligrain</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Poligrain</h1>
        <p style="margin: 10px 0 0 0;">Order Status Update</p>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px;">
        <p>Hello ${customerName},</p>
        
        <p>We wanted to update you on the status of your order <strong>#${orderNumber}</strong>.</p>
        
        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center;">
          <h3 style="color: #4CAF50; margin-top: 0;">Status Update</h3>
          <p style="font-size: 18px;"><strong>Previous Status:</strong> ${previousStatus}</p>
          <p style="font-size: 18px; color: #4CAF50;"><strong>Current Status:</strong> ${newStatus}</p>
          ${trackingInfo}
        </div>

        <p>${statusMessage}</p>

        <p>Thank you for choosing Poligrain!</p>
        
        <p>Best regards,<br>The Poligrain Team</p>
      </div>
      
      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
        <p>Poligrain - Your trusted agricultural marketplace</p>
        <p>If you have any questions, please contact us at support@poligrain.com</p>
      </div>
    </body>
    </html>
  `;

  return {
    Source: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Message: {
      Subject: {
        Data: `Order Status Update - Order #${orderNumber}`,
        Charset: "UTF-8",
      },
      Body: {
        Html: {
          Data: htmlContent,
          Charset: "UTF-8",
        },
        Text: {
          Data: `Hello ${customerName},\n\nYour order #${orderNumber} status has been updated.\n\nPrevious Status: ${previousStatus}\nCurrent Status: ${newStatus}\n\n${statusMessage}\n\nBest regards,\nThe Poligrain Team`,
          Charset: "UTF-8",
        },
      },
    },
  };
}

async function buildShippingNotificationEmail(data) {
  const {
    to,
    customerName,
    orderId,
    orderNumber,
    trackingNumber,
    carrierName,
    estimatedDelivery,
    shippingAddress,
  } = data;

  let deliveryInfo = "";
  if (estimatedDelivery) {
    const deliveryDate = new Date(estimatedDelivery).toLocaleDateString();
    deliveryInfo = `<p><strong>Estimated Delivery:</strong> ${deliveryDate}</p>`;
  }

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Your Order Has Shipped - Poligrain</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Poligrain</h1>
        <p style="margin: 10px 0 0 0;">Your Order Has Shipped!</p>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px;">
        <p>Hello ${customerName},</p>
        
        <p>Great news! Your order <strong>#${orderNumber}</strong> has been shipped and is on its way to you.</p>
        
        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="color: #4CAF50; margin-top: 0;">Shipping Details</h3>
          <p><strong>Tracking Number:</strong> ${trackingNumber || "N/A"}</p>
          <p><strong>Carrier:</strong> ${carrierName || "Standard Delivery"}</p>
          ${deliveryInfo}
        </div>

        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="color: #4CAF50; margin-top: 0;">Delivery Address</h3>
          <p style="margin: 5px 0;">${shippingAddress.fullName}</p>
          <p style="margin: 5px 0;">${shippingAddress.addressLine1}</p>
          ${shippingAddress.addressLine2 ? `<p style="margin: 5px 0;">${shippingAddress.addressLine2}</p>` : ""}
          <p style="margin: 5px 0;">${shippingAddress.city}, ${shippingAddress.state}</p>
          <p style="margin: 5px 0;">${shippingAddress.postalCode}, ${shippingAddress.country}</p>
        </div>

        <p>You can track your package using the tracking number provided above.</p>

        <p>Thank you for choosing Poligrain!</p>
        
        <p>Best regards,<br>The Poligrain Team</p>
      </div>
      
      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
        <p>Poligrain - Your trusted agricultural marketplace</p>
        <p>If you have any questions, please contact us at support@poligrain.com</p>
      </div>
    </body>
    </html>
  `;

  return {
    Source: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Message: {
      Subject: {
        Data: `Your Order Has Shipped - Order #${orderNumber}`,
        Charset: "UTF-8",
      },
      Body: {
        Html: {
          Data: htmlContent,
          Charset: "UTF-8",
        },
        Text: {
          Data: `Hello ${customerName},\n\nYour order #${orderNumber} has been shipped!\n\nTracking Number: ${trackingNumber || "N/A"}\nCarrier: ${carrierName || "Standard Delivery"}\n\nYou can track your package using the tracking number above.\n\nBest regards,\nThe Poligrain Team`,
          Charset: "UTF-8",
        },
      },
    },
  };
}

async function buildDeliveryConfirmationEmail(data) {
  const { to, customerName, orderId, orderNumber, deliveryDate, feedbackUrl } =
    data;

  const formattedDeliveryDate = new Date(deliveryDate).toLocaleDateString();

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Order Delivered - Poligrain</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Poligrain</h1>
        <p style="margin: 10px 0 0 0;">Order Delivered Successfully!</p>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px;">
        <p>Hello ${customerName},</p>
        
        <p>Your order <strong>#${orderNumber}</strong> has been successfully delivered on ${formattedDeliveryDate}.</p>
        
        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center;">
          <h3 style="color: #4CAF50; margin-top: 0;">Delivery Confirmed</h3>
          <p><strong>Order ID:</strong> ${orderId}</p>
          <p><strong>Delivery Date:</strong> ${formattedDeliveryDate}</p>
        </div>

        <p>We hope you're satisfied with your purchase! Your feedback is important to us.</p>
        
        ${
          feedbackUrl
            ? `<div style="text-align: center; margin: 30px 0;">
          <a href="${feedbackUrl}" style="display: inline-block; background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px;">Leave Feedback</a>
        </div>`
            : ""
        }

        <p>Thank you for choosing Poligrain!</p>
        
        <p>Best regards,<br>The Poligrain Team</p>
      </div>
      
      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
        <p>Poligrain - Your trusted agricultural marketplace</p>
        <p>If you have any questions, please contact us at support@poligrain.com</p>
      </div>
    </body>
    </html>
  `;

  return {
    Source: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Message: {
      Subject: {
        Data: `Order Delivered - Order #${orderNumber}`,
        Charset: "UTF-8",
      },
      Body: {
        Html: {
          Data: htmlContent,
          Charset: "UTF-8",
        },
        Text: {
          Data: `Hello ${customerName},\n\nYour order #${orderNumber} has been successfully delivered on ${formattedDeliveryDate}.\n\nWe hope you're satisfied with your purchase!\n\nBest regards,\nThe Poligrain Team`,
          Charset: "UTF-8",
        },
      },
    },
  };
}

function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

async function buildOrderConfirmationEmail(data) {
  const {
    to,
    customerName,
    orderId,
    orderNumber,
    totalAmount,
    orderDate,
    items,
    shippingAddress,
    paymentMethod,
    receiptAttachment,
  } = data;

  const itemsHtml = items
    .map(
      (item) => `
    <tr>
      <td style="padding: 10px; border-bottom: 1px solid #eee;">${
        item.name
      }</td>
      <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: center;">${
        item.quantity
      }${item.unit ? " " + item.unit : ""}</td>
      <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">${
        item.unitPrice
      }</td>
      <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">${
        item.totalPrice
      }</td>
    </tr>
  `
    )
    .join("");

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Order Confirmation - Poligrain</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Poligrain</h1>
        <p style="margin: 10px 0 0 0;">Order Confirmation</p>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px;">
        <p>Hello ${customerName},</p>
        
        <p>Thank you for your order! We're excited to confirm that your order <strong>#${orderNumber}</strong> has been successfully placed and is being processed.</p>
        
        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="color: #4CAF50; margin-top: 0;">Order Details</h3>
          <p><strong>Order ID:</strong> ${orderId}</p>
          <p><strong>Order Date:</strong> ${orderDate}</p>
          <p><strong>Payment Method:</strong> ${paymentMethod || "N/A"}</p>
          <p><strong>Total Amount:</strong> ${totalAmount}</p>
        </div>

        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="color: #4CAF50; margin-top: 0;">Items Ordered</h3>
          <table style="width: 100%; border-collapse: collapse;">
            <thead>
              <tr style="background-color: #f8f9fa;">
                <th style="padding: 10px; text-align: left; border-bottom: 2px solid #dee2e6;">Item</th>
                <th style="padding: 10px; text-align: center; border-bottom: 2px solid #dee2e6;">Quantity</th>
                <th style="padding: 10px; text-align: right; border-bottom: 2px solid #dee2e6;">Unit Price</th>
                <th style="padding: 10px; text-align: right; border-bottom: 2px solid #dee2e6;">Total</th>
              </tr>
            </thead>
            <tbody>
              ${itemsHtml}
            </tbody>
          </table>
        </div>

        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="color: #4CAF50; margin-top: 0;">Shipping Address</h3>
          <p style="margin: 5px 0;">${shippingAddress.fullName}</p>
          <p style="margin: 5px 0;">${shippingAddress.addressLine1}</p>
          ${
            shippingAddress.addressLine2
              ? `<p style="margin: 5px 0;">${shippingAddress.addressLine2}</p>`
              : ""
          }
          <p style="margin: 5px 0;">${shippingAddress.city}, ${
            shippingAddress.state
          }</p>
          <p style="margin: 5px 0;">${shippingAddress.postalCode}, ${
            shippingAddress.country
          }</p>
        </div>

        <p>Your receipt is attached to this email for your records.</p>

        <p>We'll send you another email with tracking information once your order has been shipped.</p>

        <p>Thank you for choosing Poligrain!</p>
        
        <p>Best regards,<br>The Poligrain Team</p>
      </div>
      
      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
        <p>Poligrain - Your trusted agricultural marketplace</p>
        <p>123 Agriculture Street, Lagos, Nigeria</p>
        <p>If you have any questions, please contact us at support@poligrain.com</p>
      </div>
    </body>
    </html>
  `;

  const textContent = `Hello ${customerName},\n\nThank you for your order! Your order #${orderNumber} has been confirmed.\n\nOrder Total: ${totalAmount}\nOrder Date: ${orderDate}\n\nWe'll send you tracking information once your order ships.\n\nBest regards,\nThe Poligrain Team`;

  const attachment =
    receiptAttachment && receiptAttachment.content
      ? `Content-Type: application/pdf
Content-Disposition: attachment; filename="${receiptAttachment.filename}"
Content-Transfer-Encoding: base64

${receiptAttachment.content}`
      : "";

  const rawEmail = `From: Poligrain <noreply@poligrain.com>
To: ${to}
Subject: Order Confirmation - Order #${orderNumber}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary"

--boundary
Content-Type: multipart/alternative; boundary="alt-boundary"

--alt-boundary
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 7bit

${textContent}

--alt-boundary
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: 7bit

${htmlContent}

--alt-boundary--

${attachment ? "--boundary\n" + attachment + "\n\n--boundary--" : ""}`;

  return {
    FromEmailAddress: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Content: {
      Raw: {
        Data: Buffer.from(rawEmail),
      },
    },
  };
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

  const textContent = `Hello ${customerName},\n\nYour order #${orderNumber} status has been updated.\n\nPrevious Status: ${previousStatus}\nCurrent Status: ${newStatus}\n\n${statusMessage}\n\nBest regards,\nThe Poligrain Team`;

  return {
    FromEmailAddress: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Content: {
      Simple: {
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
            Data: textContent,
            Charset: "UTF-8",
          },
        },
      },
    },
  };
}

async function buildReceiptOnlyEmail(data) {
  const { to, customerName, orderId, orderNumber, receiptAttachment } = data;

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Receipt - Poligrain</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Poligrain</h1>
        <p style="margin: 10px 0 0 0;">Order Receipt</p>
      </div>
      
      <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px;">
        <p>Hello ${customerName},</p>
        
        <p>Please find attached the receipt for your order <strong>#${orderNumber}</strong>.</p>
        
        <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center;">
          <h3 style="color: #4CAF50; margin-top: 0;">Receipt Information</h3>
          <p><strong>Order ID:</strong> ${orderId}</p>
          <p><strong>Order Number:</strong> #${orderNumber}</p>
        </div>

        <p>Thank you for your business!</p>
        
        <p>Best regards,<br>The Poligrain Team</p>
      </div>
      
      <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
        <p>Poligrain - Your trusted agricultural marketplace</p>
        <p>If you have any questions, please contact us at support@poligrain.com</p>
      </div>
    </body>
    </html>
  `;

  const textContent = `Hello ${customerName},\n\nPlease find attached the receipt for your order #${orderNumber}.\n\nOrder ID: ${orderId}\n\nThank you for your business!\n\nBest regards,\nThe Poligrain Team`;

  const attachment =
    receiptAttachment && receiptAttachment.content
      ? `Content-Type: application/pdf
Content-Disposition: attachment; filename="${receiptAttachment.filename}"
Content-Transfer-Encoding: base64

${receiptAttachment.content}`
      : "";

  const rawEmail = `From: Poligrain <noreply@poligrain.com>
To: ${to}
Subject: Receipt - Order #${orderNumber}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary"

--boundary
Content-Type: multipart/alternative; boundary="alt-boundary"

--alt-boundary
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 7bit

${textContent}

--alt-boundary
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: 7bit

${htmlContent}

--alt-boundary--

${attachment ? "--boundary\n" + attachment + "\n\n--boundary--" : ""}`;

  return {
    FromEmailAddress: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Content: {
      Raw: {
        Data: Buffer.from(rawEmail),
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
          ${
            shippingAddress.addressLine2
              ? `<p style="margin: 5px 0;">${shippingAddress.addressLine2}</p>`
              : ""
          }
          <p style="margin: 5px 0;">${shippingAddress.city}, ${
            shippingAddress.state
          }</p>
          <p style="margin: 5px 0;">${shippingAddress.postalCode}, ${
            shippingAddress.country
          }</p>
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

  const textContent = `Hello ${customerName},\n\nYour order #${orderNumber} has been shipped!\n\nTracking Number: ${
    trackingNumber || "N/A"
  }\nCarrier: ${
    carrierName || "Standard Delivery"
  }\n\nYou can track your package using the tracking number above.\n\nBest regards,\nThe Poligrain Team`;

  return {
    FromEmailAddress: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Content: {
      Simple: {
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
            Data: textContent,
            Charset: "UTF-8",
          },
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

  const textContent = `Hello ${customerName},\n\nYour order #${orderNumber} has been successfully delivered on ${formattedDeliveryDate}.\n\nWe hope you're satisfied with your purchase!\n\nBest regards,\nThe Poligrain Team`;

  return {
    FromEmailAddress: "noreply@poligrain.com",
    Destination: {
      ToAddresses: [to],
    },
    Content: {
      Simple: {
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
            Data: textContent,
            Charset: "UTF-8",
          },
        },
      },
    },
  };
}

module.exports = {
  buildOrderConfirmationEmail,
  buildOrderStatusUpdateEmail,
  buildReceiptOnlyEmail,
  buildShippingNotificationEmail,
  buildDeliveryConfirmationEmail,
};

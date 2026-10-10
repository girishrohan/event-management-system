const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// 1. SMTP Transporter Configuration using Environment Variables
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '465'),
  secure: process.env.SMTP_PORT === '465', // true for 465, false for 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS // Gmail App Password
  }
});

// Verify SMTP connection config on start
transporter.verify((error) => {
  if (error) {
    console.warn("⚠️ SMTP Connection Verification Failed (Server running in offline/sandbox mode):", error.message);
  } else {
    console.log("✨ SMTP Server is fully verified and ready to deliver administrator notifications!");
  }
});

// 2. Notification API Endpoint
app.post('/api/notify', async (req, res) => {
  const { formType, payload } = req.body;
  const recipient = process.env.SMTP_RECIPIENT || 'dd058288@gmail.com';

  console.log(`[SMTP] Received inbound notification trigger for form type: ${formType}`);

  // Format formType label
  let displayTitle = 'New Event Booking Received';
  if (formType === 'contact') displayTitle = 'New Contact Message Received';
  if (formType === 'inquiry') displayTitle = 'New Event Specifications Inquiry Received';
  if (formType === 'registration') displayTitle = 'New Administrative Registration Received';

  // Construct Email Template Body matching required subject/format
  const emailContent = `
New Event Booking

Name: ${payload.customerName || 'N/A'}
Email: ${payload.customerEmail || 'N/A'}
Phone: ${payload.phoneNumber || 'N/A'}
Event Type: ${payload.eventType || 'N/A'}
Event Date: ${payload.eventDate || 'N/A'}
Guests: ${payload.guestCount || 'N/A'}
Message: ${payload.message || 'N/A'}

---------------------------------------------
Submission Time: ${new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })} (IST)
System Notification Node: AuraMailer Agent v1.0
---------------------------------------------
`;

  const mailOptions = {
    from: `"AuraEvents Mailer Agent" <${process.env.SMTP_USER || 'mailer@auraevents.com'}>`,
    to: recipient,
    subject: displayTitle,
    text: emailContent
  };

  try {
    // Attempt real email delivery
    const info = await transporter.sendMail(mailOptions);
    console.log(`[SMTP SUCCESS] Mail delivered successfully to ${recipient}. MessageID: ${info.messageId}`);
    res.json({ success: true, message: 'Nodemailer notification delivered', messageId: info.messageId });
  } catch (err) {
    // Secure Error Handling: Log mail errors in server logs, but do NOT fail user transactions
    console.error(`[SMTP ERROR LOG] Failed to send email via SMTP transporter:`, err.message);
    
    // Return HTTP 200/OK with success: false (resilient fail-safe so data commits succeed regardless)
    res.status(200).json({ 
      success: false, 
      error: err.message, 
      message: 'Mail delivery failed/skipped due to server configurations, transaction is still committed.' 
    });
  }
});

// Start Express server on PORT 5000 (or env PORT)
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Secure AuraMailer Backend Server active on port ${PORT}`));

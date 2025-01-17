
export default {
  async email(message, env, ctx) {
    // Set up the forward and auto-reply email addresses
    const forwardTo = 'pradeep@gmail.com';
    const autoReplyFrom = 'noreply@gmail.com';
    const autoReplySubject = 'Thank you for your email';
    const autoReplyBody = 'We have received your email and will get back to you shortly.';

    // Forward the email
    await forwardEmail(message, forwardTo);

    await sendAutoReply(message, autoReplyFrom, autoReplySubject, autoReplyBody);


    return new Response('Email processed', { status: 200 });
  }
}

async function forwardEmail(message, forwardTo) {
  const emailBody = new FormData();
  emailBody.append('from', message.headers.get('To'));
  emailBody.append('to', forwardTo);
  emailBody.append('subject', message.headers.get('Subject'));

  const { textBody, htmlBody, attachments } = await getEmailContent(message);
  emailBody.append('text', textBody);
  emailBody.append('html', htmlBody);

  attachments.forEach((attachment, index) => {
    emailBody.append(`attachment${index}`, attachment.blob, { filename: attachment.filename });
  });

  return await sendEmail(emailBody);
}

async function sendAutoReply(message, autoReplyFrom, autoReplySubject, autoReplyBody, apiKey, domain) {
  const emailBody = new URLSearchParams();
  emailBody.append('from', autoReplyFrom);
  emailBody.append('to', message.headers.get('From'));
  emailBody.append('subject', autoReplySubject);
  emailBody.append('text', autoReplyBody);
  return await sendEmail(emailBody);
}

async function sendEmail(emailBody) {
  const apiKey = '';
  const domain = '';

  const response = await fetch(`https://api.mailgun.net/v3/${domain}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa('api:' + apiKey)}`
    },
    body: emailBody
  });

  if (!response.ok) {
    throw new Error(`Failed to send email: ${response.statusText}`);
  }

  return response;
}

async function getEmailContent(message) {
  let textBody = 'No text content';
  let htmlBody = 'No HTML content';
  let attachments = [];

  if (message.raw) {
    const { text, html, emailAttachments } = await parseRawEmail(message.raw);
    textBody = text;
    htmlBody = html;
    attachments = emailAttachments;
  } else {
    console.log("Raw content of the message not found.");
  }

  return { textBody, htmlBody, attachments };
}

async function parseRawEmail(raw) {
  if (raw instanceof ReadableStream) {
    raw = await streamToString(raw);
  }

  const boundaryMatch = raw.match(/boundary="(.+?)"/);
  if (!boundaryMatch) {
    throw new Error('No boundary found in raw email');
  }

  const boundary = boundaryMatch[1];
  const parts = raw.split(`--${boundary}`);
  let text = '';
  let html = '';
  let emailAttachments = [];

  for (const part of parts) {
    if (part.includes('Content-Type: text/plain')) {
      text = part.split('\r\n\r\n')[1].split(`\r\n--${boundary}`)[0].trim();
      text = quotedPrintableDecode(text);
    } else if (part.includes('Content-Type: text/html')) {
      html = part.split('\r\n\r\n')[1].split(`\r\n--${boundary}`)[0].trim();
      html = quotedPrintableDecode(html);
    } else if (part.includes('Content-Disposition: attachment')) {
      const attachmentInfo = extractAttachmentInfo(part);
      if (attachmentInfo) {
        const attachmentBlob = new Blob([attachmentInfo.content], { type: attachmentInfo.contentType });
        emailAttachments.push({ blob: attachmentBlob, filename: attachmentInfo.filename });
      }
    }
  }

  return { text, html, emailAttachments };
}

function extractAttachmentInfo(part) {
  const contentTypeMatch = part.match(/Content-Type: (.+?)\r\n/);
  const filenameMatch = part.match(/filename="(.+?)"/);
  const contentStart = part.indexOf('\r\n\r\n') + 4;

  if (contentTypeMatch && filenameMatch) {
    const contentType = contentTypeMatch[1];
    const filename = filenameMatch[1];
    const content = part.substring(contentStart, part.length).trim();
    return { contentType, filename, content };
  }

  return null;
}

// Function to decode quoted-printable encoding
function quotedPrintableDecode(input) {
  return input.replace(/=([0-9A-F]{2})/gi, (match, p1) => {
    return String.fromCharCode(parseInt(p1, 16));
  }).replace(/=\r\n/g, '').replace(/=20/g, ' ').replace(/Â/g, '');
}

// Helper function to convert a readable stream to a string
async function streamToString(stream) {
  const reader = stream.getReader();
  let result = '';
  let done, value;
  while ({ done, value } = await reader.read(), !done) {
    result += new TextDecoder('utf-8').decode(value);
  }
  return result;
}

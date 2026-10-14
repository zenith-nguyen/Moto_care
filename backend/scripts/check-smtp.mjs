import 'dotenv/config';
import nodemailer from 'nodemailer';

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

if (process.env.EMAIL_ENABLED !== 'true') {
  throw new Error('Set EMAIL_ENABLED=true in the local environment before checking SMTP');
}

const secure = process.env.SMTP_SECURE === 'true';
const transporter = nodemailer.createTransport({
  host: required('SMTP_HOST'),
  port: Number(process.env.SMTP_PORT ?? 587),
  secure,
  requireTLS: !secure,
  connectionTimeout: Number(process.env.SMTP_CONNECTION_TIMEOUT_MS ?? 10_000),
  greetingTimeout: Number(process.env.SMTP_CONNECTION_TIMEOUT_MS ?? 10_000),
  socketTimeout: Number(process.env.SMTP_SOCKET_TIMEOUT_MS ?? 30_000),
  auth: { user: required('SMTP_USER'), pass: required('SMTP_PASSWORD') },
});

await transporter.verify();
if (process.argv.includes('--send')) {
  const recipient = required('SMTP_TEST_RECIPIENT');
  await transporter.sendMail({
    from: required('SMTP_FROM'),
    to: recipient,
    subject: 'MotoCare SMTP test',
    text: 'MotoCare SMTP is configured correctly. This message contains no verification code or secret.',
  });
  console.log('SMTP verified and a test message was accepted for delivery.');
} else {
  console.log('SMTP connection and authentication verified. No message was sent.');
}

transporter.close();

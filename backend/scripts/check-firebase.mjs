import 'dotenv/config';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

if (process.env.PUSH_NOTIFICATIONS_ENABLED !== 'true') {
  throw new Error('Set PUSH_NOTIFICATIONS_ENABLED=true before checking Firebase credentials');
}
if (!process.env.FIREBASE_PROJECT_ID?.trim()) {
  throw new Error('FIREBASE_PROJECT_ID is required');
}

const credential = applicationDefault();
const token = await credential.getAccessToken();
if (!token.access_token) throw new Error('Firebase Application Default Credentials did not return an access token');
if (process.argv.includes('--send')) {
  const registrationToken = process.env.FCM_TEST_TOKEN?.trim();
  if (!registrationToken) throw new Error('FCM_TEST_TOKEN is required only for push:test');
  const app = initializeApp({
    credential,
    projectId: process.env.FIREBASE_PROJECT_ID.trim(),
  }, `motocare-push-check-${process.pid}`);
  await getMessaging(app).send({
    token: registrationToken,
    notification: {
      title: 'MotoCare push test',
      body: 'Firebase Cloud Messaging is configured correctly.',
    },
    data: { route: 'home', type: 'SYSTEM' },
    android: { priority: 'high', ttl: 60_000 },
  });
  console.log('Firebase credentials verified and a test push was accepted for delivery.');
} else {
  console.log('Firebase Application Default Credentials verified. No push notification was sent.');
}

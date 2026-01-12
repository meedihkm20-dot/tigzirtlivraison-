export default () => ({
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || 'dz-delivery',
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || 'firebase-adminsdk@example.com',
    databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://dz-delivery.firebaseio.com',
  },
});

const admin = require('firebase-admin');

// Initialize with default credentials (uses application default credentials or local environment)
try {
  admin.initializeApp();
} catch (e) {
  // already initialized in some environments
}

const firestore = admin.firestore();

async function createOutbox() {
  const docRef = firestore.collection('outbox_notifications').doc();
  const payload = {
    title: 'Test automatique from CLI',
    body: 'Ceci est un test automatique pour vérifier le consumer outbox',
    targetType: 'topic',
    topic: 'annonces',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'pending'
  };

  await docRef.set(payload);
  console.log('Created outbox doc with id:', docRef.id);
}

createOutbox().catch(err => {
  console.error('Error creating outbox doc:', err);
  process.exit(1);
});

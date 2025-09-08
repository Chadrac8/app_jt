// Script de test pour créer un message de contact et vérifier que la fonction se déclenche

const admin = require('firebase-admin');

// Initialiser Firebase Admin avec les credentials du projet
const serviceAccount = require('./service-account-key.json'); // Vous devrez télécharger ce fichier

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testContactMessage() {
  try {
    console.log('🧪 Test de création d\'un message de contact...');
    
    const testMessage = {
      name: 'Test User',
      email: 'test@example.com',
      subject: 'Message de test',
      message: 'Ceci est un message de test pour vérifier la fonction email.',
      createdAt: admin.firestore.Timestamp.now(),
      isRead: false
    };

    const docRef = await db.collection('contact_messages').add(testMessage);
    console.log('✅ Message de test créé avec l\'ID:', docRef.id);
    console.log('📋 Données:', testMessage);
    console.log('');
    console.log('🔍 Vérifiez les logs Firebase Functions pour voir si la fonction s\'est déclenchée:');
    console.log('   firebase functions:log --only onContactMessageCreated');
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

testContactMessage();

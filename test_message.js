// Test simple pour créer un document dans Firestore et déclencher la fonction

const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, serverTimestamp } = require('firebase/firestore');

// Configuration Firebase (vous pouvez récupérer cette config depuis votre projet)
const firebaseConfig = {
  // Remplacez avec votre vraie config Firebase si vous voulez tester localement
  projectId: "hjye25u8iwm0i0zls78urffsc0jcgj"
};

// Initialiser Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testContactMessage() {
  try {
    console.log('🧪 Création d\'un message de test...');
    
    const testMessage = {
      name: 'Test Utilisateur',
      email: 'test@example.com',
      subject: 'Message de test depuis Node.js',
      message: 'Ceci est un message de test pour vérifier que la fonction Firebase se déclenche.',
      createdAt: serverTimestamp(),
      isRead: false
    };

    const docRef = await addDoc(collection(db, 'contact_messages'), testMessage);
    console.log('✅ Message de test créé avec ID:', docRef.id);
    
    console.log('🔍 Vérifiez les logs Firebase Functions dans quelques secondes avec:');
    console.log('firebase functions:log --only onContactMessageCreated');
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  }
}

testContactMessage();

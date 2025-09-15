const admin = require('firebase-admin');

// Initialiser Firebase Admin
try {
  const serviceAccountPath = './firebase-admin-key.json';
  const serviceAccount = require(serviceAccountPath);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://hjye25u8iwm0i0zls78urffsc0jcgj-default-rtdb.firebaseio.com"
  });
} catch (error) {
  console.log('⚠️  Configuration Firebase Admin avec les credentials par défaut');
  admin.initializeApp({
    projectId: 'hjye25u8iwm0i0zls78urffsc0jcgj'
  });
}

const db = admin.firestore();

// Actions par défaut
const defaultActions = [
  {
    title: 'Prendre le baptême',
    description: 'Faire une demande de baptême',
    iconCodePoint: 57421, // Icons.water_drop
    actionType: 'form',
    isActive: true,
    order: 1,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#2196F3'
  },
  {
    title: 'Rendez-vous avec le pasteur',
    description: 'Prendre un rendez-vous personnel',
    iconCodePoint: 59441, // Icons.person_add
    actionType: 'navigation',
    targetModule: 'rendez_vous',
    isActive: true,
    order: 2,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#4CAF50'
  },
  {
    title: 'Rejoindre une équipe',
    description: 'Intégrer un groupe ou une équipe',
    iconCodePoint: 57778, // Icons.group_add
    actionType: 'navigation',
    targetModule: 'groupes',
    isActive: true,
    order: 3,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#FF9800'
  },
  {
    title: 'Requêtes de prière',
    description: 'Demander une prière ou prier pour d\'autres',
    iconCodePoint: 59143, // Icons.favorite
    actionType: 'navigation',
    targetModule: 'mur_priere',
    isActive: true,
    order: 4,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#E91E63'
  },
  {
    title: 'Poser une question au pasteur',
    description: 'Envoyer une question personnelle',
    iconCodePoint: 59648, // Icons.help_outline
    actionType: 'form',
    isActive: true,
    order: 5,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#9C27B0'
  },
  {
    title: 'Proposer une idée',
    description: 'Partager une suggestion ou idée',
    iconCodePoint: 59644, // Icons.lightbulb_outline
    actionType: 'form',
    isActive: true,
    order: 6,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#FFC107'
  },
  {
    title: 'Chanter un chant spécial',
    description: 'Proposer un chant pour le service',
    iconCodePoint: 59470, // Icons.music_note
    actionType: 'form',
    isActive: true,
    order: 7,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#673AB7'
  },
  {
    title: 'Informations sur l\'église',
    description: 'En savoir plus sur notre église',
    iconCodePoint: 59651, // Icons.info_outline
    actionType: 'form',
    isActive: true,
    order: 8,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    color: '#607D8B'
  }
];

async function initializePourVousActions() {
  try {
    console.log('🔍 Vérification de la collection pour_vous_actions...');
    
    const snapshot = await db.collection('pour_vous_actions').limit(1).get();
    
    if (snapshot.empty) {
      console.log('📝 Collection vide, création des actions par défaut...');
      
      const batch = db.batch();
      
      defaultActions.forEach(action => {
        const docRef = db.collection('pour_vous_actions').doc();
        batch.set(docRef, action);
      });
      
      await batch.commit();
      console.log(`✅ ${defaultActions.length} actions créées avec succès`);
    } else {
      console.log('✅ Collection pour_vous_actions existe déjà avec des données');
    }
    
    // Statistiques
    const allDocs = await db.collection('pour_vous_actions').get();
    const activeDocs = await db.collection('pour_vous_actions').where('isActive', '==', true).get();
    
    console.log('\n📊 Statistiques:');
    console.log(`   Total actions: ${allDocs.size}`);
    console.log(`   Actions actives: ${activeDocs.size}`);
    console.log(`   Actions inactives: ${allDocs.size - activeDocs.size}`);
    
    // Test de la requête qui posait problème
    console.log('\n🧪 Test de la requête principale...');
    const testQuery = await db.collection('pour_vous_actions')
      .where('isActive', '==', true)
      .orderBy('order')
      .get();
    
    console.log(`✅ Requête réussie, ${testQuery.size} actions trouvées`);
    
    if (testQuery.size > 0) {
      console.log('\n📋 Actions disponibles:');
      testQuery.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`   ${index + 1}. ${data.title} (ordre: ${data.order})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error);
    
    if (error.code === 'failed-precondition') {
      console.log('\n💡 Suggestion: Vérifiez que les index Firebase sont déployés');
      console.log('   Commande: firebase deploy --only firestore:indexes');
    }
  }
}

// Exécution
initializePourVousActions()
  .then(() => {
    console.log('\n✅ Initialisation terminée');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Erreur fatale:', error);
    process.exit(1);
  });
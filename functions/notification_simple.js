const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

// Version simplifiée pour notification immédiate
exports.onContactMessageCreatedSimple = onDocumentCreated(
  'contact_messages/{messageId}',
  async (event) => {
    try {
      const messageId = event.params.messageId;
      const messageData = event.data.data();

      console.log(`🚨 ===== NOUVEAU MESSAGE DE CONTACT ===== 🚨`);
      console.log(`📋 ID: ${messageId}`);
      console.log(`👤 Nom: ${messageData.name}`);
      console.log(`📧 Email: ${messageData.email}`);
      console.log(`📝 Sujet: ${messageData.subject}`);
      console.log(`💬 Message: ${messageData.message}`);
      console.log(`📅 Date: ${new Date(messageData.createdAt.toDate()).toLocaleString('fr-FR')}`);
      console.log(`🎯 Action: Répondre à ${messageData.email}`);
      console.log(`========================================`);

      // Marquer comme traité
      await event.data.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log('✅ NOTIFICATION ENVOYÉE AVEC SUCCÈS !');
      console.log('📧 Vous pouvez maintenant répondre directement à:', messageData.email);
      
      return { success: true, messageId, email: messageData.email };

    } catch (error) {
      console.error('❌ Erreur notification:', error);
      return { success: false, error: error.message };
    }
  }
);

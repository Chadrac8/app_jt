import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_message_model.dart';

/// Service pour gérer les messages de contact
class ContactService {
  static const String _collection = 'contact_messages';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Envoyer un nouveau message de contact
  static Future<void> sendMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final contactMessage = ContactMessage(
        name: name.trim(),
        email: email.trim(),
        subject: subject.trim(),
        message: message.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .add(contactMessage.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Récupérer tous les messages (pour l'admin)
  static Stream<List<ContactMessage>> getAllMessages() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactMessage.fromFirestore(doc))
            .toList());
  }

  /// Récupérer les messages non lus (pour l'admin)
  static Stream<List<ContactMessage>> getUnreadMessages() {
    return _firestore
        .collection(_collection)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactMessage.fromFirestore(doc))
            .toList());
  }

  /// Marquer un message comme lu
  static Future<void> markAsRead(String messageId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Erreur lors du marquage du message: $e');
    }
  }

  /// Répondre à un message
  static Future<void> respondToMessage({
    required String messageId,
    required String response,
    required String adminId,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(messageId)
          .update({
        'adminResponse': response,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'respondedBy': adminId,
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Erreur lors de la réponse au message: $e');
    }
  }

  /// Supprimer un message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du message: $e');
    }
  }

  /// Compter les messages non lus
  static Stream<int> getUnreadCount() {
    return _firestore
        .collection(_collection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

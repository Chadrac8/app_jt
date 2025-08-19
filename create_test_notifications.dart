import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script pour créer des notifications de test
/// Utilisation: dart run create_test_notifications.dart
void main() async {
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  
  // Assurez-vous d'être connecté
  final user = auth.currentUser;
  if (user == null) {
    print('Erreur: Aucun utilisateur connecté. Connectez-vous d\'abord dans l\'app.');
    return;
  }
  
  print('Création de notifications de test pour l\'utilisateur: ${user.uid}');
  
  final notifications = [
    {
      'userId': user.uid,
      'type': 'service',
      'title': 'Nouvelle affectation de service',
      'message': 'Vous avez été assigné à l\'équipe Louange pour le culte du dimanche 22 décembre.',
      'receivedAt': FieldValue.serverTimestamp(),
      'isRead': false,
    },
    {
      'userId': user.uid,
      'type': 'group',
      'title': 'Prochaine réunion de groupe',
      'message': 'Rappel : Réunion du groupe de prière demain à 19h30 en salle B.',
      'receivedAt': FieldValue.serverTimestamp(),
      'isRead': false,
    },
    {
      'userId': user.uid,
      'type': 'event',
      'title': 'Nouvel événement disponible',
      'message': 'Inscription ouverte pour la conférence "La famille selon Dieu" du 27 décembre.',
      'receivedAt': FieldValue.serverTimestamp(),
      'isRead': true,
    },
    {
      'userId': user.uid,
      'type': 'form',
      'title': 'Formulaire à remplir',
      'message': 'Le formulaire d\'évaluation du culte de décembre est maintenant disponible.',
      'receivedAt': FieldValue.serverTimestamp(),
      'isRead': true,
    },
    {
      'userId': user.uid,
      'type': 'announcement',
      'title': 'Annonce de l\'église',
      'message': 'Changement d\'horaire : Le culte de dimanche prochain commencera à 10h15.',
      'receivedAt': FieldValue.serverTimestamp(),
      'isRead': false,
    },
  ];
  
  try {
    for (int i = 0; i < notifications.length; i++) {
      final docRef = await firestore
          .collection('push_notifications')
          .add(notifications[i]);
      print('Notification ${i + 1} créée avec l\'ID: ${docRef.id}');
    }
    
    print('\n✅ ${notifications.length} notifications de test créées avec succès!');
    print('Vous pouvez maintenant tester l\'interface des notifications dans l\'app.');
    
  } catch (e) {
    print('❌ Erreur lors de la création des notifications: $e');
  }
}

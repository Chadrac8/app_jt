import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> debugFirebaseCollections() async {
  print('🔍 Debug des collections Firestore...');
  
  final firestore = FirebaseFirestore.instance;
  
  // Lister les collections populaires
  final collectionsToCheck = [
    'people',
    'persons',
    'users',
    'membres',
    'personnes',
  ];
  
  for (final collectionName in collectionsToCheck) {
    try {
      print('\n📁 Vérification de la collection: $collectionName');
      
      final snapshot = await firestore.collection(collectionName).limit(5).get();
      print('📊 Nombre de documents: ${snapshot.docs.length}');
      
      if (snapshot.docs.isNotEmpty) {
        print('📄 Premier document:');
        final firstDoc = snapshot.docs.first;
        print('   ID: ${firstDoc.id}');
        final data = firstDoc.data() as Map<String, dynamic>;
        print('   Champs: ${data.keys.join(', ')}');
        
        // Afficher quelques valeurs importantes
        if (data.containsKey('firstName')) {
          print('   Nom: ${data['firstName']} ${data['lastName'] ?? ''}');
        }
        if (data.containsKey('email')) {
          print('   Email: ${data['email']}');
        }
      }
    } catch (e) {
      print('❌ Erreur pour $collectionName: $e');
    }
  }
  
  print('\n✅ Debug terminé');
}

void main() async {
  await debugFirebaseCollections();
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script pour ajouter des numéros aux chants existants qui n'en ont pas
void main() async {
  print('🎵 Script de mise à jour des numéros de chants');
  print('=====================================');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    final firestore = FirebaseFirestore.instance;
    final songsCollection = firestore.collection('songs');
    
    // Récupérer tous les chants publiés
    print('📖 Récupération des chants...');
    final snapshot = await songsCollection
        .where('status', isEqualTo: 'published')
        .orderBy('title')
        .get();
    
    print('📊 ${snapshot.docs.length} chants trouvés');
    
    if (snapshot.docs.isEmpty) {
      print('⚠️ Aucun chant trouvé');
      return;
    }
    
    // Demander confirmation
    print('\n❓ Voulez-vous attribuer des numéros séquentiels aux chants triés par titre ? (y/n)');
    final response = stdin.readLineSync()?.toLowerCase();
    
    if (response != 'y' && response != 'yes') {
      print('❌ Opération annulée');
      return;
    }
    
    print('\n🔄 Attribution des numéros...');
    
    final batch = firestore.batch();
    int updateCount = 0;
    
    for (int i = 0; i < snapshot.docs.length; i++) {
      final doc = snapshot.docs[i];
      final data = doc.data();
      final currentNumber = data['number'];
      
      // Attribuer un numéro seulement si le chant n'en a pas déjà un
      if (currentNumber == null) {
        final newNumber = i + 1;
        batch.update(doc.reference, {'number': newNumber});
        updateCount++;
        
        print('  📝 ${data['title']} → Numéro $newNumber');
      } else {
        print('  ✅ ${data['title']} → Déjà numéroté ($currentNumber)');
      }
    }
    
    if (updateCount > 0) {
      print('\n💾 Sauvegarde des modifications...');
      await batch.commit();
      print('✅ $updateCount chants mis à jour avec succès!');
    } else {
      print('\n✅ Tous les chants ont déjà des numéros');
    }
    
    print('\n🎉 Terminé!');
    
  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }
}
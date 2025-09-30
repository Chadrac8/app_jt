import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🎵 Script de migration des numéros de chants');
  print('========================================');

  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');

    final firestore = FirebaseFirestore.instance;
    
    // Récupérer tous les chants
    final songsSnapshot = await firestore
        .collection('songs')
        .orderBy('title')
        .get();

    print('📚 ${songsSnapshot.docs.length} chants trouvés');

    if (songsSnapshot.docs.isEmpty) {
      print('⚠️  Aucun chant trouvé dans la collection');
      return;
    }

    // Vérifier combien de chants ont déjà un numéro
    int songsWithNumbers = 0;
    int songsWithoutNumbers = 0;

    for (var doc in songsSnapshot.docs) {
      final data = doc.data();
      if (data['number'] != null) {
        songsWithNumbers++;
      } else {
        songsWithoutNumbers++;
      }
    }

    print('📊 État actuel:');
    print('   - Chants avec numéro: $songsWithNumbers');
    print('   - Chants sans numéro: $songsWithoutNumbers');

    if (songsWithoutNumbers == 0) {
      print('✅ Tous les chants ont déjà un numéro!');
      return;
    }

    // Demander confirmation
    print('\n❓ Voulez-vous attribuer des numéros aux chants sans numéro? (y/N)');
    final response = stdin.readLineSync()?.toLowerCase();
    
    if (response != 'y' && response != 'yes') {
      print('❌ Opération annulée');
      return;
    }

    // Trouver le plus grand numéro existant
    int maxNumber = 0;
    for (var doc in songsSnapshot.docs) {
      final data = doc.data();
      final number = data['number'] as int?;
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }

    print('🔢 Plus grand numéro existant: $maxNumber');
    int nextNumber = maxNumber + 1;

    // Mettre à jour les chants sans numéro
    final batch = firestore.batch();
    int updatedCount = 0;

    for (var doc in songsSnapshot.docs) {
      final data = doc.data();
      if (data['number'] == null) {
        batch.update(doc.reference, {'number': nextNumber});
        print('   📝 "${data['title']}" → numéro $nextNumber');
        nextNumber++;
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      await batch.commit();
      print('\n✅ $updatedCount chants mis à jour avec succès!');
      print('🎯 Numéros attribués: ${maxNumber + 1} à ${nextNumber - 1}');
    } else {
      print('\n⚠️  Aucun chant à mettre à jour');
    }

  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }

  print('\n🎉 Script terminé avec succès!');
  print('💡 Les chants seront maintenant triés par numéro dans l\'application');
}
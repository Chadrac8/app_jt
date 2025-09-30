import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🎵 Script de renumération des cantiques');
  print('====================================');

  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');

    final firestore = FirebaseFirestore.instance;
    
    // Récupérer tous les chants pour analyser la situation
    final songsSnapshot = await firestore
        .collection('songs')
        .orderBy('number')
        .get();

    print('📚 ${songsSnapshot.docs.length} chants trouvés');

    if (songsSnapshot.docs.isEmpty) {
      print('⚠️  Aucun chant trouvé dans la collection');
      return;
    }

    // Analyser les chants et afficher les premiers
    print('\n📋 Premiers chants par numéro:');
    List<Map<String, dynamic>> cantiquesList = [];
    int displayCount = 0;
    
    for (var doc in songsSnapshot.docs) {
      final data = doc.data();
      final number = data['number'] as int?;
      final title = data['title'] as String? ?? 'Sans titre';
      final categories = data['categories'] as List<dynamic>? ?? [];
      
      if (displayCount < 20) {
        print('   $number - "$title" (Catégories: $categories)');
        displayCount++;
      }
      
      // Identifier les cantiques (vous pouvez ajuster ces critères)
      if (_isCantique(title, categories)) {
        cantiquesList.add({
          'id': doc.id,
          'title': title,
          'number': number,
          'categories': categories,
          'doc': doc,
        });
      }
    }

    print('\n🔍 ${cantiquesList.length} cantiques identifiés');
    
    if (cantiquesList.isEmpty) {
      print('⚠️  Aucun cantique identifié. Vérifiez les critères de détection.');
      return;
    }

    // Trier les cantiques par titre pour une renumération cohérente
    cantiquesList.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));
    
    print('\n📝 Cantiques à renumérotter:');
    for (int i = 0; i < cantiquesList.length && i < 10; i++) {
      final cantique = cantiquesList[i];
      print('   ${cantique['number']} → ${i + 1} : "${cantique['title']}"');
    }
    if (cantiquesList.length > 10) {
      print('   ... et ${cantiquesList.length - 10} autres');
    }

    // Demander confirmation
    print('\n❓ Voulez-vous renumérotter les cantiques de 1 à ${cantiquesList.length}? (y/N)');
    final response = stdin.readLineSync()?.toLowerCase();
    
    if (response != 'y' && response != 'yes') {
      print('❌ Opération annulée');
      return;
    }

    // Renumérotter les cantiques
    final batch = firestore.batch();
    int updatedCount = 0;

    for (int i = 0; i < cantiquesList.length; i++) {
      final cantique = cantiquesList[i];
      final newNumber = i + 1;
      final currentNumber = cantique['number'] as int?;
      
      if (currentNumber != newNumber) {
        final docRef = (cantique['doc'] as DocumentSnapshot).reference;
        batch.update(docRef, {'number': newNumber});
        print('   📝 "${cantique['title']}" : $currentNumber → $newNumber');
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      await batch.commit();
      print('\n✅ $updatedCount cantiques renumérrotés avec succès!');
      print('🎯 Les cantiques vont maintenant de 1 à ${cantiquesList.length}');
    } else {
      print('\n⚠️  Aucun cantique à renumérotter (déjà correctement numérotés)');
    }

  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }

  print('\n🎉 Script terminé avec succès!');
  print('💡 Les cantiques sont maintenant numérotés à partir de 1');
}

/// Détermine si un chant est un cantique basé sur le titre et les catégories
bool _isCantique(String title, List<dynamic> categories) {
  // Convertir en minuscules pour la comparaison
  final titleLower = title.toLowerCase();
  final categoriesStr = categories.join(' ').toLowerCase();
  
  // Critères pour identifier un cantique
  return 
    // Par catégorie
    categoriesStr.contains('cantique') ||
    categoriesStr.contains('hymne') ||
    
    // Par titre (mots-clés typiques des cantiques)
    titleLower.contains('cantique') ||
    titleLower.contains('hymne') ||
    titleLower.startsWith('ô ') ||
    titleLower.startsWith('o ') ||
    titleLower.contains('seigneur') ||
    titleLower.contains('jésus') ||
    titleLower.contains('dieu') ||
    titleLower.contains('éternel') ||
    titleLower.contains('christ') ||
    titleLower.contains('gloire') ||
    titleLower.contains('louange') ||
    titleLower.contains('alléluia') ||
    titleLower.contains('alleluia') ||
    
    // Patterns typiques des cantiques traditionnels
    titleLower.matches(RegExp(r'^(il|elle|nous|vous|ils|elles)\s+\w+')) ||
    titleLower.matches(RegExp(r'^(que|quand|comme|dans|sur|avec)\s+\w+')) ||
    titleLower.matches(RegExp(r'^(mon|ma|mes|ton|ta|tes|son|sa|ses|notre|votre|leur)\s+\w+'));
}

extension StringExtension on String {
  bool matches(RegExp regExp) {
    return regExp.hasMatch(this);
  }
}
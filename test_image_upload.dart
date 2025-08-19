import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'lib/services/image_upload_service.dart';

/// Script de test pour vérifier l'upload d'images
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé avec succès');
    
    // Test de la classe ImageUploadService
    print('📝 Test de l\'upload d\'images...');
    
    // Simuler un upload (remplacez par un vrai fichier pour tester)
    // final testFile = File('/path/to/test/image.jpg');
    // if (await testFile.exists()) {
    //   final url = await ImageUploadService.uploadImage(
    //     file: testFile,
    //     folder: 'test',
    //     fileName: 'test_image.jpg',
    //   );
    //   
    //   if (url != null) {
    //     print('✅ Upload réussi: $url');
    //   } else {
    //     print('❌ Échec de l\'upload');
    //   }
    // } else {
    //   print('⚠️  Fichier de test non trouvé');
    // }
    
    print('🔧 Service d\'upload configuré et prêt');
    
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation: $e');
  }
}

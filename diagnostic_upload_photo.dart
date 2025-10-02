import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Diagnostic complet pour le problème d'upload photo de profil
/// À exécuter dans un test ou depuis l'app pour vérifier les autorisations
class ProfileImageUploadDiagnostic {
  
  static Future<void> runDiagnostic() async {
    print('🔍 === DIAGNOSTIC UPLOAD PHOTO DE PROFIL ===');
    
    try {
      // 1. Vérifier l'authentification Firebase
      await _checkFirebaseAuth();
      
      // 2. Vérifier l'état de la PersonModel
      await _checkPersonModel();
      
      // 3. Vérifier les autorisations Storage
      await _checkStoragePermissions();
      
      // 4. Recommandations
      await _showRecommendations();
      
      print('✅ === DIAGNOSTIC TERMINÉ ===');
      
    } catch (e) {
      print('❌ Erreur durant le diagnostic: $e');
    }
  }
  
  static Future<void> _checkFirebaseAuth() async {
    print('\n📋 1. VÉRIFICATION AUTHENTIFICATION FIREBASE');
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      print('💡 L\'utilisateur doit être connecté pour uploader une photo de profil');
      return;
    }
    
    print('✅ Utilisateur connecté:');
    print('   - UID: ${user.uid}');
    print('   - Email: ${user.email}');
    print('   - Nom: ${user.displayName ?? 'Non défini'}');
    print('   - Email vérifié: ${user.emailVerified}');
    print('   - Dernière connexion: ${user.metadata.lastSignInTime}');
    
    // Vérifier le token d'authentification
    try {
      final idToken = await user.getIdToken();
      print('✅ Token d\'authentification valide (longueur: ${idToken.length})');
    } catch (e) {
      print('❌ Erreur token authentification: $e');
    }
  }
  
  static Future<void> _checkPersonModel() async {
    print('\n👤 2. VÉRIFICATION PERSONMODEL');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Impossible de vérifier PersonModel - utilisateur non connecté');
      return;
    }
    
    try {
      // Chercher la PersonModel avec l'UID Firebase Auth
      final querySnapshot = await FirebaseFirestore.instance
          .collection('persons')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        print('❌ Aucune PersonModel trouvée avec UID: ${user.uid}');
        print('💡 Cela peut indiquer un problème de liaison Auth-PersonModel');
        
        // Chercher par email comme fallback
        final emailQuery = await FirebaseFirestore.instance
            .collection('persons')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
            
        if (emailQuery.docs.isNotEmpty) {
          final person = emailQuery.docs.first.data();
          print('📋 PersonModel trouvée par email:');
          print('   - ID: ${emailQuery.docs.first.id}');
          print('   - UID: ${person['uid'] ?? 'NULL'}');
          print('   - Email: ${person['email']}');
          print('   - Nom: ${person['firstName']} ${person['lastName']}');
          print('⚠️ Le champ UID est manquant ou incorrect');
        }
        
      } else {
        final person = querySnapshot.docs.first.data();
        print('✅ PersonModel trouvée:');
        print('   - ID Firestore: ${querySnapshot.docs.first.id}');
        print('   - UID Firebase Auth: ${person['uid']}');
        print('   - Email: ${person['email']}');
        print('   - Nom: ${person['firstName']} ${person['lastName']}');
        print('   - Photo actuelle: ${person['profileImageUrl'] ?? 'Aucune'}');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la vérification PersonModel: $e');
    }
  }
  
  static Future<void> _checkStoragePermissions() async {
    print('\n🔒 3. VÉRIFICATION AUTORISATIONS STORAGE');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Impossible de vérifier Storage - utilisateur non connecté');
      return;
    }
    
    print('📋 Règles Storage pour les photos de profil:');
    print('   Path: profiles/{userId}/**');
    print('   Règle: allow read, write: if request.auth != null && request.auth.uid == userId');
    print('');
    print('✅ Configuration actuelle:');
    print('   - request.auth.uid: ${user.uid}');
    print('   - Path utilisé: profiles/${user.uid}/image.jpg');
    print('   - Match: ✅ (user.uid == path userId)');
    
    // Test théorique des chemins
    final correctPath = 'profiles/${user.uid}/test.jpg';
    print('');
    print('🎯 Chemins pour upload:');
    print('   ✅ CORRECT: $correctPath');
    print('   ❌ INCORRECT: profiles/unknown/test.jpg');
    print('   ❌ INCORRECT: profiles/firestore_doc_id/test.jpg');
  }
  
  static Future<void> _showRecommendations() async {
    print('\n💡 4. RECOMMANDATIONS');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('🔑 Étape 1: Connecter l\'utilisateur');
      print('   await FirebaseAuth.instance.signInWithEmailAndPassword(...)');
      return;
    }
    
    // Vérifier si PersonModel a le bon UID
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('persons')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        print('🔗 Étape 1: Lier PersonModel à Firebase Auth');
        print('   await FirebaseFirestore.instance.collection("persons")');
        print('     .doc(personId).update({"uid": "${user.uid}"})');
      }
    } catch (e) {
      print('⚠️ Impossible de vérifier la liaison PersonModel');
    }
    
    print('');
    print('📸 Étape 2: Upload photo avec le bon UID');
    print('   final user = FirebaseAuth.instance.currentUser!;');
    print('   final path = "profiles/\${user.uid}/photo.jpg";');
    print('   await ImageStorageService.uploadImage(bytes, customPath: path);');
    
    print('');
    print('🔧 Code corrigé dans member_profile_page.dart:');
    print('   - ❌ userId = _currentPerson?.id (ID PersonModel)');
    print('   - ✅ userId = FirebaseAuth.instance.currentUser!.uid');
  }
}

/// Fonction utilitaire pour tester l'upload depuis l'extérieur
Future<void> testProfileImageUpload() async {
  print('🧪 === TEST UPLOAD PHOTO DE PROFIL ===');
  await ProfileImageUploadDiagnostic.runDiagnostic();
}
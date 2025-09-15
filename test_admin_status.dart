import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Initialiser Firebase
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  
  print("🔍 Test du statut administrateur...");
  print("=" * 50);
  
  try {
    // 1. Lister tous les utilisateurs
    print("\n1. 📋 Utilisateurs existants:");
    final usersQuery = await firestore.collection('users').get();
    
    if (usersQuery.docs.isEmpty) {
      print("   ❌ Aucun utilisateur trouvé");
      return;
    }
    
    for (var doc in usersQuery.docs) {
      final data = doc.data();
      print("   👤 ${data['nom'] ?? 'Sans nom'} ${data['prenom'] ?? ''} (ID: ${doc.id})");
      print("      Email: ${data['email'] ?? 'N/A'}");
    }
    
    // 2. Vérifier les rôles existants
    print("\n2. 🎭 Rôles disponibles:");
    final rolesQuery = await firestore.collection('roles').get();
    
    if (rolesQuery.docs.isEmpty) {
      print("   ❌ Aucun rôle trouvé - il faut initialiser les rôles par défaut");
      print("\n🚀 Pour résoudre cela:");
      print("   1. Connectez-vous à l'app");
      print("   2. Les rôles par défaut seront créés automatiquement");
      return;
    }
    
    for (var doc in rolesQuery.docs) {
      final data = doc.data();
      print("   🎭 ${data['name']} (ID: ${doc.id})");
      print("      Description: ${data['description'] ?? 'N/A'}");
      print("      Actif: ${data['isActive'] ?? false}");
    }
    
    // 3. Vérifier les assignations de rôles
    print("\n3. 🔗 Assignations de rôles:");
    final userRolesQuery = await firestore.collection('user_roles').get();
    
    if (userRolesQuery.docs.isEmpty) {
      print("   ❌ Aucune assignation de rôle trouvée");
      print("\n💡 Solution: Assigner le rôle admin à votre utilisateur");
      
      // Proposer d'assigner le rôle admin au premier utilisateur
      if (usersQuery.docs.isNotEmpty) {
        final firstUser = usersQuery.docs.first;
        print("\n🔧 Voulez-vous assigner le rôle admin à ${firstUser.data()['nom']} ?");
        print("   Ajoutez ce code à votre script:");
        print("""
        await firestore.collection('user_roles').add({
          'userId': '${firstUser.id}',
          'roleId': 'admin',
          'assignedBy': 'system',
          'assignedAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'expiresAt': null,
        });
        """);
      }
      return;
    }
    
    for (var doc in userRolesQuery.docs) {
      final data = doc.data();
      print("   🔗 Utilisateur ${data['userId']} -> Rôle ${data['roleId']}");
      print("      Actif: ${data['isActive'] ?? false}");
      print("      Assigné par: ${data['assignedBy'] ?? 'N/A'}");
      
      if (data['expiresAt'] != null) {
        final expiry = (data['expiresAt'] as Timestamp).toDate();
        print("      Expire le: $expiry");
      }
    }
    
    // 4. Recommandations
    print("\n4. 🎯 Recommandations:");
    
    // Vérifier si au moins un utilisateur a le rôle admin
    final hasAdmin = userRolesQuery.docs.any((doc) {
      final data = doc.data();
      return data['roleId'] == 'admin' && (data['isActive'] ?? false);
    });
    
    if (!hasAdmin) {
      print("   ⚠️  Aucun utilisateur n'a le rôle admin actif");
      print("   📝 Action requise: Assigner le rôle admin à votre compte");
    } else {
      print("   ✅ Au moins un utilisateur a le rôle admin");
    }
    
    print("\n" + "=" * 50);
    print("✅ Test terminé");
    
  } catch (e) {
    print("❌ Erreur: $e");
  }
}
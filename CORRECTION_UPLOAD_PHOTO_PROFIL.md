# 🖼️ CORRECTION UPLOAD PHOTO DE PROFIL

## ❌ Problème identifié

L'utilisateur ne peut pas uploader sa photo de profil avec l'erreur :
```
[firebase_storage/unauthorized] User is not authorized to perform the desired action.
```

## 🔍 Cause racine

**Mauvaise utilisation des identifiants pour Firebase Storage**

- **Problème** : La méthode `_pickProfileImage()` utilisait `_currentPerson?.id` (ID PersonModel Firestore)
- **Règles Storage** : Configurées pour `request.auth.uid` (UID Firebase Auth)
- **Conséquence** : Mismatch entre l'ID utilisé dans le path et l'UID autorisé

## ✅ Solution appliquée

### 1. Correction du path Firebase Storage

**AVANT :**
```dart
final userId = _currentPerson?.id ?? 'unknown'; // ❌ ID PersonModel
final imageUrl = await ImageStorageService.uploadImage(
  imageBytes,
  customPath: 'profiles/$userId/...',
);
```

**APRÈS :**
```dart
final user = FirebaseAuth.instance.currentUser; // ✅ Firebase Auth User
if (user == null) throw Exception('Utilisateur non connecté');
final userId = user.uid; // ✅ UID Firebase Auth

final imageUrl = await ImageStorageService.uploadImage(
  imageBytes,
  customPath: 'profiles/$userId/...',
);
```

### 2. Import ajouté

```dart
import 'package:firebase_auth/firebase_auth.dart';
```

## 🔧 Règles Firebase Storage

Les règles étaient correctes :
```javascript
match /profiles/{userId}/{allPaths=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

- `request.auth.uid` = UID Firebase Auth de l'utilisateur connecté
- `userId` dans le path doit correspondre à cet UID

## 🎯 Résultat attendu

✅ **L'utilisateur peut maintenant uploader sa photo de profil**
- Path : `profiles/{firebase_auth_uid}/image.jpg`
- Autorisation : Utilisateur connecté avec le bon UID
- Sécurité : Chaque utilisateur ne peut modifier que ses propres photos

## 🧪 Test

1. Se connecter dans l'app
2. Aller sur le profil utilisateur
3. Appuyer sur l'icône photo de profil
4. Sélectionner une image depuis la galerie
5. ✅ L'upload devrait maintenant réussir

## 📝 Notes importantes

### Différence UID vs ID
- **UID Firebase Auth** : Identifiant unique pour l'authentification (`xK8mN2pQ9rS5...`)
- **ID PersonModel** : Identifiant document Firestore (`ymljo94rbJbLg98YOs9X`)
- **Pour Storage** : Toujours utiliser l'UID Firebase Auth

### Sécurité
Les règles Firebase Storage garantissent que :
- Seul l'utilisateur connecté peut modifier ses propres fichiers
- Les autres utilisateurs ne peuvent pas accéder aux photos d'autrui
- Chaque utilisateur a son dossier privé `/profiles/{son_uid}/`

## 🔗 Fichiers modifiés

- `lib/pages/member_profile_page.dart` : Correction de l'UID utilisé
- Import `firebase_auth` ajouté pour accéder au User actuel
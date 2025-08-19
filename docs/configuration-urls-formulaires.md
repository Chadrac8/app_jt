# Configuration des URLs des Formulaires - Jubilé Tabernacle

## 🎯 Objectif

Configurer les liens vers les formulaires du module Formulaires pour qu'ils intègrent correctement le nom de domaine personnalisé `app.jubiletabernacle.org`.

## ✅ Modifications Apportées

### 1. **Création du fichier de configuration des URLs**

**Fichier :** `lib/config/app_urls.dart`

```dart
class AppConfig {
  // URL Configuration
  static const String baseUrl = 'https://app.jubiletabernacle.org';
  static const String firebaseUrl = 'https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app';
  
  // Form URLs
  static String generatePublicFormUrl(String formId) {
    return '$baseUrl/forms/$formId';
  }
  
  // Page URLs, Event URLs, etc.
}
```

### 2. **Mise à jour du service des formulaires**

**Fichier :** `lib/services/forms_firebase_service.dart`

- **Ajout de l'import :** `import '../config/app_urls.dart';`
- **Modification de la fonction :**

```dart
// AVANT
static String generatePublicFormUrl(String formId) {
  // TODO: Replace with actual domain
  return 'https://your-domain.com/forms/$formId';
}

// APRÈS
static String generatePublicFormUrl(String formId) {
  return AppConfig.generatePublicFormUrl(formId);
}
```

### 3. **Configuration du routage pour les formulaires publics**

**Fichier :** `lib/routes/simple_routes.dart`

- **Ajout de l'import :** `import '../pages/form_public_page.dart';`
- **Modification du générateur de routes :**

```dart
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
  
  // Gérer les routes avec paramètres pour les formulaires
  if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'forms') {
    final formId = uri.pathSegments[1];
    return MaterialPageRoute(
      builder: (context) => FormPublicPage(formId: formId),
      settings: settings,
    );
  }
  
  // Routes existantes...
}
```

## 🔗 **Format des URLs Générées**

### **Avant les modifications :**
```
https://your-domain.com/forms/[form-id]
```

### **Après les modifications :**
```
https://app.jubiletabernacle.org/forms/[form-id]
```

## 📍 **Pages Affectées**

Les pages suivantes utilisent maintenant les URLs avec le bon domaine :

1. **`lib/pages/form_detail_page.dart`**
   - Fonction `_copyFormUrl()` - Copie le lien du formulaire

2. **`lib/pages/forms_home_page.dart`**
   - Fonction `_copyFormUrl(FormModel form)` - Copie le lien depuis la liste

3. **`lib/pages/member_forms_page.dart`**
   - Navigation vers les formulaires publics

## 🛠️ **Fonctionnalités**

### **1. Génération d'URLs Centralisée**
- Toutes les URLs sont générées depuis `AppConfig`
- Facilite les futures modifications de domaine
- Cohérence dans toute l'application

### **2. Support des Routes Dynamiques**
- Les URLs `/forms/[form-id]` sont automatiquement routées
- Compatible avec le système de navigation Flutter
- Support du partage de liens directs

### **3. URLs Configurables**
- Domaine principal : `app.jubiletabernacle.org`
- Domaine de fallback : `hjye25u8iwm0i0zls78urffsc0jcgj.web.app`
- Facilement modifiable dans un seul fichier

## 🧪 **Tests**

### **Script de test :** `test-form-urls.sh`
```bash
./test-form-urls.sh
```

**Vérifications effectuées :**
- ✅ Fichier de configuration créé
- ✅ Service mis à jour
- ✅ Pages utilisatrices connectées
- ✅ Format des URLs correct
- ✅ Application déployée

## 📝 **Comment Tester**

### **1. Test depuis l'interface Admin :**
1. Connectez-vous à l'interface admin
2. Allez dans "Formulaires"
3. Créez ou sélectionnez un formulaire
4. Cliquez sur "Copier le lien"
5. Vérifiez que l'URL commence par `https://app.jubiletabernacle.org`

### **2. Test de navigation directe :**
1. Copiez une URL de formulaire
2. Ouvrez un nouvel onglet
3. Collez l'URL
4. Vérifiez que le formulaire s'affiche correctement

### **3. Test depuis l'interface Membre :**
1. Connectez-vous en tant que membre
2. Allez dans "Formulaires"
3. Cliquez sur un formulaire disponible
4. Vérifiez la navigation

## 🚀 **Déploiement**

Les modifications ont été déployées sur :
- **Firebase URL :** https://hjye25u8iwm0i0zls78urffsc0jcgj.web.app
- **Domaine personnalisé :** https://app.jubiletabernacle.org

## 🔧 **Configuration Additionnelle**

### **Extensions Possibles :**

1. **URLs pour d'autres modules :**
   ```dart
   static String generateEventUrl(String eventId) {
     return '$baseUrl/events/$eventId';
   }
   ```

2. **URLs avec paramètres :**
   ```dart
   static String generateFormUrlWithParams(String formId, Map<String, String> params) {
     final uri = Uri.parse('$baseUrl/forms/$formId');
     return uri.replace(queryParameters: params).toString();
   }
   ```

## ⚠️ **Notes Importantes**

1. **Propagation DNS :** Assurez-vous que le domaine `app.jubiletabernacle.org` est correctement configuré
2. **Certificats SSL :** Firebase gère automatiquement les certificats SSL
3. **Cache :** Les anciens liens peuvent être mis en cache, attendez la propagation
4. **Redirections :** Considérez ajouter des redirections depuis l'ancien domaine si nécessaire

## 🎉 **Résultat Final**

✅ **Tous les liens vers les formulaires utilisent maintenant votre domaine personnalisé `app.jubiletabernacle.org`**

Les utilisateurs qui copient et partagent des liens de formulaires obtiendront des URLs avec votre domaine de marque, renforçant l'identité de Jubilé Tabernacle.

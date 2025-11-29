# 🍎 Déploiement App Store - Jubilé Tabernacle

## 🚀 Démarrage Rapide

### 1. Scripts Disponibles

```bash
# 📦 Build et Upload complet vers App Store
./deploy_app_store.sh

# 📸 Préparer les captures d'écran
./prepare_screenshots.sh

# ✅ Validation avant soumission
./validate_app_store_final.sh
```

### 2. Processus Complet

#### Étape 1: Préparation
- ✅ Toutes les icônes présentes dans `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- ✅ Version configurée dans `pubspec.yaml`: **1.0.0+1**
- ✅ Bundle ID: **org.jubiletabernacle.app**
- ✅ Politique de confidentialité hébergée

#### Étape 2: Captures d'écran
```bash
./prepare_screenshots.sh
```
Prendre des captures pour:
- iPhone 6.7" (1290x2796)
- iPhone 6.5" (1242x2688)
- iPhone 5.5" (1242x2208)

#### Étape 3: Build et Upload
```bash
./deploy_app_store.sh
```

Ce script va:
1. Nettoyer le projet
2. Installer les dépendances
3. Builder l'app iOS
4. Créer l'archive Xcode
5. Exporter l'IPA
6. (Optionnel) Upload vers App Store Connect

#### Étape 4: Configuration App Store Connect
Suivre le guide détaillé: [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md)

1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. Créer l'app si pas encore fait
3. Uploader les captures d'écran
4. Remplir la description et métadonnées
5. Sélectionner le build
6. Soumettre pour révision

## 📚 Documentation Complète

- **[GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md)** - Guide complet détaillé (50+ pages)
- **[CHECKLIST_APP_STORE.md](./CHECKLIST_APP_STORE.md)** - Checklist complète étape par étape
- **[deploy_app_store.sh](./deploy_app_store.sh)** - Script de build automatisé
- **[prepare_screenshots.sh](./prepare_screenshots.sh)** - Guide pour les captures

## ⚙️ Configuration Requise

### Avant de Commencer

1. **Compte Apple Developer**
   - Compte actif ($99/an)
   - Accès à App Store Connect

2. **Outils**
   - macOS avec Xcode installé
   - Flutter installé
   - CocoaPods installé

3. **Configuration Apple**
   - Bundle ID créé: `org.jubiletabernacle.app`
   - Certificat de distribution installé
   - Profil de provisioning App Store

4. **Dans le Script**
   Modifier `deploy_app_store.sh` ligne 173 et 196:
   ```bash
   DEVELOPMENT_TEAM="VOTRE_TEAM_ID"
   ```
   Remplacer `VOTRE_TEAM_ID` par votre Team ID Apple Developer

## 📋 Informations de l'App

- **Nom**: Jubilé Tabernacle
- **Bundle ID**: org.jubiletabernacle.app
- **Version**: 1.0.0
- **Build**: 1
- **Catégorie**: Style de vie
- **Classification**: 4+ (Tous âges)
- **Prix**: Gratuit

## 🎯 Points Importants

### Pour l'Approbation Apple

1. **Compte de test fonctionnel** ⚠️ CRUCIAL
   ```
   Email: testuser@example.com
   Mot de passe: TestPassword123!
   ```

2. **Politique de confidentialité**
   - Doit être hébergée et accessible
   - URL à fournir dans App Store Connect

3. **Captures d'écran**
   - Minimum 3 par taille de device
   - Recommandé 5-8 pour meilleur impact

4. **Description**
   - Claire, sans fautes
   - Met en avant les fonctionnalités

5. **Notes de révision**
   - Expliquer les fonctionnalités
   - Guider les reviewers Apple

## 🔄 Workflow Typique

```bash
# 1. Développer et tester
flutter run -d "iPhone 15 Pro Max"

# 2. Prendre les captures d'écran
./prepare_screenshots.sh
# Suivre les instructions pour prendre les captures

# 3. Build et upload
./deploy_app_store.sh
# Le script guide à travers tout le processus

# 4. Configuration App Store Connect
# Suivre GUIDE_APP_STORE.md section "Configuration App Store Connect"

# 5. Soumettre
# Cliquer sur "Envoyer pour révision" dans App Store Connect

# 6. Attendre l'approbation (1-3 jours généralement)
```

## 📱 Captures d'Écran Recommandées

Ordre suggéré:
1. 🏠 Page d'accueil avec Pain quotidien
2. 📖 Module Bible avec un verset
3. ⛪ Vie de l'église (sermons/événements)
4. 🙏 Prières communautaires
5. 👤 Profil utilisateur
6. 💰 Module Offrandes (optionnel)
7. 🌙 Mode sombre (optionnel)

## ❓ FAQ

### Comment obtenir mon Team ID Apple ?
1. Aller sur [developer.apple.com](https://developer.apple.com)
2. Account > Membership
3. Le Team ID est affiché (10 caractères)

### L'upload échoue, que faire ?
1. Vérifier les certificats et profils
2. Vérifier que le Bundle ID correspond
3. Essayer Xcode Organizer ou Transporter manuellement
4. Voir les logs dans `build/ios/`

### Combien de temps pour l'approbation ?
- Traitement du build: 10-30 minutes
- Révision Apple: 1-3 jours (max 7 jours)
- Publication: Immédiate après approbation

### Mon app a été rejetée, que faire ?
1. Lire attentivement le message de rejet
2. Corriger selon la guideline mentionnée
3. Si changement métadonnées: resoumettre sans nouveau build
4. Si changement code: nouveau build nécessaire
5. Répondre dans Resolution Center si besoin de clarification

## 🆘 Support

### Problèmes Techniques
- Voir [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md) section "Résolution de Problèmes"
- Consulter les logs: `build/ios/`
- Forums: [Apple Developer Forums](https://developer.apple.com/forums/)

### Questions sur le Process
- Consulter [CHECKLIST_APP_STORE.md](./CHECKLIST_APP_STORE.md)
- App Store Connect Help: [help.apple.com/app-store-connect](https://help.apple.com/app-store-connect/)

### Contact
- Email: contact@jubiletabernacle.org
- Site: www.jubiletabernacle.org

## 🎉 Après Publication

Une fois approuvé:
1. ✅ L'app apparaît sur l'App Store (peut prendre 24h)
2. ✅ Partagez le lien: `https://apps.apple.com/app/jubile-tabernacle/idXXXXXXXXX`
3. ✅ Surveillez Analytics dans App Store Connect
4. ✅ Répondez aux avis utilisateurs
5. ✅ Surveillez Firebase Crashlytics pour les crashs

## 📊 Ressources

- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)

---

**Bonne chance avec votre soumission App Store ! 🍎✨**

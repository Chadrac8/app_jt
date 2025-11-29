# 🍎 App Store - Index des Ressources

## 📚 Documentation Complète

Voici tous les documents et scripts pour déployer **Jubilé Tabernacle** sur l'App Store.

---

## 🚀 DÉMARRAGE RAPIDE

**Pour déployer rapidement, suivez ces 3 étapes:**

1. **Lisez d'abord:** [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md)
   - Points critiques à ne pas oublier
   - Team ID à configurer
   - Compte de test à créer

2. **Préparez les captures:** 
   ```bash
   ./prepare_screenshots.sh
   ```

3. **Lancez le déploiement:**
   ```bash
   ./deploy_app_store.sh
   ```

4. **Suivez le guide:** [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md)
   - Configuration App Store Connect
   - Métadonnées à remplir
   - Soumission pour révision

---

## 📖 Documents Disponibles

### 1. 🔴 [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md)
**À LIRE EN PREMIER !**

- ⚠️ Points critiques obligatoires
- Team ID à configurer
- Compte de test pour reviewers
- Politique de confidentialité
- Erreurs fréquentes à éviter
- Checklist ultra-rapide

**Durée de lecture: 10 minutes**

---

### 2. 📘 [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md)
**Guide complet et détaillé**

- Configuration Apple Developer
- Création de l'app dans App Store Connect
- Build et upload
- Configuration métadonnées
- Soumission pour review
- Après approbation
- Mises à jour futures

**Durée de lecture: 30 minutes**  
**Pages: ~50**

---

### 3. ✅ [CHECKLIST_APP_STORE.md](./CHECKLIST_APP_STORE.md)
**Checklist complète étape par étape**

12 phases couvrant:
- Préparation (Phase 1)
- Captures d'écran (Phase 2)
- Build et archive (Phase 3)
- Upload (Phase 4)
- Configuration App Store Connect (Phase 5-8)
- Soumission (Phase 9-10)
- Suivi et publication (Phase 11-12)

**Format: Checklist avec cases à cocher**  
**Idéal pour: Suivre la progression**

---

### 4. 📱 [README_APP_STORE.md](./README_APP_STORE.md)
**Vue d'ensemble et référence rapide**

- Démarrage rapide
- Scripts disponibles
- Configuration requise
- Workflow typique
- FAQ
- Ressources

**Durée de lecture: 15 minutes**  
**Idéal pour: Comprendre le processus global**

---

## 🛠️ Scripts Automatisés

### 1. 🚀 [deploy_app_store.sh](./deploy_app_store.sh)
**Script principal de déploiement**

```bash
./deploy_app_store.sh
```

**Ce qu'il fait:**
1. ✅ Vérifications préliminaires (Flutter, Xcode, version)
2. 🧹 Nettoyage complet
3. 📦 Installation dépendances (Flutter + CocoaPods)
4. 🔨 Build Flutter iOS release
5. 📦 Archive Xcode
6. 📤 Export IPA pour App Store
7. ☁️ Upload vers App Store Connect (optionnel)

**Durée: 15-30 minutes** (première fois)

⚠️ **IMPORTANT:** Configurer votre Team ID aux lignes 173 et 196

---

### 2. 📸 [prepare_screenshots.sh](./prepare_screenshots.sh)
**Préparation des captures d'écran**

```bash
./prepare_screenshots.sh
```

**Ce qu'il fait:**
- Crée les dossiers pour organiser les captures
- Affiche les résolutions requises
- Guide pour prendre les captures sur simulateur
- Crée la structure: `screenshots_app_store/`

**Captures requises:**
- iPhone 6.7" (1290 x 2796 px)
- iPhone 6.5" (1242 x 2688 px)
- iPhone 5.5" (1242 x 2208 px)
- iPad Pro 12.9" (2048 x 2732 px) - optionnel

---

### 3. ✅ [validate_app_store_final.sh](./validate_app_store_final.sh)
**Validation avant soumission** (existe déjà)

```bash
./validate_app_store_final.sh
```

**Ce qu'il vérifie:**
- Fichiers requis présents
- Configuration Info.plist
- Permissions définies
- Format de version correct
- Description complète

---

## 🗂️ Structure des Fichiers

```
projet/
├── 📄 IMPORTANT_APP_STORE.md       ← Lire en premier !
├── 📘 GUIDE_APP_STORE.md           ← Guide détaillé complet
├── ✅ CHECKLIST_APP_STORE.md       ← Checklist étape par étape
├── 📱 README_APP_STORE.md          ← Vue d'ensemble
├── 📑 INDEX_APP_STORE.md           ← Ce fichier
│
├── 🚀 deploy_app_store.sh          ← Script principal
├── 📸 prepare_screenshots.sh       ← Aide captures d'écran
├── ✅ validate_app_store_final.sh  ← Validation
│
├── 📁 screenshots_app_store/       ← Captures (à créer)
│   ├── 6.7_inch/
│   ├── 6.5_inch/
│   ├── 5.5_inch/
│   └── 12.9_inch/
│
└── 📁 build/ios/                   ← Généré par le script
    ├── archive/Runner.xcarchive
    └── ipa/Runner.ipa
```

---

## 🎯 Parcours Recommandé

### Pour un Débutant
1. 📖 Lire [README_APP_STORE.md](./README_APP_STORE.md) - Vue d'ensemble
2. 🔴 Lire [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md) - Points critiques
3. ✅ Suivre [CHECKLIST_APP_STORE.md](./CHECKLIST_APP_STORE.md) - Étape par étape
4. 📘 Consulter [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md) - En cas de doute

### Pour un Utilisateur Expérimenté
1. 🔴 Vérifier [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md) - Checklist rapide
2. 🚀 Exécuter `./deploy_app_store.sh`
3. 📸 Préparer captures avec `./prepare_screenshots.sh`
4. 📘 Suivre [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md) section "Configuration App Store Connect"

---

## 📋 Informations de l'Application

**Détails techniques:**
- **Nom**: Jubilé Tabernacle
- **Bundle ID**: org.jubiletabernacle.app
- **Version actuelle**: 1.0.0+1
- **Catégorie**: Style de vie
- **Classification**: 4+ (Tous âges)
- **Prix**: Gratuit
- **Langue principale**: Français (France)

**Technologies:**
- Flutter / Dart
- Firebase (Auth, Firestore, Storage, FCM)
- Sign in with Apple
- Push Notifications
- HelloAsso (dons)

---

## ⚙️ Configuration Requise

### Compte et Outils
- ✅ Compte Apple Developer ($99/an)
- ✅ macOS avec Xcode installé
- ✅ Flutter installé
- ✅ CocoaPods installé
- ✅ Accès à App Store Connect

### Configuration Apple
- ✅ Bundle ID créé: `org.jubiletabernacle.app`
- ✅ Certificat de distribution installé
- ✅ Profil de provisioning App Store configuré
- ✅ Team ID connu

### Assets Préparés
- ✅ Icônes toutes tailles (fait ✓)
- ✅ Captures d'écran (à faire avec script)
- ✅ Politique de confidentialité hébergée (à faire)
- ✅ Description (fournie dans docs)

---

## 🚦 Statut de Préparation

### ✅ Prêt
- [x] Configuration iOS (Info.plist, Bundle ID, icônes)
- [x] Scripts de déploiement créés
- [x] Documentation complète
- [x] Checklists et guides

### ⏳ À Faire
- [ ] Configurer Team ID dans `deploy_app_store.sh`
- [ ] Créer compte de test pour reviewers
- [ ] Héberger politique de confidentialité
- [ ] Prendre captures d'écran (3 tailles)
- [ ] Créer app dans App Store Connect

---

## 🆘 Aide et Support

### En Cas de Problème

**Pendant le build:**
- Consulter [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md) section "Erreurs fréquentes"
- Vérifier les logs: `build/ios/`
- Relancer `flutter clean && flutter pub get`

**Pendant la configuration App Store Connect:**
- Suivre [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md) section correspondante
- Vérifier [CHECKLIST_APP_STORE.md](./CHECKLIST_APP_STORE.md)

**Si l'app est rejetée:**
- Lire [GUIDE_APP_STORE.md](./GUIDE_APP_STORE.md) section "Résolution de Problèmes"
- Consulter [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md) section "En cas de problème"

### Ressources Externes

**Documentation Apple:**
- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Developer](https://developer.apple.com)

**Support Apple:**
- [Developer Support](https://developer.apple.com/contact/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Forums](https://developer.apple.com/forums/)

**Contact Projet:**
- Email: contact@jubiletabernacle.org
- Site: www.jubiletabernacle.org

---

## ⏱️ Timeline Estimée

**Préparation initiale:** 2-4 heures
- Configuration Team ID: 5 min
- Création compte de test: 10 min
- Hébergement privacy policy: 30 min
- Captures d'écran: 1-2 heures
- Configuration App Store Connect: 1-2 heures

**Build et upload:** 30-60 minutes
- Exécution du script: 20-40 min
- Upload vers App Store Connect: 10-20 min
- Traitement du build: 10-30 min

**Révision Apple:** 1-3 jours
- En attente: 0-2 jours
- En révision: 1-2 jours

**Total: 3-7 jours** de la première préparation à la publication

---

## 🎯 Prochaines Étapes

### 1. Configuration Initiale (Today)
```bash
# 1. Configurer Team ID dans deploy_app_store.sh
# 2. Créer compte de test Firebase
# 3. Héberger privacy_policy.html
```

### 2. Captures d'Écran (Today)
```bash
./prepare_screenshots.sh
# Suivre les instructions pour prendre les captures
```

### 3. Build et Upload (Today/Tomorrow)
```bash
./deploy_app_store.sh
# Suivre les étapes du script
```

### 4. Configuration App Store Connect (Tomorrow)
- Créer l'app
- Uploader captures
- Remplir métadonnées
- Sélectionner build

### 5. Soumission (Tomorrow)
- Vérification finale avec CHECKLIST_APP_STORE.md
- Envoyer pour révision

### 6. Attente (2-5 jours)
- Surveiller emails Apple
- Vérifier statut quotidiennement

### 7. Publication (Après approbation)
- Partager le lien App Store
- Communiquer aux membres

---

## ✨ Points Forts de Cette Documentation

✅ **Complète** - Couvre tout le processus de A à Z  
✅ **Structurée** - Documents organisés par usage  
✅ **Actionnable** - Scripts automatisés + checklists  
✅ **Pédagogique** - Explications détaillées + exemples  
✅ **Pratique** - FAQ, troubleshooting, timeline  
✅ **Professionnelle** - Respect des standards Apple  

---

## 🎉 Vous Êtes Prêt !

Avec cette documentation et ces scripts, vous avez tout ce qu'il faut pour:
- ✅ Builder l'application iOS
- ✅ Préparer tous les assets
- ✅ Configurer App Store Connect
- ✅ Soumettre pour révision
- ✅ Gérer les mises à jour

**Commencez par lire [IMPORTANT_APP_STORE.md](./IMPORTANT_APP_STORE.md) puis lancez-vous ! 🚀**

---

**Bonne chance avec votre publication sur l'App Store ! 🍎✨**

---

*Dernière mise à jour: 29 novembre 2024*  
*Documentation créée pour Jubilé Tabernacle v1.0.0*

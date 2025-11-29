# ✅ Checklist Déploiement App Store - Jubilé Tabernacle

## 🔐 Phase 1: Préparation (Avant le Build)

### Compte et Configuration
- [ ] Compte Apple Developer actif ($99/an payé)
- [ ] Accès à App Store Connect vérifié
- [ ] Xcode installé et à jour
- [ ] Bundle ID créé: `org.jubiletabernacle.app`
- [ ] Certificat de distribution Apple installé
- [ ] Profil de provisioning App Store créé

### Application
- [ ] Version incrémentée dans `pubspec.yaml` (actuel: 1.0.0+1)
- [ ] Toutes les fonctionnalités testées sur device réel
- [ ] Pas de crashs ou bugs majeurs
- [ ] Performance optimale (pas de lag)
- [ ] Toutes les traductions à jour (si multilingue)

### Assets et Médias
- [ ] Icônes app de toutes les tailles présentes (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
- [ ] Icône App Store 1024x1024 px
- [ ] Splash screen configuré
- [ ] Toutes les images optimisées (pas trop lourdes)

### Documents Légaux
- [ ] Politique de confidentialité hébergée et accessible
  URL: https://votre-domaine.com/privacy_policy.html
- [ ] Conditions d'utilisation (si applicable)
- [ ] Mentions légales (si applicable)

---

## 📸 Phase 2: Captures d'Écran

### Captures iPhone (OBLIGATOIRE)
- [ ] **iPhone 6.7"** (1290 x 2796 px) - Minimum 3, recommandé 5-8
  - [ ] Écran d'accueil / Pain quotidien
  - [ ] Module Bible
  - [ ] Vie de l'église
  - [ ] Prières communautaires
  - [ ] Profil utilisateur
  
- [ ] **iPhone 6.5"** (1242 x 2688 px) - Même nombre que 6.7"
- [ ] **iPhone 5.5"** (1242 x 2208 px) - Même nombre que 6.7"

### Captures iPad (OPTIONNEL mais recommandé)
- [ ] **iPad Pro 12.9"** (2048 x 2732 px) - Minimum 2

### Outil
```bash
./prepare_screenshots.sh
```

---

## 🏗️ Phase 3: Build et Archive

### Préparation du Build
- [ ] `flutter clean` exécuté
- [ ] `flutter pub get` exécuté
- [ ] Pods iOS à jour (`cd ios && pod install`)
- [ ] Aucune erreur dans `flutter analyze`
- [ ] Tests passés (si vous avez des tests)

### Build
**Option A: Script automatique (Recommandé)**
```bash
./deploy_app_store.sh
```

**Option B: Manuel**
- [ ] `flutter build ios --release` réussi
- [ ] Archive Xcode créée (Product > Archive)
- [ ] IPA exporté pour App Store

### Validation du Build
- [ ] Taille de l'IPA < 100 MB (idéalement < 50 MB)
- [ ] Archive contient tous les assets nécessaires
- [ ] Pas d'avertissements critiques dans Xcode

---

## ☁️ Phase 4: Upload vers App Store Connect

### Upload
- [ ] Build uploadé via script, Xcode Organizer ou Transporter
- [ ] Email de confirmation d'upload reçu
- [ ] Build visible dans App Store Connect (attendre 10-30 min de traitement)
- [ ] Statut du build: "Prêt à soumettre"
- [ ] Aucune erreur de processing

### Vérification Post-Upload
- [ ] Build number correct affiché
- [ ] Version correcte affichée
- [ ] Aucun avertissement de compliance

---

## 🎨 Phase 5: Configuration App Store Connect

### Informations de l'App (Onglet "Informations sur l'app")

#### Identification
- [ ] Nom: **Jubilé Tabernacle**
- [ ] Sous-titre (30 car): **Votre église connectée**
- [ ] Bundle ID: **org.jubiletabernacle.app**

#### Catégories
- [ ] Catégorie principale: **Style de vie**
- [ ] Catégorie secondaire: **Références**

#### Confidentialité
- [ ] URL politique de confidentialité ajoutée
- [ ] URL testée et accessible
- [ ] Conforme au RGPD

#### Licence et Achats
- [ ] Type: **Gratuite**
- [ ] Pas d'achats in-app (ou configurés si présents)

### Prix et Disponibilité
- [ ] Prix: **Gratuit**
- [ ] Disponibilité: **Tous les pays** (ou sélection personnalisée)
- [ ] Précommande: **Non**

---

## 📝 Phase 6: Préparation de la Version

### Localisation Française

#### Informations Marketing
- [ ] **Nom** (30 caractères): Jubilé Tabernacle
- [ ] **Sous-titre** (30 caractères): Votre église connectée
- [ ] **Texte promotionnel** (170 caractères):
  ```
  Votre église connectée ! Bible, Pain quotidien, Sermons du Message, 
  Prières communautaires et plus encore. 🙏✨
  ```

#### Description (max 4000 caractères)
- [ ] Description complète copiée depuis GUIDE_APP_STORE.md
- [ ] Sans fautes d'orthographe
- [ ] Formatée avec émojis et sections claires
- [ ] Met en avant les fonctionnalités principales

#### Mots-clés (max 100 caractères)
- [ ] Mots-clés optimisés:
  ```
  église,bible,chrétien,prière,sermon,foi,évangile,spirituel,message,branham
  ```

#### URLs
- [ ] **URL d'assistance**: https://www.jubiletabernacle.org/support
- [ ] **URL marketing**: https://www.jubiletabernacle.org (optionnel)

#### Captures d'écran
- [ ] Toutes uploadées pour iPhone 6.7"
- [ ] Toutes uploadées pour iPhone 6.5"
- [ ] Toutes uploadées pour iPhone 5.5"
- [ ] Ordre correct (la plus importante en premier)

### Informations de Build

#### Sélection du Build
- [ ] Build sélectionné dans la liste
- [ ] Version et build number corrects

#### Export Compliance
- [ ] Question: **Votre app utilise-t-elle le chiffrement ?** → **Oui**
- [ ] Question: **Utilise-t-elle le chiffrement exempt ?** → **Oui**
  (HTTPS via Firebase est exempt)

#### Content Rights
- [ ] Coché: **"J'ai les droits pour utiliser tout le contenu de cette app"**

---

## 👶 Phase 7: Classification par Âge

### Questionnaire de Contenu
- [ ] Violence/Horreur: **Aucune**
- [ ] Contenu médical/Traitement: **Aucun**
- [ ] Contenu sexuel/Nudité: **Aucun**
- [ ] Langage grossier/Humour: **Aucun**
- [ ] Alcool/Tabac/Drogues: **Aucun**
- [ ] Jeux d'argent simulés: **Non**
- [ ] Jeux d'argent réels: **Non**
- [ ] Horreur/Peur: **Aucun**
- [ ] Concours/Tirages: **Non**
- [ ] API non restreintes: **Non**
- [ ] Contenu généré par utilisateurs non filtré: **Non**

**Résultat attendu: 4+ (Tous âges)**

---

## 🧪 Phase 8: Informations de Test

### Coordonnées de Révision
- [ ] **Prénom**: [Votre prénom]
- [ ] **Nom**: [Votre nom]
- [ ] **Téléphone**: [Format international: +33...]
- [ ] **Email**: [Email valide que vous consultez]

### Compte de Test (CRUCIAL)
- [ ] Créé un compte de test dans Firebase
  ```
  Email: testuser@example.com
  Mot de passe: TestPassword123!
  ```
- [ ] Compte testé et fonctionnel
- [ ] Toutes les fonctionnalités accessibles avec ce compte

### Notes pour la Révision
- [ ] Notes détaillées ajoutées:
  ```
  Jubilé Tabernacle est l'application officielle de notre assemblée chrétienne.
  
  Points importants:
  - L'app est entièrement gratuite, sans publicité ni achats in-app
  - Authentification via Email/Mot de passe ou Sign in with Apple
  - Firebase est utilisé pour l'authentification et le stockage
  - Les notifications push sont utilisées pour les événements et le pain quotidien
  - Le contenu des sermons provient de branham.org (domaine public)
  
  Pour tester l'app complètement:
  1. Connectez-vous avec le compte test fourni
  2. Naviguez dans tous les modules (Bible, Pain quotidien, Vie de l'église, etc.)
  3. Testez les fonctionnalités de prière communautaire
  4. Vérifiez les paramètres et le mode sombre
  ```

### Pièces jointes (si nécessaire)
- [ ] Aucun fichier supplémentaire nécessaire pour cette app

---

## ✅ Phase 9: Vérification Finale

### Checklist Complète
- [ ] **Toutes** les captures d'écran uploadées et visibles
- [ ] Description **sans fautes**, bien formatée
- [ ] Mots-clés optimisés (100 caractères max)
- [ ] Build sélectionné et visible
- [ ] Classification par âge complétée (devrait afficher 4+)
- [ ] Export Compliance répondu
- [ ] Politique de confidentialité accessible
- [ ] URLs d'assistance testées
- [ ] Compte de test fourni et fonctionnel
- [ ] Notes de révision claires et détaillées

### Vérification Technique
- [ ] Aucun message d'erreur dans App Store Connect
- [ ] Aucun avertissement bloquant
- [ ] Status: "Prêt à soumettre" visible

### Relecture
- [ ] Relire TOUTE la fiche App Store
- [ ] Vérifier l'orthographe de la description
- [ ] Vérifier que les captures montrent bien l'app
- [ ] S'assurer que le compte de test fonctionne

---

## 🚀 Phase 10: Soumission

### Avant de Soumettre
- [ ] Dernière relecture complète
- [ ] Tous les points de cette checklist cochés
- [ ] Confiant que l'app respecte les Guidelines Apple

### Soumission
- [ ] Clic sur **"Ajouter pour révision"** (coin supérieur droit)
- [ ] Vérification finale des informations
- [ ] Clic sur **"Envoyer pour révision"**
- [ ] Confirmation de soumission
- [ ] Email de confirmation reçu

### Après Soumission
- [ ] Status changé à "En attente de révision"
- [ ] Notification email reçue
- [ ] Délai estimé noté (généralement 1-3 jours)

---

## 📊 Phase 11: Suivi de la Révision

### Surveillance
- [ ] Vérifier quotidiennement le statut dans App Store Connect
- [ ] Consulter les emails (Apple peut demander des clarifications)
- [ ] Notifications activées sur l'app App Store Connect (mobile)

### Statuts Possibles
- 🟡 **En attente de révision**: Normal, dans la file d'attente
- 🔵 **En révision**: Apple teste actuellement l'app (1-2 jours)
- 🟢 **Prêt pour la vente**: ✅ **APPROUVÉ !** L'app va être publiée
- 🔴 **Rejeté**: Lire le message, corriger, resoumettre

### Si Rejeté
- [ ] Lire attentivement le message de rejet
- [ ] Identifier la Guideline violée
- [ ] Corriger le problème (code ou métadonnées)
- [ ] Si correction de métadonnées uniquement: resoumettre sans nouveau build
- [ ] Si correction de code: nouveau build nécessaire
- [ ] Répondre poliment dans le Resolution Center si clarification nécessaire

---

## 🎉 Phase 12: Après Approbation

### Publication
- [ ] Status: **"Prêt pour la vente"**
- [ ] App visible sur l'App Store (peut prendre 24h)
- [ ] Tester le lien App Store
- [ ] Rechercher l'app par nom sur l'App Store

### Post-Publication
- [ ] Partager le lien App Store:
  ```
  https://apps.apple.com/app/jubile-tabernacle/idXXXXXXXXX
  ```
- [ ] Surveiller les premiers avis/notes
- [ ] Surveiller Firebase Crashlytics (crashs)
- [ ] Vérifier Analytics (téléchargements)

### Communication
- [ ] Annoncer sur les réseaux sociaux
- [ ] Envoyer email aux membres de l'église
- [ ] Ajouter lien sur site web
- [ ] Créer badge App Store pour communications

---

## 🔄 Futures Mises à Jour

### Process de Mise à Jour
1. [ ] Développer les nouvelles fonctionnalités
2. [ ] Incrémenter la version dans `pubspec.yaml`
   ```yaml
   # Exemple: 1.0.0+1 → 1.0.1+2 (correctif)
   #          1.0.0+1 → 1.1.0+2 (nouvelle fonctionnalité)
   ```
3. [ ] Tester complètement
4. [ ] Nouveau build et upload (`./deploy_app_store.sh`)
5. [ ] Dans App Store Connect:
   - [ ] Créer nouvelle version
   - [ ] Ajouter notes de version ("Quoi de neuf")
   - [ ] Nouvelles captures si UI changée
   - [ ] Sélectionner le nouveau build
   - [ ] Soumettre pour révision

---

## 📞 Support et Ressources

### Scripts Disponibles
```bash
# Build et upload complet
./deploy_app_store.sh

# Préparer les captures d'écran
./prepare_screenshots.sh

# Validation (existe déjà)
./validate_app_store_final.sh
```

### Liens Utiles
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Guide complet](./GUIDE_APP_STORE.md)

### Support
- **Email**: contact@jubiletabernacle.org
- **Cette checklist**: `CHECKLIST_APP_STORE.md`
- **Guide détaillé**: `GUIDE_APP_STORE.md`

---

## 🎯 Rappels Importants

⚠️ **CRUCIAL pour l'approbation:**
1. Compte de test fonctionnel
2. Notes de révision détaillées
3. Captures d'écran de qualité
4. Politique de confidentialité accessible
5. Pas de contenu restreint ou liens non autorisés

⏱️ **Délais moyens:**
- Processing du build: 10-30 minutes
- Révision Apple: 1-3 jours (peut aller jusqu'à 7 jours)
- Publication après approbation: Immédiate (ou manuelle)

💰 **Coût:**
- Apple Developer: $99/an
- Autres: Aucun coût supplémentaire pour cette app

---

**Dernière mise à jour**: 29 novembre 2024
**Version de l'app**: 1.0.0+1
**Status**: Prêt pour soumission ✅

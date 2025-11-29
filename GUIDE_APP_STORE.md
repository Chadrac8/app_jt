# 🍎 Guide de Déploiement App Store - Jubilé Tabernacle

## 📋 Table des Matières
1. [Prérequis](#prérequis)
2. [Configuration Apple Developer](#configuration-apple-developer)
3. [Création de l'App dans App Store Connect](#création-de-lapp)
4. [Build et Upload](#build-et-upload)
5. [Configuration dans App Store Connect](#configuration-app-store-connect)
6. [Soumission pour Review](#soumission)
7. [Après Approbation](#après-approbation)

---

## 🔐 Prérequis

### Compte Apple Developer
- ✅ Compte Apple Developer actif ($99/an)
- ✅ Accès à [App Store Connect](https://appstoreconnect.apple.com)
- ✅ Xcode installé (version récente)
- ✅ Certificats et profils de provisioning configurés

### Documents et Assets
- ✅ Icônes d'application (toutes les tailles)
- ✅ Captures d'écran pour toutes les tailles d'iPhone/iPad
- ✅ Politique de confidentialité hébergée (URL)
- ✅ Description de l'application
- ✅ Mots-clés App Store (max 100 caractères)

---

## 🏗️ Configuration Apple Developer

### 1. Créer un Bundle Identifier

1. Aller sur [Apple Developer](https://developer.apple.com)
2. **Certificates, Identifiers & Profiles** > **Identifiers**
3. Cliquer sur **+** pour créer un nouvel identifier
4. Sélectionner **App IDs** > **Continue**
5. Sélectionner **App** > **Continue**
6. Remplir:
   - **Description**: Jubilé Tabernacle
   - **Bundle ID**: `org.jubiletabernacle.app` (explicite)
   - **Capabilities**: Cocher
     - ✅ Push Notifications
     - ✅ Sign in with Apple
     - ✅ Background Modes
7. **Continue** > **Register**

### 2. Configurer les Capabilities

- **Push Notifications**: Déjà configuré avec Firebase
- **Sign in with Apple**: Pour l'authentification
- **Background Modes**: Pour les notifications

### 3. Certificats et Profils

#### Certificat de Distribution
1. **Certificates** > **+**
2. **Apple Distribution** > **Continue**
3. Suivre les instructions pour créer un CSR
4. Télécharger et installer le certificat

#### Profil de Provisioning
1. **Profiles** > **+**
2. **App Store** > **Continue**
3. Sélectionner **org.jubiletabernacle.app**
4. Sélectionner votre certificat de distribution
5. Nommer: "Jubile Tabernacle App Store"
6. **Generate** > **Download** > **Install**

---

## 📱 Création de l'App dans App Store Connect

### 1. Créer une Nouvelle App

1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. **Mes Apps** > **+** > **Nouvelle app**
3. Remplir les informations:

   **Informations générales:**
   - **Plateformes**: iOS
   - **Nom**: Jubilé Tabernacle
   - **Langue principale**: Français (France)
   - **Bundle ID**: org.jubiletabernacle.app
   - **SKU**: JUBILETABERNACLE001
   - **Accès utilisateur**: Accès complet

4. **Créer**

### 2. Informations de l'App

#### Onglet "Informations sur l'app"

**Localisation (Français):**
- **Nom**: Jubilé Tabernacle
- **Sous-titre** (max 30 caractères):
  ```
  Votre église connectée
  ```

**Catégories:**
- **Catégorie principale**: Style de vie
- **Catégorie secondaire**: Références

**Confidentialité:**
- **URL de la politique de confidentialité**:
  ```
  https://votre-domaine.com/privacy_policy.html
  ```

#### Onglet "Prix et disponibilité"

- **Prix**: Gratuit
- **Disponibilité**: Tous les pays
- **App précommande**: Non

---

## 🚀 Build et Upload

### Option 1: Script Automatique (Recommandé)

```bash
# Rendre le script exécutable
chmod +x deploy_app_store.sh

# Lancer le script
./deploy_app_store.sh
```

Le script va:
1. ✅ Vérifier la configuration
2. ✅ Nettoyer les builds précédents
3. ✅ Installer les dépendances
4. ✅ Builder l'application
5. ✅ Créer l'archive Xcode
6. ✅ Exporter l'IPA
7. ✅ Proposer l'upload vers App Store Connect

### Option 2: Build Manuel avec Flutter

```bash
# 1. Nettoyer
flutter clean
flutter pub get

# 2. Build iOS
flutter build ios --release

# 3. Ouvrir dans Xcode
open ios/Runner.xcworkspace

# Dans Xcode:
# - Product > Archive
# - Window > Organizer
# - Sélectionner l'archive > Distribute App
# - App Store Connect > Upload
```

### Option 3: Transporter App

1. Télécharger [Transporter](https://apps.apple.com/app/transporter/id1450874784)
2. Utiliser le fichier IPA généré: `build/ios/ipa/Runner.ipa`
3. Glisser-déposer dans Transporter
4. Cliquer sur **Deliver**

---

## ⚙️ Configuration dans App Store Connect

### 1. Préparer la Soumission

Une fois le build uploadé et traité (~10-30 minutes):

1. **App Store Connect** > **Mes Apps** > **Jubilé Tabernacle**
2. Aller dans **App Store** (onglet de gauche)
3. Cliquer sur **+ Version** ou sélectionner la version 1.0.0

### 2. Informations de Version

#### Captures d'écran (OBLIGATOIRE)

**iPhone 6.7" (Pro Max) - 1290 x 2796 px**
Minimum 3 captures, recommandé 5-8:
- Écran d'accueil avec Pain quotidien
- Module Bible avec versets
- Vie de l'église (sermons, événements)
- Liste des prières communautaires
- Page de profil utilisateur

**iPhone 6.5" (Plus) - 1242 x 2688 px**
Mêmes captures redimensionnées

**iPhone 5.5" - 1242 x 2208 px**
Mêmes captures redimensionnées

**iPad Pro 12.9" - 2048 x 2732 px**
Facultatif mais recommandé

> 💡 **Astuce**: Utilisez un simulateur iOS pour prendre les captures:
> ```bash
> # Lancer le simulateur
> open -a Simulator
> 
> # Choisir le device (iPhone 15 Pro Max)
> # Lancer l'app: flutter run
> 
> # Prendre des captures: Cmd + S
> # Les fichiers sont dans ~/Desktop
> ```

#### Description de l'App (max 4000 caractères)

```
Bienvenue dans l'application officielle de l'assemblée chrétienne Jubilé Tabernacle de France !

🙏 REJOIGNEZ VOTRE COMMUNAUTÉ SPIRITUELLE

Jubilé Tabernacle est votre compagnon quotidien pour vivre et partager votre foi. Restez connecté avec votre église, accédez aux enseignements du Message et grandissez spirituellement.

📖 FONCTIONNALITÉS PRINCIPALES

• Pain Quotidien
Recevez chaque jour une parole inspirante et un verset biblique pour nourrir votre foi et commencer votre journée dans la présence de Dieu.

• Bible Complète
Accédez à plusieurs versions de la Bible en français (Louis Segond, BFC, TOB, PDV, NBS, Martin, Ostervald) avec recherche, favoris et notes personnelles.

• Sermons et Enseignements
Écoutez et regardez les prédications du Message, avec transcriptions, schémas bibliques et références scripturaires.

• Vie de l'Église
Restez informé des événements, activités et célébrations de votre assemblée. Inscrivez-vous facilement aux événements.

• Prières Communautaires
Partagez vos sujets de prière, soutenez les frères et sœurs dans l'intercession et recevez le soutien de votre communauté.

• Offrandes et Dîmes
Soutenez l'œuvre de Dieu facilement et en toute sécurité via carte bancaire, virement ou chèque.

• Gestion de Profil
Personnalisez votre expérience et gérez vos informations en toute sécurité.

✨ POURQUOI JUBILÉ TABERNACLE ?

✓ Interface intuitive et agréable
✓ Mode sombre pour lire confortablement
✓ Synchronisation cloud de vos données
✓ Notifications pour ne rien manquer
✓ Partage facile de versets et citations
✓ Totalement gratuit, sans publicité

🔐 CONFIDENTIALITÉ ET SÉCURITÉ

Vos données personnelles sont protégées et sécurisées. Nous respectons votre vie privée conformément au RGPD.

💬 CONTACT ET SUPPORT

Une question ? Un besoin d'aide ?
Email: contact@jubiletabernacle.org
Site web: www.jubiletabernacle.org

Téléchargez maintenant et vivez votre foi au quotidien avec Jubilé Tabernacle ! 🙏✨
```

#### Mots-clés (max 100 caractères, séparés par des virgules)

```
église,bible,chrétien,prière,sermon,foi,évangile,spirituel,message,branham
```

#### Texte promotionnel (max 170 caractères)

```
Votre église connectée ! Bible, Pain quotidien, Sermons du Message, Prières communautaires et plus encore. 🙏✨
```

#### URL d'assistance

```
https://www.jubiletabernacle.org/support
```

#### URL marketing (optionnel)

```
https://www.jubiletabernacle.org
```

### 3. Informations de Build

**Sélectionner le build:**
1. Dans **Build**, cliquer sur **Sélectionner un build**
2. Choisir le build uploadé (1.0.0+1)
3. **Terminé**

**Export Compliance:**
- Votre app utilise-t-elle le chiffrement ? **Oui**
- Votre app utilise-t-elle le chiffrement exempt ? **Oui**
  (Firebase utilise HTTPS, ce qui est exempt)

**Content Rights:**
- ✅ Cocher "J'ai les droits pour utiliser tout le contenu"

### 4. Classification par Âge

**Répondre au questionnaire:**
- Violence/Horreur: Aucune
- Contenu médical: Aucun
- Contenu sexuel: Aucun
- Langage grossier: Aucun
- Alcool/Tabac/Drogues: Aucun
- Jeux d'argent: Aucun
- Contenu effrayant: Aucun

**Résultat attendu:** 4+ (Tous âges)

### 5. Informations de Révision

**Coordonnées:**
- Nom: [Votre nom]
- Téléphone: [Votre téléphone]
- Email: [Votre email]

**Informations de connexion (pour les reviewers):**
```
Email de test: testuser@example.com
Mot de passe: TestPassword123!

Notes: Cette application nécessite un compte. 
Utilisez les identifiants fournis pour tester toutes les fonctionnalités.
```

**Notes pour la révision:**
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

---

## 📤 Soumission pour Review

### Checklist Finale

Avant de soumettre, vérifier:

- ✅ Toutes les captures d'écran uploadées
- ✅ Description complète et sans fautes
- ✅ Mots-clés optimisés
- ✅ Build sélectionné
- ✅ Classification par âge complétée
- ✅ Politique de confidentialité accessible
- ✅ Compte de test fourni
- ✅ Notes de révision claires

### Soumettre

1. Cliquer sur **Ajouter pour révision** (en haut à droite)
2. Vérifier que tout est correct
3. Cliquer sur **Envoyer pour révision**
4. **Confirmer la soumission**

### Délais de Review

- **Délai moyen**: 1-3 jours
- **Maximum**: 7 jours
- **Statut consultable**: App Store Connect > Mes Apps

### Statuts Possibles

- 🟡 **En attente de révision**: File d'attente
- 🔵 **En révision**: Apple teste l'app
- 🟢 **Prêt pour la vente**: Approuvé ! 🎉
- 🔴 **Rejeté**: Modifications nécessaires

---

## ✅ Après Approbation

### Publication Automatique ou Manuelle

**Automatique (recommandé):**
- L'app est publiée dès approbation

**Manuelle:**
- Dans **Prix et disponibilité**
- Sélectionner "Publier manuellement"
- Après approbation, cliquer sur **Publier cette version**

### Surveillance

**Premières 48h:**
- Surveiller les avis utilisateurs
- Vérifier l'absence de crashs (Firebase Crashlytics)
- Monitorer les téléchargements

**Outils:**
- **App Store Connect** > **Analytics**
- **Firebase Console** > **Crashlytics**
- **Alertes email**: Configurées dans App Store Connect

---

## 🔄 Mises à Jour Futures

### Incrémenter la Version

Dans `pubspec.yaml`:
```yaml
# Version actuelle
version: 1.0.0+1

# Nouvelle version mineure (correctifs)
version: 1.0.1+2

# Nouvelle version majeure (fonctionnalités)
version: 1.1.0+3
```

### Process de Mise à Jour

1. Modifier le code
2. Incrémenter la version dans `pubspec.yaml`
3. Tester l'application
4. Lancer `./deploy_app_store.sh`
5. Dans App Store Connect:
   - Créer une **nouvelle version**
   - Ajouter les **notes de version** ("Quoi de neuf")
   - Sélectionner le nouveau build
   - **Envoyer pour révision**

### Notes de Version Exemple

```
Cette mise à jour apporte plusieurs améliorations :

✨ Nouveautés
• Nouveau design Material Design 3
• Amélioration du module Offrandes
• Mode sombre optimisé

🐛 Corrections
• Correction du partage dans Pain quotidien
• Amélioration des performances
• Correction de bugs mineurs

💡 Améliorations
• Interface plus fluide et intuitive
• Meilleure synchronisation
• Optimisation de la consommation batterie
```

---

## 🆘 Résolution de Problèmes

### Problèmes Courants

#### ❌ "Missing Compliance"
**Solution:** Répondre au questionnaire Export Compliance

#### ❌ "Missing Screenshots"
**Solution:** Uploader les captures pour iPhone 6.7" et 6.5"

#### ❌ "Invalid Binary"
**Solution:**
- Vérifier le Bundle ID
- Vérifier les certificats
- Rebuild avec Xcode

#### ❌ "Metadata Rejected"
**Solution:**
- Lire attentivement le message de rejet
- Modifier les informations concernées
- Resoumettre (pas besoin de nouveau build)

#### ❌ "App Rejected - Guideline X.X"
**Solution:** Lire les App Store Guidelines et corriger

### Contact Apple

**App Review:**
- App Store Connect > Résolution Center
- Expliquer la situation en anglais

**Support Technique:**
- [Apple Developer Support](https://developer.apple.com/contact/)
- Forums: [Apple Developer Forums](https://developer.apple.com/forums/)

---

## 📊 Checklist Complète

### Avant le Build
- [ ] Version incrémentée dans `pubspec.yaml`
- [ ] Toutes les fonctionnalités testées
- [ ] Icônes de toutes les tailles présentes
- [ ] Firebase configuré correctement
- [ ] Politique de confidentialité hébergée

### Configuration Apple
- [ ] Compte Apple Developer actif
- [ ] Bundle ID créé
- [ ] Certificats installés
- [ ] Profils de provisioning configurés
- [ ] App créée dans App Store Connect

### Assets et Métadonnées
- [ ] Captures d'écran (6.7", 6.5", 5.5")
- [ ] Description complète
- [ ] Mots-clés optimisés
- [ ] URLs (privacy, support, marketing)
- [ ] Icône App Store (1024x1024)

### Build et Upload
- [ ] Build réussi sans erreurs
- [ ] Archive créée
- [ ] IPA exporté
- [ ] Upload vers App Store Connect
- [ ] Build traité (visible dans App Store Connect)

### Configuration App Store Connect
- [ ] Build sélectionné
- [ ] Captures d'écran uploadées
- [ ] Description et métadonnées remplies
- [ ] Classification par âge complétée
- [ ] Export Compliance répondu
- [ ] Compte de test fourni
- [ ] Notes de révision ajoutées

### Soumission
- [ ] Révision finale de toutes les infos
- [ ] Soumis pour révision
- [ ] Email de confirmation reçu

---

## 🎯 Conseils pour une Approbation Rapide

1. **Compte de test fonctionnel**: Crucial pour les reviewers
2. **Notes de révision détaillées**: Expliquez tout ce qui pourrait être ambigu
3. **Captures d'écran de qualité**: Montrez les fonctionnalités principales
4. **Description claire**: Sans fautes, bien structurée
5. **Respect des guidelines**: Lisez les [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
6. **Politique de confidentialité**: Conforme au RGPD et accessible
7. **Pas de contenu restreint**: Pas de liens externes non autorisés
8. **Performance**: App fluide, pas de crashs

---

## 📚 Ressources Utiles

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Marketing Guidelines](https://developer.apple.com/app-store/marketing/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

## 💬 Support

Pour toute question sur le déploiement:
- Email: contact@jubiletabernacle.org
- Documentation: Ce fichier
- Script de déploiement: `deploy_app_store.sh`

---

**Bonne chance avec votre soumission App Store ! 🎉🍎**

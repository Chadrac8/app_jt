# Module Pain Quotidien 🍞

## Description
Module complet pour afficher le pain quotidien (verset biblique + citation) récupéré depuis branham.org avec système de cache et sauvegarde Firestore.

## Fonctionnalités

### ✨ Principales
- **Scraping automatique** du pain quotidien depuis branham.org
- **Cache local** avec SharedPreferences pour accès hors ligne
- **Sauvegarde Firestore** pour synchronisation entre appareils
- **Interface élégante** avec preview sur la page d'accueil
- **Page dédiée** avec contenu complet
- **Partage** du contenu quotidien
- **Mise à jour forcée** avec pull-to-refresh

### 📱 Composants
- `DailyBreadPreviewWidget` : Widget de prévisualisation pour la page d'accueil
- `DailyBreadPage` : Page complète avec verset et citation du jour
- `DailyBreadService` : Service de récupération et gestion des données
- `DailyBreadModel` : Modèle de données avec conversions JSON/Firestore

## Installation

### 1. Dépendances requises
Ajouter dans `pubspec.yaml` :
```yaml
dependencies:
  http: ^1.1.0
  html: ^0.15.4  # Pour le parsing HTML
  shared_preferences: ^2.2.2
  share_plus: ^7.2.1
  cloud_firestore: ^4.13.6
```

### 2. Configuration Firestore
Le module crée automatiquement la collection `daily_bread` dans Firestore.

### 3. Intégration dans l'app

#### A. Sur la page d'accueil
```dart
import 'package:jubile_tabernacle/modules/pain_quotidien/pain_quotidien.dart';

// Dans la page d'accueil
const DailyBreadPreviewWidget(),
```

#### B. Navigation directe
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DailyBreadPage()),
);
```

## Structure des données

### DailyBreadModel
```dart
class DailyBreadModel {
  final String id;              // Date YYYY-MM-DD
  final String text;            // Citation de W.M. Branham
  final String reference;       // Référence de la citation
  final String date;            // Date de la citation
  final String dailyBread;      // Verset biblique du jour
  final String dailyBreadReference; // Référence du verset
  final String sermonTitle;     // Titre de la prédication
  final String sermonDate;      // Date de la prédication
  final String audioUrl;        // URL audio (si disponible)
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

## Fonctionnement

### 1. Récupération des données
1. **Cache local** : Vérification du cache SharedPreferences
2. **Firestore** : Si pas en cache, récupération depuis Firestore
3. **Scraping** : Si pas en Firestore, scraping de branham.org
4. **Fallback** : Contenu par défaut si échec

### 2. Mise en cache
- **Local** : SharedPreferences pour accès rapide hors ligne
- **Cloud** : Firestore pour synchronisation entre appareils
- **Durée** : Cache valide jusqu'à minuit (nouveau contenu quotidien)

### 3. Interface utilisateur
- **Preview** : Aperçu élégant sur la page d'accueil (2 lignes max)
- **Page complète** : Affichage détaillé avec verset et citation
- **Partage** : Bouton de partage avec texte formaté
- **Refresh** : Mise à jour forcée disponible

## Personnalisation

### Thème
Le module utilise `AppTheme` pour la cohérence visuelle :
- `primaryColor` : Couleur principale
- `surfaceColor` : Couleur de fond des cartes
- `textPrimaryColor` / `textSecondaryColor` : Couleurs de texte

### Contenu par défaut
En cas d'échec du scraping, le module affiche :
- Citation : "La foi est quelque chose que vous avez..."
- Verset : Jean 3:16
- Rotation quotidienne basée sur le jour de l'année

## API du service

### DailyBreadService
```dart
// Récupérer le pain quotidien du jour
final bread = await DailyBreadService.instance.getTodayDailyBread();

// Forcer la mise à jour
final newBread = await DailyBreadService.instance.forceUpdate();

// Historique (Stream)
DailyBreadService.instance.getDailyBreadHistory(limit: 30);

// Recherche
final results = await DailyBreadService.instance.searchDailyBread('foi');
```

## État actuel

### ✅ Implémenté
- [x] Modèle de données complet
- [x] Service avec cache et Firestore
- [x] Widget de prévisualisation
- [x] Page complète
- [x] Système de partage
- [x] Contenu par défaut rotatif

### 🚧 En cours / TODO
- [ ] Parsing HTML complet (actuellement version simplifiée)
- [ ] Page d'historique
- [ ] Notifications push quotidiennes
- [ ] Mode hors ligne avancé
- [ ] Analytics d'utilisation

## Notes techniques

### Scraping branham.org
- URL : `https://branham.org/fr/quoteoftheday`
- Headers User-Agent mobiles pour éviter le blocage
- Timeout de 15 secondes
- Parsing HTML pour extraire :
  - Citation principale
  - Verset biblique "Pain quotidien"
  - Titre et date de prédication
  - URL audio (si disponible)

### Performance
- Cache local pour accès instantané
- Requêtes réseau asynchrones
- Fallback sur contenu local en cas d'erreur
- Mise à jour en arrière-plan

## Support

Le module est conçu pour être robuste :
- Gestion d'erreurs complète
- Fallbacks à tous les niveaux
- Logs détaillés pour débogage
- Interface utilisateur informative

---

**Auteur** : Assistant IA  
**Version** : 1.0.0  
**Dernière mise à jour** : 21 août 2025

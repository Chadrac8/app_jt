# 📖 Plans de Lecture - Module Bible

## 🎯 Vue d'ensemble

La fonctionnalité "Plans de lecture" du module Bible permet aux utilisateurs de suivre des plans structurés pour lire la Bible de manière organisée et progressive. Cette fonctionnalité encourage la lecture quotidienne et aide les utilisateurs à développer une habitude de lecture biblique.

## ✨ Fonctionnalités principales

### 🏠 Interface d'accueil
- **Widget dynamique** sur l'onglet Accueil du module Bible
- **Affichage conditionnel** : plan actif ou invitation à découvrir
- **Progression visuelle** avec barre de progression animée
- **Statut quotidien** : lecture terminée ou à faire

### 📋 Catalogue des plans
- **Plans prédéfinis** : Bible en 1 an, Nouveau Testament, Psaumes, etc.
- **Catégories** : Classique, Nouveau Testament, Psaumes, Évangiles, Sagesse
- **Filtrage** par catégorie et recherche textuelle
- **Niveaux de difficulté** : Débutant, Intermédiaire, Avancé
- **Plans populaires** mis en avant

### 📚 Plans disponibles par défaut
1. **Bible en 1 an** (365 jours) - Classique - Débutant
2. **Nouveau Testament en 90 jours** - Nouveau Testament - Intermédiaire
3. **Psaumes en 30 jours** - Psaumes - Débutant
4. **Les 4 Évangiles en 28 jours** - Évangiles - Débutant
5. **Proverbes en 31 jours** - Sagesse - Débutant

### 📖 Lecture quotidienne
- **Interface de lecture** avec navigation entre les passages
- **Intégration** avec le module Bible existant
- **Réflexions et prières** pour chaque jour
- **Prise de notes personnelles** par jour

### 📊 Suivi du progrès
- **Progression globale** avec pourcentage
- **Historique des lectures** terminées
- **Séries de lecture** (streak)
- **Statistiques détaillées** (jours terminés, restants, série actuelle)

## 🏗️ Architecture technique

### 📁 Structure des fichiers
```
lib/modules/bible/
├── models/
│   └── reading_plan.dart           # Modèles de données
├── services/
│   └── reading_plan_service.dart   # Service de gestion des plans
├── views/
│   ├── reading_plans_home_page.dart    # Page principale des plans
│   ├── reading_plan_detail_view.dart   # Détail d'un plan
│   ├── active_reading_plan_view.dart   # Vue du plan actif
│   └── daily_reading_view.dart         # Lecture quotidienne
├── widgets/
│   └── reading_plan_home_widget.dart   # Widget pour l'accueil
└── bible_page.dart                 # Page principale (modifiée)

assets/bible/
└── reading_plans.json             # Plans de lecture par défaut
```

### 🔄 Modèles de données

#### `ReadingPlan`
- **Métadonnées** : ID, nom, description, catégorie
- **Configuration** : durée, temps de lecture estimé, difficulté
- **Contenu** : liste des jours avec lectures et réflexions

#### `ReadingPlanDay`
- **Jour** : numéro et titre
- **Lectures** : références bibliques
- **Contenu** : réflexion et prière optionnelles

#### `UserReadingProgress`
- **Progression** : jour actuel, jours terminés
- **Métadonnées** : date de début, dernière lecture
- **Notes** : réflexions personnelles par jour

### 💾 Persistance des données
- **SharedPreferences** pour stocker le progrès utilisateur
- **JSON local** pour les plans prédéfinis
- **Cache en mémoire** pour optimiser les performances

## 🎨 Interface utilisateur

### 🏠 Widget d'accueil
- **États adaptatifs** :
  - Chargement avec shimmer
  - Invitation à découvrir (aucun plan actif)
  - Affichage du plan actif avec progression
- **Design moderne** avec cartes arrondies et gradients
- **Indicateurs visuels** pour le statut quotidien

### 📱 Navigation
- **Onglets** : Actuel, Découvrir, Populaires
- **Transitions fluides** entre les vues
- **Boutons d'action** contextuels

### 📖 Expérience de lecture
- **Interface dédiée** pour chaque jour
- **Navigation** entre les différents passages
- **Sections** pour réflexion, prière et notes
- **Feedback visuel** lors de la completion

## 🔧 Installation et configuration

### 1. Ajout des assets
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/bible/reading_plans.json
```

### 2. Importation des dépendances
Les dépendances nécessaires sont déjà incluses dans le projet :
- `shared_preferences` : persistance des données
- `google_fonts` : typographie
- `flutter/material.dart` : composants UI

### 3. Utilisation
```dart
// Dans n'importe quelle page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ReadingPlansHomePage(),
  ),
);
```

## 📊 Fonctionnalités avancées

### 🔄 Synchronisation
- **Sauvegarde automatique** du progrès
- **Récupération** en cas de fermeture d'app
- **Cache intelligent** pour les performances

### 📈 Statistiques
- **Calcul de séries** de lecture consécutives
- **Pourcentage de progression** en temps réel
- **Historique détaillé** des lectures

### 🎯 Personnalisation
- **Notes personnelles** pour chaque jour
- **Flexibilité** dans l'ordre de lecture
- **Reprise** possible après interruption

## 🚀 Extensions possibles

### 📡 Fonctionnalités futures
1. **Plans personnalisés** créés par l'utilisateur
2. **Partage** de plans entre utilisateurs
3. **Notifications** de rappel quotidien
4. **Synchronisation cloud** entre appareils
5. **Communauté** avec commentaires partagés
6. **Audio** intégré pour l'écoute
7. **Métriques avancées** et badges

### 🔌 Intégrations
1. **Calendrier** pour planifier les lectures
2. **Notifications push** pour les rappels
3. **Partage social** des progrès
4. **Export PDF** des notes personnelles

## 📖 Guide d'utilisation

### Pour les utilisateurs

#### 🚀 Commencer un plan
1. Ouvrir le module Bible
2. Cliquer sur "Plans de lecture" dans l'onglet Accueil
3. Parcourir les plans disponibles
4. Sélectionner un plan et cliquer "Commencer"

#### 📚 Lecture quotidienne
1. Revenir à l'onglet Accueil pour voir le plan actif
2. Cliquer sur "Commencer la lecture" du jour
3. Lire les passages proposés
4. Ajouter des notes personnelles si souhaité
5. Cliquer "Terminer la lecture" pour marquer comme fait

#### 📊 Suivre ses progrès
1. Voir la barre de progression sur l'accueil
2. Consulter l'historique dans l'onglet "Actuel"
3. Vérifier les statistiques (jours terminés, série, etc.)

### Pour les développeurs

#### 🔧 Ajouter de nouveaux plans
1. Modifier `assets/bible/reading_plans.json`
2. Suivre la structure JSON existante
3. Tester avec `flutter run`

#### 🎨 Personnaliser l'interface
1. Modifier les widgets dans `lib/modules/bible/widgets/`
2. Adapter les couleurs et styles selon le thème
3. Ajouter des animations si nécessaire

## 🐛 Dépannage

### Problèmes courants
1. **Plans non chargés** : Vérifier que `reading_plans.json` est dans les assets
2. **Progrès perdu** : SharedPreferences peut être effacé lors de désinstallation
3. **Performance lente** : Le cache se reconstruit au premier lancement

### Debug
```dart
// Activer les logs du service
ReadingPlanService.clearCache(); // Forcer le rechargement
```

## 📝 Changelog

### Version 1.0.0 (Initial)
- ✅ Implémentation complète des plans de lecture
- ✅ Interface utilisateur moderne et intuitive
- ✅ 5 plans prédéfinis disponibles
- ✅ Suivi de progression avec persistance
- ✅ Intégration parfaite avec le module Bible existant
- ✅ Support des notes personnelles
- ✅ Statistiques détaillées de progression

## 🤝 Contribution

### Standards de code
- Utiliser `dart format` pour le formatage
- Suivre les conventions de nommage Flutter
- Documenter les fonctions publiques
- Tester sur iOS et Android

### Ajout de fonctionnalités
1. Créer une branche feature
2. Implémenter les changements
3. Ajouter des tests si nécessaire
4. Créer une pull request

---

**✨ La fonctionnalité "Plans de lecture" est maintenant complètement implémentée et prête à être utilisée !**

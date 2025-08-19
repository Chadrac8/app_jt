# 🎨 Guide de la Nouvelle Palette de Couleurs

## Vue d'ensemble

L'application utilise maintenant une palette élégante basée sur le rouge bordeaux (#850606) avec des accents or et crème, créant une ambiance spirituelle et raffinée parfaite pour une application d'église.

## 🎯 Palette Principale

| Couleur | Code Hex | Usage Principal |
|---------|----------|----------------|
| **Rouge Bordeaux** | `#850606` | Couleur primaire, éléments importants |
| **Or** | `#D4AF37` | Couleur secondaire, accents, boutons spéciaux |
| **Crème** | `#F5E6D3` | Surfaces, cartes |
| **Brun Doré** | `#8B4513` | Couleur tertiaire, texte secondaire |
| **Blanc Antique** | `#FFF8DC` | Arrière-plan principal |
| **Brun Très Foncé** | `#2F1B14` | Texte principal, éléments sombres |

## 🔧 Utilisation dans le Code

### 1. Via AppTheme (Recommandé)
```dart
// Couleurs principales
AppTheme.primaryColor      // Rouge bordeaux
AppTheme.secondaryColor    // Or
AppTheme.tertiaryColor     // Brun doré
AppTheme.backgroundColor   // Blanc antique
AppTheme.surfaceColor      // Crème

// Couleurs de texte
AppTheme.textPrimaryColor   // Brun très foncé
AppTheme.textSecondaryColor // Brun doré
AppTheme.textTertiaryColor  // Rouge bordeaux
```

### 2. Via AppColors (Détaillé)
```dart
// Couleurs principales
AppColors.primary          // Rouge bordeaux
AppColors.secondary        // Or
AppColors.tertiary         // Brun doré

// Couleurs neutres
AppColors.background       // Blanc antique
AppColors.surface          // Crème
AppColors.textPrimary      // Brun très foncé

// Couleurs fonctionnelles
AppColors.success          // Vert
AppColors.error            // Rouge d'erreur
AppColors.warning          // Or (même que secondary)
```

### 3. Via Theme.of(context)
```dart
// Dans vos widgets, utilisez le thème
final theme = Theme.of(context);
Color primaryColor = theme.colorScheme.primary;
Color surfaceColor = theme.colorScheme.surface;
```

## 🎨 Applications Spécifiques

### Interface Utilisateur
- **AppBar** : Transparente avec texte brun foncé
- **Boutons principaux** : Fond rouge bordeaux, texte blanc antique
- **Boutons secondaires** : Bordure or, texte rouge bordeaux
- **FloatingActionButton** : Fond or, texte brun foncé
- **Cards** : Fond crème avec ombre brun foncé

### Navigation
- **BottomNavigationBar** : Fond crème, éléments sélectionnés en rouge bordeaux
- **Items non sélectionnés** : Brun doré
- **Indicateurs** : Rouge bordeaux

### Formulaires
- **Champs de saisie** : Fond blanc antique, bordures brun doré
- **Focus** : Bordure rouge bordeaux
- **Labels** : Texte brun doré

### États et Statuts
```dart
// Rôles utilisateur
AppColors.getRoleColor('member')    // Brun doré
AppColors.getRoleColor('leader')    // Or
AppColors.getRoleColor('pastor')    // Rouge bordeaux

// Types de groupes
AppColors.getGroupTypeColor('prière')     // Rouge bordeaux
AppColors.getGroupTypeColor('jeunesse')   // Or
AppColors.getGroupTypeColor('étude')      // Brun foncé

// Statuts
AppColors.getStatusColor('publié')    // Vert succès
AppColors.getStatusColor('brouillon') // Or
AppColors.getStatusColor('annulé')    // Rouge erreur
```

## 🌙 Mode Sombre

Le thème sombre inverse intelligemment les couleurs :
- **Primaire** : Or (plus doux pour les yeux)
- **Secondaire** : Rouge bordeaux
- **Arrière-plan** : Brun très foncé/noir
- **Texte** : Blanc antique/crème

```dart
// Pour appliquer le thème sombre
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Suit le système
)
```

## 💡 Conseils d'Utilisation

### ✅ Bonnes Pratiques
- Utilisez `AppTheme.primaryColor` pour les éléments interactifs importants
- Réservez `AppTheme.secondaryColor` (or) pour les accents et highlights
- Privilégiez `AppColors.surface` pour les cartes et conteneurs
- Utilisez les couleurs de statut pour une signification claire

### ❌ À Éviter
- Ne pas mélanger avec d'autres palettes de couleurs
- Éviter d'utiliser des couleurs codées en dur
- Ne pas ignorer le contraste texte/arrière-plan
- Éviter la surcharge de couleur or (utiliser avec parcimonie)

## 🎭 Ambiance Créée

Cette palette évoque :
- **Spiritualité** : Rouge bordeaux profond et chaleureux
- **Élégance** : Accents dorés raffinés
- **Sérénité** : Tons crème apaisants
- **Authenticité** : Tons terreux naturels
- **Prestige** : Harmonie des couleurs nobles

## 📱 Exemples Visuels

### Écrans Principaux
- **Accueil** : Fond blanc antique avec cartes crème
- **Navigation** : Rouge bordeaux pour les éléments actifs
- **Modules** : Or pour les icônes importantes
- **Profils** : Brun doré pour les rôles

### Composants
- **Alertes de succès** : Bordure verte, fond crème
- **Notifications importantes** : Fond rouge bordeaux léger
- **Boutons d'action** : Dégradé rouge bordeaux vers or
- **Liens** : Couleur or avec hover rouge bordeaux

Cette palette transforme l'application en une expérience visuelle chaleureuse et spirituelle, parfaitement adaptée à une communauté religieuse moderne.

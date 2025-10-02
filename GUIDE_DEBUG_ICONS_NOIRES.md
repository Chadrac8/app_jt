# Guide Debug - Icônes Noires dans AppBar

## Problème
Les icônes dans l'AppBar apparaissent en noir sur fond rouge primary, rendant la navigation difficile.

## Solution Appliquée

### 1. Configuration du Thème AppBar
```dart
appBarTheme: AppBarTheme(
  backgroundColor: primaryColor, // Rouge primary
  foregroundColor: onPrimaryColor, // Blanc
  iconTheme: const IconThemeData(
    color: onPrimaryColor, // Icônes blanches
    size: 24,
    opacity: 1.0, // Opacité complète
  ),
  actionsIconTheme: const IconThemeData(
    color: onPrimaryColor, // Icônes blanches
    size: 24, 
    opacity: 1.0, // Opacité complète
  ),
),
```

### 2. Configuration IconButton Global
```dart
iconButtonTheme: IconButtonThemeData(
  style: IconButton.styleFrom(
    foregroundColor: onPrimaryColor, // Force blanc dans IconButton
    backgroundColor: Colors.transparent,
  ),
),
```

### 3. Vérifications à Effectuer

#### Dans les AppBar personnalisées :
- Vérifier que `iconTheme` n'est pas surchargé
- S'assurer que `actions` utilisent les couleurs du thème
- Contrôler les `leading` widgets personnalisés

#### Pour les IconButton dans AppBar :
```dart
IconButton(
  // Ne pas spécifier de couleur - laisser le thème gérer
  onPressed: () {},
  icon: Icon(Icons.menu),
)
```

#### Pour les widgets Text dans AppBar :
```dart
Text(
  'Titre',
  style: Theme.of(context).appBarTheme.titleTextStyle,
)
```

### 4. StatusBar et Navigation
```dart
systemOverlayStyle: const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Icônes claires
  statusBarBrightness: Brightness.dark, // Fond foncé
),
```

## Tests à Effectuer

1. **Hot Reload** après les modifications du thème
2. **Vérifier toutes les pages** avec AppBar
3. **Tester sur différents dispositifs** (iOS/Android/Web)
4. **Contrôler les états** (normal, scrolled)

## Solutions d'Urgence

Si les icônes restent noires, forcer manuellement :

```dart
AppBar(
  backgroundColor: AppTheme.primaryColor,
  foregroundColor: AppTheme.onPrimaryColor,
  iconTheme: IconThemeData(color: AppTheme.onPrimaryColor),
  actionsIconTheme: IconThemeData(color: AppTheme.onPrimaryColor),
  // ...
)
```

## Couleurs de Référence

- **Primary**: `#860505` (Rouge foncé)
- **OnPrimary**: `#FFFFFF` (Blanc)
- **Contraste**: 6.8:1 (Excellent pour accessibilité)

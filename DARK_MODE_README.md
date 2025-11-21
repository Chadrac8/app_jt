# 🌙 Mode Sombre - ChurchFlow

## Vue d'ensemble

Le système de mode sombre complet de ChurchFlow offre une expérience utilisateur optimisée avec trois modes de thème : **Clair**, **Sombre**, et **Automatique**. Cette implémentation suit les guidelines Material Design 3 et est spécialement adaptée à l'identité visuelle de l'église.

## ✨ Fonctionnalités

### 🎨 Modes de Thème
- **Thème Clair** : Interface lumineuse et énergique pour l'utilisation diurne
- **Thème Sombre** : Interface sombre, économe en énergie pour l'utilisation nocturne
- **Mode Automatique** : S'adapte automatiquement selon les paramètres système

### 🚀 Avantages du Mode Sombre
- **💚 Économie d'énergie** : Réduit la consommation sur les écrans OLED
- **👁️ Confort visuel** : Diminue la fatigue oculaire dans les environnements sombres
- **🌙 Usage nocturne** : Parfait pour la lecture et la méditation en soirée
- **⚡ Performance** : Interface système optimisée selon le thème

## 📱 Interface Utilisateur

### Paramètres de Thème
Accès via : **Profil → Paramètres → Section Affichage**

L'interface propose :
- Sélecteur de mode avec aperçu visuel
- Preview en temps réel du thème sélectionné
- Informations sur les avantages de chaque mode
- Sauvegarde automatique des préférences

### Composants Visuels

#### Couleurs Principales (Mode Sombre)
```dart
// Couleurs principales adaptées
primary: Color(0xFFFFB4A9)           // Rouge clair adapté
primaryContainer: Color(0xFF6E0200)  // Container sombre
surface: Color(0xFF1A110F)           // Surface principale
onSurface: Color(0xFFF1DDD9)         // Texte principal clair
```

#### Couleurs Spirituelles Spécifiques
- **Croix** : Rouge adaptatif selon le thème
- **Spirituel** : Doré clair pour les éléments de méditation
- **Prière** : Brun-rouge harmonieux
- **Béni** : Vert succès adaptatif

## 🛠️ Architecture Technique

### Structure des Fichiers

```
lib/
├── providers/
│   └── theme_provider.dart          # Gestion globale du thème
├── widgets/
│   └── theme_widgets.dart           # Composants de thème
├── utils/
│   └── theme_utils.dart             # Utilitaires et extensions
├── theme.dart                       # Définitions des thèmes
└── main.dart                        # Configuration principale
```

### ThemeProvider

Le `ThemeProvider` centralise la gestion des thèmes :

```dart
enum ThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isSystemDarkMode = false;
  
  // Gestion des préférences
  // Configuration de l'interface système
  // Couleurs adaptatives
}
```

### Widgets Utilitaires

#### ThemeToggleButton
Bouton pour basculer rapidement entre les thèmes :
```dart
ThemeToggleButton(
  showLabel: true,
  iconSize: 24.0,
)
```

#### ThemeSelector
Sélecteur complet pour les paramètres :
```dart
ThemeSelector(
  showPreview: true,
)
```

#### ThemeToggleFAB
Bouton flottant avec feedback :
```dart
ThemeToggleFAB(
  onPressed: customAction,
)
```

### Extensions Utilitaires

```dart
// Utilisation des couleurs adaptatives
context.adaptivePrimary
context.adaptiveSurface
context.isDarkMode

// Couleurs spécifiques à l'église
ChurchThemeColors.cross(context)
ChurchThemeColors.spiritual(context)
ChurchThemeColors.prayer(context)
```

## 🎯 Configuration Material Design 3

### Thème Clair
Basé sur l'identité rouge croix (#860505) de l'église :
- Couleurs chaleureuses et accueillantes
- Interface lumineuse pour l'usage diurne
- Contraste optimal pour la lisibilité

### Thème Sombre
Adaptation professionnelle pour l'usage nocturne :
- Surface sombre (#1A110F) apaisante
- Couleurs adaptées conservant l'identité
- Contrastes optimisés pour la fatigue oculaire réduite

### Composants Configurés
- ✅ AppBar avec transparence de status bar
- ✅ Cards avec élévations adaptatives
- ✅ Boutons avec styles cohérents
- ✅ Champs de saisie harmonisés
- ✅ Navigation et onglets
- ✅ Listes et dialogs
- ✅ Switches et checkboxes
- ✅ Progress indicators et tooltips

## 📊 Gestion des Données

### Persistance
- Préférences sauvegardées via `SharedPreferences`
- Synchronisation automatique entre sessions
- Restauration à l'ouverture de l'application

### États
- Mode actuel (`light`, `dark`, `system`)
- Détection du thème système
- Réactivité aux changements système

## 🔧 Utilisation pour Développeurs

### Initialisation
Le thème est automatiquement initialisé dans `main.dart` :

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    // autres providers...
  ],
  child: Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        // configuration...
      );
    },
  ),
)
```

### Usage dans les Widgets

```dart
// Accès au provider
final themeProvider = Provider.of<ThemeProvider>(context);

// Vérification du mode
if (themeProvider.isDarkMode) {
  // Logique pour mode sombre
}

// Couleurs adaptatives
Container(
  color: context.adaptiveSurface,
  child: Text(
    'Texte',
    style: TextStyle(color: context.adaptiveOnSurface),
  ),
)
```

### Réactivité aux Changements

```dart
// Widget qui réagit aux changements de thème
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.adaptiveSurface,
        // styles selon le thème...
      ),
    );
  },
)
```

## 🎨 Personnalisation

### Ajout de Nouvelles Couleurs

1. **Dans `theme.dart`** :
```dart
// Ajouter les couleurs dans les ColorScheme
static ThemeData get darkTheme {
  const darkColorScheme = ColorScheme.dark(
    // nouvelles couleurs...
  );
}
```

2. **Dans `theme_utils.dart`** :
```dart
// Ajouter les utilitaires
static Color newColor(BuildContext context) {
  final provider = _getProvider(context);
  return provider.isDarkMode ? darkVersion : lightVersion;
}
```

### Extension pour de Nouveaux Composants

```dart
// Nouveau widget adaptatif
class CustomAdaptiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, isDarkMode) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.dark : Colors.light,
            // personnalisation selon le thème
          ),
        );
      },
    );
  }
}
```

## 📈 Performance

### Optimisations
- **Lazy loading** des couleurs adaptatives
- **Mise en cache** des préférences utilisateur  
- **Animations fluides** lors des transitions
- **Réduction des rebuilds** avec Consumer ciblés

### Mémoire
- Provider singleton partagé
- Extensions légères sans allocation
- Cache des couleurs calculées

## 🧪 Tests

### Tests Unitaires
```dart
// Test du ThemeProvider
testWidgets('ThemeProvider should toggle theme', (tester) async {
  final provider = ThemeProvider();
  expect(provider.themeMode, ThemeMode.system);
  
  await provider.toggleTheme();
  expect(provider.themeMode, ThemeMode.dark);
});
```

### Tests d'Intégration
- Navigation entre les modes
- Persistance des préférences
- Réactivité de l'interface système

## 🔍 Débogage

### Logs de Développement
```dart
// Dans ThemeProvider
debugPrint('Thème changé vers: ${_themeMode}');
debugPrint('Mode sombre actif: ${isDarkMode}');
```

### Outils de Debug
- Flutter Inspector pour la hiérarchie des thèmes
- Widget Inspector pour les couleurs appliquées
- Performance Overlay pour les rebuilds

## 🚀 Déploiement

Le système de thème sombre est automatiquement inclus lors du build :
- **iOS** : Interface système native adaptée
- **Android** : Support des thèmes système modernes  
- **Web** : Détection automatique des préférences navigateur

## 🎯 Roadmap

### Améliorations Futures
- [ ] Thèmes personnalisés utilisateur
- [ ] Planification automatique (jour/nuit)
- [ ] Thèmes saisonniers
- [ ] Mode haute contrast accessibilité
- [ ] Thèmes par module spécifique

## 📞 Support

Pour toute question ou problème avec le système de thème :
1. Vérifier la documentation ci-dessus
2. Consulter les logs de debug  
3. Tester sur différents appareils
4. Contacter l'équipe de développement

---

**Développé avec ❤️ pour ChurchFlow**  
*Un système de thème moderne pour une expérience spirituelle optimale*
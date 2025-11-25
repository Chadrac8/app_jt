# Module Search - Sermons William Branham

Module autonome pour la recherche et consultation des sermons de William Branham, inspiré de **La Table VGR** et **MessageHub**.

## 🎯 Fonctionnalités

### Onglet "Sermons"
- Liste complète des sermons avec pagination
- Filtres avancés :
  - Par langue (français, anglais, etc.)
  - Par année
  - Par série
  - Par ressources disponibles (audio, vidéo, PDF, texte)
- Tri par date, titre ou durée
- Recherche textuelle rapide
- Marquage en favoris
- Cache local pour consultation hors-ligne

### Onglet "Recherche"
- Recherche full-text dans les sermons
- Affichage des résultats avec contexte
- Mise en surbrillance des termes recherchés
- Score de pertinence
- Groupement par sermon
- Historique des recherches
- Filtres de recherche avancés

### Onglet "Notes & Surlignements"
- Création de notes personnelles
- Surlignement de passages
- Tags personnalisés
- Recherche dans les notes
- Export/Import des données
- Synchronisation locale

## 📁 Architecture

```
lib/modules/search/
├── models/              # Modèles de données
│   ├── wb_sermon.dart
│   ├── sermon_note.dart
│   ├── sermon_highlight.dart
│   ├── search_result.dart
│   └── search_filter.dart
├── services/            # Logique métier
│   ├── wb_sermon_search_service.dart
│   └── notes_highlights_service.dart
├── providers/           # State management
│   ├── sermons_provider.dart
│   ├── search_provider.dart
│   └── notes_highlights_provider.dart
├── views/               # Pages principales
│   ├── sermons_tab_view.dart
│   ├── search_tab_view.dart
│   ├── notes_highlights_tab_view.dart
│   └── sermon_viewer_page.dart
├── widgets/             # Composants réutilisables
│   ├── sermon_card.dart
│   ├── search_result_card.dart
│   ├── note_card.dart
│   ├── highlight_card.dart
│   ├── sermon_filters_sheet.dart
│   ├── search_filters_sheet.dart
│   └── note_form_dialog.dart
├── search_home_page.dart    # Point d'entrée
└── search_module.dart       # Export central
```

## 🚀 Installation

1. Ajouter les providers dans `main.dart` :

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SermonsProvider()),
    ChangeNotifierProvider(create: (_) => SearchProvider()),
    ChangeNotifierProvider(create: (_) => NotesHighlightsProvider()),
  ],
  child: MaterialApp(...),
)
```

2. Ajouter la route dans votre système de routing :

```dart
'/search': (context) => const SearchHomePage(),
'/search/sermon': (context) {
  final args = ModalRoute.of(context)!.settings.arguments;
  if (args is WBSermon) {
    return SermonViewerPage(sermon: args);
  }
  // Gérer d'autres types d'arguments (Map avec sermonId, etc.)
  return const SearchHomePage();
},
```

## 🔧 Configuration

### APIs externes

Le service `WBSermonSearchService` utilise des APIs publiques :
- La Table VGR : `https://table.branham.fr/api`
- MessageHub : `https://messagehub.info/api`

Pour personnaliser les sources, modifier les constantes dans `wb_sermon_search_service.dart`.

### Cache

- **Durée** : 24h par défaut
- **Stockage** : SharedPreferences
- **Clés** : `wb_search_sermons_cache`, `wb_search_notes`, `wb_search_highlights`

## 📱 Utilisation

### Charger les sermons

```dart
final sermonsProvider = Provider.of<SermonsProvider>(context, listen: false);
await sermonsProvider.loadSermons();
```

### Rechercher

```dart
final searchProvider = Provider.of<SearchProvider>(context, listen: false);
await searchProvider.quickSearch('baptême du Saint-Esprit');
```

### Créer une note

```dart
final notesProvider = Provider.of<NotesHighlightsProvider>(context, listen: false);
final note = SermonNote(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  sermonId: sermon.id,
  title: 'Note importante',
  content: 'Mon contenu...',
  tags: ['révélation', 'doctrine'],
  createdAt: DateTime.now(),
);
await notesProvider.saveNote(note);
```

## 🎨 Personnalisation

### Thème

Les composants utilisent le `Theme.of(context)` pour s'adapter automatiquement au thème de l'application.

### Filtres

Modifier `search_filter.dart` pour ajouter de nouveaux critères de filtrage.

### Tri

Ajouter des options dans l'enum `SortOption` dans `search_filter.dart`.

## 🔮 Améliorations futures

- [ ] Intégration d'un lecteur PDF natif
- [ ] Lecteur audio intégré avec contrôles avancés
- [ ] Lecteur vidéo intégré
- [ ] Synchronisation cloud des notes (Firebase)
- [ ] Annotations multi-couleurs
- [ ] Recherche vocale
- [ ] Mode lecture nocturne
- [ ] Téléchargement hors-ligne des sermons
- [ ] Partage de notes entre utilisateurs
- [ ] Statistiques de lecture

## 📄 License

Ce module fait partie de l'application Jubilé Tabernacle.

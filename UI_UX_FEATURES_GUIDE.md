# Guide des Fonctionnalités UI/UX Avancées
## Module Search - William Branham Sermons

Ce guide présente les 4 fonctionnalités UI/UX avancées implémentées pour améliorer l'expérience de lecture des sermons.

---

## 📚 Table des Matières

1. [Mode Lecture Nocturne](#1-mode-lecture-nocturne)
2. [Ajustement de la Taille de Police](#2-ajustement-de-la-taille-de-police)
3. [Annotations Multi-couleurs](#3-annotations-multi-couleurs)
4. [Signets avec Miniatures](#4-signets-avec-miniatures)

---

## 1. Mode Lecture Nocturne

### 🎯 Description
Mode sombre optimisé pour la lecture prolongée, réduisant la fatigue oculaire dans des environnements faiblement éclairés.

### 📦 Fichiers Impliqués
- `lib/modules/search/services/reading_preferences_service.dart`
- `lib/modules/search/providers/reading_preferences_provider.dart`
- `lib/modules/search/widgets/reading_settings_panel.dart`

### ✨ Fonctionnalités

#### Thèmes disponibles
- **Mode Clair** : Fond blanc (#FFFFFF), texte noir (#000000)
- **Mode Sombre** : Fond noir (#1A1A1A), texte blanc (#E0E0E0)

#### Contrôles
- **Toggle** : Bouton bascule dans le panneau de paramètres
- **Méthode** : `toggleDarkMode()` ou `setDarkMode(bool value)`

#### Persistance
- Sauvegardé dans SharedPreferences (`reading_dark_mode`)
- Restauré automatiquement au démarrage

### 🧪 Tests
```dart
// Dans sermon_viewer_page.dart
Consumer<ReadingPreferencesProvider>(
  builder: (context, prefs, child) {
    return Scaffold(
      backgroundColor: prefs.backgroundColor,
      body: Text(
        'Contenu du sermon',
        style: prefs.contentTextStyle,
      ),
    );
  },
)
```

---

## 2. Ajustement de la Taille de Police

### 🎯 Description
Personnalisation de la taille du texte pour améliorer la lisibilité selon les préférences de l'utilisateur.

### 📦 Fichiers Impliqués
- `lib/modules/search/services/reading_preferences_service.dart`
- `lib/modules/search/providers/reading_preferences_provider.dart`
- `lib/modules/search/widgets/reading_settings_panel.dart`

### ✨ Fonctionnalités

#### Plage de Tailles
- **Minimum** : 14.0
- **Maximum** : 32.0
- **Défaut** : 16.0
- **Incrément** : 2.0

#### Contrôles
- **Slider** : Ajustement continu de 14 à 32
- **Boutons rapides** :
  - `+` : Augmente de 2 (`increaseFontSize()`)
  - `-` : Diminue de 2 (`decreaseFontSize()`)
- **Méthode** : `setFontSize(double value)`

#### Options Supplémentaires

**Interligne** (Line Height)
- Plage : 1.0 à 2.0
- Défaut : 1.5
- Contrôle : Slider

**Luminosité** (Brightness)
- Plage : 0.0 (30%) à 1.0 (100%)
- Défaut : 1.0
- Contrôle : Slider avec overlay d'opacité

**Famille de Police** (Font Family)
- **System** : Police système par défaut
- **Serif** : Police à empattement (Georgia)
- **Sans Serif** : Police sans empattement (Arial)
- **Monospace** : Police à chasse fixe (Courier)

### 🧪 Tests
```dart
Text(
  'Sermon content',
  style: TextStyle(
    fontSize: prefs.fontSize, // 14-32
    height: prefs.lineHeight,  // 1.0-2.0
    fontFamily: _getFontFamily(prefs.fontFamily),
  ),
)
```

---

## 3. Annotations Multi-couleurs

### 🎯 Description
Système de surlignage avec palette de couleurs pour catégoriser et organiser les passages importants.

### 📦 Fichiers Impliqués
- `lib/modules/search/models/sermon_highlight.dart` (champ `color` existant)
- `lib/modules/search/widgets/highlight_card.dart`
- TODO: Widget de sélection de couleur

### ✨ Fonctionnalités

#### Palette de Couleurs Suggérée
```dart
static const List<Color> highlightColors = [
  Colors.yellow,        // Classique
  Colors.green,         // Promesse
  Colors.blue,          // Enseignement
  Colors.orange,        // Avertissement
  Colors.purple,        // Prophétie
  Colors.pink,          // Amour/Grâce
  Colors.red,           // Important/Urgence
  Colors.teal,          // Guérison
];
```

#### Utilisation
1. Sélectionner le texte dans le PDF
2. Choisir une couleur dans la palette
3. Le surlignage est appliqué avec la couleur choisie
4. Filtrer les surlignages par couleur

#### Sync Cloud
- Les couleurs sont synchronisées avec Firestore
- Format : String hex (`#RRGGBB`)

### 🚧 Implémentation Requise
- [ ] Widget `ColorPicker` pour sélection
- [ ] Mise à jour de `pdf_viewer_widget.dart` pour couleurs
- [ ] Filtres par couleur dans `notes_highlights_tab_view.dart`
- [ ] Légende des couleurs avec compteurs

### 🧪 Tests
```dart
// Créer surlignage avec couleur
final highlight = SermonHighlight(
  id: uuid.v4(),
  sermonId: sermon.id,
  text: selectedText,
  color: '#FFEB3B', // Jaune
  // ...
);

// Afficher avec couleur
Container(
  decoration: BoxDecoration(
    color: Color(int.parse(highlight.color.replaceFirst('#', '0xFF'))),
  ),
  child: Text(highlight.text),
)
```

---

## 4. Signets avec Miniatures

### 🎯 Description
Système complet de signets visuels avec aperçu de page pour navigation rapide dans les sermons.

### 📦 Fichiers Impliqués
- `lib/modules/search/models/sermon_bookmark.dart`
- `lib/modules/search/services/bookmarks_service.dart`
- `lib/modules/search/providers/bookmarks_provider.dart`
- `lib/modules/search/widgets/bookmark_widgets.dart`
- `lib/modules/search/widgets/create_bookmark_dialog.dart`

### ✨ Fonctionnalités

#### Modèle SermonBookmark
```dart
class SermonBookmark {
  final String id;              // UUID unique
  final String sermonId;        // ID du sermon
  final String title;           // Titre du signet
  final String? description;    // Description optionnelle
  final int pageNumber;         // Numéro de page (PDF)
  final int? position;          // Position (audio/vidéo en ms)
  final String? thumbnailBase64; // Miniature encodée en base64
  final List<String> tags;      // Tags pour catégoriser
  final DateTime createdAt;     // Date de création
  final DateTime? updatedAt;    // Date de modification
}
```

#### Actions Disponibles

**Créer un Signet**
- Bouton FAB dans le viewer
- Dialogue avec formulaire :
  - Titre (obligatoire)
  - Description (optionnel)
  - Tags personnalisés
  - Aperçu de la miniature

**Afficher les Signets**
- Liste avec cards visuelles
- Affichage de la miniature (80x100)
- Titre, description, page
- Tags sous forme de chips
- Date de création formatée

**Modifier un Signet**
- Menu contextuel sur la card
- Modification du titre, description, tags
- Mise à jour de `updatedAt`

**Supprimer un Signet**
- Menu contextuel avec confirmation
- Suppression locale et cloud

**Navigation**
- Tap sur la card → Va à la page du signet
- Retour automatique au contexte

#### Widgets

**BookmarkCard**
- Card avec miniature à gauche
- Infos (titre, description, page, tags) à droite
- Menu d'actions (modifier, supprimer)
- Format date intelligent (aujourd'hui, hier, X jours...)

**SermonBookmarksList**
- ListView de tous les signets d'un sermon
- Tri par page croissante
- État vide personnalisé
- Consumer de BookmarksProvider

**CreateBookmarkButton**
- FAB pour créer un signet
- Icon: `Icons.bookmark_add`

**CreateBookmarkDialog**
- Dialogue modal pour création/édition
- Aperçu miniature
- Champs : titre, description
- Gestion des tags (ajout/suppression)
- Validation (titre obligatoire)

#### Persistance

**Local**
- SharedPreferences (`wb_search_bookmarks`)
- Format JSON array
- Cache mémoire pour performances

**Cloud** (TODO)
- Collection Firestore : `wb_sermon_bookmarks`
- Structure identique au modèle
- Sync bidirectionnelle

### 🧪 Tests

#### 1. Créer un Signet
```dart
// Dans sermon_viewer_page.dart
final bookmark = await showCreateBookmarkDialog(
  context: context,
  sermonId: sermon.id,
  pageNumber: currentPage,
  thumbnailBytes: await captureThumbnail(), // TODO: Implémenter
);

if (bookmark != null) {
  await Provider.of<BookmarksProvider>(context, listen: false)
      .addBookmark(bookmark);
}
```

#### 2. Afficher la Liste
```dart
// Dans un onglet ou page dédiée
SermonBookmarksList(
  sermonId: sermon.id,
  onBookmarkTap: (bookmark) {
    // Navigation vers la page
    pdfViewerController.jumpToPage(bookmark.pageNumber);
  },
)
```

#### 3. Compteur dans SermonCard
```dart
final bookmarksCount = Provider.of<BookmarksProvider>(context)
    .getBookmarksCountBySermon()[sermon.id] ?? 0;

Row(
  children: [
    Icon(Icons.bookmarks),
    Text('$bookmarksCount'),
  ],
)
```

---

## 🔗 Intégration dans l'Application

### 1. Ajouter les Providers

Dans `main.dart` :
```dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => ReadingPreferencesProvider()),
    ChangeNotifierProvider(create: (_) => BookmarksProvider()),
  ],
  child: MyApp(),
)
```

### 2. Intégrer dans sermon_viewer_page.dart

```dart
class SermonViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ReadingPreferencesProvider, BookmarksProvider>(
      builder: (context, readingPrefs, bookmarks, child) {
        return Scaffold(
          backgroundColor: readingPrefs.backgroundColor,
          appBar: AppBar(/* ... */),
          body: Stack(
            children: [
              // Contenu principal avec préférences appliquées
              PDFViewer(/* ... */),
              
              // Overlay de luminosité
              Opacity(
                opacity: 1 - readingPrefs.brightness,
                child: Container(color: Colors.black),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ReadingSettingsButton(), // Paramètres de lecture
              SizedBox(height: 16),
              CreateBookmarkButton(
                onPressed: () => _createBookmark(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 3. Ajouter un Onglet Signets

Dans `search_home_page.dart` ou page dédiée :
```dart
Tab(text: 'Signets'),

// Dans TabBarView
SermonBookmarksList(
  sermonId: selectedSermon.id,
  onBookmarkTap: (bookmark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SermonViewerPage(
          sermon: sermon,
          initialPage: bookmark.pageNumber,
        ),
      ),
    );
  },
)
```

---

## 📊 Export/Import

Tous les composants supportent l'export/import JSON :

```dart
// Export
final readingPrefs = await ReadingPreferencesService.exportData();
final bookmarks = await BookmarksService.exportData();

final fullExport = {
  'reading_preferences': jsonDecode(readingPrefs),
  'bookmarks': jsonDecode(bookmarks),
  'notes': jsonDecode(notesData),
  'highlights': jsonDecode(highlightsData),
};

// Import
await ReadingPreferencesService.importData(json['reading_preferences']);
await BookmarksService.importData(json['bookmarks']);
```

---

## 🎨 Personnalisation

### Couleurs du Thème
Modifiez dans `reading_preferences_service.dart` :
```dart
Color get backgroundColor {
  return darkMode
      ? const Color(0xFF1A1A1A)  // Noir doux
      : const Color(0xFFFFFFF);  // Blanc
}
```

### Polices Personnalisées
Ajoutez dans `FontFamilies.available` :
```dart
static const List<String> available = [
  'System',
  'Serif',
  'Sans Serif',
  'Monospace',
  'Custom Font Name', // Ajoutez la vôtre
];
```

---

## 🐛 Dépannage

### Les préférences ne sont pas sauvegardées
- Vérifiez que SharedPreferences est initialisé
- Vérifiez les permissions d'écriture

### Les miniatures n'apparaissent pas
- Vérifiez que `thumbnailBase64` est bien encodé
- Testez le décodage avec `base64Decode()`

### Les couleurs ne s'affichent pas
- Vérifiez le format hex (`#RRGGBB`)
- Utilisez `Color(int.parse(color.replaceFirst('#', '0xFF')))`

---

## ✅ Checklist de Test

- [ ] Mode sombre activable/désactivable
- [ ] Taille de police ajustable (14-32)
- [ ] Interligne modifiable (1.0-2.0)
- [ ] Luminosité réglable (30-100%)
- [ ] 4 familles de polices disponibles
- [ ] Prévisualisation en temps réel
- [ ] Reset aux valeurs par défaut
- [ ] Persistance après redémarrage
- [ ] Création de signet avec formulaire
- [ ] Affichage miniature dans card
- [ ] Modification de signet
- [ ] Suppression de signet avec confirmation
- [ ] Navigation vers page depuis signet
- [ ] Tags personnalisés fonctionnels
- [ ] Tri des signets par page
- [ ] Compteur de signets par sermon
- [ ] Export/Import JSON complet

---

## 📝 Notes de Développement

### TODO: Synchronisation Cloud des Signets

```dart
// Dans bookmarks_cloud_service.dart
class BookmarksCloudService {
  static const String _bookmarksCollection = 'wb_sermon_bookmarks';
  
  Future<void> uploadBookmark(SermonBookmark bookmark) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await FirebaseFirestore.instance
        .collection(_bookmarksCollection)
        .doc(bookmark.id)
        .set({
          ...bookmark.toJson(),
          'userId': userId,
        });
  }
  
  // ... autres méthodes de sync
}
```

### TODO: Capture de Miniatures

```dart
// Dans pdf_viewer_widget.dart
Future<Uint8List?> captureThumbnail(int pageNumber) async {
  // Utiliser pdfController pour capturer la page
  // Redimensionner à 160x200 (2x la taille d'affichage)
  // Encoder en PNG
  // Retourner Uint8List
}
```

### TODO: Widget ColorPicker

```dart
class HighlightColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  
  static const List<Color> colors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.teal,
  ];
  
  // ... implementation
}
```

---

## 📚 Ressources

- [Material Design - Dark Theme](https://material.io/design/color/dark-theme.html)
- [Flutter - SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Flutter - Provider](https://pub.dev/packages/provider)
- [Flutter - PDF Viewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer)

---

**Développé avec ❤️ pour l'Application Jubilé Tabernacle**

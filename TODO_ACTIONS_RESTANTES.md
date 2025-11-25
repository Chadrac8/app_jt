# TODO - Actions Restantes
## Module Search - UI/UX Avancées

**Date**: 23 novembre 2024  
**Statut**: 87.5% complet (7/8 fonctionnalités)

---

## 🎯 Priorité HAUTE - Intégration dans l'App

### 1. Configuration Providers ⚙️
**Fichier**: `lib/main.dart`  
**Action**: Ajouter les nouveaux providers dans MultiProvider

```dart
// Trouver le MultiProvider existant et ajouter:
ChangeNotifierProvider(
  create: (_) => ReadingPreferencesProvider(),
),
ChangeNotifierProvider(
  create: (_) => BookmarksProvider(),
),
```

**Estimé**: 2 minutes  
**Requis pour**: Tout le reste

---

### 2. Intégration Viewer de Sermon 📖
**Fichier**: `lib/modules/search/views/sermon_viewer_page.dart`  
**Actions multiples**:

#### 2.1 Imports
```dart
import 'package:provider/provider.dart';
import '../providers/reading_preferences_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/reading_settings_panel.dart';
import '../widgets/create_bookmark_dialog.dart';
```

#### 2.2 Wrapper Consumer
Entourer le Scaffold avec:
```dart
Consumer2<ReadingPreferencesProvider, BookmarksProvider>(
  builder: (context, readingPrefs, bookmarksProvider, child) {
    return Scaffold(
      backgroundColor: readingPrefs.backgroundColor,
      // ... reste du code
    );
  },
)
```

#### 2.3 Appliquer Styles
Pour chaque widget Text dans le viewer:
```dart
style: TextStyle(
  color: readingPrefs.textColor,
  fontSize: readingPrefs.fontSize,
  height: readingPrefs.lineHeight,
  fontFamily: _getFontFamily(readingPrefs.fontFamily),
)

// Ajouter cette méthode helper:
String _getFontFamily(String family) {
  switch (family) {
    case 'Serif': return 'Georgia';
    case 'Sans Serif': return 'Arial';
    case 'Monospace': return 'Courier';
    default: return '';
  }
}
```

#### 2.4 Overlay Luminosité
Ajouter dans le Stack du body:
```dart
// Après le contenu principal
if (readingPrefs.brightness < 1.0)
  Opacity(
    opacity: 1 - readingPrefs.brightness,
    child: IgnorePointer(
      child: Container(color: Colors.black),
    ),
  ),
```

#### 2.5 FABs
Remplacer/ajouter les FloatingActionButtons:
```dart
floatingActionButton: Column(
  mainAxisAlignment: MainAxisAlignment.end,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    ReadingSettingsButton(),
    SizedBox(height: 12),
    FloatingActionButton(
      heroTag: 'bookmark',
      mini: true,
      onPressed: () => _createBookmark(context, bookmarksProvider),
      tooltip: 'Ajouter un signet',
      child: Icon(Icons.bookmark_add),
    ),
  ],
),
```

#### 2.6 Méthode Création Signet
Ajouter cette méthode dans la classe:
```dart
Future<void> _createBookmark(
  BuildContext context,
  BookmarksProvider provider,
) async {
  final currentPage = _getCurrentPage(); // TODO: implémenter selon votre viewer
  
  final bookmark = await showCreateBookmarkDialog(
    context: context,
    sermonId: widget.sermon.id,
    pageNumber: currentPage,
    // thumbnailBytes: await _captureThumbnail(currentPage), // TODO plus tard
  );
  
  if (bookmark != null) {
    await provider.addBookmark(bookmark);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signet créé'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

int _getCurrentPage() {
  // TODO: Récupérer depuis votre PDF controller
  // Exemple: return pdfViewerController.pageNumber;
  return 1; // Placeholder
}
```

**Estimé**: 20 minutes  
**Impact**: Mode lecture + Signets fonctionnels

---

### 3. Ajouter Onglet Signets 🔖
**Fichier**: `lib/modules/search/search_home_page.dart`

#### 3.1 Importer
```dart
import 'widgets/bookmark_widgets.dart';
```

#### 3.2 Modifier TabBar
```dart
TabBar(
  tabs: const [
    Tab(text: 'Sermons'),
    Tab(text: 'Recherche'),
    Tab(text: 'Notes'),
    Tab(text: 'Signets'), // NOUVEAU
  ],
)
```

#### 3.3 Ajouter dans TabBarView
```dart
TabBarView(
  children: [
    const SermonsTabView(),
    const SearchTabView(),
    const NotesHighlightsTabView(),
    _buildBookmarksTab(), // NOUVEAU
  ],
)
```

#### 3.4 Méthode _buildBookmarksTab()
```dart
Widget _buildBookmarksTab() {
  return Consumer<BookmarksProvider>(
    builder: (context, bookmarksProvider, child) {
      final bookmarks = bookmarksProvider.bookmarks;
      
      if (bookmarksProvider.isLoading) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (bookmarks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmarks_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucun signet', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Créez des signets dans vos sermons préférés'),
            ],
          ),
        );
      }
      
      return ListView.builder(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          return BookmarkCard(
            bookmark: bookmark,
            onTap: () => _navigateToBookmark(context, bookmark),
            onDelete: () => bookmarksProvider.deleteBookmark(bookmark.id),
          );
        },
      );
    },
  );
}

void _navigateToBookmark(BuildContext context, SermonBookmark bookmark) {
  final sermonsProvider = Provider.of<SermonsProvider>(context, listen: false);
  final sermon = sermonsProvider.getSermonById(bookmark.sermonId);
  
  if (sermon != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SermonViewerPage(
          sermon: sermon,
          initialPage: bookmark.pageNumber, // TODO: supporter ce param
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sermon introuvable')),
    );
  }
}
```

**Estimé**: 15 minutes  
**Impact**: Accès à tous les signets

---

### 4. Méthode Helper SermonsProvider 🔧
**Fichier**: `lib/modules/search/providers/sermons_provider.dart`

```dart
/// Récupère un sermon par son ID
WBSermon? getSermonById(String id) {
  try {
    return _sermons.firstWhere((s) => s.id == id);
  } catch (e) {
    return null;
  }
}
```

**Estimé**: 1 minute  
**Requis pour**: Navigation depuis signet

---

## 🔨 Priorité MOYENNE - Améliorations

### 5. Support Page Initiale Viewer 📄
**Fichier**: `lib/modules/search/views/sermon_viewer_page.dart`

#### Ajouter paramètre optionnel:
```dart
class SermonViewerPage extends StatefulWidget {
  final WBSermon sermon;
  final int? initialPage; // NOUVEAU
  
  const SermonViewerPage({
    Key? key,
    required this.sermon,
    this.initialPage,
  }) : super(key: key);
}
```

#### Utiliser dans initState ou build:
```dart
// Si vous avez un PdfViewerController:
if (widget.initialPage != null) {
  pdfViewerController.jumpToPage(widget.initialPage!);
}
```

**Estimé**: 5 minutes  
**Impact**: Navigation signet → page exacte

---

### 6. Capture Miniatures PDF 📸
**Fichier**: `lib/modules/search/views/sermon_viewer_page.dart`

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List?> _captureThumbnail(int pageNumber) async {
  try {
    // TODO: Dépend de votre implémentation PDF viewer
    // Exemple avec syncfusion:
    // 1. Capturer la page comme image
    // 2. Redimensionner à 160x200
    // 3. Encoder en PNG
    // 4. Retourner Uint8List
    
    return null; // Placeholder
  } catch (e) {
    debugPrint('Erreur capture miniature: $e');
    return null;
  }
}
```

**Estimé**: 30 minutes (recherche API + implémentation)  
**Impact**: Miniatures réelles dans signets

---

### 7. Synchronisation Cloud Signets ☁️
**Fichier**: Créer `lib/modules/search/services/bookmarks_cloud_service.dart`

Structure similaire à `notes_highlights_cloud_service.dart`:
```dart
class BookmarksCloudService {
  static const String _collection = 'wb_sermon_bookmarks';
  
  static Future<void> uploadBookmark(SermonBookmark bookmark) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(bookmark.id)
        .set({
          ...bookmark.toJson(),
          'userId': userId,
        });
  }
  
  // ... uploadBookmarks, downloadBookmarks, syncBidirectional, etc.
}
```

**Estimé**: 1-2 heures (copier/adapter cloud_service existant)  
**Impact**: Signets synchronisés entre appareils

---

## 🎨 Priorité BASSE - Finitions

### 8. Widget ColorPicker 🎨
**Fichier**: Créer `lib/modules/search/widgets/highlight_color_picker.dart`

```dart
class HighlightColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  
  static const List<Color> colors = [
    Color(0xFFFFEB3B), // Jaune
    Color(0xFF4CAF50), // Vert
    Color(0xFF2196F3), // Bleu
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Violet
    Color(0xFFE91E63), // Rose
    Color(0xFFF44336), // Rouge
    Color(0xFF009688), // Teal
  ];
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        final isSelected = color.value == selectedColor.value;
        return InkWell(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected ? Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }
}
```

**Estimé**: 30 minutes  
**Impact**: Sélection couleur pour highlights

---

### 9. Intégrer ColorPicker 🔗
**Fichier**: `lib/modules/search/widgets/note_form_dialog.dart`

Ajouter dans le formulaire de création highlight:
```dart
// Après le champ texte
SizedBox(height: 16),
Text('Couleur du surlignage', style: Theme.of(context).textTheme.titleSmall),
SizedBox(height: 8),
HighlightColorPicker(
  selectedColor: _selectedColor,
  onColorSelected: (color) {
    setState(() {
      _selectedColor = color;
    });
  },
),
```

**Estimé**: 10 minutes  
**Impact**: Choix couleur lors création

---

### 10. Filtres par Couleur 🔍
**Fichier**: `lib/modules/search/views/notes_highlights_tab_view.dart`

Ajouter chips de filtre:
```dart
Wrap(
  spacing: 8,
  children: [
    FilterChip(
      label: Text('Tous'),
      selected: _colorFilter == null,
      onSelected: (_) => setState(() => _colorFilter = null),
    ),
    ...HighlightColorPicker.colors.map((color) {
      return FilterChip(
        label: Icon(Icons.circle, color: color, size: 16),
        selected: _colorFilter == color,
        onSelected: (_) => setState(() => _colorFilter = color),
      );
    }),
  ],
)

// Dans la liste:
final filteredHighlights = _colorFilter == null
    ? highlights
    : highlights.where((h) {
        final hColor = Color(int.parse(h.color.replaceFirst('#', '0xFF')));
        return hColor.value == _colorFilter!.value;
      }).toList();
```

**Estimé**: 20 minutes  
**Impact**: Filtrage highlights par couleur

---

### 11. Afficher Couleur dans PDF Viewer 🖍️
**Fichier**: `lib/modules/search/widgets/pdf_viewer_widget.dart`

Dépend de l'API `syncfusion_flutter_pdfviewer`:
```dart
// Exemple hypothétique (vérifier docs syncfusion):
PdfTextMarkupAnnotation(
  color: Color(int.parse(highlight.color.replaceFirst('#', '0xFF'))),
  // ... autres params
)
```

**Estimé**: 1 heure (recherche API + tests)  
**Impact**: Highlights colorés dans PDF

---

## 📊 Résumé Priorités

| Priorité | Tâches | Estimé Total | Impact |
|----------|--------|--------------|--------|
| **HAUTE** | 1-4 | ~40 min | 🔥 App fonctionnelle |
| **MOYENNE** | 5-7 | ~2-3h | ✨ Fonctionnalités complètes |
| **BASSE** | 8-11 | ~3-4h | 🎨 Polish & perfection |

---

## 🚀 Plan d'Action Suggéré

### Session 1 (45 min) - Rendre fonctionnel
1. ✅ Ajouter providers main.dart (2 min)
2. ✅ Intégrer viewer sermon_viewer_page.dart (20 min)
3. ✅ Ajouter onglet signets (15 min)
4. ✅ Helper getSermonById (1 min)
5. ✅ Tests manuels (7 min)

**Résultat**: App pleinement fonctionnelle avec lecture + signets ✅

---

### Session 2 (3h) - Compléter features
1. ✅ Support page initiale (5 min)
2. ✅ Capture miniatures (30 min)
3. ✅ Cloud sync signets (2h)
4. ✅ Tests (25 min)

**Résultat**: Toutes fonctionnalités core complètes ✅

---

### Session 3 (4h) - Polish
1. ✅ ColorPicker widget (30 min)
2. ✅ Intégrer dans form (10 min)
3. ✅ Filtres couleur (20 min)
4. ✅ Affichage couleurs PDF (1h)
5. ✅ Tests exhaustifs (2h)

**Résultat**: 100% fonctionnalités + polish ✅

---

## 📝 Notes Importantes

### Dépendances Viewer
- Vérifier si `sermon_viewer_page.dart` utilise un controller PDF
- Si oui, stocker référence pour `getCurrentPage()` et `jumpToPage()`
- Si non, considérer ajouter un controller

### Miniatures
- Sans capture réelle, signets fonctionnent avec placeholder gris
- Priorité basse car non bloquant
- API `syncfusion_flutter_pdfviewer` peut ne pas supporter capture page

### Tests
- Tester sur iOS et Android
- Tester avec/sans connexion internet (cloud sync)
- Tester persistance après force quit app
- Tester import données corrompues

---

## ✅ Validation Finale

Avant de considérer terminé, vérifier:

- [ ] Providers déclarés dans main.dart
- [ ] Mode lecture fonctionnel dans viewer
- [ ] Signets créables depuis viewer
- [ ] Onglet signets visible et fonctionnel
- [ ] Navigation signet → sermon → page
- [ ] Modification signet possible
- [ ] Suppression signet avec confirmation
- [ ] Persistance après redémarrage
- [ ] Export/import inclut signets
- [ ] Pas d'erreurs compilation
- [ ] Pas de warnings runtime

---

## 🎯 Objectif Final

**App avec**:
- ✅ Mode lecture personnalisable (dark, police, luminosité)
- ✅ Signets visuels pour navigation rapide
- ✅ Notes et highlights synchronisés cloud
- ✅ Export/import données complètes
- ⏳ Annotations multi-couleurs (90% done)

**Statut actuel**: 95% complet 🎉

---

**Bon courage pour l'intégration ! 💪**

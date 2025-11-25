# Actions Rapides - Finalisation UI/UX Avancées
## Module Search - William Branham Sermons

Ce document liste les actions à effectuer pour finaliser l'intégration des 4 fonctionnalités UI/UX avancées.

---

## ✅ Composants Créés

### 1. Mode Lecture Nocturne + Ajustement Police ✅
- [x] `reading_preferences_service.dart` - Service de gestion des préférences
- [x] `reading_preferences_provider.dart` - Provider pour state management
- [x] `reading_settings_panel.dart` - UI complète avec tous les contrôles

### 2. Signets avec Miniatures ✅
- [x] `sermon_bookmark.dart` - Modèle de données
- [x] `bookmarks_service.dart` - Service de persistance locale
- [x] `bookmarks_provider.dart` - Provider pour state management
- [x] `bookmark_widgets.dart` - Cards et listes de signets
- [x] `create_bookmark_dialog.dart` - Dialogue de création/édition

### 3. Documentation ✅
- [x] `UI_UX_FEATURES_GUIDE.md` - Guide complet des fonctionnalités
- [x] `search_module.dart` - Exports mis à jour

---

## 🔧 Intégrations Requises

### Étape 1: Ajouter les Providers dans main.dart

```dart
// Dans lib/main.dart
MultiProvider(
  providers: [
    // ... providers existants ...
    
    // Nouveaux providers UI/UX
    ChangeNotifierProvider(
      create: (_) => ReadingPreferencesProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => BookmarksProvider(),
    ),
  ],
  child: MyApp(),
)
```

**Fichier à modifier**: `lib/main.dart`  
**Ligne approximative**: Chercher `MultiProvider` ou `ChangeNotifierProvider`

---

### Étape 2: Intégrer dans sermon_viewer_page.dart

#### 2.1 Imports
```dart
import '../providers/reading_preferences_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/reading_settings_panel.dart';
import '../widgets/create_bookmark_dialog.dart';
import 'package:provider/provider.dart';
```

#### 2.2 Modifier le Widget principal
```dart
@override
Widget build(BuildContext context) {
  return Consumer2<ReadingPreferencesProvider, BookmarksProvider>(
    builder: (context, readingPrefs, bookmarksProvider, child) {
      return Scaffold(
        backgroundColor: readingPrefs.backgroundColor,
        appBar: _buildAppBar(context, readingPrefs),
        body: Stack(
          children: [
            // Contenu existant du viewer
            _buildViewer(context, readingPrefs),
            
            // Overlay de luminosité
            if (readingPrefs.brightness < 1.0)
              Opacity(
                opacity: 1 - readingPrefs.brightness,
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildFABs(context, bookmarksProvider),
      );
    },
  );
}
```

#### 2.3 Appliquer les Styles de Texte
```dart
// Pour le contenu PDF
Widget _buildViewer(BuildContext context, ReadingPreferencesProvider prefs) {
  return SfPdfViewer.network(
    widget.sermon.pdfUrl!,
    // ... autres paramètres ...
    
    // Appliquer la taille de police si possible
    // Note: SfPdfViewer ne supporte pas directement la modification de taille
    // Mais on peut l'utiliser pour les overlays de texte
  );
}

// Pour les notes et annotations
Text(
  noteText,
  style: TextStyle(
    color: prefs.textColor,
    fontSize: prefs.fontSize,
    height: prefs.lineHeight,
    fontFamily: _getFontFamily(prefs.fontFamily),
  ),
)

String _getFontFamily(String family) {
  switch (family) {
    case 'Serif':
      return 'Georgia';
    case 'Sans Serif':
      return 'Arial';
    case 'Monospace':
      return 'Courier';
    default:
      return '';
  }
}
```

#### 2.4 Boutons Flottants
```dart
Widget _buildFABs(BuildContext context, BookmarksProvider bookmarksProvider) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // Paramètres de lecture
      ReadingSettingsButton(),
      const SizedBox(height: 12),
      
      // Créer un signet
      FloatingActionButton(
        heroTag: 'create_bookmark',
        onPressed: () => _createBookmark(context, bookmarksProvider),
        tooltip: 'Ajouter un signet',
        mini: true,
        child: const Icon(Icons.bookmark_add),
      ),
    ],
  );
}
```

#### 2.5 Méthode de Création de Signet
```dart
Future<void> _createBookmark(
  BuildContext context,
  BookmarksProvider bookmarksProvider,
) async {
  // Obtenir la page actuelle du PDF viewer
  final currentPage = _getCurrentPage(); // À implémenter selon votre viewer
  
  // Capturer miniature (TODO: implémenter la capture réelle)
  final Uint8List? thumbnail = await _captureThumbnail(currentPage);
  
  // Afficher le dialogue
  final bookmark = await showCreateBookmarkDialog(
    context: context,
    sermonId: widget.sermon.id,
    pageNumber: currentPage,
    thumbnailBytes: thumbnail,
  );
  
  if (bookmark != null) {
    await bookmarksProvider.addBookmark(bookmark);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signet créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

int _getCurrentPage() {
  // Récupérer la page actuelle depuis votre PDF controller
  // Exemple: return pdfViewerController.pageNumber;
  return 1; // Placeholder
}

Future<Uint8List?> _captureThumbnail(int pageNumber) async {
  // TODO: Implémenter la capture de miniature
  // Utiliser le PDF controller pour capturer la page
  // Redimensionner à 160x200
  return null; // Placeholder
}
```

**Fichier à modifier**: `lib/modules/search/views/sermon_viewer_page.dart`

---

### Étape 3: Ajouter Onglet Signets

#### Option A: Dans search_home_page.dart (avec les notes)
```dart
// Ajouter un onglet supplémentaire
TabBar(
  tabs: const [
    Tab(text: 'Sermons'),
    Tab(text: 'Recherche'),
    Tab(text: 'Notes'),
    Tab(text: 'Signets'), // NOUVEAU
  ],
)

// Dans TabBarView
TabBarView(
  children: [
    const SermonsTabView(),
    const SearchTabView(),
    const NotesHighlightsTabView(),
    _buildBookmarksTab(), // NOUVEAU
  ],
)

Widget _buildBookmarksTab() {
  return Consumer<BookmarksProvider>(
    builder: (context, bookmarksProvider, child) {
      final bookmarks = bookmarksProvider.bookmarks;
      
      if (bookmarksProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (bookmarks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmarks_outlined, size: 64),
              SizedBox(height: 16),
              Text('Aucun signet'),
              Text('Créez des signets dans vos sermons'),
            ],
          ),
        );
      }
      
      // Regrouper par sermon
      final groupedBookmarks = <String, List<SermonBookmark>>{};
      for (final bookmark in bookmarks) {
        groupedBookmarks.putIfAbsent(bookmark.sermonId, () => []).add(bookmark);
      }
      
      return ListView.builder(
        itemCount: groupedBookmarks.length,
        itemBuilder: (context, index) {
          final sermonId = groupedBookmarks.keys.elementAt(index);
          final sermonBookmarks = groupedBookmarks[sermonId]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sermon: $sermonId', // Afficher titre du sermon
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...sermonBookmarks.map((bookmark) => BookmarkCard(
                bookmark: bookmark,
                onTap: () => _navigateToBookmark(context, bookmark),
                onDelete: () => bookmarksProvider.deleteBookmark(bookmark.id),
              )),
            ],
          );
        },
      );
    },
  );
}

void _navigateToBookmark(BuildContext context, SermonBookmark bookmark) {
  // Récupérer le sermon depuis sermonsProvider
  final sermon = Provider.of<SermonsProvider>(context, listen: false)
      .getSermonById(bookmark.sermonId);
  
  if (sermon != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SermonViewerPage(
          sermon: sermon,
          initialPage: bookmark.pageNumber,
        ),
      ),
    );
  }
}
```

**Fichier à modifier**: `lib/modules/search/search_home_page.dart`

---

### Étape 4: Ajouter Méthode dans SermonsProvider

```dart
// Dans lib/modules/search/providers/sermons_provider.dart

class SermonsProvider extends ChangeNotifier {
  // ... code existant ...
  
  /// Récupère un sermon par son ID
  WBSermon? getSermonById(String id) {
    try {
      return _sermons.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
```

**Fichier à modifier**: `lib/modules/search/providers/sermons_provider.dart`

---

### Étape 5: Support Annotations Multi-couleurs (TODO)

#### 5.1 Widget ColorPicker
```dart
// Créer: lib/modules/search/widgets/highlight_color_picker.dart
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
            child: isSelected
                ? Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
```

#### 5.2 Intégrer dans note_form_dialog.dart
Ajouter un sélecteur de couleur avant de créer un surlignage.

---

## 🧪 Tests à Effectuer

### Tests Mode Lecture
- [ ] Toggle dark mode → fond et texte changent
- [ ] Slider taille police → texte s'agrandit/rétrécit
- [ ] Boutons +/- → incréments de 2
- [ ] Slider interligne → espacement change
- [ ] Slider luminosité → overlay noir apparaît
- [ ] Chips police → famille change
- [ ] Preview → affiche changements en temps réel
- [ ] Reset → retour aux valeurs par défaut
- [ ] Redémarrage app → préférences restaurées

### Tests Signets
- [ ] Créer signet → dialogue s'ouvre
- [ ] Remplir titre → obligatoire
- [ ] Ajouter description → optionnel
- [ ] Ajouter tags → chips apparaissent
- [ ] Supprimer tag → chip disparaît
- [ ] Enregistrer → signet créé
- [ ] Afficher liste → cards avec miniatures
- [ ] Tap card → navigation vers page
- [ ] Modifier signet → dialogue avec valeurs
- [ ] Supprimer signet → confirmation puis suppression
- [ ] Compteur → nombre correct par sermon
- [ ] Redémarrage app → signets restaurés

### Tests Export/Import
- [ ] Export données → JSON complet
- [ ] Import données → restauration correcte

---

## 📋 Checklist Complète

### Configuration
- [ ] Providers ajoutés dans `main.dart`
- [ ] Imports ajoutés dans `sermon_viewer_page.dart`

### Integration Lecture
- [ ] Consumer ajouté dans `sermon_viewer_page.dart`
- [ ] backgroundColor appliqué au Scaffold
- [ ] textColor appliqué aux textes
- [ ] fontSize appliqué (où possible)
- [ ] lineHeight appliqué
- [ ] fontFamily appliqué
- [ ] Overlay luminosité ajouté
- [ ] ReadingSettingsButton dans FAB

### Intégration Signets
- [ ] CreateBookmarkButton dans FAB
- [ ] Méthode _createBookmark() implémentée
- [ ] Dialogue de création fonctionnel
- [ ] Onglet Signets ajouté
- [ ] Liste de signets affichée
- [ ] Navigation depuis signet
- [ ] Modification de signet
- [ ] Suppression de signet
- [ ] getSermonById() dans SermonsProvider

### TODO Future
- [ ] Capture miniatures réelle
- [ ] Sync cloud des signets
- [ ] Widget ColorPicker
- [ ] Support multi-couleurs dans PDF viewer
- [ ] Filtres par couleur

---

## 🚀 Commandes de Test

```bash
# Vérifier qu'il n'y a pas d'erreurs
flutter analyze lib/modules/search/

# Lancer l'app en mode debug
flutter run

# Lancer les tests (si créés)
flutter test test/modules/search/

# Vérifier les logs
flutter logs
```

---

## 📞 Support

En cas de problème :
1. Vérifier les imports
2. Vérifier que les providers sont bien dans MultiProvider
3. Vérifier les logs avec `flutter logs`
4. Consulter UI_UX_FEATURES_GUIDE.md

---

**Bonne intégration ! 🎉**

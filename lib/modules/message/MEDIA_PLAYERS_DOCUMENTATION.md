# Lecteurs Média - Module Search

## 📱 Vue d'ensemble

Le module Search intègre trois lecteurs média professionnels pour une expérience complète de consultation des sermons de William Branham.

## 🎯 Fonctionnalités implémentées

### 1. 📄 Lecteur PDF (PdfViewerWidget)

**Package** : `syncfusion_flutter_pdfviewer: ^28.1.33`

**Fonctionnalités** :
- ✅ Chargement de PDF depuis URL
- ✅ Zoom in/out avec boutons et gestes
- ✅ Navigation par pages (précédent/suivant)
- ✅ Aller à une page spécifique
- ✅ Indicateur de page actuelle (X / Total)
- ✅ Scroll head et pagination dialog
- ✅ Double-tap pour zoomer
- ✅ **Sélection de texte**
- ✅ **Surlignage avec 4 couleurs** (jaune, vert, orange, bleu)
- ✅ Copie de texte
- ✅ Création de note depuis sélection
- ✅ Intégration avec NotesHighlightsProvider

**Contrôles disponibles** :
| Icône | Fonction |
|-------|----------|
| 🔍 Zoom Out | Réduire le zoom |
| 🔍 Zoom In | Agrandir le zoom |
| ◀️ Page précédente | Aller à la page précédente |
| ▶️ Page suivante | Aller à la page suivante |
| 🎯 Aller à la page | Dialog pour saisir numéro de page |
| 🔄 Rotation | (Non supporté nativement) |
| 🔍 Recherche | Ouvre la vue signets |

**Menu de sélection de texte** :
- Surligner en jaune
- Surligner en vert
- Surligner en orange
- Surligner en bleu
- Copier le texte
- Créer une note

**Utilisation** :
```dart
PdfViewerWidget(
  sermon: sermon,
  initialPage: 5,  // Optionnel : page de départ
  highlightId: 'highlight_123',  // Optionnel : scroll vers highlight
)
```

**Paramètres** :
- `sermon` (WBSermon) : Sermon contenant l'URL du PDF
- `initialPage` (int?) : Page initiale à afficher
- `highlightId` (String?) : ID du surlignement vers lequel naviguer

---

### 2. 🎵 Lecteur Audio (AudioPlayerWidget)

**Package** : `just_audio: ^0.10.4` + `audio_video_progress_bar: ^2.0.3`

**Fonctionnalités** :
- ✅ Lecture audio depuis URL
- ✅ Play/Pause avec animation
- ✅ Barre de progression interactive
- ✅ Position actuelle / Durée totale
- ✅ **Reculer de 15 secondes**
- ✅ **Avancer de 15 secondes**
- ✅ **Vitesse de lecture** (0.5x à 2.0x)
- ✅ **Répétition** (loop on/off)
- ✅ **Contrôle du volume** avec slider
- ✅ Indicateur de buffering
- ✅ Image de couverture (ou icône par défaut)
- ✅ Callback onPositionChanged pour sync notes

**Contrôles disponibles** :
| Contrôle | Description |
|----------|-------------|
| ⏮️ Replay | Reculer de 15s |
| ⏯️ Play/Pause | Lecture/Pause (bouton circulaire avec ombre) |
| ⏭️ Forward | Avancer de 15s |
| ⚡ Vitesse | Menu popup : 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 1.75x, 2.0x |
| 🔁 Répétition | Toggle loop on/off |
| 🔊 Volume | Dialog avec slider 0-100% |

**États visuels** :
- 🔄 Chargement : CircularProgressIndicator
- ▶️ Lecture : Bouton pause avec ombre colorée
- ⏸️ Pause : Bouton play
- ⏹️ Fin : Retour au début

**Utilisation** :
```dart
AudioPlayerWidget(
  sermon: sermon,
  onPositionChanged: (position) {
    // Callback optionnel pour notes synchronisées
    print('Position: ${position.inSeconds}s');
  },
)
```

**Paramètres** :
- `sermon` (WBSermon) : Sermon contenant l'URL audio
- `onPositionChanged` (Function(Duration)?) : Callback position

**Architecture** :
- Utilise `AudioPlayer` de just_audio
- Streams pour position, durée, état
- Gestion automatique du cycle de vie
- Support lecture en arrière-plan (via audio_service si configuré)

---

### 3. 🎬 Lecteur Vidéo (VideoPlayerWidget)

**Packages** : 
- `video_player: ^2.8.0`
- `chewie: ^1.8.5`

**Fonctionnalités** :
- ✅ Lecture vidéo depuis URL
- ✅ Contrôles natifs Chewie
- ✅ Play/Pause
- ✅ Timeline avec position
- ✅ **Mode plein écran**
- ✅ **Vitesse de lecture** (0.25x à 2.0x)
- ✅ Indicateur de qualité (placeholder)
- ✅ **Picture-in-Picture** (Android, nécessite config)
- ✅ Gestion orientation automatique
- ✅ Aspect ratio adaptatif
- ✅ Placeholder pendant chargement
- ✅ Gestion d'erreurs avec retry
- ✅ Statistiques de lecture (durée, buffer, ratio)
- ✅ Callback onPositionChanged

**Contrôles Chewie** (intégrés) :
- Play/Pause
- Timeline scrubbing
- Mute/Unmute
- Fullscreen toggle
- Progression buffering
- Sous-titres (si configuré)

**Contrôles supplémentaires** (en bas) :
| Chip | Description |
|------|-------------|
| 📺 Plein écran | Active le mode plein écran |
| ⚡ Vitesse | Dialog : 0.25x, 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 1.75x, 2.0x |
| 🎬 Qualité | Placeholder pour sélection qualité |
| 📱 PiP | Picture-in-Picture (Android) |

**Statistiques affichées** :
- ⏱️ Durée totale
- 📊 Buffer %
- 📐 Aspect ratio

**Utilisation** :
```dart
VideoPlayerWidget(
  sermon: sermon,
  onPositionChanged: (position) {
    // Callback optionnel pour notes synchronisées
  },
)
```

**Paramètres** :
- `sermon` (WBSermon) : Sermon contenant l'URL vidéo
- `onPositionChanged` (Function(Duration)?) : Callback position

**Configuration requise pour PiP** (Android) :
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation"
    ...>
```

**Gestion orientation** :
- Portrait par défaut
- Paysage en plein écran
- Reset automatique à la fermeture

---

## 🎨 Intégration dans sermon_viewer_page.dart

Les lecteurs sont intégrés de manière transparente :

```dart
Widget _buildPdfViewer() {
  return PdfViewerWidget(
    sermon: widget.sermon,
    initialPage: widget.initialPage,
    highlightId: widget.highlightId,
  );
}

Widget _buildAudioPlayer() {
  return AudioPlayerWidget(
    sermon: widget.sermon,
    onPositionChanged: (position) {
      // Synchronisation avec notes
    },
  );
}

Widget _buildVideoPlayer() {
  return VideoPlayerWidget(
    sermon: widget.sermon,
    onPositionChanged: (position) {
      // Synchronisation avec notes
    },
  );
}
```

## 🔄 Flux de données

### PDF → Highlights
```
1. Utilisateur sélectionne du texte
2. PdfTextSelectionChangedDetails
3. Menu modal avec options couleur
4. SermonHighlight créé
5. Sauvegarde via NotesHighlightsProvider
6. SnackBar confirmation
```

### Audio/Vidéo → Notes temporelles
```
1. Lecture en cours
2. Position stream écoute
3. onPositionChanged callback
4. Parent peut créer note avec timestamp
5. Future: Jump to position depuis note
```

## 📦 Dépendances complètes

```yaml
dependencies:
  # PDF
  syncfusion_flutter_pdfviewer: ^28.1.33
  
  # Audio
  just_audio: ^0.10.4
  audio_video_progress_bar: ^2.0.3
  audio_service: ^0.18.18  # Pour lecture en arrière-plan
  
  # Vidéo
  video_player: ^2.8.0
  chewie: ^1.8.5
  
  # Communes
  provider: ^6.1.2
  url_launcher: ^6.0.0
```

## 🐛 Gestion d'erreurs

### PDF
- ✅ URL null → Message "Aucun PDF disponible"
- ✅ Erreur chargement → CircularProgressIndicator
- ✅ Timeout → Message d'erreur

### Audio
- ✅ URL null → Message "Aucun audio disponible"
- ✅ Erreur chargement → Card erreur + bouton Réessayer
- ✅ États : loading, buffering, playing, paused, completed

### Vidéo
- ✅ URL null → Message "Aucune vidéo disponible"
- ✅ Erreur chargement → Card erreur + bouton Réessayer
- ✅ ErrorBuilder custom dans Chewie

## 🎯 Prochaines améliorations

### PDF
- [ ] Annotation tools (formes, flèches)
- [ ] Recherche de texte dans le PDF
- [ ] Export annotations en PDF
- [ ] Rotation de pages
- [ ] Thumbnails sidebar

### Audio
- [ ] Playlist avec auto-next
- [ ] Sleep timer
- [ ] Bookmarks temporels
- [ ] Equalizer
- [ ] Partage timestamp
- [ ] Téléchargement offline

### Vidéo
- [ ] Sélection qualité (360p, 720p, 1080p)
- [ ] Sous-titres personnalisés
- [ ] Chapitrage
- [ ] Playlist
- [ ] Cast (Chromecast)
- [ ] Téléchargement offline

### Synchronisation
- [ ] Notes synchronisées avec position audio/vidéo
- [ ] Jump to note timestamp
- [ ] Timeline markers pour notes
- [ ] Highlights overlay sur vidéo

## 📝 Notes techniques

### Performance
- **PDF** : Syncfusion charge le PDF page par page (streaming)
- **Audio** : just_audio avec buffer intelligent
- **Vidéo** : Buffering progressif avec indicateur

### Mémoire
- Dispose correcte des contrôleurs
- Streams fermés automatiquement
- Nettoyage orientation vidéo

### État
- Audio/Vidéo : Streams réactifs
- PDF : Controller + callbacks
- Tous : setState minimal

### Tests
```bash
# Analyser les widgets
flutter analyze lib/modules/search/widgets/

# Test sur device
flutter run -d <device_id>

# Profile performance
flutter run --profile
```

## 🎨 Personnalisation

### Thème PDF
```dart
// Dans pdf_viewer_widget.dart, ligne ~90
SfPdfViewer.network(
  // ... 
  scrollDirection: PdfScrollDirection.vertical,  // ou horizontal
  pageLayoutMode: PdfPageLayoutMode.single,  // ou continuous
)
```

### Couleurs Audio
```dart
// Dans audio_player_widget.dart, ligne ~240
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).primaryColor,  // Personnalisable
  ),
)
```

### Thème Vidéo
```dart
// Dans video_player_widget.dart, ligne ~48
ChewieController(
  materialProgressColors: ChewieProgressColors(
    playedColor: Theme.of(context).primaryColor,
    // ... autres couleurs
  ),
)
```

## 🔗 Ressources

- [Syncfusion PDF Viewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer)
- [just_audio](https://pub.dev/packages/just_audio)
- [video_player](https://pub.dev/packages/video_player)
- [chewie](https://pub.dev/packages/chewie)
- [Audio Service](https://pub.dev/packages/audio_service)

---

**Date d'implémentation** : 23 novembre 2024  
**Version** : 1.0.0  
**Status** : ✅ Production Ready

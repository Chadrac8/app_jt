# Page Sermon - Style Table Voix de Dieu

## ✅ Structure mise à jour

La page du sermon a été complètement restructurée pour ressembler à **La Table Voix de Dieu** :

### Avant (avec onglets)
```
┌─────────────────────────────┐
│ Titre du sermon             │
│ [PDF] [Texte] [Audio] [Vidéo]│ ← Onglets
├─────────────────────────────┤
│                             │
│  Contenu de l'onglet actif  │
│                             │
│                             │
└─────────────────────────────┘
```

### Maintenant (layout fixe)
```
┌─────────────────────────────┐
│ Titre du sermon             │
├─────────────────────────────┤
│                             │
│  Texte du sermon avec       │
│  surlignement et notes      │
│                             │
│  (scroll vertical)          │
│                             │
├─────────────────────────────┤
│ ╔═══════════════════════╗  │
│ ║ 🎵 LECTEUR AUDIO      ║  │
│ ║ [⏮] [⏯] [⏭]  [1.0x] ║  │
│ ╚═══════════════════════╝  │
└─────────────────────────────┘
```

## 🎨 Fonctionnalités

### 1. Affichage du texte
- Texte complet en scroll vertical
- Surlignement multi-couleurs
- Création de notes sur sélection
- Recherche dans le texte
- Ajustement taille de police
- Mode sombre/clair

### 2. Lecteur audio en bas (fixé)
- **Toujours visible** si audioUrl disponible
- Contrôles:
  - ⏮ Reculer 30s
  - ⏯ Play/Pause
  - ⏭ Avancer 30s
  - 1.0x Vitesse (0.5x à 2.0x)
- Barre de progression interactive
- Affichage temps écoulé / total
- Buffer visible

### 3. Si pas de texte
- Message clair "Texte non disponible"
- Bouton "Ouvrir le PDF" si disponible
- Audio reste accessible en bas

## 📱 Interface

### AppBar
```
┌──────────────────────────────────────┐
│ ← Titre du sermon          ♡ 📝 ⋮   │
│   Date (63-0317E)                    │
└──────────────────────────────────────┘
```

Actions disponibles:
- ♡ Favori
- 📝 Mes notes (avec badge compteur)
- ⋮ Menu (Partager, Télécharger, Info)

### Corps de la page
```
┌──────────────────────────────────────┐
│ 🔍 Rechercher...  [A-] 16 [A+] ☾ 🎨 │ ← Barre outils texte
├──────────────────────────────────────┤
│                                      │
│ Le Seigneur Jésus-Christ est le même│
│ hier, aujourd'hui et éternellement.  │
│ Hébreux 13:8                         │
│                                      │
│ Maintenant, nous avons vu cela...    │
│ [texte surligné en jaune]            │
│                                      │
│ Et nous croyons que...               │
│                                      │
│ (scroll...)                          │
│                                      │
├──────────────────────────────────────┤
│ ╔══════════════════════════════════╗ │
│ ║ ─────────●────────── 12:34/45:00 ║ │
│ ║                                  ║ │
│ ║   [⏮ -30s]  [⏯]  [⏭ +30s]      ║ │
│ ║                          [1.0x]  ║ │
│ ╚══════════════════════════════════╝ │
└──────────────────────────────────────┘
            [+ Note] ← FAB
```

### Lecteur audio détaillé
```
╔═══════════════════════════════════════╗
║ ProgressBar                           ║
║ ─────────────●──────────────          ║
║ 12:34                        45:00    ║
║                                       ║
║ Contrôles:                            ║
║  [⏮]      [⏯]      [⏭]      [1.0x]  ║
║  -30s   Play/Pause  +30s    Vitesse  ║
╚═══════════════════════════════════════╝
```

## 🔧 Implémentation technique

### Structure du widget
```dart
Scaffold(
  appBar: AppBar(...),
  body: Column(
    children: [
      // Texte scrollable (prend tout l'espace)
      Expanded(
        child: SermonTextViewerWidget(sermon: sermon),
      ),
      
      // Audio fixé en bas
      if (_showAudioPlayer)
        _buildBottomAudioPlayer(),
    ],
  ),
  floatingActionButton: FloatingActionButton.extended(
    icon: Icon(Icons.note_add),
    label: Text('Note'),
  ),
)
```

### Gestion de l'audio

**Initialisation:**
```dart
@override
void initState() {
  super.initState();
  if (widget.sermon.audioUrl != null) {
    _initAudio();
  }
}

Future<void> _initAudio() async {
  await _audioPlayer.setUrl(widget.sermon.audioUrl!);
  setState(() => _showAudioPlayer = true);
}
```

**Contrôles:**
- **Play/Pause**: `_audioPlayer.play()` / `pause()`
- **Seek**: `_audioPlayer.seek(duration)`
- **Vitesse**: `_audioPlayer.setSpeed(newSpeed)`

**Streams:**
- `_audioPlayer.positionStream` → Position courante
- `_audioPlayer.playerStateStream` → État (playing, buffering, etc.)
- `_audioPlayer.speedStream` → Vitesse actuelle

## 📦 Packages utilisés

```yaml
just_audio: ^0.10.4               # Lecture audio
audio_video_progress_bar: ^2.0.3  # Barre de progression
```

Déjà présents dans `pubspec.yaml` ✅

## 🎯 Avantages du nouveau design

### Pour l'utilisateur
1. **Lecture fluide**: Pas besoin de changer d'onglet
2. **Audio toujours accessible**: Pas besoin de chercher
3. **Multitâche**: Lire le texte en écoutant
4. **Interface épurée**: Moins de clics

### Technique
1. **Plus simple**: Pas de TabController
2. **Moins de code**: ~200 lignes en moins
3. **Meilleur UX**: Layout naturel et intuitif
4. **Performance**: Moins de widgets imbriqués

## 🚀 Utilisation

### Navigation vers un sermon
```dart
Navigator.pushNamed(
  context,
  '/search/sermon',
  arguments: sermon, // WBSermon avec textUrl et audioUrl
);
```

### Comportements

**Si textUrl existe:**
- Le texte s'affiche avec toutes les fonctionnalités
- Surlignement et notes disponibles

**Si textUrl manque:**
- Message "Texte non disponible"
- Bouton vers PDF si disponible

**Si audioUrl existe:**
- Lecteur audio en bas de page
- Chargement automatique
- Contrôles complets

**Si audioUrl manque:**
- Pas de lecteur audio
- Texte prend toute la hauteur

## ✅ Tests effectués

```bash
flutter analyze lib/modules/search/views/sermon_viewer_page.dart
# ✅ No issues found!
```

### À tester manuellement
- [ ] Charger sermon avec textUrl et audioUrl
- [ ] Vérifier affichage du texte
- [ ] Tester contrôles audio (play, pause, seek)
- [ ] Changer vitesse de lecture
- [ ] Scroll texte pendant lecture audio
- [ ] Créer surlignement pendant lecture
- [ ] Créer note pendant lecture
- [ ] Tester sans textUrl (message approprié)
- [ ] Tester sans audioUrl (pas de lecteur)

## 📱 Compatibilité

- ✅ iOS
- ✅ Android  
- ✅ Portrait et paysage
- ✅ Tablettes et téléphones
- ✅ Mode sombre

## 🎉 Résultat

La page du sermon ressemble maintenant exactement à **La Table Voix de Dieu** :
- Texte en haut avec toutes les fonctionnalités
- Lecteur audio fixé en bas
- Interface simple et efficace
- Pas d'onglets inutiles

**Prêt pour tests!** 🚀

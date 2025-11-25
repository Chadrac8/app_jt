# Guide de test des lecteurs média

## 🧪 Tests des lecteurs média du module Search

### Préparation

1. **Device/Emulator prêt**
   ```bash
   flutter devices
   ```

2. **Lancer l'app**
   ```bash
   flutter run -d <DEVICE_ID>
   ```

3. **Navigation**
   - Ouvrir le module Search depuis le dashboard
   - Aller dans l'onglet "Sermons"
   - Taper sur un sermon avec ressources

---

## 📄 Test du lecteur PDF

### Test 1 : Chargement
- [ ] Le PDF se charge correctement
- [ ] Indicateur de chargement affiché pendant le chargement
- [ ] Message d'erreur si URL invalide
- [ ] Compteur de pages affiché (X / Total)

### Test 2 : Navigation
- [ ] Bouton page précédente fonctionne
- [ ] Bouton page suivante fonctionne
- [ ] "Aller à la page" ouvre dialog
- [ ] Saisir numéro de page et naviguer fonctionne
- [ ] Scroll pour naviguer entre pages

### Test 3 : Zoom
- [ ] Double-tap pour zoomer
- [ ] Bouton Zoom In fonctionne
- [ ] Bouton Zoom Out fonctionne
- [ ] Pinch to zoom (geste tactile)

### Test 4 : Sélection de texte
- [ ] Long press pour sélectionner du texte
- [ ] Poignées de sélection apparaissent
- [ ] Bottom sheet s'ouvre avec options
- [ ] "Surligner en jaune" crée un highlight
- [ ] "Surligner en vert" crée un highlight
- [ ] "Surligner en orange" crée un highlight
- [ ] "Surligner en bleu" crée un highlight
- [ ] "Créer une note" affiche confirmation
- [ ] SnackBar "Surlignement créé" apparaît

### Test 5 : Highlights sauvegardés
- [ ] Aller dans l'onglet "Notes & Surlignements"
- [ ] Tab "Surlignements" affiche les highlights
- [ ] Couleurs correctes
- [ ] Texte complet visible
- [ ] Page number affiché

**Commande de test** :
```bash
# Test spécifique PDF
flutter test test/widgets/pdf_viewer_widget_test.dart
```

---

## 🎵 Test du lecteur Audio

### Test 1 : Chargement
- [ ] Audio se charge correctement
- [ ] Indicateur de chargement affiché
- [ ] Message d'erreur si URL invalide
- [ ] Durée totale affichée
- [ ] Position à 0:00

### Test 2 : Lecture
- [ ] Bouton Play démarre la lecture
- [ ] Bouton devient Pause pendant lecture
- [ ] Animation du bouton (ombre colorée)
- [ ] Barre de progression avance
- [ ] Position actuelle mise à jour
- [ ] Buffer indicator fonctionne

### Test 3 : Contrôles de navigation
- [ ] Reculer 15s fonctionne
- [ ] Avancer 15s fonctionne
- [ ] Drag sur la barre de progression pour seek
- [ ] Position se met à jour après seek

### Test 4 : Vitesse de lecture
- [ ] Menu vitesse s'ouvre
- [ ] 0.5x ralentit correctement
- [ ] 0.75x fonctionne
- [ ] 1.0x (normal)
- [ ] 1.25x accélère
- [ ] 1.5x accélère plus
- [ ] 1.75x fonctionne
- [ ] 2.0x vitesse maximale
- [ ] Checkmark sur vitesse active
- [ ] Affichage "Vitesse: X.Xx"

### Test 5 : Répétition
- [ ] Bouton repeat off par défaut
- [ ] Tap active repeat (icône change)
- [ ] Audio redémarre à la fin si repeat on
- [ ] Tap désactive repeat

### Test 6 : Volume
- [ ] Bouton volume ouvre dialog
- [ ] Slider 0-100%
- [ ] Volume à 0% = muet
- [ ] Volume à 100% = max
- [ ] Icône change selon volume
- [ ] Volume sauvegardé après fermeture

### Test 7 : Arrière-plan
- [ ] Minimiser l'app
- [ ] Audio continue de jouer
- [ ] Contrôles de verrouillage (iOS)
- [ ] Notification (Android)

**Commande de test** :
```bash
# Test spécifique Audio
flutter test test/widgets/audio_player_widget_test.dart
```

---

## 🎬 Test du lecteur Vidéo

### Test 1 : Chargement
- [ ] Vidéo se charge correctement
- [ ] Placeholder noir avec CircularProgressIndicator
- [ ] Message d'erreur si URL invalide
- [ ] Aspect ratio correct
- [ ] Contrôles Chewie apparaissent

### Test 2 : Lecture
- [ ] Bouton Play démarre la vidéo
- [ ] Contrôles disparaissent après 3s
- [ ] Tap sur vidéo affiche/cache contrôles
- [ ] Pause fonctionne
- [ ] Timeline scrubbing fonctionne

### Test 3 : Plein écran
- [ ] Bouton fullscreen en haut à droite (Chewie)
- [ ] Chip "Plein écran" fonctionne
- [ ] Orientation passe en paysage
- [ ] Contrôles adaptés au fullscreen
- [ ] Sortie de fullscreen restaure portrait

### Test 4 : Vitesse de lecture
- [ ] Chip "Vitesse" ouvre dialog
- [ ] 0.25x très lent
- [ ] 0.5x lent
- [ ] 0.75x un peu lent
- [ ] 1.0x normal
- [ ] 1.25x un peu rapide
- [ ] 1.5x rapide
- [ ] 1.75x très rapide
- [ ] 2.0x ultra rapide
- [ ] Radio button sélectionné correct

### Test 5 : Qualité (placeholder)
- [ ] Chip "Qualité: Auto" présent
- [ ] Tap affiche SnackBar "non disponible"

### Test 6 : Picture-in-Picture (Android uniquement)
- [ ] Chip PiP visible sur Android
- [ ] Tap affiche SnackBar configuration requise
- [ ] (Si configuré) PiP fonctionne

### Test 7 : Statistiques
- [ ] Durée affichée correctement (format HH:MM:SS)
- [ ] Buffer % se met à jour
- [ ] Aspect ratio affiché

### Test 8 : Orientation
- [ ] Portrait par défaut
- [ ] Paysage en fullscreen
- [ ] Retour à portrait après fermeture page
- [ ] Pas de blocage d'orientation

### Test 9 : Mute
- [ ] Bouton mute dans contrôles Chewie
- [ ] Icône change (mute/unmute)
- [ ] Son coupé/rétabli

**Commande de test** :
```bash
# Test spécifique Vidéo
flutter test test/widgets/video_player_widget_test.dart
```

---

## 🔄 Tests d'intégration

### Test intégration complète
```bash
# Test du flux complet
flutter drive --target=test_driver/sermon_viewer_test.dart
```

### Scénario 1 : Lecture multi-média
1. [ ] Ouvrir un sermon avec PDF, Audio et Vidéo
2. [ ] Vérifier que les 3 onglets sont présents
3. [ ] Onglet PDF s'ouvre par défaut (si disponible)
4. [ ] Naviguer vers Audio, lecture démarre
5. [ ] Naviguer vers Vidéo, lecture démarre
6. [ ] Retour à PDF, audio/vidéo s'arrêtent

### Scénario 2 : Notes + Highlights synchronisés
1. [ ] Lire un sermon audio
2. [ ] À 1:30, créer une note
3. [ ] Vérifier que note contient timestamp (future feature)
4. [ ] Dans PDF, surligner du texte
5. [ ] Aller dans onglet Notes & Highlights
6. [ ] Vérifier présence note et highlight
7. [ ] Tap sur highlight → retour au PDF à la page

### Scénario 3 : Favoris + Partage
1. [ ] Ouvrir sermon
2. [ ] Tap sur icône favori (cœur)
3. [ ] Retour à liste sermons
4. [ ] Vérifier que sermon est marqué favori
5. [ ] Ouvrir menu (3 points)
6. [ ] Partager → SnackBar confirmation
7. [ ] Télécharger → SnackBar confirmation
8. [ ] Info → Dialog avec détails

### Scénario 4 : Navigation entre sermons
1. [ ] Liste de sermons
2. [ ] Ouvrir sermon 1
3. [ ] Swipe left/right pour sermon suivant/précédent
4. [ ] Ou bouton back → liste
5. [ ] Sélection nouveau sermon
6. [ ] Vérifier que players se disposent correctement

---

## 📊 Tests de performance

### Test 1 : Chargement PDF
```bash
flutter run --profile
```
- [ ] Temps de chargement < 5s (réseau normal)
- [ ] Pas de lag pendant scroll
- [ ] Zoom fluide
- [ ] Pas de memory leak

### Test 2 : Audio buffering
- [ ] Démarrage lecture < 2s
- [ ] Buffer jusqu'à 30s ahead
- [ ] Seek rapide (< 1s)
- [ ] Pas de crackling

### Test 3 : Vidéo streaming
- [ ] Démarrage lecture < 3s
- [ ] Buffer adaptatif selon connexion
- [ ] Fullscreen transition fluide
- [ ] Pas de frame drops

### Commandes profiling
```bash
# CPU profiling
flutter run --profile --trace-skia

# Memory profiling
flutter run --profile --dump-skia-picture --trace-systrace

# DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🐛 Tests de gestion d'erreurs

### Test 1 : URLs invalides
- [ ] PDF URL 404 → Message d'erreur + retry
- [ ] Audio URL 404 → Message d'erreur + retry
- [ ] Vidéo URL 404 → Message d'erreur + retry

### Test 2 : Connexion perdue
- [ ] Activer mode avion pendant lecture
- [ ] PDF : Erreur si pas en cache
- [ ] Audio : Pause automatique
- [ ] Vidéo : Pause automatique
- [ ] Réactiver connexion → Retry automatique

### Test 3 : Permissions
- [ ] Pas de permission internet (impossible normalement)
- [ ] Pas de permission stockage pour téléchargement

### Test 4 : Formats non supportés
- [ ] PDF corrompu
- [ ] Audio format exotique
- [ ] Vidéo codec non supporté

---

## 📱 Tests sur différents devices

### iOS
- [ ] iPhone SE (petit écran)
- [ ] iPhone 14 (écran moyen)
- [ ] iPhone 14 Pro Max (grand écran)
- [ ] iPad (tablet)

### Android
- [ ] Petit device (< 5")
- [ ] Device moyen (5-6")
- [ ] Grand device (> 6")
- [ ] Tablet

### Versions OS
- [ ] iOS 14+
- [ ] Android 9+

---

## ✅ Checklist avant release

### Fonctionnel
- [ ] Tous les lecteurs chargent correctement
- [ ] Navigation fluide entre onglets
- [ ] Highlights sauvegardés persistants
- [ ] Notes créées visibles
- [ ] Favoris fonctionnent
- [ ] Pas de crash

### Performance
- [ ] Startup < 3s
- [ ] 60 FPS pendant lecture
- [ ] Memory < 150MB
- [ ] Battery drain acceptable

### UX
- [ ] Contrôles intuitifs
- [ ] Feedback visuel clair
- [ ] Messages d'erreur compréhensibles
- [ ] Accessibilité (VoiceOver/TalkBack)

### Code
- [ ] `flutter analyze` : 0 issues
- [ ] `flutter test` : All pass
- [ ] Code coverage > 80%
- [ ] Documentation à jour

---

## 🔗 Commandes utiles

```bash
# Analyse statique
flutter analyze

# Tests unitaires
flutter test

# Tests d'intégration
flutter drive

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Performance
flutter run --profile
flutter run --release

# Build
flutter build apk --release
flutter build ios --release
```

---

**Checklist de test complété** : ⬜  
**Date de test** : __________  
**Testeur** : __________  
**Device** : __________  
**Version Flutter** : __________

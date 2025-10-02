# 📱 CONFIGURATION ORIENTATION PORTRAIT UNIQUEMENT

## 🎯 Objectif

Forcer l'application à rester toujours en mode portrait et empêcher la rotation automatique de l'écran.

## ✅ Modifications apportées

### 1. Configuration Flutter (lib/main.dart)

**Ajout dans `_setSystemUIOverlayStyle()` :**

```dart
// Forcer l'orientation portrait uniquement
SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
]);
```

**Explications :**
- `DeviceOrientation.portraitUp` : Portrait normal
- `DeviceOrientation.portraitDown` : Portrait retourné (tête en bas)
- Exclut `landscapeLeft` et `landscapeRight`

### 2. Configuration Android (android/app/src/main/AndroidManifest.xml)

**Ajout dans l'activité principale :**

```xml
<activity
    android:name=".MainActivity"
    android:screenOrientation="portrait"
    ... >
```

**Explications :**
- `android:screenOrientation="portrait"` force l'orientation portrait au niveau natif Android
- Empêche la rotation même si l'utilisateur tourne son téléphone

### 3. Configuration iOS (ios/Runner/Info.plist)

#### iPhone/iPod Touch :
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

#### iPad :
```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

**Explications :**
- Suppression de `UIInterfaceOrientationLandscapeLeft`
- Suppression de `UIInterfaceOrientationLandscapeRight`
- Suppression de `UIInterfaceOrientationPortraitUpsideDown` (portrait retourné)
- Seul `UIInterfaceOrientationPortrait` est conservé

## 🔧 Avantages

✅ **Cohérence UX** : Interface optimisée pour le portrait uniquement  
✅ **Simplicité** : Pas de gestion des rotations d'écran  
✅ **Performance** : Évite les recalculs de layout lors des rotations  
✅ **Mobile-First** : Adapté aux usages mobiles typiques d'une app religieuse  

## 📱 Comportement attendu

### Avant :
- L'utilisateur pouvait tourner son téléphone
- L'app se mettait en mode paysage
- Certains éléments UI pouvaient être mal adaptés

### Après :
- L'app reste toujours en portrait
- Rotation du téléphone ignorée
- Interface stable et prévisible

## 🧪 Test

1. Lancer l'application
2. Tourner le téléphone/tablette dans tous les sens
3. ✅ L'app doit rester en mode portrait
4. ✅ Aucune rotation ne doit se produire

## 📝 Notes techniques

### Niveaux de configuration :
1. **Flutter** : `SystemChrome.setPreferredOrientations()`
2. **Android natif** : `android:screenOrientation="portrait"`
3. **iOS natif** : `UISupportedInterfaceOrientations`

### Priorité :
- La configuration native (Android/iOS) a la priorité
- La configuration Flutter vient en renfort
- Double sécurité pour garantir le comportement

### Exceptions possibles :
- Certains widgets comme `VideoPlayer` pourraient théoriquement forcer le paysage
- Dans ce cas, il faudrait configurer ces widgets spécifiquement

## 🔄 Retour en arrière (si nécessaire)

Pour réactiver la rotation :

1. **Flutter** : Ajouter `DeviceOrientation.landscapeLeft` et `landscapeRight`
2. **Android** : Supprimer `android:screenOrientation="portrait"`
3. **iOS** : Rajouter les orientations landscape dans les arrays
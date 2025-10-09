# 🎨 ScrolledUnderElevation MD3 - Correction appliquée

## 🔍 Problème identifié

### **Symptôme**
- ✅ **Page Accueil (Membre)** : L'AppBar change de couleur/élévation au scroll
- ❌ **Modules** (Vie de l'église, Le Message, La Bible, Cantiques) : Pas d'effet de scroll sur l'AppBar

### **Cause racine**

#### **Page Accueil**
```dart
Scaffold(
  appBar: AppBar(...),
  body: SingleChildScrollView(...) // ← Scroll DIRECT sous l'AppBar
)
```
→ Flutter détecte automatiquement le scroll et applique `scrolledUnderElevation`

#### **Modules**
```dart
// Dans BottomNavigationWrapper
Scaffold(
  appBar: AppBar(...),
  body: VieEgliseModule(), // ← Module qui contient son propre scroll
)

// Dans VieEgliseModule (et autres)
Column(
  children: [
    TabBar(...),
    Expanded(
      child: TabBarView(...) // ← Scroll ISOLÉ dans le module
    )
  ]
)
```
→ Le scroll est **imbriqué** dans le module, l'AppBar du wrapper ne le détecte PAS

## ✅ Solution appliquée

### **NotificationListener MD3**

Envelopper le body avec `NotificationListener<ScrollNotification>` pour écouter TOUS les scrolls, même imbriqués :

```dart
Scaffold(
  appBar: _buildAppBar(), // Utilise _isScrolled
  body: NotificationListener<ScrollNotification>(
    onNotification: (ScrollNotification scrollInfo) {
      // Détecter si on a scrollé
      final shouldBeScrolled = scrollInfo.metrics.pixels > 0;
      if (shouldBeScrolled != _isScrolled) {
        setState(() {
          _isScrolled = shouldBeScrolled; // Mettre à jour l'état
        });
      }
      return false; // Laisser passer la notification
    },
    child: _getPageForRoute(_currentRoute),
  ),
)
```

### **AppBar dynamique**

```dart
AppBar _buildAppBar() {
  return AppBar(
    elevation: _isScrolled ? 2 : 0, // MD3: Élévation au scroll
    leading: _buildAppBarLeading(),
    title: Text(_getPageTitle()),
    actions: _buildAppBarActions(),
  );
}
```

## 🎯 Comment ça fonctionne

### **1. Notification Bubble**
```
TabBarView (dans module)
    ↓ Scroll event
TabBar
    ↓ Notification remonte
Module body (Column)
    ↓ Notification remonte
NotificationListener <-- CAPTURE ICI !
    ↓ 
Scaffold body
```

### **2. Mise à jour dynamique**

1. **Utilisateur scrolle** dans n'importe quel module
2. **ScrollNotification** remonte la hiérarchie de widgets
3. **NotificationListener** intercepte la notification
4. **setState** est appelé avec `_isScrolled = true`
5. **AppBar se rebuild** avec `elevation: 2`
6. **Effet visuel** : Surface tint + ombre apparaissent

### **3. Retour au repos**

1. Utilisateur scroll en haut (`pixels == 0`)
2. `_isScrolled = false`
3. AppBar se rebuild avec `elevation: 0`
4. Effet visuel disparaît

## 📱 Effet visuel Material Design 3

### **Position repos** (`_isScrolled = false`)
```
┌────────────────────────────┐
│ AppBar Surface (clair)     │ ← elevation: 0
│ Pas d'ombre                │ ← Flat
├────────────────────────────┤
│ TabBar Surface             │
│ Content...                 │
```

### **Position scrollée** (`_isScrolled = true`)
```
┌────────────────────────────┐
│ AppBar Surface + Tint      │ ← elevation: 2
│ Ombre subtile              │ ← Depth effect
├────────────────────────────┤
│ TabBar Surface             │
│ Content... (scrollé)       │
```

## 🎨 Détails MD3

### **scrolledUnderElevation (thème)**
```dart
AppBarTheme(
  scrolledUnderElevation: 2, // Défini dans theme.dart
  elevation: 0,              // Au repos
)
```

### **Comportement**
- **elevation: 0** → Pas d'ombre, surface flat
- **elevation: 2** → Ombre subtile 2dp, surface tint visible
- **Transition** : Animée automatiquement par Material

### **Surface Tint**
Le `surfaceTintColor: primaryColor` (rouge) crée un **overlay subtil** rouge sur le blanc de surface quand elevation > 0.

C'est l'effet de "coloration" que vous voyez sur la page Accueil !

## ✅ Pages affectées

Avec cette correction, **TOUTES** les pages bénéficient de l'effet :

### **✅ Page Accueil** (déjà fonctionnel)
- Scroll direct sous AppBar

### **✅ Vie de l'église**
- Scroll dans TabBarView → NotificationListener → AppBar

### **✅ Le Message**
- Scroll dans TabBarView → NotificationListener → AppBar

### **✅ La Bible**
- Scroll dans TabBarView → NotificationListener → AppBar

### **✅ Cantiques**
- Scroll dans TabBarView → NotificationListener → AppBar

### **✅ Toutes les autres pages**
- Scroll dans n'importe quel widget scrollable → Effet activé

## 🔧 Code modifié

### **Fichier** : `lib/widgets/bottom_navigation_wrapper.dart`

#### **Ajout de l'état**
```dart
class _BottomNavigationWrapperState extends State<BottomNavigationWrapper> {
  bool _isScrolled = false; // ← NOUVEAU
  // ...
}
```

#### **NotificationListener sur body**
```dart
body: NotificationListener<ScrollNotification>( // ← NOUVEAU
  onNotification: (ScrollNotification scrollInfo) {
    final shouldBeScrolled = scrollInfo.metrics.pixels > 0;
    if (shouldBeScrolled != _isScrolled) {
      setState(() {
        _isScrolled = shouldBeScrolled;
      });
    }
    return false;
  },
  child: RepaintBoundary(
    child: _getPageForRoute(_currentRoute),
  ),
),
```

#### **AppBar avec elevation dynamique**
```dart
AppBar _buildAppBar() {
  return AppBar(
    elevation: _isScrolled ? 2 : 0, // ← NOUVEAU
    leading: _buildAppBarLeading(),
    title: Text(_getPageTitle()),
    actions: _buildAppBarActions(),
  );
}
```

## 📊 Performance

### **Impact**
- ✅ **Minimal** : Seulement `setState` quand état change (repos ↔ scrollé)
- ✅ **Efficient** : Pas de rebuild constant, juste 2 états
- ✅ **Fluide** : Transition animée par Material

### **Optimisation**
```dart
if (shouldBeScrolled != _isScrolled) { // ← Évite setState inutiles
  setState(() {
    _isScrolled = shouldBeScrolled;
  });
}
```

Pas de `setState` à chaque pixel scrollé, uniquement au changement d'état !

## 🎯 Avantages Material Design 3

1. **Cohérence** : Toutes les pages ont le même comportement
2. **Affordance** : Utilisateur voit qu'il a scrollé (feedback visuel)
3. **Profondeur** : L'AppBar "flotte" au-dessus du contenu
4. **Surface tint** : Overlay rouge subtil renforce l'identité visuelle
5. **Standard Google** : Comme Gmail, Photos, Drive, Calendar

## ✅ Test

Pour tester l'effet :
1. Lancer l'application
2. Aller sur **Vie de l'église**, **Le Message**, **La Bible**, ou **Cantiques**
3. Scroller vers le bas
4. Observer : AppBar change légèrement de couleur + ombre apparaît
5. Scroller en haut
6. Observer : AppBar revient à l'état flat

**Résultat** : Même comportement que la page Accueil ! ✅

---

**Date de correction** : 9 octobre 2025  
**Fichier modifié** : `lib/widgets/bottom_navigation_wrapper.dart`  
**Lignes ajoutées** : ~15 lignes  
**Norme** : Material Design 3 scrolledUnderElevation  
**Statut** : ✅ Appliqué et prêt pour hot reload

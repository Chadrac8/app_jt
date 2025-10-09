# 📱 Material Design 3 - Guidelines TabBar

## ✅ Configuration MD3 appliquée

### 🎨 **Primary Tabs (recommandé pour votre app)**

Votre TabBarTheme est maintenant configuré selon MD3 :

```dart
tabBarTheme: TabBarThemeData(
  labelColor: primaryColor,              // Rouge pour tab active
  unselectedLabelColor: onSurfaceVariant, // Gris pour tabs inactives
  indicatorColor: primaryColor,          // Indicateur rouge
  dividerColor: Colors.transparent,      // Pas de divider
  overlayColor: // États hover/pressed avec primaryColor
)
```

### 📐 **Utilisation dans vos pages**

#### ✅ **Option 1 : TabBar dans AppBar.bottom (RECOMMANDÉ)**
```dart
AppBar(
  title: Text('Ma Page'),
  bottom: TabBar(
    tabs: [
      Tab(text: 'Onglet 1'),
      Tab(text: 'Onglet 2'),
    ],
  ),
)
```
**Avantages MD3 :**
- ✅ Intégration visuelle parfaite
- ✅ Surface cohérente (claire)
- ✅ Indicateur rouge sur fond clair
- ✅ Look professionnel et moderne

#### ✅ **Option 2 : TabBar dans SliverPersistentHeader**
```dart
SliverPersistentHeader(
  pinned: true,
  delegate: _SliverAppBarDelegate(
    TabBar(
      tabs: [...],
    ),
  ),
)
```
**Avantages MD3 :**
- ✅ Tabs qui restent visibles au scroll
- ✅ Animation fluide
- ✅ Fond Surface Container cohérent

#### ❌ **À ÉVITER : TabBar avec fond coloré différent**
```dart
// ❌ NE PLUS FAIRE (Material Design 2)
Container(
  color: Colors.red,
  child: TabBar(
    labelColor: Colors.white,
    indicatorColor: Colors.white,
  ),
)
```

### 🎯 **Votre configuration actuelle**

Vos pages utilisent des TabBar :
- ✅ `event_detail_page.dart` - TabBar dans SliverPersistentHeader
- ✅ `service_detail_page.dart` - TabBar dans SliverPersistentHeader  
- ✅ `services_member_view.dart` - TabBar standalone
- ✅ `service_form_view.dart` - TabBar en bottomNavigationBar

**Toutes héritent maintenant du TabBarTheme MD3 :**
- Texte actif : Rouge
- Texte inactif : Gris
- Indicateur : Rouge
- Fond : Transparent/Surface (selon contexte)

### 📊 **Comparaison MD2 vs MD3**

| Aspect | Material Design 2 | Material Design 3 |
|--------|------------------|-------------------|
| **Fond TabBar** | Rouge (primary) | Surface (clair) |
| **Label actif** | Blanc | Rouge (primary) |
| **Label inactif** | Blanc 70% | Gris (onSurfaceVariant) |
| **Indicateur** | Blanc | Rouge (primary) |
| **Intégration** | Séparée visuellement | Intégrée à l'AppBar |
| **Look** | Coloré, agressif | Épuré, professionnel |

### 🎨 **Personnalisation locale (si nécessaire)**

Si une page spécifique nécessite un style différent :

```dart
TabBar(
  // Override local du thème
  labelColor: Colors.blue,  // Couleur spécifique
  indicatorColor: Colors.blue,
  tabs: [...],
)
```

Mais **préférez toujours le thème global** pour cohérence !

### 💡 **Recommandations finales**

1. ✅ **Utilisez TabBar dans AppBar.bottom** quand possible
2. ✅ **Gardez le fond transparent ou Surface** (clair)
3. ✅ **Utilisez primary (rouge) pour indicateur et texte actif**
4. ✅ **Utilisez onSurfaceVariant (gris) pour texte inactif**
5. ✅ **Pas de divider visible** (dividerColor: transparent)
6. ✅ **États hover/pressed avec primary opacity**
7. ✅ **Typographie MD3** (14sp, semibold pour actif)

### 📱 **Exemples d'apps Google avec MD3 Tabs**

- **Google Photos** : Tabs intégrées, fond clair, indicateur bleu
- **Google Drive** : Tabs Surface, texte actif bleu, inactif gris
- **Gmail** : Primary tabs, look épuré et moderne
- **Google Calendar** : Tabs intégrées à l'AppBar Surface

### 🚀 **Résultat dans votre app**

Avec la nouvelle configuration MD3 :
- ✅ **AppBar claire** + **Tabs intégrées** = Look professionnel
- ✅ **Rouge utilisé comme accent** (indicateur + texte actif)
- ✅ **Cohérence visuelle** avec le reste de l'app
- ✅ **Conforme guidelines Google 2024**
- ✅ **Accessible** (bons contrastes)

---

**Date de mise à jour** : 9 octobre 2025  
**Norme** : Material Design 3 (2024)  
**Statut** : ✅ Appliqué dans theme.dart

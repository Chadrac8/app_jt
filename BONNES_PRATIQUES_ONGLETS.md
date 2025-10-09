# 📱 Bonnes Pratiques: Gestion des Titres d'Onglets Longs

**Date**: 9 octobre 2025  
**Contexte**: Titres trop longs dans les TabBar qui ne s'affichent pas complètement

---

## 🎯 Problème

Les titres d'onglets longs sont tronqués ou provoquent des problèmes d'affichage, nuisant à l'expérience utilisateur.

---

## ✅ Solutions Professionnelles (Par Ordre de Préférence)

### **1. 🥇 RECOMMANDÉ: Raccourcir le Texte (Best Practice)**

**Principe**: Utiliser des mots courts et concis

#### Exemples de Transformation

| ❌ Titre Long | ✅ Titre Court | Gain |
|--------------|---------------|------|
| "Événements à venir" | "Événements" | -50% |
| "Pain quotidien" | "Pain" ou "Daily" | -60% |
| "Messages et prédications" | "Messages" | -65% |
| "Requêtes de prière" | "Prières" | -60% |
| "Témoignages des fidèles" | "Témoignages" | -50% |
| "Cantiques et louanges" | "Cantiques" | -55% |

**Standards**:
- **iOS**: Max 12 caractères recommandé
- **Android**: Max 15 caractères recommandé
- **Desktop**: Max 20 caractères recommandé

**Code**:
```dart
Tab(
  text: 'Événements', // ✅ Court et clair
  icon: Icon(Icons.event),
)
```

---

### **2. 🥈 Icône + Texte Court**

**Principe**: Combiner icône + texte très court

#### Exemples

```dart
TabBar(
  tabs: [
    Tab(icon: Icon(Icons.event), text: 'Agenda'),
    Tab(icon: Icon(Icons.book), text: 'Pain'),
    Tab(icon: Icon(Icons.mic), text: 'Sermons'),
    Tab(icon: Icon(Icons.music_note), text: 'Cantiques'),
  ],
)
```

**Avantages**:
- ✅ Icône = reconnaissance visuelle rapide
- ✅ Texte court = lisible partout
- ✅ Conforme Material Design 3
- ✅ Conforme Apple HIG

**Standards**:
- **iOS**: Icône 28x28pt + texte 8 caractères max
- **Android**: Icône 24x24dp + texte 10 caractères max

---

### **3. 🥉 Icône Seule (Mode Compact)**

**Principe**: Sur mobile, utiliser uniquement l'icône

#### Implémentation Adaptative

```dart
TabBar(
  tabs: AppTheme.isMobile
      ? [
          // Mobile: Icône seule
          Tab(icon: Icon(Icons.event)),
          Tab(icon: Icon(Icons.book)),
          Tab(icon: Icon(Icons.mic)),
          Tab(icon: Icon(Icons.music_note)),
        ]
      : [
          // Desktop: Icône + texte
          Tab(icon: Icon(Icons.event), text: 'Événements'),
          Tab(icon: Icon(Icons.book), text: 'Pain quotidien'),
          Tab(icon: Icon(Icons.mic), text: 'Prédications'),
          Tab(icon: Icon(Icons.music_note), text: 'Cantiques'),
        ],
)
```

**Avantages**:
- ✅ Gain d'espace maximal
- ✅ Design épuré mobile
- ✅ Détail sur desktop

---

### **4. 🔧 Ellipsis avec Tooltip (Solution Technique)**

**Principe**: Tronquer avec "..." + tooltip au hover/tap

#### Implémentation

```dart
Tab(
  child: Tooltip(
    message: 'Événements à venir', // Texte complet
    child: Text(
      'Événements à venir',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(fontSize: 14),
    ),
  ),
)
```

**Avantages**:
- ✅ Texte complet disponible
- ✅ Pas de perte d'information

**Inconvénients**:
- ⚠️ Moins professionnel (tooltip = friction)
- ⚠️ Mobile: tap = activation tab, pas tooltip

---

### **5. 🎨 TabBar Scrollable (Si Nombreux Onglets)**

**Principe**: Rendre la TabBar horizontalement scrollable

#### Implémentation

```dart
TabBar(
  isScrollable: true, // ✅ Permet scroll horizontal
  tabs: [
    Tab(text: 'Événements à venir'),
    Tab(text: 'Pain quotidien'),
    Tab(text: 'Prédications'),
    Tab(text: 'Cantiques'),
    Tab(text: 'Témoignages'),
  ],
  // Optionnel: indicateurs de scroll
  tabAlignment: TabAlignment.start,
  padding: EdgeInsets.symmetric(horizontal: 16),
)
```

**Avantages**:
- ✅ Textes complets lisibles
- ✅ Pas de limite nombre d'onglets

**Inconvénients**:
- ⚠️ Onglets cachés = découvrabilité réduite
- ⚠️ Scroll horizontal = friction UX

**Standards**:
- **Recommandé si**: > 5 onglets OU textes > 15 caractères
- **À éviter si**: ≤ 3 onglets (tous doivent être visibles)

---

### **6. 🔀 Navigation Drawer/Menu (Alternative)**

**Principe**: Remplacer TabBar par un menu latéral

#### Quand l'utiliser?

- ✅ > 6 sections
- ✅ Titres longs obligatoires
- ✅ Navigation secondaire

```dart
Drawer(
  child: ListView(
    children: [
      ListTile(
        leading: Icon(Icons.event),
        title: Text('Événements à venir'), // ✅ Texte complet
        onTap: () => _navigateTo(0),
      ),
      ListTile(
        leading: Icon(Icons.book),
        title: Text('Pain quotidien'),
        onTap: () => _navigateTo(1),
      ),
      // ...
    ],
  ),
)
```

---

## 📊 Tableau Comparatif des Solutions

| Solution | Lisibilité | Espace | Mobile | Desktop | Professionnel |
|----------|-----------|--------|--------|---------|---------------|
| **1. Texte court** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| **2. Icône + court** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| **3. Icône seule** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ⚠️ | ⭐⭐⭐⭐ |
| **4. Ellipsis + tooltip** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⚠️ | ✅ | ⭐⭐⭐ |
| **5. Scrollable** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⚠️ | ✅ | ⭐⭐⭐ |
| **6. Drawer/Menu** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ | ⭐⭐⭐⭐ |

---

## 🎯 Recommandations par Cas d'Usage

### **Cas 1: Application Simple (2-4 Sections)**
✅ **Solution 1 ou 2** (Texte court ou Icône + texte court)

```dart
TabBar(
  tabs: [
    Tab(icon: Icon(Icons.home), text: 'Accueil'),
    Tab(icon: Icon(Icons.event), text: 'Agenda'),
    Tab(icon: Icon(Icons.person), text: 'Profil'),
  ],
)
```

### **Cas 2: Application Moyenne (5-6 Sections)**
✅ **Solution 2 ou 5** (Icône + texte OU Scrollable)

```dart
TabBar(
  isScrollable: true,
  tabs: [
    Tab(icon: Icon(Icons.event), text: 'Événements'),
    Tab(icon: Icon(Icons.book), text: 'Pain quotidien'),
    Tab(icon: Icon(Icons.mic), text: 'Prédications'),
    Tab(icon: Icon(Icons.music_note), text: 'Cantiques'),
    Tab(icon: Icon(Icons.favorite), text: 'Témoignages'),
  ],
)
```

### **Cas 3: Application Complexe (> 6 Sections)**
✅ **Solution 6** (Navigation Drawer)

---

## 🌍 Standards par Plateforme

### **iOS/macOS (Apple HIG)**

**TabBar**:
- ✅ Max **5 onglets** visibles
- ✅ Icône + texte court (12 caractères max)
- ✅ Si > 5: dernier onglet = "Plus" → liste complète
- ❌ Pas de TabBar scrollable (non-natif iOS)

**Exemple conforme iOS**:
```dart
CupertinoTabScaffold(
  tabBar: CupertinoTabBar(
    items: [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Accueil'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.calendar), label: 'Agenda'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.book), label: 'Pain'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.mic), label: 'Sermons'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.ellipsis), label: 'Plus'),
    ],
  ),
)
```

### **Android (Material Design 3)**

**TabBar**:
- ✅ Max **6 onglets** recommandés
- ✅ Icône + texte court (15 caractères max)
- ✅ Scrollable autorisé si > 6 onglets
- ✅ Icône seule OK si contrainte d'espace

**Exemple conforme MD3**:
```dart
TabBar(
  isScrollable: true,
  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  tabs: [
    Tab(icon: Icon(Icons.event), text: 'Événements'),
    Tab(icon: Icon(Icons.book), text: 'Pain'),
    Tab(icon: Icon(Icons.mic), text: 'Messages'),
    Tab(icon: Icon(Icons.music_note), text: 'Cantiques'),
  ],
)
```

---

## 💡 Exemples d'Applications Professionnelles

### **YouTube Mobile**
- ✅ 5 onglets: Accueil, Shorts, +, Abonnements, Bibliothèque
- ✅ Icône + texte très court (< 12 car.)

### **Spotify**
- ✅ 3 onglets: Accueil, Rechercher, Bibliothèque
- ✅ Icône + texte court

### **Gmail**
- ✅ Scrollable horizontal pour labels longs
- ✅ "Principal", "Réseaux sociaux", "Promotions"

### **Instagram**
- ✅ Icônes seules (5 onglets)
- ✅ Pas de texte (reconnaissance par icône)

---

## 🎨 Code Adaptatif Recommandé

### **Solution Professionnelle Complète**

```dart
class AdaptiveTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Détecter si mobile ou desktop
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return TabBar(
      isScrollable: isMobile ? false : true, // Fixed mobile, scroll desktop
      labelPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      tabs: [
        // Onglet 1
        _buildTab(
          icon: Icons.event,
          shortText: 'Agenda',
          fullText: 'Événements à venir',
          isMobile: isMobile,
        ),
        // Onglet 2
        _buildTab(
          icon: Icons.book,
          shortText: 'Pain',
          fullText: 'Pain quotidien',
          isMobile: isMobile,
        ),
        // Onglet 3
        _buildTab(
          icon: Icons.mic,
          shortText: 'Messages',
          fullText: 'Prédications',
          isMobile: isMobile,
        ),
        // Onglet 4
        _buildTab(
          icon: Icons.music_note,
          shortText: 'Cantiques',
          fullText: 'Cantiques',
          isMobile: isMobile,
        ),
      ],
    );
  }
  
  Widget _buildTab({
    required IconData icon,
    required String shortText,
    required String fullText,
    required bool isMobile,
  }) {
    if (isMobile) {
      // Mobile: Icône + texte court
      return Tab(
        icon: Icon(icon, size: 24),
        child: Text(
          shortText,
          style: TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    } else {
      // Desktop: Icône + texte complet (avec ellipsis si besoin)
      return Tab(
        icon: Icon(icon, size: 24),
        child: Text(
          fullText,
          style: TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }
  }
}
```

---

## 🚫 À ÉVITER (Anti-Patterns)

### ❌ **Texte très petit**
```dart
Tab(text: 'Événements à venir', style: TextStyle(fontSize: 8)) // ❌ Illisible
```

### ❌ **Texte sur 2 lignes**
```dart
Tab(
  child: Text(
    'Événements\nà venir', // ❌ Prend trop de hauteur
    textAlign: TextAlign.center,
  ),
)
```

### ❌ **Abréviations cryptiques**
```dart
Tab(text: 'Evt.') // ❌ Pas clair
Tab(text: 'Prd.') // ❌ Incompréhensible
```

### ❌ **Trop d'onglets non-scrollables**
```dart
TabBar(
  isScrollable: false, // ❌ 7 onglets = texte écrasé
  tabs: List.generate(7, (i) => Tab(text: 'Onglet $i')),
)
```

---

## ✅ Checklist de Validation

Avant de finaliser vos onglets, vérifiez :

- [ ] ✅ Texte ≤ 15 caractères sur mobile
- [ ] ✅ Icône présente pour reconnaissance visuelle
- [ ] ✅ Tous les onglets visibles sans scroll (≤ 5 onglets)
- [ ] ✅ Texte lisible en un coup d'œil
- [ ] ✅ Pas d'abréviations cryptiques
- [ ] ✅ Testé sur iPhone SE (petit écran)
- [ ] ✅ Testé sur iPad (grand écran)
- [ ] ✅ Dark mode: texte lisible
- [ ] ✅ Indicateur de sélection visible

---

## 🎯 Recommandation Finale

**Pour votre application** (Jubilé Tabernacle) :

### **Option A: Texte Court (Recommandé)**
```dart
TabBar(
  tabs: [
    Tab(icon: Icon(Icons.event), text: 'Agenda'),
    Tab(icon: Icon(Icons.book), text: 'Pain'),
    Tab(icon: Icon(Icons.mic), text: 'Messages'),
    Tab(icon: Icon(Icons.music_note), text: 'Cantiques'),
  ],
)
```

### **Option B: Adaptatif Mobile/Desktop**
```dart
TabBar(
  tabs: AppTheme.isMobile
      ? [
          Tab(icon: Icon(Icons.event), text: 'Agenda'),
          Tab(icon: Icon(Icons.book), text: 'Pain'),
          Tab(icon: Icon(Icons.mic), text: 'Sermons'),
          Tab(icon: Icon(Icons.music_note), text: 'Chants'),
        ]
      : [
          Tab(icon: Icon(Icons.event), text: 'Événements'),
          Tab(icon: Icon(Icons.book), text: 'Pain quotidien'),
          Tab(icon: Icon(Icons.mic), text: 'Prédications'),
          Tab(icon: Icon(Icons.music_note), text: 'Cantiques'),
        ],
)
```

---

## 📚 Ressources Officielles

- [Material Design 3 - Tabs](https://m3.material.io/components/tabs/overview)
- [Apple HIG - Tab Bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Flutter TabBar Documentation](https://api.flutter.dev/flutter/material/TabBar-class.html)

---

**Conclusion**: La **solution la plus professionnelle** est de **raccourcir le texte** (Solution 1) ou d'utiliser **Icône + texte court** (Solution 2). Ces approches sont universellement reconnues et offrent la meilleure expérience utilisateur.

---

**Auteur**: GitHub Copilot  
**Date**: 9 octobre 2025

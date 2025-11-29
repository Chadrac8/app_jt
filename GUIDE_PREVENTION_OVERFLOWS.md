# Guide de Prévention des Overflows - Application Jubilé Tabernacle

## 🎯 Objectif
Ce guide garantit qu'aucun overflow de texte n'apparaisse sur Android ou iOS dans l'application.

## ✅ Règles Obligatoires

### 1. **TOUJOURS utiliser overflow + maxLines dans les Text**

❌ **MAUVAIS** :
```dart
Text('Mon texte qui peut être long')
```

✅ **BON** :
```dart
Text(
  'Mon texte qui peut être long',
  overflow: TextOverflow.ellipsis,
  maxLines: 1, // ou 2, 3 selon le contexte
)
```

### 2. **TOUJOURS utiliser Flexible dans les Row avec texte**

❌ **MAUVAIS** :
```dart
Row(
  children: [
    Icon(Icons.star),
    Text('Texte qui peut déborder'),
  ],
)
```

✅ **BON** :
```dart
Row(
  children: [
    Icon(Icons.star),
    const SizedBox(width: 4),
    Flexible(
      child: Text(
        'Texte qui peut déborder',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ],
)
```

### 3. **TOUJOURS adapter les tailles iOS/Android**

❌ **MAUVAIS** :
```dart
Text(
  'Mon texte',
  style: TextStyle(fontSize: 14),
)
```

✅ **BON** :
```dart
Text(
  'Mon texte',
  style: TextStyle(
    fontSize: AppTheme.isApplePlatform ? 14 : 13,
    height: 1.2,
    letterSpacing: AppTheme.isApplePlatform ? -0.1 : -0.2,
  ),
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)
```

### 4. **Utiliser les helpers du AppTheme**

```dart
// Pour les boutons avec icône + texte
TextButton(
  child: AppTheme.adaptiveButtonContent(
    label: 'Voir plus',
    icon: Icons.arrow_forward,
    iconAfterText: true,
  ),
)

// Pour les Chip labels
Chip(
  label: AppTheme.adaptiveChipLabel('Mon label'),
)

// Pour les Tabs
TabBar(
  tabs: [
    AppTheme.adaptiveTab(text: 'Accueil', icon: Icons.home),
  ],
)

// Pour les FilterChip
AppTheme.adaptiveFilterChip(
  label: 'Filtre',
  selected: true,
  onSelected: (val) {},
)
```

## 📋 Checklist Avant Commit

Avant de commiter du code avec des widgets visuels, vérifier :

- [ ] Tous les `Text` ont `overflow` et `maxLines`
- [ ] Tous les `Row` avec texte utilisent `Flexible` ou `Expanded`
- [ ] Tous les `Chip`, `FilterChip`, `ChoiceChip` ont des labels avec overflow
- [ ] Les tailles de police sont adaptées iOS/Android (`AppTheme.isApplePlatform`)
- [ ] Les padding sont réduits sur Android si nécessaire
- [ ] Les `letterSpacing` sont négatifs pour condenser le texte
- [ ] Les `height: 1.2` sont ajoutés pour un meilleur espacement

## 🔍 Zones Critiques à Surveiller

### Cartes (Cards)
- Header avec badges (type, catégorie, status)
- Titres (max 2 lignes)
- Contenu (max 3-4 lignes)
- Row auteur + date
- Row des actions (boutons)

### Boutons
- TextButton/ElevatedButton avec icône + texte
- Boutons "Voir plus", "En savoir plus", etc.
- Actions dans les dialogs

### Chips
- FilterChip avec filtres actifs
- ChoiceChip avec options
- Chip avec tags ou catégories

### Navigation
- BottomNavigationBar labels
- TabBar tabs
- Drawer items

## 🛠️ Commandes de Vérification

```bash
# Rechercher les Text sans overflow
grep -r "Text(" lib/ --include="*.dart" | grep -v "overflow"

# Rechercher les Row suspects
grep -r "Row(" lib/ --include="*.dart" -A 5 | grep "Text("

# Rechercher les Chip sans overflow
grep -r "label: Text(" lib/ --include="*.dart" | grep -v "overflow"
```

## 📱 Tests Obligatoires

### Avant chaque release :
1. Tester sur Android avec écran **petit** (< 5.5 pouces)
2. Tester avec **textes longs** (noms, titres, descriptions)
3. Vérifier en **mode paysage**
4. Tester avec **police système agrandie** (paramètres accessibilité)

### Zones à tester en priorité :
- ✅ Cartes de prières/témoignages
- ✅ Onglet Sermons (cards + filtres)
- ✅ Onglet Offrandes (boutons d'action)
- ✅ Navigation bottom + tabs
- ✅ Dialogs et formulaires
- ✅ Listes avec badges/chips

## 🚨 En Cas de Réclamation Client

Si un client signale un overflow :

1. **Localiser** : Noter exactement où (page, widget, conditions)
2. **Reproduire** : Tester sur Android avec petit écran
3. **Identifier** : Chercher le Row ou Text sans overflow handling
4. **Corriger** : Appliquer les règles ci-dessus
5. **Tester** : Vérifier sur plusieurs tailles d'écran
6. **Documenter** : Ajouter un test case si besoin

## 📝 Exemples de Corrections

### Exemple 1 : Prayer Card Header
```dart
// AVANT (overflow)
Row(
  children: [
    Container(
      child: Row(
        children: [
          Icon(Icons.star, size: 16),
          Text('Témoignage'),
        ],
      ),
    ),
    Container(
      child: Text('Catégorie très longue'),
    ),
  ],
)

// APRÈS (pas d'overflow)
Row(
  children: [
    Flexible(
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Témoignage',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(width: 6),
    Flexible(
      child: Container(
        child: Text(
          'Catégorie très longue',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ),
  ],
)
```

### Exemple 2 : Bouton avec texte long
```dart
// AVANT (overflow)
ElevatedButton.icon(
  icon: Icon(Icons.download),
  label: Text('Télécharger le document PDF'),
)

// APRÈS (pas d'overflow)
ElevatedButton.icon(
  icon: Icon(Icons.download, size: 18),
  label: Flexible(
    child: Text(
      'Télécharger le document PDF',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(
        fontSize: AppTheme.isApplePlatform ? 14 : 13,
        height: 1.2,
      ),
    ),
  ),
)
```

## 🎨 Tailles de Police Recommandées

| Élément | iOS | Android | Remarques |
|---------|-----|---------|-----------|
| Titre principal | 20px | 18px | maxLines: 2 |
| Titre carte | 18px | 17px | maxLines: 2 |
| Titre section | 16px | 15px | maxLines: 1 |
| Corps de texte | 16px | 15px | maxLines: 3-4 |
| Label bouton | 14px | 13px | maxLines: 1 |
| Label chip | 13px | 11.5px | maxLines: 1 |
| Label nav | 12px | 11px | maxLines: 1 |
| Metadata | 12px | 11px | maxLines: 1 |

## ✨ Nouveautés Theme

Le fichier `lib/theme.dart` contient maintenant :
- ✅ `ChipTheme` avec `WidgetStateTextStyle` adaptatif
- ✅ `TabBarTheme` avec tailles iOS/Android
- ✅ `BottomNavigationBarTheme` adaptatif
- ✅ `TextTheme` avec `labelLarge/Medium/Small` adaptatifs
- ✅ Helpers : `adaptiveTab()`, `adaptiveFilterChip()`, `adaptiveChoiceChip()`, `adaptiveButtonContent()`, `adaptiveChipLabel()`

## 🔗 Fichiers Corrigés

Liste complète des fichiers avec corrections anti-overflow :
1. `lib/theme.dart` - Thèmes adaptatifs
2. `lib/widgets/prayer_card.dart` - Cartes de prière
3. `lib/widgets/prayer_search_filter_bar.dart` - Filtres
4. `lib/widgets/prayer_request_card.dart` - Cartes de requête
5. `lib/widgets/service_calendar_view.dart` - Calendrier
6. `lib/widgets/song_search_filter_bar.dart` - Filtres cantiques
7. `lib/widgets/task_search_filter_bar.dart` - Filtres tâches
8. `lib/widgets/service_search_filter_bar.dart` - Filtres services
9. `lib/widgets/page_components/component_renderer.dart` - Composants de page
10. `lib/modules/vie_eglise/widgets/sermons_tab.dart` - Onglet sermons
11. `lib/modules/vie_eglise/widgets/offrandes_tab.dart` - Onglet offrandes
12. `lib/pages/member_dashboard_page.dart` - Dashboard membre
13. `lib/shared/widgets/expandable_text.dart` - Texte expandable
14. `lib/widgets/bottom_navigation_wrapper.dart` - Navigation

---

**Version** : 1.0  
**Dernière mise à jour** : 29 novembre 2025  
**Responsable** : Équipe Dev Jubilé Tabernacle

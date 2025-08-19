# Guide de la Palette de Couleurs Raffinée - Jubilé Tabernacle

## Vue d'ensemble
Cette palette raffinée met l'accent sur l'expérience utilisateur avec des états interactifs clairement définis, offrant une interface moderne et intuitive.

## Couleurs Principales avec États Interactifs

### 🔴 Rouge Bordeaux - Couleur Signature
- **Base** : `#850606` - Rouge bordeaux profond et spirituel
- **Hover/Focus** : `#A50707` - État de survol et focus
- **Active/Pressed** : `#5C0404` - État actif et pressed

### 🎨 Palette de Fond
- **Background** : `#F8F9FA` - Fond principal doux et moderne
- **Surface** : `#E9ECEF` - Surfaces des cartes et conteneurs

### 📝 Hiérarchie Textuelle
- **Text Primary** : `#212529` - Texte principal avec excellent contraste
- **Text Secondary** : `#6C757D` - Texte secondaire et métadonnées

## Applications par État

### 🎯 États Interactifs des Boutons
```dart
// Bouton normal
backgroundColor: #850606

// Au survol (hover)
backgroundColor: #A50707

// Lors du clic (pressed)
backgroundColor: #5C0404
```

### 📋 Champs de Saisie
- **Fond** : `#F8F9FA` (Background)
- **Bordure normale** : `#6C757D` (Text Secondary)
- **Bordure focus** : `#A50707` (Hover)
- **Bordure erreur** : `#F44336` (Error)

### 🃏 Cartes et Conteneurs
- **Fond des cartes** : `#E9ECEF` (Surface)
- **Ombre** : `#6C757D` avec transparence
- **Bordure des chips** : `#6C757D` (Text Secondary)

## Navigation et Interface

### 📱 Bottom Navigation
- **Fond** : `#E9ECEF` (Surface)
- **Élément sélectionné** : `#850606` (Primary)
- **Éléments non sélectionnés** : `#6C757D` (Text Secondary)

### 🎈 Floating Action Button
- **Fond** : `#6C757D` (Text Secondary)
- **Icône** : `#FFFFFF` (Blanc)

## Contexte d'Usage par Rôle

### 👥 Système de Rôles
- **Pasteur** : `#850606` (Primary) - Autorité spirituelle
- **Leader** : `#A50707` (Hover) - Leadership actif
- **Membre** : `#6C757D` (Text Secondary) - Participation

### 📊 Types de Groupes
- **Prière/Louange** : `#850606` (Primary) - Spiritualité
- **Jeunesse** : `#A50707` (Hover) - Dynamisme
- **Leadership** : `#5C0404` (Active) - Responsabilité
- **Étude Biblique** : `#212529` (Text Primary) - Sérieux

## Mode Sombre Adapté

### 🌙 Couleurs Inversées
- **Fond** : `#1A1D20` - Fond très sombre
- **Surface** : `#212529` - Surfaces sombres
- **Primary sombre** : `#6C757D` (Text Secondary devient primaire)
- **Secondary sombre** : `#850606` (Primary reste identique)

## Avantages de cette Palette

### ✨ Expérience Utilisateur
- **États visuels clairs** pour toutes les interactions
- **Feedback immédiat** sur les actions utilisateur
- **Hiérarchie intuitive** de l'information

### 🎨 Design Cohérent
- **Palette restreinte** mais expressive
- **Transitions fluides** entre les états
- **Contraste optimal** pour l'accessibilité

### 🔧 Facilité de Maintenance
- **Couleurs nommées** selon leur usage
- **États prédéfinis** pour tous les composants
- **Documentation claire** des applications

## Code d'Implémentation

### Couleurs de Base
```dart
static const Color primaryColor = Color(0xFF850606);
static const Color primaryHover = Color(0xFFA50707);
static const Color primaryActive = Color(0xFF5C0404);
static const Color backgroundColor = Color(0xFFF8F9FA);
static const Color surfaceColor = Color(0xFFE9ECEF);
static const Color textSecondaryColor = Color(0xFF6C757D);
```

### États Interactifs
```dart
MaterialStateProperty.resolveWith<Color?>((states) {
  if (states.contains(MaterialState.pressed)) return primaryActive;
  if (states.contains(MaterialState.hovered)) return primaryHover;
  return primaryColor;
})
```

## Guidelines d'Usage

### ✅ À Faire
- Utiliser les états interactifs pour tous les éléments cliquables
- Respecter la hiérarchie textuelle définie
- Appliquer les couleurs de contexte selon les rôles

### ❌ À Éviter
- Mélanger les couleurs avec d'autres palettes
- Ignorer les états hover/active sur les éléments interactifs
- Utiliser des couleurs non définies dans le système

Cette palette raffinée offre une expérience utilisateur moderne et professionnelle tout en conservant l'identité spirituelle forte de Jubilé Tabernacle ! 🎉

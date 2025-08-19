# Guide d'utilisation du composant Container Grid

## Vue d'ensemble

Le composant **Container Grid** est un conteneur avancé qui permet d'organiser d'autres composants du module "Constructeur des pages" en disposition de grille. Il offre une flexibilité complète pour créer des mises en page structurées et esthétiques.

## Fonctionnalités

### ✅ Fonctionnalités implémentées

1. **Support de tous les composants** : Peut contenir tous les types de composants du page builder
2. **Configuration flexible** : Nombre de colonnes de 1 à 6
3. **Espacement personnalisable** : Contrôle précis des espacements vertical et horizontal
4. **Ratio d'aspect ajustable** : Contrôle de la proportion hauteur/largeur des éléments
5. **Apparence personnalisable** : Couleurs, bordures, coins arrondis, élévation
6. **Hauteur adaptative** : Hauteur automatique ou fixe selon les besoins
7. **Éditeur avancé** : Interface dédiée pour la configuration complète
8. **Réorganisation** : Possibilité de réordonner les composants par glisser-déposer
9. **Prévisualisation** : Aperçu en temps réel des modifications

### 📋 Composants supportés

**Tous les types de composants peuvent être ajoutés dans un Container Grid :**

**Contenu textuel :**
- Texte, Verset biblique, Bannière, Citation

**Médias :**
- Image, Vidéo, Audio

**Interactif :**
- Bouton, HTML, WebView

**Organisation :**
- Liste, Carte, Google Map, Groupes, Événements, Mur de prière

**Composants Grid :**
- Carte Grid, Statistique Grid, Icône + Texte Grid, Image Card Grid, Progression Grid

## Configuration

### 1. Configuration de la grille

**Nombre de colonnes :** 1 à 6 colonnes
- Contrôle via curseur dans l'éditeur
- Ajustement dynamique de la largeur des éléments

**Ratio hauteur/largeur :** 0.5 à 2.0
- 1.0 = carré parfait
- < 1.0 = plus large que haut
- > 1.0 = plus haut que large

### 2. Espacement

**Espacement vertical :** 0 à 50px entre les lignes
**Espacement horizontal :** 0 à 50px entre les colonnes
**Padding interne :** 0 à 50px autour du contenu

### 3. Apparence

**Couleur d'arrière-plan :** Format hexadécimal (#FFFFFF)
**Couleur de bordure :** Format hexadécimal (#E0E0E0)
**Épaisseur de bordure :** En pixels
**Rayon des coins :** 0 à 30px pour les coins arrondis
**Élévation :** 0 à 10 pour l'effet d'ombre

### 4. Dimensions

**Hauteur automatique :** S'adapte au contenu (recommandé)
**Hauteur fixe :** 200 à 1000px avec défilement si nécessaire

## Utilisation

### 1. Ajouter un Container Grid

1. Dans le **Constructeur des pages**, cliquez sur "Ajouter un composant"
2. Dans la catégorie **Organisation**, sélectionnez **Container Grid**
3. Le composant est créé avec une configuration par défaut (2 colonnes)

### 2. Configurer le Container Grid

#### Option 1 : Configuration rapide
1. Cliquez sur l'icône d'édition du composant
2. Modifiez le nombre de colonnes directement
3. Sauvegardez

#### Option 2 : Éditeur avancé
1. Cliquez sur l'icône d'édition du composant
2. Cliquez sur "Ouvrir l'éditeur avancé"
3. Utilisez les onglets **Configuration** et **Composants**

### 3. Ajouter des composants dans la grille

1. Dans l'éditeur avancé, allez à l'onglet **Composants**
2. Cliquez sur "Ajouter" pour ajouter un nouveau composant
3. Sélectionnez le type de composant désiré
4. Configurez le composant selon vos besoins
5. Répétez pour ajouter d'autres composants

### 4. Gérer les composants

**Modifier un composant :**
- Cliquez sur l'icône "Modifier" à côté du composant

**Supprimer un composant :**
- Cliquez sur l'icône "Supprimer" à côté du composant

**Réorganiser les composants :**
- Utilisez l'icône de glissement pour déplacer les composants

## Structure des données

Le composant Container Grid stocke ses données dans le format suivant :

```json
{
  "columns": 2,
  "mainAxisSpacing": 12.0,
  "crossAxisSpacing": 12.0,
  "childAspectRatio": 1.0,
  "padding": 16.0,
  "autoHeight": true,
  "maxHeight": 400.0
}
```

Le style est stocké séparément :

```json
{
  "backgroundColor": "#FFFFFF",
  "borderColor": "#E0E0E0",
  "borderWidth": 1.0,
  "borderRadius": 8.0,
  "elevation": 0.0
}
```

## Cas d'usage

### 1. Tableau de bord

```
+------------------+------------------+------------------+
|   Statistique    |   Statistique    |   Statistique    |
|    Membres       |   Événements     |    Finances      |
+------------------+------------------+------------------+
|        Carte de bienvenue          |   Progression    |
|                                     |    Objectifs     |
+-------------------------------------+------------------+
```

### 2. Galerie de services

```
+------------------+------------------+
|   Icône + Texte  |   Icône + Texte  |
|     Culte        |      Prière      |
+------------------+------------------+
|   Icône + Texte  |   Icône + Texte  |
|     Jeunesse     |    Formation     |
+------------------+------------------+
```

### 3. Section d'accueil

```
+-------------------------------------+
|          Bannière de bienvenue      |
+------------------+------------------+
|      Image       |      Texte       |
|    d'accueil     |   de présentation|
+------------------+------------------+
|              Bouton d'action        |
+-------------------------------------+
```

## Bonnes pratiques

### 1. Choix du nombre de colonnes
- **Mobile :** 1-2 colonnes maximum
- **Tablette :** 2-3 colonnes
- **Desktop :** 3-4 colonnes (parfois plus)

### 2. Cohérence visuelle
- Utilisez des composants de même famille (ex: tous Grid Card)
- Maintenez un ratio d'aspect cohérent
- Harmonisez les couleurs et styles

### 3. Hiérarchie de l'information
- Placez les éléments importants en haut à gauche
- Utilisez la taille et les couleurs pour créer de la hiérarchie
- Groupez les éléments liés

### 4. Performance
- Évitez trop de composants dans une seule grille (max 12-15)
- Utilisez la hauteur fixe pour les grilles très longues
- Optimisez les images pour un chargement rapide

### 5. Responsivité
- Testez sur différentes tailles d'écran
- Ajustez le ratio d'aspect selon le contenu
- Considérez l'usage mobile first

## Fichiers impliqués

- `lib/widgets/grid_container_builder.dart` : Éditeur avancé du Container Grid
- `lib/widgets/page_components/component_renderer.dart` : Rendu du Container Grid
- `lib/widgets/page_components/component_editor.dart` : Éditeur simple intégré
- `lib/pages/page_builder_page.dart` : Configuration par défaut

## Dépannage

### Problème : Les composants ne s'affichent pas
**Solution :** Vérifiez que les composants ont été ajoutés via l'éditeur avancé

### Problème : La grille est trop petite
**Solution :** Ajustez le ratio d'aspect ou activez la hauteur automatique

### Problème : Les espacements sont incorrects
**Solution :** Utilisez l'éditeur avancé pour ajuster précisément les espacements

### Problème : Performance lente
**Solution :** Réduisez le nombre de composants ou utilisez une hauteur fixe avec défilement

## Test et validation

Pour tester le composant Container Grid :
1. Créez une page avec un composant Container Grid
2. Ajoutez différents types de composants
3. Testez différentes configurations de colonnes
4. Vérifiez le rendu en mode prévisualisation
5. Testez la responsivité sur différents appareils

Le composant Container Grid est maintenant entièrement fonctionnel et prêt pour une utilisation en production ! 🎉

## Exemple complet

Voici un exemple de Container Grid configuré avec 6 composants :

```dart
PageComponent(
  type: 'grid_container',
  data: {
    'columns': 3,
    'mainAxisSpacing': 16.0,
    'crossAxisSpacing': 16.0,
    'childAspectRatio': 1.0,
    'padding': 20.0,
    'autoHeight': true,
  },
  styling: {
    'backgroundColor': '#F5F5F5',
    'borderColor': '#E0E0E0',
    'borderWidth': 2.0,
    'borderRadius': 12.0,
    'elevation': 4.0,
  },
  children: [
    // Vos composants ici...
  ],
)
```

Ce composant offre une solution complète pour créer des mises en page sophistiquées et professionnelles ! 🚀

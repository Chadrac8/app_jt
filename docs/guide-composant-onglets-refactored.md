# Guide du Composant Onglets - Version Refactorisée

## Vue d'ensemble

Le composant "Onglets" permet de créer des interfaces organisées avec plusieurs onglets, chacun pouvant contenir différents composants. Cette version refactorisée offre une interface d'édition moderne et intuitive avec deux onglets principaux : "Configuration" et "Composants".

## Nouvelles Fonctionnalités de l'Éditeur Refactorisé

### Interface à Deux Onglets

L'éditeur a été complètement refactorisé pour adopter une interface similaire au Container Grid avec deux onglets principaux :

#### 1. Onglet "Configuration"
- **Configuration générale** : Position des onglets, affichage des icônes, style
- **Style et apparence** : Couleurs de fond et d'indicateur avec prévisualisation
- **Gestion des onglets** : Liste des onglets avec ajout, modification et suppression

#### 2. Onglet "Composants"
- **Sélecteur d'onglet** : Dropdown pour choisir l'onglet à éditer
- **Gestion des composants** : Ajout, modification, suppression et réorganisation
- **Prévisualisation** : Affichage en temps réel du contenu de l'onglet sélectionné

### Améliorations Apportées

1. **Interface unifiée** : Design cohérent avec les autres éditeurs de composants
2. **Meilleure organisation** : Séparation claire entre configuration et contenu
3. **Gestion simplifiée** : Interface plus intuitive pour la gestion des composants
4. **Prévisualisation améliorée** : Feedback visuel en temps réel
5. **Sauvegarde optimisée** : Gestion d'état améliorée et sauvegarde fiable

## Configuration Disponible

### Position des Onglets
- **En haut** (par défaut) : Onglets au-dessus du contenu
- **En bas** : Onglets sous le contenu
- **À gauche** : Onglets à gauche du contenu
- **À droite** : Onglets à droite du contenu

### Style des Onglets
- **Material** (par défaut) : Style Material Design
- **Cupertino** : Style iOS
- **Personnalisé** : Style customisable

### Options d'Affichage
- **Afficher les icônes** : Activer/désactiver l'affichage des icônes
- **Couleur de fond** : Personnaliser la couleur de fond des onglets
- **Couleur de l'indicateur** : Personnaliser la couleur de l'indicateur actif

## Gestion des Onglets

### Ajouter un Onglet
1. Dans l'onglet "Configuration", cliquez sur "Ajouter" dans la section "Liste des onglets"
2. Un nouvel onglet sera créé avec un titre par défaut
3. Utilisez le bouton "Modifier" pour personnaliser le titre et l'icône

### Modifier un Onglet
1. Cliquez sur l'icône "Modifier" à côté de l'onglet souhaité
2. Changez le titre dans le champ de texte
3. Sélectionnez une nouvelle icône dans la grille
4. Cliquez sur "Enregistrer"

### Supprimer un Onglet
1. Cliquez sur l'icône "Supprimer" (rouge) à côté de l'onglet
2. Confirmez la suppression
3. **Note** : Vous devez avoir au moins un onglet

## Gestion des Composants

### Ajouter un Composant à un Onglet
1. Allez dans l'onglet "Composants"
2. Sélectionnez l'onglet cible dans le dropdown
3. Cliquez sur "Ajouter composant"
4. Choisissez le type de composant dans le sélecteur
5. Configurez le composant dans l'éditeur qui s'ouvre

### Modifier un Composant
1. Dans la liste des composants, cliquez sur l'icône "Modifier"
2. L'éditeur du composant s'ouvrira avec ses paramètres
3. Modifiez les propriétés selon vos besoins
4. Sauvegardez les modifications

### Réorganiser les Composants
1. Utilisez la poignée de glisser-déposer (icône avec les barres)
2. Faites glisser le composant vers sa nouvelle position
3. L'ordre sera automatiquement mis à jour

### Supprimer un Composant
1. Cliquez sur l'icône "Supprimer" (rouge) du composant
2. Le composant sera immédiatement supprimé

## Types de Composants Disponibles

Tous les composants du module Page Builder sont disponibles dans les onglets :

### Contenu Textuel
- **Texte** : Paragraphes avec formatage
- **Verset biblique** : Citations avec références
- **Bannière** : Messages d'annonce
- **Citation** : Citations avec auteur

### Médias
- **Image** : Photos et illustrations
- **Vidéo** : Vidéos YouTube ou fichiers
- **Audio** : Fichiers audio et musique

### Interactif
- **Bouton** : Boutons d'action cliquables
- **HTML** : Code HTML personnalisé
- **WebView** : Pages web intégrées

### Organisation
- **Liste** : Listes à puces ou numérotées
- **Container Grid** : Grilles de composants
- **Carte** : Cartes géographiques
- **Google Map** : Cartes Google avec adresses
- **Groupes** : Gestion des groupes d'utilisateurs
- **Événements** : Calendriers et événements

## Utilisation dans une Page

### Code d'Exemple

```dart
// Créer un composant onglets
final tabsComponent = PageComponent(
  id: 'tabs_001',
  type: 'tabs',
  name: 'Onglets principaux',
  data: {
    'tabs': [
      {
        'id': 'tab_1',
        'title': 'Accueil',
        'icon': Icons.home.codePoint,
        'components': [
          // Liste des composants de l'onglet
        ]
      }
    ],
    'tabPosition': 'top',
    'showIcons': true,
    'tabStyle': 'material',
    'height': 400.0,
  },
  styling: {
    'backgroundColor': '#FFFFFF',
    'indicatorColor': '#1976D2',
  },
);

// Utiliser dans un widget
CustomTabsWidget(
  tabs: tabsComponent.data['tabs'],
  tabPosition: tabsComponent.data['tabPosition'],
  showIcons: tabsComponent.data['showIcons'],
  tabStyle: tabsComponent.data['tabStyle'],
  backgroundColor: tabsComponent.styling['backgroundColor'],
  indicatorColor: tabsComponent.styling['indicatorColor'],
  height: tabsComponent.data['height'],
)
```

## Intégration avec le Page Builder

### Ajouter des Onglets à une Page
1. Dans le Page Builder, cliquez sur "Ajouter un composant"
2. Sélectionnez "Onglets" dans la catégorie "Organisation"
3. Le composant sera ajouté avec un onglet par défaut
4. Utilisez l'éditeur pour configurer vos onglets et ajouter du contenu

### Édition Avancée
1. Cliquez sur le bouton "Éditer" du composant onglets dans la liste
2. L'éditeur refactorisé s'ouvrira avec les deux onglets
3. Configurez le style dans l'onglet "Configuration"
4. Gérez le contenu dans l'onglet "Composants"
5. Sauvegardez pour appliquer les modifications

## Conseils d'Utilisation

### Bonnes Pratiques
1. **Titres clairs** : Utilisez des titres courts et descriptifs
2. **Icônes cohérentes** : Choisissez des icônes qui représentent le contenu
3. **Contenu équilibré** : Évitez les onglets trop chargés
4. **Navigation intuitive** : Organisez logiquement vos onglets

### Exemples d'Usage
- **Page d'accueil** : Présentation, actualités, événements
- **Centre de ressources** : Documents, vidéos, liens
- **Profil utilisateur** : Informations, préférences, historique
- **Tableau de bord** : Statistiques, tâches, notifications

## Dépannage

### Problèmes Courants

**L'onglet ne s'affiche pas :**
- Vérifiez que l'onglet contient au moins un composant
- Assurez-vous que la hauteur est définie

**Erreur de sauvegarde :**
- Vérifiez que tous les onglets ont un titre valide
- Assurez-vous qu'il reste au moins un onglet

**Composants qui ne s'affichent pas :**
- Vérifiez la configuration de chaque composant
- Assurez-vous que les données requises sont présentes

### Support
Pour toute question ou problème, consultez la documentation technique ou contactez l'équipe de développement.

## Historique des Versions

### Version Refactorisée (Actuelle)
- ✅ Interface à deux onglets (Configuration/Composants)
- ✅ Design unifié avec le Container Grid
- ✅ Gestion des composants simplifiée
- ✅ Prévisualisation en temps réel
- ✅ Sauvegarde optimisée

### Version Précédente
- Interface en panneau latéral
- Configuration et contenu mélangés
- Gestion moins intuitive

# Guide d'utilisation du composant Onglets

## Vue d'ensemble

Le composant **Onglets** permet de créer une interface à onglets pour organiser le contenu en sous-pages. Chaque onglet peut contenir tous les autres composants disponibles dans le module "Constructeur des pages".

## Fonctionnalités

### ✅ Fonctionnalités implémentées

1. **Création d'onglets** : Ajout et suppression d'onglets
2. **Configuration des onglets** : Personnalisation du titre et de l'icône de chaque onglet
3. **Position des onglets** : Placement en haut, bas, gauche ou droite
4. **Icônes** : Possibilité d'afficher ou masquer les icônes des onglets
5. **Styles** : Style Material avec couleurs personnalisables
6. **Tous les composants disponibles** : Chaque onglet peut contenir tous les types de composants du page builder
7. **Réorganisation** : Possibilité de réorganiser les composants dans chaque onglet
8. **Hauteur configurable** : Définition de la hauteur du composant

### 📋 Composants disponibles dans les onglets

**Contenu textuel :**
- Texte
- Verset biblique  
- Bannière
- Citation

**Médias :**
- Image
- Vidéo
- Audio

**Interactif :**
- Bouton
- HTML
- WebView

**Organisation :**
- Liste
- Container Grid
- Carte
- Google Map
- Groupes
- Événements

## Utilisation

### 1. Ajouter un composant Onglets

1. Dans le **Constructeur des pages**, cliquez sur "Ajouter un composant"
2. Dans la catégorie **Organisation**, sélectionnez **Onglets**
3. Le composant est créé avec 2 onglets par défaut

### 2. Configurer les onglets

1. Cliquez sur l'icône d'édition du composant Onglets
2. Dans l'éditeur d'onglets :
   - **Panneau de configuration** (gauche) : Paramètres généraux
   - **Zone d'édition** (droite) : Contenu des onglets

### 3. Gérer les onglets

**Ajouter un onglet :**
- Cliquez sur le bouton "Ajouter un onglet"

**Modifier un onglet :**
- Cliquez sur l'icône "Modifier" à côté du nom de l'onglet
- Changez le titre et l'icône

**Supprimer un onglet :**
- Cliquez sur l'icône "Supprimer" à côté du nom de l'onglet
- Note : Au moins un onglet doit toujours exister

### 4. Ajouter du contenu aux onglets

1. Sélectionnez l'onglet à éditer
2. Cliquez sur "Ajouter un composant"
3. Choisissez le type de composant désiré
4. Configurez le composant selon vos besoins

### 5. Configuration avancée

**Position des onglets :**
- Haut (par défaut)
- Bas
- Gauche  
- Droite

**Options d'affichage :**
- Afficher/masquer les icônes
- Couleur de l'indicateur
- Couleur d'arrière-plan

## Structure des données

Le composant Onglets stocke ses données dans le format suivant :

```json
{
  "tabPosition": "top",
  "showIcons": true,
  "tabStyle": "material",
  "height": 400.0,
  "tabs": [
    {
      "id": "tab_1",
      "title": "Onglet 1",
      "icon": "home",
      "components": [...],
      "isVisible": true,
      "settings": {}
    }
  ]
}
```

## Fichiers impliqués

- `lib/widgets/custom_tabs_widget.dart` : Widget de rendu des onglets
- `lib/widgets/tab_page_builder.dart` : Éditeur des onglets
- `lib/widgets/page_components/component_renderer.dart` : Rendu des composants
- `lib/widgets/page_components/component_editor.dart` : Édition des composants
- `lib/pages/page_builder_page.dart` : Page builder principal

## Bonnes pratiques

1. **Contenu équilibré** : Évitez de surcharger un onglet avec trop de composants
2. **Noms d'onglets clairs** : Utilisez des titres descriptifs et courts
3. **Icônes appropriées** : Choisissez des icônes qui représentent bien le contenu
4. **Hauteur adaptée** : Ajustez la hauteur selon le contenu le plus volumineux
5. **Organisation logique** : Groupez le contenu connexe dans le même onglet

## Test et validation

Pour tester le composant :
1. Créez une page avec un composant Onglets
2. Ajoutez différents types de composants dans chaque onglet
3. Vérifiez le rendu en mode prévisualisation
4. Testez la navigation entre les onglets

Le composant est maintenant pleinement fonctionnel et prêt à être utilisé ! 🎉

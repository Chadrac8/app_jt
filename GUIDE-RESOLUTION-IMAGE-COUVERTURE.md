# 🔧 Guide de résolution - Image de couverture Module Ressources

## Problème
L'image de couverture du module "Ressources" ne s'affiche pas dans la vue Membre.

## ✅ Solutions appliquées

### 1. **Correction du modèle par défaut**
- ✅ Ajouté `coverImageUrl` et `showCoverImage` dans le fallback du BottomNavigationWrapper
- ✅ Ajouté les mêmes champs dans la configuration par défaut d'AppConfigFirebaseService

### 2. **Debug ajouté**
- ✅ Logs de debug dans la console pour diagnostiquer
- ✅ Widget de debug visuel avec informations de configuration
- ✅ Image de test temporaire pour valider l'affichage

### 3. **Vérifications à effectuer**

#### A. **Côté Administration**
1. Aller dans **Admin → Ressources → Configuration**
2. Vérifier que le switch "Afficher l'image de couverture" est **activé**
3. Vérifier qu'une image est **sélectionnée et sauvegardée**
4. Confirmer le message "Configuration sauvegardée avec succès"

#### B. **Côté Membre**
1. Aller dans le module **Ressources** (vue membre)
2. Vérifier le widget de debug orange qui affiche :
   - Module Config: OK/NULL
   - Show Cover: true/false
   - Image URL: URL/NULL
   - Should show image: true/false

#### C. **Côté Technique**
1. Vérifier les logs de la console pour les messages de debug
2. Contrôler que Firebase Storage contient les images uploadées
3. Vérifier que Firestore contient la configuration du module

## 🧪 Tests de diagnostic

### Test 1: Configuration par défaut
```bash
# Lancer le script de diagnostic
dart diagnostic_cover_image.dart
```

### Test 2: Interface visuelle
1. L'image de test (gradient bleu) devrait toujours s'afficher
2. Le widget de debug orange devrait montrer les informations

### Test 3: Configuration admin
1. Aller dans Admin → Ressources → Configuration
2. Activer l'image de couverture
3. Sélectionner une image
4. Sauvegarder
5. Retourner dans la vue membre pour vérifier

## 🔄 Workflow de résolution

1. **Vérifier la configuration Firebase**
   - Collection: `app_config`
   - Document: `main_config`
   - Champ modules → ressources → `showCoverImage` et `coverImageUrl`

2. **Tester l'upload d'image**
   - Admin → Ressources → Configuration
   - Sélectionner une image test
   - Vérifier que l'upload fonctionne

3. **Valider l'affichage**
   - Vue membre → Module Ressources
   - Vérifier le widget de debug
   - Confirmer l'affichage de l'image

## 🚀 Nettoyage après résolution

Une fois le problème résolu, supprimer :
- Les logs de debug dans `ressources_member_view.dart`
- Le widget de debug orange
- L'image de test temporaire
- Garder uniquement la logique d'affichage conditionnelle originale

## 📊 États possibles

| État | Show Cover | Image URL | Résultat |
|------|------------|-----------|----------|
| 1    | false      | null      | ❌ Pas d'image |
| 2    | false      | url       | ❌ Pas d'image (désactivé) |
| 3    | true       | null      | ❌ Pas d'image (pas d'URL) |
| 4    | true       | url       | ✅ Image affichée |

L'objectif est d'atteindre l'État 4.

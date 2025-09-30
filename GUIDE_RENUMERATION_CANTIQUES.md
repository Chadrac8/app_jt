# 🎵 Guide de Renumération des Cantiques

## Problème
Les cantiques commencent au numéro 243 au lieu de 1 après l'application du script de migration automatique.

## Solutions Disponibles

### 🎯 **Solution 1: Interface Administrateur (Recommandée)**

Dans l'application Flutter :

1. **Ouvrir la section Administration**
   - Connectez-vous avec un compte administrateur
   - Allez dans "Chants" > "Administration"

2. **Utiliser le bouton de renumération**
   - Dans la barre d'actions, cliquez sur l'icône `format_list_numbered`
   - Confirmez l'opération
   - Attendez que la renumération se termine

3. **Vérification**
   - Les cantiques seront automatiquement identifiés
   - Ils seront renumérrotés de 1 à N
   - Les autres chants gardent leurs numéros actuels

### 🛠️ **Solution 2: Script Automatique**

```bash
cd /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle
dart run fix_cantiques_numbers.dart
```

Ce script :
- Identifie automatiquement les cantiques par titre et tags
- Les renumérote séquentiellement à partir de 1
- Affiche un rapport détaillé des modifications

### 🔧 **Solution 3: Console Firebase (Manuelle)**

1. **Accéder à Firebase**
   - https://console.firebase.google.com
   - Sélectionnez votre projet
   - Allez dans "Firestore Database"

2. **Ouvrir la collection "songs"**
   - Naviguez dans la collection
   - Identifiez les cantiques par leur titre

3. **Modifier manuellement**
   - Pour chaque cantique :
     - Cliquez sur le document
     - Modifiez le champ "number"
     - Attribuez 1, 2, 3, etc.

### 🔍 **Identification des Cantiques**

Les cantiques sont identifiés par :

**Titres typiques :**
- Commençant par "Ô", "O", "Mon", "Ma"
- Contenant "Dieu", "Jésus", "Seigneur", "Christ"
- Contenant "Gloire", "Louange", "Alléluia"

**Tags/Catégories :**
- "cantique", "hymne", "traditionnel"

**Exemples :**
- ✅ "Ô Dieu notre aide"
- ✅ "Mon Jésus je t'aime"
- ✅ "Gloire à Dieu au plus haut des cieux"
- ✅ "Il est vivant"

## 🎯 Résultat Attendu

Après renumération :
- **Cantiques :** numéros 1, 2, 3, ..., N
- **Autres chants :** gardent leurs numéros actuels (243+)
- **Tri dans l'app :** Les cantiques apparaissent en premier

## 🚀 Recommandation

1. **Utilisez la Solution 1** (interface admin) pour plus de simplicité
2. **Vérifiez le résultat** dans l'application
3. **Si nécessaire**, ajustez manuellement quelques numéros via Firebase

## 📝 Notes Techniques

- Le tri se fait par le champ `number` en priorité
- Si pas de numéro, tri alphabétique par titre
- Les modifications sont instantanées dans l'application
- Pas de perte de données, seulement modification des numéros

---

✅ **Votre système de tri par numéro fonctionne parfaitement !**
Il suffit maintenant de corriger la numérotation des cantiques.
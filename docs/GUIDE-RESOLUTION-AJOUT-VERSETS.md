# Guide de résolution - Ajout de versets bibliques

## Problème
Vous ne pouvez pas ajouter de versets bibliques aux nouveaux passages thématiques que vous créez.

## Cause
L'authentification anonyme n'est pas activée dans Firebase Authentication, ce qui empêche les utilisateurs non connectés de créer et modifier des thèmes.

## Solution

### Étape 1: Activer l'authentification anonyme

1. **Ouvrez la console Firebase** :
   - Allez sur : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/authentication/providers

2. **Activez l'authentification anonyme** :
   - Dans l'onglet "Sign-in method"
   - Cliquez sur "Anonymous"
   - Basculez le bouton pour "Enable"
   - Cliquez sur "Save"

### Étape 2: Vérification

1. **Redémarrez l'application Flutter**
2. **Testez la création d'un thème** :
   - Allez dans "Passages thématiques"
   - Cliquez sur le bouton "+" pour créer un thème
   - Remplissez les informations et sauvegardez

3. **Testez l'ajout de passages** :
   - Ouvrez le thème créé
   - Cliquez sur "Ajouter un passage"
   - Saisissez une référence biblique (ex: "Jean 3:16")
   - Sauvegardez

## Messages d'erreur courants

### "admin-restricted-operation"
- **Cause** : L'authentification anonyme n'est pas activée
- **Solution** : Suivez l'Étape 1 ci-dessus

### "Utilisateur non connecté"
- **Cause** : Aucune méthode d'authentification disponible
- **Solution** : Activez l'authentification anonyme ou implémentez une connexion utilisateur

### "Missing or insufficient permissions"
- **Cause** : Règles Firestore trop restrictives
- **Solution** : Les règles ont été mises à jour pour permettre l'accès aux thèmes publics

## Fonctionnalités disponibles après correction

✅ **Création de thèmes personnalisés**
✅ **Ajout de versets bibliques aux thèmes**
✅ **Modification des thèmes existants**
✅ **Suppression des thèmes et passages**
✅ **Visualisation des thèmes publics sans connexion**

## Support technique

Si le problème persiste après avoir suivi ces étapes :

1. Vérifiez que l'authentification anonyme est bien activée
2. Attendez quelques minutes pour la propagation des changements
3. Videz le cache du navigateur (si utilisation web)
4. Redémarrez complètement l'application

## Remarques importantes

- L'authentification anonyme permet d'utiliser l'application sans créer de compte
- Les thèmes créés de manière anonyme sont associés à l'ID anonyme de l'utilisateur
- Pour une expérience optimale, considérez implémenter une authentification complète (email/password, Google, etc.)

---

**Dernière mise à jour** : 13 juillet 2025  
**Version de l'application** : Passages thématiques v1.0

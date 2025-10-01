# Guide de résolution des erreurs d'index Firestore

## Problème identifié
Les erreurs indiquent que Firebase Firestore nécessite des index composites pour :
- **Rôles** : requête sur `isActive` + `isSystemRole` + `name` + `__name__`
- **Permissions** : requête sur `module` + `category` + `__name__`

## Solution automatique (Recommandée)

### Étape 1 : Déployer les index
```bash
./deploy_firestore_indexes.sh
```

### Étape 2 : Attendre la création des index
- Les index Firestore prennent quelques minutes à être créés
- Surveillez la console Firebase pour voir le statut

### Étape 3 : Relancer l'application
```bash
flutter hot restart
```

## Solution manuelle (Alternative)

Si le script ne fonctionne pas, cliquez directement sur ces liens :

### 1. Index pour les rôles
https://console.firebase.google.com/v1/r/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes?create_composite=Clxwcm9qZWN0cy9oanllMjV1OGl3bTBpMHpsczc4dXJmZnNjMGpjZ2ovZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JvbGVzL2luZGV4ZXMvXxABGgwKCGlzQWN0aXZlEAEaEAoMaXNTeXN0ZW1Sb2xlEAIaCAoEbmFtZRABGgwKCF9fbmFtZV9fEAE

### 2. Index pour les permissions
https://console.firebase.google.com/v1/r/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes?create_composite=CmJwcm9qZWN0cy9oanllMjV1OGl3bTBpMHpsczc4dXJmZnNjMGpjZ2ovZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3Blcm1pc3Npb25zL2luZGV4ZXMvXxABGgoKBm1vZHVsZRABGgwKCGNhdGVnb3J5EAEaDAoIX19uYW1lX18QAQ

## Vérification

Une fois les index créés, les erreurs suivantes devraient disparaître :
- `❌ Erreur PermissionProvider.loadRoles`
- `❌ Erreur PermissionProvider.loadPermissions`

## Configuration ajoutée

Les index suivants ont été ajoutés à `firestore.indexes.json` :

```json
{
  "collectionGroup": "roles",
  "fields": [
    {"fieldPath": "isActive", "order": "ASCENDING"},
    {"fieldPath": "isSystemRole", "order": "ASCENDING"},
    {"fieldPath": "name", "order": "ASCENDING"},
    {"fieldPath": "__name__", "order": "ASCENDING"}
  ]
},
{
  "collectionGroup": "permissions",
  "fields": [
    {"fieldPath": "module", "order": "ASCENDING"},
    {"fieldPath": "category", "order": "ASCENDING"},
    {"fieldPath": "__name__", "order": "ASCENDING"}
  ]
}
```

## Notes importantes
- Les index Firestore sont gratuits jusqu'à 50 000 opérations/jour
- La création d'index peut prendre 5-10 minutes
- Une fois créés, les index améliorent les performances des requêtes
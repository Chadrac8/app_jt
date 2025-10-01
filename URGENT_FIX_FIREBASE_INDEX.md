# 🔥 RÉSOLUTION URGENTE - Erreur Index Firebase Rôles

## ❌ Problème identifié
```
❌ Erreur PermissionProvider.loadRoles: [cloud_firestore/failed-precondition] 
The query requires an index with: isActive + isSystemRole + name + __name__
```

## 🚀 SOLUTION IMMÉDIATE (2 minutes)

### Méthode 1 : Lien direct Firebase (RECOMMANDÉE)
Cliquez sur ce lien pour créer l'index automatiquement :
👉 [CRÉER L'INDEX ROLES](https://console.firebase.google.com/v1/r/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes?create_composite=Clxwcm9qZWN0cy9oanllMjV1OGl3bTBpMHpsczc4dXJmZnNjMGpjZ2ovZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JvbGVzL2luZGV4ZXMvXxABGgwKCGlzQWN0aXZlEAEaEAoMaXNTeXN0ZW1Sb2xlEAIaCAoEbmFtZRABGgwKCF9fbmFtZV9fEAE)

### Méthode 2 : Console Firebase manuelle
1. Aller à : [Firebase Console > Firestore > Index](https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes)
2. Cliquer sur **"Créer un index"**
3. **Collection** : `roles`
4. **Champs** à ajouter dans l'ordre :
   - `isActive` - Croissant
   - `isSystemRole` - Croissant  
   - `name` - Croissant
   - `__name__` - Croissant

## ⏱️ Temps d'attente
- **Création de l'index** : 5-10 minutes
- **Propagation** : 2-3 minutes supplémentaires

## 🔍 Vérification
Une fois l'index créé, vous devriez voir dans les logs :
```
✅ PermissionProvider initialisé pour [user-id]
✅ AdminViewToggleButton - Accès admin détecté
```

## 🆘 Si le problème persiste
L'index pourrait être en conflit. Supprimez l'ancien index d'abord :
```bash
# Supprimer l'ancien index
firebase firestore:indexes:delete
# Puis recréer avec le nouveau
firebase deploy --only firestore:indexes
```

## 📱 Test final
1. **Redémarrer l'application** Flutter
2. **Aller sur la page Accueil**
3. **Vérifier** la présence du bouton admin (icône paramètres)

---
**Status** : 🔴 CRITIQUE - Empêche l'affichage du bouton admin  
**Priorité** : 🚨 IMMÉDIATE - Requis pour l'accès administrateur
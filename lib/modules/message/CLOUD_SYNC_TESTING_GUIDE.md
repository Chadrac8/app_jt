# Guide de test - Synchronisation Cloud

## Prérequis

- ✅ Règles Firestore déployées (`./deploy_cloud_sync.sh`)
- ✅ Index Firestore créés (attendre 5-10 min après déploiement)
- ✅ Utilisateur Firebase Auth connecté dans l'app
- ✅ Connexion internet active

## Test 1 : Synchronisation basique ⭐

**Objectif** : Vérifier que les notes se synchronisent entre appareils

### Étapes
1. Sur l'appareil A :
   - Ouvrir le module Search WB
   - Créer une nouvelle note sur un sermon
   - Vérifier l'icône cloud devient verte (✅)
   
2. Dans la console Firestore :
   - Aller sur https://console.firebase.google.com
   - Ouvrir Firestore Database
   - Vérifier que la collection `wb_sermon_notes` contient la note
   - Vérifier que `userId` correspond à l'utilisateur connecté

3. Sur l'appareil B (même utilisateur) :
   - Ouvrir le module Search WB
   - Appuyer sur l'icône cloud dans l'AppBar
   - Vérifier l'information de synchronisation
   - Appuyer sur "Synchroniser"
   - Aller dans l'onglet "Notes"
   - **Résultat attendu** : La note apparaît

### Critères de réussite ✅
- [ ] Note créée sur A
- [ ] Note visible dans Firestore avec userId correct
- [ ] Note apparaît sur B après synchronisation
- [ ] Indicateur cloud vert sur les deux appareils

---

## Test 2 : Mode offline 📴

**Objectif** : Vérifier le fonctionnement sans connexion internet

### Étapes
1. Sur un appareil :
   - Activer le mode avion
   - Créer 3 notes sur différents sermons
   - Créer 2 surlignements
   - Vérifier l'icône cloud devient grise (☁️ offline)
   
2. Vérifier la sauvegarde locale :
   - Fermer et rouvrir l'app
   - **Résultat attendu** : Les notes et surlignements sont toujours présents

3. Réactiver la connexion :
   - Désactiver le mode avion
   - Attendre quelques secondes
   - **Résultat attendu** : L'icône cloud devient verte automatiquement
   
4. Vérifier dans Firestore :
   - Les 3 notes doivent apparaître
   - Les 2 surlignements doivent apparaître

### Critères de réussite ✅
- [ ] Création offline fonctionne
- [ ] Données persistantes après redémarrage
- [ ] Icône indique correctement l'état offline
- [ ] Synchronisation automatique après reconnexion
- [ ] Toutes les données offline uploadées

---

## Test 3 : Résolution de conflits ⚔️

**Objectif** : Vérifier que les conflits sont résolus correctement

### Étapes
1. Préparer le conflit :
   - Sur l'appareil A : Activer le mode avion
   - Sur l'appareil B : Activer le mode avion
   
2. Créer le conflit :
   - Sur A : Créer une note avec titre "Test Conflit" à 10h00
   - Sur B : Créer une note avec le MÊME ID (utiliser la même note si possible)
   - Sur A : Modifier le contenu à 10h05 : "Version A"
   - Sur B : Modifier le contenu à 10h10 : "Version B"

3. Résoudre :
   - Sur A : Désactiver le mode avion, attendre sync
   - Sur B : Désactiver le mode avion, attendre sync
   
4. Vérifier :
   - Sur A et B : Ouvrir la note "Test Conflit"
   - **Résultat attendu** : La "Version B" (plus récente) est affichée sur les deux appareils

### Critères de réussite ✅
- [ ] Conflit créé avec succès
- [ ] Les deux appareils synchronisent
- [ ] Version la plus récente (B) conservée
- [ ] Même contenu sur A et B après sync

---

## Test 4 : Multi-utilisateurs 👥

**Objectif** : Vérifier l'isolation des données entre utilisateurs

### Étapes
1. Utilisateur 1 :
   - Se connecter avec le compte utilisateur1@test.com
   - Créer 2 notes personnelles
   - Vérifier qu'elles apparaissent dans Firestore

2. Utilisateur 2 :
   - Se déconnecter de l'utilisateur 1
   - Se connecter avec utilisateur2@test.com
   - Ouvrir l'onglet "Notes"
   - **Résultat attendu** : Aucune note n'est visible
   - Créer 2 notes différentes

3. Retour utilisateur 1 :
   - Se déconnecter de l'utilisateur 2
   - Se connecter avec utilisateur1@test.com
   - Synchroniser
   - **Résultat attendu** : Seules les 2 notes de l'utilisateur 1 sont visibles

4. Vérifier dans Firestore :
   - Filtrer par `userId` de l'utilisateur 1
   - Vérifier 2 notes avec ce userId
   - Filtrer par `userId` de l'utilisateur 2
   - Vérifier 2 notes avec cet autre userId

### Critères de réussite ✅
- [ ] Chaque utilisateur voit uniquement ses notes
- [ ] Pas de fuite de données entre utilisateurs
- [ ] Firestore contient les bonnes données avec les bons userId
- [ ] Règles de sécurité fonctionnent correctement

---

## Test 5 : Performance ⚡

**Objectif** : Mesurer les performances de synchronisation

### Étapes
1. Créer beaucoup de données :
   - Créer 100 notes localement (utiliser un script ou le faire manuellement)
   - Noter l'heure de début

2. Synchroniser vers le cloud :
   - Menu → "Synchroniser maintenant"
   - Noter le temps de synchronisation
   - **Temps attendu** : < 10 secondes pour 100 notes

3. Vider local et télécharger :
   - Menu → "Vider le cache"
   - Menu → "Synchroniser maintenant"
   - Noter le temps de téléchargement
   - **Temps attendu** : < 10 secondes pour 100 notes

4. Vérifier la mémoire :
   - Ouvrir les outils de développement
   - Vérifier l'utilisation mémoire
   - **Mémoire attendue** : < 50 MB pour 100 notes

### Critères de réussite ✅
- [ ] Upload de 100 notes en < 10s
- [ ] Download de 100 notes en < 10s
- [ ] Utilisation mémoire raisonnable
- [ ] Pas de ralentissement de l'interface
- [ ] Pas de crash

---

## Test 6 : Gestion d'erreurs 🚨

**Objectif** : Vérifier que les erreurs sont bien gérées

### Scénarios à tester

#### 6.1 Utilisateur non connecté
1. Se déconnecter de Firebase Auth
2. Essayer de créer une note
3. **Résultat attendu** : Note sauvegardée localement, icône cloud grise
4. Essayer de synchroniser
5. **Résultat attendu** : Message "Non connecté"

#### 6.2 Pas de connexion internet
1. Activer le mode avion
2. Créer une note
3. **Résultat attendu** : Sauvegarde locale OK, icône cloud grise
4. Menu → "Synchroniser maintenant"
5. **Résultat attendu** : Message d'erreur "Pas de connexion"

#### 6.3 Règles Firestore refusées
1. Dans Firestore, modifier temporairement les règles pour refuser l'accès
2. Essayer de synchroniser
3. **Résultat attendu** : Message d'erreur "Permission denied"
4. Rétablir les règles correctes

### Critères de réussite ✅
- [ ] Messages d'erreur clairs
- [ ] Pas de crash de l'app
- [ ] Données locales préservées
- [ ] Interface reste utilisable

---

## Test 7 : Statistiques et monitoring 📊

**Objectif** : Vérifier les fonctionnalités de monitoring

### Étapes
1. Créer des données :
   - Créer 5 notes localement
   - Créer 3 surlignements
   - Synchroniser

2. Consulter les statistiques :
   - Menu → "Statistiques cloud"
   - Vérifier :
     - Notes dans le cloud : 5
     - Surlignements dans le cloud : 3
     - Notes locales : 5
     - Surlignements locaux : 3

3. Vérifier l'indicateur de sync :
   - Cliquer sur l'icône cloud
   - Vérifier :
     - État connexion : Connecté
     - Dernière synchronisation : heure affichée
     - Auto-sync : État (Activé/Désactivé)

### Critères de réussite ✅
- [ ] Statistiques cloud correctes
- [ ] Statistiques locales correctes
- [ ] Indicateur de sync à jour
- [ ] Dernière heure de sync correcte

---

## Test 8 : Auto-sync ⚙️

**Objectif** : Vérifier le fonctionnement de la synchronisation automatique

### Étapes
1. Activer l'auto-sync :
   - Cliquer sur l'icône cloud
   - Activer "Synchronisation automatique"

2. Créer une note :
   - Créer une nouvelle note
   - Attendre 1-2 secondes
   - Vérifier dans Firestore
   - **Résultat attendu** : Note uploadée automatiquement

3. Modifier une note :
   - Modifier une note existante
   - Attendre 1-2 secondes
   - Vérifier dans Firestore
   - **Résultat attendu** : Modification synchronisée

4. Désactiver l'auto-sync :
   - Cliquer sur l'icône cloud
   - Désactiver "Synchronisation automatique"
   - Créer une nouvelle note
   - Attendre 5 secondes
   - Vérifier dans Firestore
   - **Résultat attendu** : Note NON synchronisée automatiquement

### Critères de réussite ✅
- [ ] Auto-sync ON : upload automatique
- [ ] Auto-sync OFF : pas d'upload automatique
- [ ] Toggle fonctionne correctement
- [ ] Indicateur visuel correct

---

## Checklist finale ✅

### Fonctionnalités de base
- [ ] Création de note → sync cloud
- [ ] Modification de note → sync cloud
- [ ] Suppression de note → suppression cloud
- [ ] Création de highlight → sync cloud
- [ ] Modification de highlight → sync cloud
- [ ] Suppression de highlight → suppression cloud

### Synchronisation
- [ ] Sync manuelle bidirectionnelle
- [ ] Sync automatique lors de la connexion
- [ ] Sync automatique après sauvegarde (si activée)
- [ ] Indicateur de sync dans l'AppBar
- [ ] Dialog d'information de sync

### Mode offline
- [ ] Création offline
- [ ] Modification offline
- [ ] Suppression offline
- [ ] Persistance après redémarrage
- [ ] Sync automatique après reconnexion

### Sécurité
- [ ] Isolation des données par utilisateur
- [ ] Règles Firestore appliquées
- [ ] Pas de fuite de données
- [ ] userId automatique

### Performance
- [ ] Sync rapide (< 10s pour 100 items)
- [ ] Pas de ralentissement UI
- [ ] Utilisation mémoire raisonnable
- [ ] Pas de crash

### UX
- [ ] Messages d'erreur clairs
- [ ] Indicateurs visuels corrects
- [ ] Statistiques précises
- [ ] Documentation accessible

---

## Problèmes connus et solutions

### Problème : "Permission denied"
**Solution** : Vérifier que les règles Firestore sont déployées et que l'utilisateur est connecté.

### Problème : Index non créés
**Solution** : Attendre 5-10 minutes après le déploiement. Vérifier dans la console Firebase.

### Problème : Sync lente
**Solution** : Vérifier la connexion internet. Si beaucoup de données, c'est normal.

### Problème : Données dupliquées
**Solution** : Vérifier que les IDs sont uniques. Utiliser `syncBidirectional()` pour fusionner.

---

## Reporting des bugs

Si vous trouvez un bug, noter :
1. Étapes pour reproduire
2. Comportement attendu vs observé
3. Logs de la console Flutter
4. État de la synchronisation (connecté, offline, etc.)
5. Données dans Firestore (screenshot si possible)

---

## Conclusion

Ce guide couvre tous les scénarios de test importants pour la synchronisation cloud. Une fois tous les tests passés avec succès, la fonctionnalité est prête pour la production ! 🎉

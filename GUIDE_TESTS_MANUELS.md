# 🧪 Guide Tests Manuels - Intégration Groupes ↔ Événements

> **Phase 8 : Validation complète**  
> **Date:** 14 octobre 2025  
> **Durée estimée:** 45 minutes

---

## 🎯 Objectif

Valider end-to-end toutes les fonctionnalités de l'intégration Planning Center Groups style.

---

## ✅ Checklist Pré-Tests

Avant de commencer, assurez-vous que :

- [ ] Firebase index déployés (`firebase deploy --only firestore:indexes`)
- [ ] Application compilée sans erreurs (`flutter analyze`)
- [ ] Simulateur/Émulateur démarré
- [ ] Base de données Firestore accessible
- [ ] Compte test administrateur connecté

---

## 📋 Test Suite 1 : Création Groupe avec Récurrence

### Test 1.1 : Groupe hebdomadaire simple

**Objectif :** Créer groupe avec réunions chaque mardi

**Étapes :**
1. Ouvrir **Groupes** → Tap **+** (Nouveau groupe)
2. Remplir :
   - Nom: `Test Jeunes`
   - Description: `Groupe test hebdomadaire`
   - Type: `Fellowship`
   - Lieu: `Salle 3`
3. Cocher **"Générer des événements automatiquement"**
4. Configuration récurrence :
   - Fréquence: `Hebdomadaire`
   - Jours: Cocher `Mardi`
   - Heure: `19:30`
   - Durée: `120 minutes`
   - Fin: `Jamais`
5. Tap **Enregistrer**

**Résultats attendus :**
- ✅ Groupe créé avec succès
- ✅ `generateEvents = true` dans Firestore
- ✅ Snackbar confirmation: "Groupe créé"
- ✅ Navigation vers page détails groupe

**Vérification Firestore :**
```json
{
  "name": "Test Jeunes",
  "generateEvents": true,
  "recurrenceConfig": {
    "frequency": "weekly",
    "interval": 1,
    "daysOfWeek": [2],
    "startDate": "2025-10-14T19:30:00.000",
    "endType": "never"
  }
}
```

**Temps :** ~2 min  
**Priorité :** 🔴 CRITIQUE

---

### Test 1.2 : Groupe quotidien avec fin après X occurrences

**Objectif :** Créer groupe quotidien limité à 5 réunions

**Étapes :**
1. Nouveau groupe
2. Remplir :
   - Nom: `Prière Matinale Test`
   - Type: `Prayer`
   - Lieu: `En ligne`
3. Générer événements: ✅
4. Configuration :
   - Fréquence: `Quotidien`
   - Intervalle: `1`
   - Heure: `07:00`
   - Durée: `60 minutes`
   - Fin: `Après`
   - Occurrences: `5`
5. Enregistrer

**Résultats attendus :**
- ✅ 5 événements créés exactement
- ✅ Onglet "Réunions" affiche 5 réunions futures
- ✅ Pas d'événement après la 5ème occurrence

**Vérification Firestore :**
```dart
// Query événements
final events = await FirebaseFirestore.instance
  .collection('events')
  .where('linkedGroupId', isEqualTo: groupId)
  .get();

assert(events.docs.length == 5);
```

**Temps :** ~3 min  
**Priorité :** 🔴 CRITIQUE

---

### Test 1.3 : Groupe mensuel (2ème mardi)

**Objectif :** Créer groupe mensuel avec day of week

**Étapes :**
1. Nouveau groupe
2. Remplir :
   - Nom: `Comité Test`
3. Configuration :
   - Fréquence: `Mensuel`
   - Type: `Le 2ème mardi`
   - Heure: `20:00`
   - Durée: `90 minutes`
   - Fin: `Le`
   - Date fin: `31 décembre 2025`
4. Enregistrer

**Résultats attendus :**
- ✅ 3 événements créés (oct, nov, déc 2025)
- ✅ Chaque événement sur un 2ème mardi
- ✅ Dates: 14 oct, 11 nov, 9 déc

**Temps :** ~3 min  
**Priorité :** 🟡 HAUTE

---

## 📋 Test Suite 2 : Interface Groupe

### Test 2.1 : Carte Événements Générés

**Objectif :** Vérifier affichage carte stats dans onglet Infos

**Étapes :**
1. Ouvrir groupe créé dans Test 1.1
2. Aller dans onglet **Informations**
3. Scroller jusqu'à la carte **Événements générés**

**Résultats attendus :**
- ✅ Carte visible avec bordure primaire
- ✅ Titre: "📅 Événements générés"
- ✅ Stats affichées :
  - Total: X événements
  - À venir: Y
  - Passés: Z
- ✅ Bouton **"Voir tous les événements"**
- ✅ Menu `•••` avec option **"Désactiver génération"**

**Temps :** ~1 min  
**Priorité :** 🟡 HAUTE

---

### Test 2.2 : Timeline Réunions

**Objectif :** Vérifier affichage timeline dans onglet Réunions

**Étapes :**
1. Même groupe Test 1.1
2. Aller dans onglet **Réunions**
3. Observer la liste

**Résultats attendus :**
- ✅ Section **"🔜 À venir"** en haut
- ✅ Première réunion avec badge **"AUJOURD'HUI"** (si c'est mardi)
- ✅ Points timeline verticaux (vert → gris)
- ✅ Badge **"🔗 → Événement lié"** pour chaque réunion
- ✅ Section **"📜 Passées"** en bas (vide si aucune passée)

**Temps :** ~2 min  
**Priorité :** 🟡 HAUTE

---

### Test 2.3 : Navigation Réunion → Événement

**Objectif :** Tester badge lien événement

**Étapes :**
1. Dans timeline (Test 2.2)
2. Tap sur badge **"🔗 → Événement lié"** de la 1ère réunion
3. Attendre navigation

**Résultats attendus :**
- ✅ Navigation vers **EventDetailPage**
- ✅ Titre événement contient nom du groupe
- ✅ Date/heure correspondent à la réunion
- ✅ Badge **"👥 Réunion du groupe"** affiché en haut
- ✅ Bouton **"Voir le groupe →"** visible

**Temps :** ~1 min  
**Priorité :** 🔴 CRITIQUE

---

## 📋 Test Suite 3 : Dialog Choix Modification

### Test 3.1 : Affichage Dialog

**Objectif :** Vérifier apparition dialog modification portée

**Étapes :**
1. Groupe Test 1.1 (hebdomadaire récurrent)
2. Onglet **Réunions**
3. Tap sur réunion future (ex: 21 octobre)
4. Tap bouton **Modifier** (⚙️ ou icône édition)

**Résultats attendus :**
- ✅ Dialog **"Modifier une réunion récurrente"** apparaît
- ✅ Badge info bleu: "Cette réunion fait partie d'une série récurrente"
- ✅ 3 options visibles :
  1. **"Cette occurrence uniquement"** (radio sélectionné par défaut)
  2. **"Cette occurrence et les suivantes"**
  3. **"Toutes les occurrences"**
- ✅ Date formatée: "14 octobre 2025"
- ✅ Boutons **Annuler** et **Continuer**

**Temps :** ~1 min  
**Priorité :** 🔴 CRITIQUE

---

### Test 3.2 : Sélection Option

**Objectif :** Tester sélection UI radio buttons

**Étapes :**
1. Dans dialog (Test 3.1)
2. Tap sur option **"Cette occurrence et les suivantes"**
3. Observer changements visuels

**Résultats attendus :**
- ✅ Bordure devient **primary color** (2px)
- ✅ Background **primary 5% opacity**
- ✅ Icône devient **primary color**
- ✅ Radio checked ✅
- ✅ Option précédente (option 1) désélectionnée
- ✅ Bordure option 1 redevient grise

**Temps :** ~30 sec  
**Priorité :** 🟡 HAUTE

---

### Test 3.3 : Annulation

**Objectif :** Vérifier comportement bouton Annuler

**Étapes :**
1. Dans dialog (après Test 3.2)
2. Tap **Annuler**

**Résultats attendus :**
- ✅ Dialog se ferme
- ✅ Retour à page groupe (onglet Réunions)
- ✅ Aucune modification appliquée
- ✅ Pas de snackbar

**Temps :** ~30 sec  
**Priorité :** 🟢 MOYENNE

---

## 📋 Test Suite 4 : Modifications Portée

### Test 4.1 : Modifier occurrence unique

**Objectif :** Changement ponctuel (heure)

**Étapes :**
1. Groupe Test 1.1
2. Modifier réunion du 21 octobre
3. Dialog → Sélectionner **"Cette occurrence uniquement"**
4. Tap **Continuer**
5. Dans formulaire édition :
   - Changer heure: `19:30` → `20:00`
   - Changer lieu: `Salle 3` → `Salle 5`
6. Enregistrer

**Résultats attendus :**
- ✅ Réunion du 21 oct modifiée (20:00, Salle 5)
- ✅ Réunion du 14 oct inchangée (19:30, Salle 3)
- ✅ Réunion du 28 oct inchangée (19:30, Salle 3)
- ✅ Événement lié au 21 oct mis à jour
- ✅ Snackbar: "Réunion modifiée"

**Vérification Firestore :**
```dart
// Réunion 21 oct
{
  "date": "2025-10-21T20:00:00.000", // ✅ 20h
  "location": "Salle 5", // ✅ Modifié
}

// Réunion 28 oct
{
  "date": "2025-10-28T19:30:00.000", // ✅ 19h30 inchangé
  "location": "Salle 3", // ✅ Inchangé
}
```

**Temps :** ~2 min  
**Priorité :** 🔴 CRITIQUE

---

### Test 4.2 : Modifier cette occurrence et suivantes

**Objectif :** Changement définitif à partir d'une date

**Étapes :**
1. Groupe Test 1.1
2. Modifier réunion du 28 octobre
3. Dialog → **"Cette occurrence et les suivantes"**
4. Continuer
5. Changer lieu: `Salle 3` → `Grande salle`
6. Enregistrer

**Résultats attendus :**
- ✅ Réunion 28 oct: Grande salle
- ✅ Réunion 4 nov: Grande salle
- ✅ Réunion 11 nov: Grande salle
- ✅ ... toutes les futures: Grande salle
- ✅ Réunion 14 oct: Salle 3 (passée, inchangée)
- ✅ Réunion 21 oct: Salle 5 (modifiée en Test 4.1, inchangée)

**Temps :** ~2 min  
**Priorité :** 🔴 CRITIQUE

---

### Test 4.3 : Modifier toutes les occurrences

**Objectif :** Changement global configuration

**Étapes :**
1. Groupe Test 1.1
2. Modifier n'importe quelle réunion
3. Dialog → **"Toutes les occurrences"**
4. Continuer
5. Changer heure: `19:30` → `18:00`
6. Enregistrer

**Résultats attendus :**
- ✅ **TOUTES** les réunions (passées + futures) : 18:00
- ✅ Réunions passées mises à jour (historique modifié)
- ✅ Réunion 21 oct : 18:00 (écrase modification ponctuelle Test 4.1)
- ✅ Configuration groupe `time = "18:00"`

**Temps :** ~2 min  
**Priorité :** 🔴 CRITIQUE

---

## 📋 Test Suite 5 : Synchronisation Bidirectionnelle

### Test 5.1 : Modifier événement → Réunion

**Objectif :** Changement depuis calendrier synchronise réunion

**Étapes :**
1. Aller dans **Calendrier**
2. Trouver événement "Test Jeunes" (mardi)
3. Tap sur événement
4. Tap **Modifier**
5. Changer description: `Nouvelle description`
6. Enregistrer

**Résultats attendus :**
- ✅ Événement mis à jour
- ✅ Réunion correspondante mise à jour automatiquement
- ✅ Aller dans Groupe → Réunions → Description affichée

**Temps :** ~2 min  
**Priorité :** 🟡 HAUTE

---

### Test 5.2 : Supprimer événement conserve réunion

**Objectif :** Supprimer événement ne supprime pas réunion

**Étapes :**
1. Calendrier → Événement "Test Jeunes" (4 nov par ex)
2. Tap **Supprimer**
3. Confirmer suppression
4. Aller dans Groupe → Réunions

**Résultats attendus :**
- ✅ Événement supprimé du calendrier
- ✅ Réunion du 4 nov toujours présente
- ✅ Badge "🔗 Événement lié" disparaît
- ✅ `linkedEventId = null` dans Firestore

**Temps :** ~2 min  
**Priorité :** 🟢 MOYENNE

---

## 📋 Test Suite 6 : Désactivation Génération

### Test 6.1 : Désactiver génération événements

**Objectif :** Arrêter génération sans supprimer groupe

**Étapes :**
1. Groupe Test 1.1 → Onglet **Informations**
2. Carte **Événements générés** → Menu `•••`
3. Tap **"Désactiver génération automatique"**
4. Confirmer dans dialog

**Résultats attendus :**
- ✅ `generateEvents = false` dans Firestore
- ✅ Événements **futurs** supprimés
- ✅ Événements **passés** conservés (historique)
- ✅ Carte **Événements générés** disparaît
- ✅ Onglet **Réunions** : sections vides ou réunions passées seules

**Temps :** ~2 min  
**Priorité :** 🟡 HAUTE

---

### Test 6.2 : Réactiver génération

**Objectif :** Recommencer génération après désactivation

**Étapes :**
1. Groupe Test 1.1 (génération désactivée)
2. Tap **Modifier groupe**
3. Cocher **"Générer des événements automatiquement"**
4. Reconfigurer récurrence (hebdomadaire, mardi, 19:30)
5. Enregistrer

**Résultats attendus :**
- ✅ `generateEvents = true`
- ✅ Nouveaux événements créés à partir d'aujourd'hui
- ✅ Carte **Événements générés** réapparaît
- ✅ Onglet **Réunions** : nouvelles réunions futures

**Temps :** ~2 min  
**Priorité :** 🟡 HAUTE

---

## 📋 Test Suite 7 : Exclusion Dates

### Test 7.1 : Ajouter dates exclues

**Objectif :** Exclure vacances/jours fériés

**Étapes :**
1. Groupe Test 1.1 → **Modifier**
2. Section **Dates exclues**
3. Tap **"Ajouter une date"**
4. Sélectionner **25 décembre 2025**
5. Tap **"Ajouter une date"**
6. Sélectionner **1er janvier 2026**
7. Enregistrer

**Résultats attendus :**
- ✅ `excludeDates = ["2025-12-25", "2026-01-01"]` dans Firestore
- ✅ Aucun événement créé le 25 déc ni 1er jan
- ✅ Si événements existaient, ils sont supprimés
- ✅ Timeline réunions n'affiche pas ces dates

**Temps :** ~2 min  
**Priorité :** 🟡 HAUTE

---

## 📋 Test Suite 8 : Cas Limites (Edge Cases)

### Test 8.1 : Mois 31 jours

**Objectif :** Groupe mensuel le 31 du mois

**Étapes :**
1. Créer groupe
2. Configuration :
   - Fréquence: `Mensuel`
   - Type: `Le 31 de chaque mois`
   - Date début: `31 octobre 2025`
   - Fin: `Après 4 occurrences`
3. Enregistrer

**Résultats attendus :**
- ✅ Octobre: 31 oct ✅
- ✅ Novembre: 30 nov ✅ (pas de 31 → dernier jour)
- ✅ Décembre: 31 déc ✅
- ✅ Janvier: 31 jan ✅

**Temps :** ~3 min  
**Priorité :** 🟢 MOYENNE

---

### Test 8.2 : Année bissextile

**Objectif :** Groupe le 29 février

**Étapes :**
1. Créer groupe
2. Configuration :
   - Fréquence: `Annuel`
   - Date début: `29 février 2024` (année bissextile)
   - Fin: `Après 3 occurrences`
3. Enregistrer

**Résultats attendus :**
- ✅ 2024: 29 fév ✅
- ✅ 2025: 28 fév ✅ (pas de 29 → 28)
- ✅ 2026: 28 fév ✅
- ⚠️ OU 2028: 29 fév (si skip années non-bissextiles)

**Temps :** ~3 min  
**Priorité :** 🟢 BASSE

---

### Test 8.3 : Changement heure été/hiver

**Objectif :** Vérifier comportement DST

**Étapes :**
1. Créer groupe quotidien
2. Date début: 25 mars 2025 (veille changement heure)
3. Heure: `02:30` (heure affectée par DST)
4. Observer événements 26-27 mars

**Résultats attendus :**
- ✅ Heure constante (2:30 local time)
- ✅ Pas de saut d'heure
- ✅ Timestamps UTC corrects dans Firestore

**Temps :** ~3 min  
**Priorité :** 🟢 BASSE

---

## 📋 Test Suite 9 : Performance

### Test 9.1 : Génération 100+ événements

**Objectif :** Tester performance génération massive

**Étapes :**
1. Créer groupe quotidien
2. Fin: `Jamais` (génère 2 ans = ~730 événements)
3. Enregistrer
4. Chronométrer temps génération

**Résultats attendus :**
- ✅ Génération complète < 30 secondes
- ✅ UI reste responsive
- ✅ Pas de crash
- ✅ Tous événements créés dans Firestore

**Temps :** ~5 min  
**Priorité :** 🟡 HAUTE

---

### Test 9.2 : Chargement timeline 50+ réunions

**Objectif :** Tester performance affichage liste

**Étapes :**
1. Groupe du Test 9.1 (730 événements)
2. Ouvrir onglet **Réunions**
3. Scroller jusqu'en bas
4. Observer fluidité

**Résultats attendus :**
- ✅ Chargement initial < 2 secondes
- ✅ Scroll fluide (60 FPS)
- ✅ Pas de lag
- ✅ Lazy loading si > 100 réunions

**Temps :** ~2 min  
**Priorité :** 🟡 HAUTE

---

## 📋 Test Suite 10 : Index Firestore

### Test 10.1 : Requête événements par groupe

**Objectif :** Vérifier index linkedGroupId + startDate

**Étapes :**
1. Ouvrir Firebase Console
2. Firestore → Collection `events`
3. Filtrer :
   - `linkedGroupId` == `{groupId du Test 1.1}`
   - ORDER BY `startDate` ASC
4. Observer temps requête

**Résultats attendus :**
- ✅ Requête réussit (pas d'erreur "Missing index")
- ✅ Temps < 100ms
- ✅ Résultats triés par date
- ✅ Index utilisé (visible dans console)

**Temps :** ~2 min  
**Priorité :** 🔴 CRITIQUE

---

### Test 10.2 : Requête meetings par eventId

**Objectif :** Vérifier index COLLECTION_GROUP linkedEventId

**Étapes :**
1. Firebase Console
2. Firestore → Collection Group Query
3. Collection: `meetings`
4. Filtrer: `linkedEventId` == `{eventId}`
5. Exécuter

**Résultats attendus :**
- ✅ Requête réussit
- ✅ Temps < 50ms
- ✅ Retourne meeting(s) correspondant(s)

**Temps :** ~2 min  
**Priorité :** 🔴 CRITIQUE

---

## 📊 Rapport Final

### Résumé des Tests

| Suite | Tests | Durée | Priorité |
|-------|-------|-------|----------|
| Suite 1 (Création) | 3 | 8 min | 🔴 |
| Suite 2 (Interface) | 3 | 4 min | 🟡 |
| Suite 3 (Dialog) | 3 | 2 min | 🔴 |
| Suite 4 (Modifications) | 3 | 6 min | 🔴 |
| Suite 5 (Sync) | 2 | 4 min | 🟡 |
| Suite 6 (Désactivation) | 2 | 4 min | 🟡 |
| Suite 7 (Exclusion) | 1 | 2 min | 🟡 |
| Suite 8 (Edge Cases) | 3 | 9 min | 🟢 |
| Suite 9 (Performance) | 2 | 7 min | 🟡 |
| Suite 10 (Index) | 2 | 4 min | 🔴 |

**Total :** 24 tests, ~50 minutes

---

### Checklist Validation Finale

- [ ] Toutes les suites 🔴 CRITIQUE passées (13 tests)
- [ ] Au moins 80% des suites 🟡 HAUTE passées
- [ ] 0 erreurs compilation
- [ ] 0 warnings critiques
- [ ] Firebase index déployés et fonctionnels
- [ ] Documentation utilisateur complète
- [ ] Code commenté et lisible

---

### Bugs Trouvés (Template)

| ID | Suite | Test | Sévérité | Description | Status |
|----|-------|------|----------|-------------|--------|
| BUG-001 | Suite 4 | Test 4.2 | Haute | Modification "futures" affecte passées | 🔴 Ouvert |
| BUG-002 | Suite 9 | Test 9.1 | Moyenne | Génération > 30s pour 730 événements | 🟡 En cours |

---

## ✅ Validation Finale

**Date test :** _______________  
**Testeur :** _______________  
**Version app :** _______________

**Résultats :**
- Tests réussis : _____ / 24
- Tests échoués : _____
- Tests skippés : _____

**Décision :**
- [ ] ✅ **VALIDÉ** - Prêt pour production
- [ ] ⚠️ **VALIDÉ avec réserves** - Bugs mineurs
- [ ] ❌ **NON VALIDÉ** - Bugs critiques

**Signature :** _______________

---

**Fichiers générés :**
- [ ] `GUIDE_UTILISATEUR_GROUPES_EVENEMENTS.md`
- [ ] `GUIDE_TESTS_MANUELS.md` (ce fichier)
- [ ] `SCRIPT_MIGRATION_GROUPES.dart`
- [ ] `PHASE_8_COMPLETE_RAPPORT.md`

**Prêt pour déploiement ! 🚀**

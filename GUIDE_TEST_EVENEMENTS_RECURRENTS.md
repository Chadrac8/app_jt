# 🧪 Guide de Test Rapide - Événements Récurrents

**Date**: 13 octobre 2025  
**Objectif**: Tester le nouveau système d'événements récurrents individuels

---

## ✅ Tests de Base (15 minutes)

### Test 1 : Créer un Événement Récurrent Simple ⏱️ 3 min

**Actions** :
1. Ouvrir l'app et naviguer vers "Événements"
2. Cliquer sur "+" pour créer un nouvel événement
3. Remplir :
   - Titre : "Test Culte du Dimanche"
   - Date : Prochain dimanche
   - Heure : 10h00
   - Lieu : "Église Test"
4. **Activer "Événement récurrent"**
5. Choisir :
   - Fréquence : Hebdomadaire
   - Jour : Dimanche
   - Fin : Après 10 occurrences
6. Cliquer "Enregistrer"

**Résultats attendus** :
- ✅ Message de succès : "Série créée avec succès"
- ✅ Navigation vers le calendrier
- ✅ 10 événements visibles dans le calendrier sur les 10 prochains dimanches
- ✅ Chaque événement a une petite icône 🔁 (repeat)
- ✅ Aucun badge "Modifié" visible

**Vérification Firestore** (optionnel) :
```
Console Firebase → Firestore → Collection "events"
- Vérifier : 10 documents créés
- Tous ont le même "seriesId"
- Le premier a "isSeriesMaster: true"
```

---

### Test 2 : Modifier UNE Occurrence ⏱️ 4 min

**Actions** :
1. Dans le calendrier, cliquer sur le **3ème dimanche** de la série
2. Cliquer sur "Modifier" (icône crayon)
3. **Dialog apparaît** : "Modifier un événement récurrent"
4. **Choisir** : ○ "Cet événement uniquement"
5. Cliquer "Continuer"
6. Modifier :
   - Titre : "Test Culte SPÉCIAL"
   - Heure : 15h00 (au lieu de 10h00)
7. Cliquer "Enregistrer"

**Résultats attendus** :
- ✅ Message : "Cette occurrence a été modifiée avec succès"
- ✅ Retour au calendrier
- ✅ Le 3ème dimanche affiche maintenant :
  - Titre : "Test Culte SPÉCIAL"
  - Heure : 15h00
  - Icône 🔁 toujours présente
  - **Badge orange "Modifié"** visible
- ✅ Les 9 autres dimanches restent inchangés (titre original, 10h00)

**Points clés** :
- Le badge "Modifié" confirme que cette occurrence a été modifiée individuellement
- Les autres occurrences ne sont PAS affectées

---

### Test 3 : Supprimer UNE Occurrence ⏱️ 3 min

**Actions** :
1. Dans le calendrier, cliquer sur le **5ème dimanche** de la série
2. Cliquer sur le menu "⋮" (trois points)
3. Sélectionner "Supprimer"
4. **Dialog apparaît** : "Supprimer un événement récurrent"
5. **Choisir** : ○ "Cet événement uniquement"
6. Cliquer "Supprimer" (bouton rouge)

**Résultats attendus** :
- ✅ Message : "Cette occurrence a été supprimée"
- ✅ Retour au calendrier
- ✅ Le 5ème dimanche est maintenant **vide** (événement disparu)
- ✅ Les autres dimanches (1, 2, 3, 4, 6, 7, 8, 9, 10) sont toujours visibles

**Points clés** :
- L'événement est en "soft delete" (deletedAt renseigné)
- Il reste en base de données mais invisible pour l'utilisateur
- Possibilité de restaurer plus tard si besoin

---

### Test 4 : Modifier TOUTES les Occurrences ⏱️ 3 min

**Actions** :
1. Cliquer sur **n'importe quel dimanche** de la série (par ex. le 7ème)
2. Cliquer "Modifier"
3. **Dialog apparaît**
4. **Choisir** : ○ "Tous les événements de la série"
5. Cliquer "Continuer"
6. Modifier :
   - Lieu : "Nouvelle Église Test"
7. Cliquer "Enregistrer"

**Résultats attendus** :
- ✅ Message : "Toutes les occurrences ont été modifiées"
- ✅ **TOUS les 9 dimanches restants** (on a supprimé le 5ème) affichent maintenant :
  - Lieu : "Nouvelle Église Test"
- ✅ Le 3ème dimanche (modifié avant) :
  - Garde son titre : "Test Culte SPÉCIAL"
  - Garde son heure : 15h00
  - A maintenant le nouveau lieu : "Nouvelle Église Test"
  - **Perd son badge "Modifié"** (car la modification globale réinitialise ce flag)

**Points clés** :
- Modifier "Tous les événements" applique le changement à toutes les occurrences
- Les modifications individuelles précédentes restent (titre, heure) mais le flag "modifié" est réinitialisé

---

### Test 5 : Supprimer Toutes les Futures Occurrences ⏱️ 2 min

**Actions** :
1. Cliquer sur le **8ème dimanche**
2. Cliquer menu "⋮" → "Supprimer"
3. **Dialog apparaît**
4. **Choisir** : ○ "Cet événement et les suivants"
5. Cliquer "Supprimer"

**Résultats attendus** :
- ✅ Message : "Cette occurrence et les suivantes ont été supprimées"
- ✅ Les dimanches 8, 9, 10 **disparaissent** du calendrier
- ✅ Les dimanches 1, 2, 3, 4, 6, 7 restent visibles
- ✅ La série est maintenant "terminée" au 7ème dimanche

**Points clés** :
- Utile pour arrêter une série récurrente à une date donnée
- Toutes les occurrences futures sont soft-deleted

---

## 🎨 Tests Visuels (5 minutes)

### Vérifier les Indicateurs Visuels

**Dans le calendrier** :
- [ ] Icône 🔁 (repeat) visible sur tous les événements de série
- [ ] Badge orange "Modifié" visible uniquement sur les occurrences modifiées individuellement
- [ ] Événements supprimés n'apparaissent plus (deletedAt filtré)

**Dans la page de détail** :
- [ ] Bouton "Modifier" ouvre le dialog de choix pour événements de série
- [ ] Bouton "Supprimer" ouvre le dialog de choix pour événements de série
- [ ] Événements simples (non récurrents) n'ont pas de dialog

---

## 🚀 Tests de Performance (Optionnel, 10 minutes)

### Test 6 : Créer une Grande Série

**Actions** :
1. Créer un événement récurrent :
   - Fréquence : Hebdomadaire
   - Fin : Après **52 occurrences** (1 an)
2. Noter le temps de création

**Résultat attendu** :
- ✅ Temps < 5 secondes pour créer 52 événements
- ✅ 52 événements affichés dans le calendrier

### Test 7 : Modifier Toutes les Occurrences d'une Grande Série

**Actions** :
1. Modifier une occurrence de la série de 52
2. Choisir "Tous les événements"
3. Changer le titre
4. Noter le temps

**Résultat attendu** :
- ✅ Temps < 10 secondes pour modifier 52 événements
- ✅ Tous les événements ont le nouveau titre

---

## ❌ Tests d'Erreur (5 minutes)

### Test 8 : Annuler les Dialogs

**Actions** :
1. Ouvrir un événement récurrent
2. Cliquer "Modifier"
3. **Cliquer "Annuler"** dans le dialog
4. Vérifier : Rien ne se passe, retour à la page de détail

5. Cliquer "Supprimer"
6. **Cliquer "Annuler"** dans le dialog
7. Vérifier : Rien ne se passe, retour à la page de détail

**Résultat attendu** :
- ✅ Annuler un dialog ne fait aucune action
- ✅ L'événement reste inchangé

### Test 9 : Modifier sans Sélectionner d'Option

**Actions** :
1. Ouvrir un événement récurrent
2. Cliquer "Modifier"
3. **Ne pas cocher d'option**
4. Essayer de cliquer "Continuer"

**Résultat attendu** :
- ✅ Bouton "Continuer" est désactivé (grisé)
- ✅ Impossible de continuer sans choisir une option

---

## 📊 Checklist Finale

Après avoir effectué tous les tests :

- [ ] ✅ Créer une série de 10 événements fonctionne
- [ ] ✅ Icône 🔁 visible sur tous les événements de la série
- [ ] ✅ Modifier une occurrence affiche le dialog de choix
- [ ] ✅ Modifier "Cet événement uniquement" fonctionne
- [ ] ✅ Badge "Modifié" apparaît sur l'occurrence modifiée
- [ ] ✅ Modifier "Tous les événements" met à jour toute la série
- [ ] ✅ Supprimer "Cet événement uniquement" cache l'occurrence
- [ ] ✅ Supprimer "Cet événement et les suivants" cache les futures
- [ ] ✅ Événements supprimés disparaissent du calendrier
- [ ] ✅ Performance acceptable (<5s création, <10s modification)
- [ ] ✅ Dialogs annulables sans effet
- [ ] ✅ Boutons désactivés si aucune option choisie

---

## 🐛 Problèmes Potentiels et Solutions

### Problème 1 : Les événements n'apparaissent pas dans le calendrier

**Causes possibles** :
- Les événements ont `deletedAt != null`
- Le filtre de dates est mal configuré
- Le `seriesId` n'est pas renseigné

**Solution** :
```dart
// Vérifier dans Firestore que deletedAt est null
// Vérifier que les dates sont dans la période affichée
```

### Problème 2 : Le badge "Modifié" ne s'affiche pas

**Causes possibles** :
- `isModifiedOccurrence` n'est pas à `true`
- Le widget n'utilise pas la condition `if (event.isModifiedOccurrence)`

**Solution** :
```dart
// Vérifier dans event_calendar_view.dart ligne ~385
if (event.isModifiedOccurrence) {
  // Badge "Modifié"
}
```

### Problème 3 : Les dialogs ne s'affichent pas

**Causes possibles** :
- `seriesId` est null (événement simple)
- Imports manquants

**Solution** :
```dart
// Vérifier dans event_detail_page.dart
import '../widgets/recurring_event_edit_dialog.dart';
import '../widgets/recurring_event_delete_dialog.dart';
```

### Problème 4 : Erreur lors de la création de série

**Message** : `"Erreur lors de la création de la série: ..."`

**Causes possibles** :
- Règle de récurrence invalide
- Problème de connexion Firestore
- Limite de batch (>500 événements)

**Solution** :
```dart
// Vérifier les logs console pour le message d'erreur exact
// Réduire le nombre d'occurrences si > 500
```

---

## 📝 Notes pour le Développeur

### Logs à Surveiller

Lors de la création d'une série, vous devriez voir :
```
📅 Création série récurrente: Test Culte du Dimanche
   Règle: Toutes les semaines
   Pré-génération: 6 mois
   Occurrences à créer: 26
   ✅ Batch de 26 événements créé
✅ Série créée: 26 événements (ID: series_1697198400000_123456)
```

Lors de la modification :
```
✏️ Modification occurrence unique: event_abc123
✅ Occurrence modifiée
```

Lors de la suppression :
```
🗑️ Suppression occurrence unique: event_xyz789
✅ Occurrence supprimée (soft delete)
```

---

## ✅ Conclusion

Si tous les tests passent, le système d'événements récurrents individuels fonctionne correctement ! 🎉

**Temps total estimé** : 35 minutes
- Tests de base : 15 min
- Tests visuels : 5 min
- Tests de performance : 10 min
- Tests d'erreur : 5 min

**Prochaine étape** : Tests utilisateur réels avec votre équipe 👥


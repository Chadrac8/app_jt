# 🔧 Guide de Migration : Événements Récurrents

## 🎯 Objectif

Corriger les événements récurrents existants qui ne s'affichent pas dans le calendrier.

## ❌ Problème

Les événements créés **avant** la correction ont :
- ✅ `isRecurring: true`
- ❌ `recurrence: null` (champ vide)

Le calendrier ne peut pas afficher leurs occurrences car il vérifie si `event.recurrence != null`.

## ✅ Solution

Une **migration automatique** qui :
1. Lit les règles de récurrence depuis `event_recurrences` collection
2. Les convertit en format `EventRecurrence`
3. Les ajoute au champ `recurrence` de chaque événement

## 📋 Instructions

### Option 1 : Via l'Interface Admin (Recommandé)

1. **Ouvrir l'app** en tant qu'administrateur

2. **Naviguer vers la page de migration** :
   ```dart
   // Ajouter cette route temporairement dans votre navigation
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => const FixRecurrenceAdminPage(),
     ),
   );
   ```

3. **Cliquer sur "Lancer la Migration"**

4. **Attendre** que la migration se termine (quelques secondes)

5. **Vérifier les logs** :
   - ✅ Nombre d'événements corrigés
   - ✓  Événements déjà OK
   - ❌ Erreurs éventuelles

6. **Tester le calendrier** : Les occurrences doivent maintenant apparaître

### Option 2 : Via Script Console

Si vous préférez exécuter via un script :

```dart
import 'package:app_jubile_tabernacle/scripts/fix_existing_recurring_events.dart';

void main() async {
  // Initialiser Firebase d'abord
  await Firebase.initializeApp();
  
  // Exécuter la migration
  await FixExistingRecurringEvents.run();
}
```

## 🧪 Test de Validation

### Avant Migration

1. Ouvrir le calendrier
2. Chercher un service récurrent (ex: Culte Dominical)
3. ❌ Pas d'occurrences visibles dans les semaines futures

### Après Migration

1. Recharger le calendrier
2. ✅ Les occurrences apparaissent chaque semaine
3. ✅ Événements cliquables et affichant les détails

### Vérification Firestore

```javascript
// Dans la console Firestore
db.collection('events')
  .where('isRecurring', '==', true)
  .get()
  .then(snap => {
    snap.docs.forEach(doc => {
      const data = doc.data();
      console.log(doc.id, {
        title: data.title,
        hasRecurrence: !!data.recurrence
      });
    });
  });
```

Tous les événements doivent avoir `hasRecurrence: true`.

## 📊 Logs Exemple

```
🔧 Début de la migration des événements récurrents...

📊 3 événements récurrents trouvés

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Événement: Culte Dominical
🆔 ID: abc123
⚠️  Champ recurrence manquant, tentative de correction...
✅ Règle de récurrence trouvée: rec456
✅ Événement mis à jour avec succès

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Événement: Réunion de Prière
🆔 ID: def789
✅ Champ recurrence déjà présent, skip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Événement: École du Dimanche
🆔 ID: ghi012
⚠️  Champ recurrence manquant, tentative de correction...
✅ Règle de récurrence trouvée: rec789
✅ Événement mis à jour avec succès

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RÉSUMÉ DE LA MIGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Événements corrigés: 2
✓  Déjà OK: 1
❌ Erreurs: 0
📊 Total traité: 3

✅ Migration terminée !
```

## ⚠️ Précautions

### Important
- ✅ **Sauvegardez Firestore** avant (facultatif mais recommandé)
- ✅ Exécutez **UNE SEULE FOIS** après le déploiement
- ✅ Vérifiez les **logs** pour détecter les erreurs
- ✅ Testez sur un **environnement de dev** d'abord si possible

### Cas d'Erreur

Si un événement n'a **pas** de règle dans `event_recurrences` :
- ❌ Il sera signalé dans les logs
- 🔧 Solution manuelle : Créer la règle via l'interface ou supprimer `isRecurring`

## 🔄 Nouveaux Événements

Les événements créés **après** la correction fonctionnent automatiquement :
- ✅ Le champ `recurrence` est rempli lors de la création
- ✅ Les occurrences apparaissent immédiatement dans le calendrier
- ✅ Aucune migration nécessaire

## 📂 Fichiers Concernés

### Script de Migration
- `lib/scripts/fix_existing_recurring_events.dart`

### Page Admin
- `lib/pages/fix_recurrence_admin_page.dart`

### Service d'Intégration (Corrigé)
- `lib/services/service_event_integration_service.dart`
  - Méthode : `_convertServicePatternToEventRecurrence()`

## 🚀 Prochaines Étapes

1. **Exécuter la migration** sur les données existantes
2. **Tester** que le calendrier affiche les occurrences
3. **Supprimer** la page admin (optionnel, après migration)
4. **Monitorer** les nouveaux événements créés

## 💡 FAQ

### Q: La migration modifie-t-elle les données existantes ?
**R:** Oui, elle ajoute le champ `recurrence` aux événements qui en manquent. Les autres données restent inchangées.

### Q: Puis-je relancer la migration plusieurs fois ?
**R:** Oui, elle détecte les événements déjà corrigés et les ignore (`skip`).

### Q: Que faire si j'ai des erreurs ?
**R:** Vérifiez que :
- Firebase est bien initialisé
- Les règles Firestore permettent l'écriture
- Chaque événement récurrent a une règle dans `event_recurrences`

### Q: Les instances Firestore (event_instances) sont-elles affectées ?
**R:** Non, la migration ne touche que les documents `events`. Les instances existantes restent intactes.

---

**Date** : 2024
**Version** : 1.0
**Status** : ✅ Prêt pour Production

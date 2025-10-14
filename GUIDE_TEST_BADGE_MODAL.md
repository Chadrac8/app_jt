# ✅ Guide Test Rapide - Badge & Modal Services Récurrents

**Date** : 13 octobre 2025  
**Durée** : 5 minutes  
**Prérequis** : Index Firestore "Enabled" (vérifier dans console)

---

## 🎯 Test Complet en 5 Étapes

### Étape 1 : Vérifier l'Index (30 secondes)

1. Ouvrir : https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/firestore/indexes
2. Chercher index `events` avec `linkedServiceId` + `startDate`
3. Vérifier statut = **🟢 Enabled**

**Si statut = Building** → Attendre 1-2 minutes supplémentaires

---

### Étape 2 : Lancer l'App (30 secondes)

```bash
cd /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle
flutter run -d "NTS-I15PM"
```

Attendez le hot reload complet.

---

### Étape 3 : Tester le Badge 🔁 (1 minute)

1. **Ouvrir** : Module Services
2. **Trouver** : Un service récurrent existant
3. **Observer** : Badge 🔁 X en bas à droite de la carte

**Résultats attendus** :
- ✅ Badge visible avec nombre
- ✅ Pas d'erreur dans les logs
- ✅ Badge cliquable (effet ripple au toucher)

**Si badge n'apparaît pas** :
- Vérifier que le service est bien marqué `isRecurring: true`
- Vérifier qu'il a un `linkedEventId`
- Check logs : Devrait voir "Loading occurrences count"

---

### Étape 4 : Tester le Modal (2 minutes)

1. **Cliquer** sur le badge 🔁 X
2. **Observer** le modal qui s'ouvre

**Checklist Modal** :
- [ ] Header : "Occurrences du service" + nom du service
- [ ] Stats : Total, Complets (✅), Incomplets (⚠️)
- [ ] Liste scrollable des occurrences
- [ ] Dates formatées avec indications ("Aujourd'hui", "Dans X jours")
- [ ] Badges statut (PUBLIÉ/BROUILLON/etc.)
- [ ] Badges assignations (nombre de personnes)
- [ ] Bouton "Voir dans Planning"
- [ ] Bouton "Fermer"

**Résultats attendus** :
- ✅ Modal s'ouvre avec animation
- ✅ Stats correctes (Total = somme des occurrences)
- ✅ Toutes occurrences listées
- ✅ Pas d'erreur "query requires index"

**Test Interactions** :
- [ ] Cliquer sur une occurrence → Navigation vers détails
- [ ] Cliquer "Voir dans Planning" → Ouvre ServicesPlanningView
- [ ] Cliquer "Fermer" → Modal se ferme
- [ ] Cliquer en dehors → Modal se ferme

---

### Étape 5 : Tester Vue Planning (1 minute)

1. **Depuis le modal** : Cliquer "Voir dans Planning"
   OU
   **Depuis Services** : Cliquer icône 📅 en haut

2. **Observer** la vue Planning

**Checklist Planning** :
- [ ] Occurrences groupées par semaine
- [ ] Dates de semaine affichées ("Semaine du X")
- [ ] Cartes d'occurrences avec détails
- [ ] Indicateurs complet/incomplet
- [ ] Bouton [person_add] visible
- [ ] Mode sélection disponible

**Résultats attendus** :
- ✅ Vue Planning s'ouvre
- ✅ Toutes occurrences visibles
- ✅ Groupement par semaine correct
- ✅ Pas d'erreur

---

## 🐛 Résolution Problèmes Courants

### Problème 1 : Badge ne s'affiche pas

**Symptômes** :
- Carte de service sans badge 🔁
- Service est pourtant récurrent

**Causes possibles** :
1. Service pas marqué `isRecurring: true`
2. Pas de `linkedEventId` 
3. Aucun événement lié dans Firestore

**Solutions** :
```dart
// Vérifier dans Firestore Console:
// Collection: services/SERVICE_ID
// Champs à vérifier:
isRecurring: true  ✅
linkedEventId: "event_xyz..."  ✅
recurrencePattern: { type: "weekly", ... }  ✅

// Collection: events
// Filtre: linkedServiceId == SERVICE_ID
// Résultat: Devrait avoir N documents
```

### Problème 2 : Erreur "query requires index"

**Symptômes** :
```
[cloud_firestore/failed-precondition] The query requires an index
```

**Solution** :
1. Vérifier index dans console : https://console.firebase.google.com/.../firestore/indexes
2. Si statut = Building → Attendre
3. Si statut = Error → Recréer via lien dans erreur
4. Si index absent → Vérifier `firestore.indexes.json` et redéployer

### Problème 3 : Modal vide

**Symptômes** :
- Modal s'ouvre
- Affiche "Aucune occurrence"
- Mais service a bien des occurrences

**Causes possibles** :
1. Événements n'ont pas `linkedServiceId`
2. Événements ont `deletedAt != null`
3. Index pas encore prêt

**Solutions** :
```dart
// Vérifier dans Firestore Console:
// Collection: events
// Filtre: linkedServiceId == "SERVICE_ID"
// Champs à vérifier pour chaque event:
linkedServiceId: "service_abc123"  ✅
deletedAt: null  ✅
startDate: Timestamp(...)  ✅
```

### Problème 4 : Stats incorrectes

**Symptômes** :
- Total ≠ Complet + Incomplet
- Nombres incohérents

**Cause** :
Logique de calcul "complet" :
```dart
bool _isOccurrenceComplete(EventModel event) {
  return event.responsibleIds.length >= 3;
}
```

**Comportement attendu** :
- Complet si ≥ 3 personnes assignées
- Incomplet si < 3 personnes

**Vérification** :
```dart
// Dans Firestore, pour chaque event:
responsibleIds: ["id1", "id2", "id3"]  → Complet ✅
responsibleIds: ["id1", "id2"]         → Incomplet ⚠️
responsibleIds: []                     → Incomplet ⚠️
```

---

## 📊 Résultats Attendus - Résumé

### Service Hebdomadaire × 6 mois

**Configuration** :
- Nom : "Culte Dominical"
- Récurrence : Tous les dimanches
- Durée : 6 mois
- Date début : 13 octobre 2025

**Résultats** :

| Élément | Valeur Attendue |
|---------|-----------------|
| **Badge** | 🔁 26 |
| **Total occurrences** | 26 |
| **Dates** | 13 oct → 12 avril |
| **Espacement** | 7 jours entre chaque |
| **Stats (si pas d'assignations)** | Total: 26, Complets: 0, Incomplets: 26 |

### Service Mensuel × 6 mois

**Configuration** :
- Nom : "Réunion Conseil"
- Récurrence : 1er lundi de chaque mois
- Durée : 6 mois

**Résultats** :

| Élément | Valeur Attendue |
|---------|-----------------|
| **Badge** | 🔁 6 |
| **Total occurrences** | 6 |
| **Dates** | Nov, Déc, Jan, Fév, Mar, Avr |
| **Espacement** | ~30 jours entre chaque |

---

## ✅ Checklist Finale

### Fonctionnalités

- [ ] Badge 🔁 apparaît sur services récurrents
- [ ] Badge affiche le bon nombre d'occurrences
- [ ] Badge est cliquable
- [ ] Modal s'ouvre au clic
- [ ] Stats correctes dans le modal
- [ ] Liste complète des occurrences
- [ ] Dates formatées lisiblement
- [ ] Navigation vers détails fonctionne
- [ ] Navigation vers Planning fonctionne
- [ ] Vue Planning affiche toutes occurrences
- [ ] Pas d'erreur "query requires index"

### Performance

- [ ] Badge charge en < 1 seconde
- [ ] Modal s'ouvre en < 500ms
- [ ] Liste scroll fluide
- [ ] Pas de lag

### Design

- [ ] Badge bien positionné (bas droite)
- [ ] Couleurs conformes au thème
- [ ] Animations fluides
- [ ] Textes lisibles
- [ ] Boutons bien espacés

---

## 🎉 Si Tous les Tests Passent

**Félicitations ! Les 3 fonctionnalités sont opérationnelles :**

1. ✅ **Badge 🔁** : Indication visuelle du nombre d'occurrences
2. ✅ **Modal Occurrences** : Vue détaillée avec stats
3. ✅ **Vue Planning** : Gestion avancée par semaine

**Prochaines étapes possibles** :
- Créer plus de services récurrents
- Tester les assignations
- Utiliser les actions en masse
- Explorer les filtres

---

## 📝 Rapport de Test

```
Date: _____________
Testeur: _____________

Service testé: _____________
Type récurrence: _____________
Nombre occurrences attendu: _____

RÉSULTATS:
[ ] Badge visible
[ ] Nombre correct
[ ] Modal fonctionne
[ ] Stats justes
[ ] Navigation OK
[ ] Planning OK

PROBLÈMES RENCONTRÉS:
_______________________________________
_______________________________________
_______________________________________

NOTES:
_______________________________________
_______________________________________
```

---

**Bon test ! 🚀**

Si tout fonctionne, vous avez maintenant une solution complète pour gérer vos services récurrents ! 🎊

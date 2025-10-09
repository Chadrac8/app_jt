# ✅ Liste de Vérification : Calendrier des Événements Récurrents

## 🎯 Objectif
Vérifier que les occurrences des événements récurrents apparaissent maintenant dans le calendrier.

---

## 📋 Checklist de Vérification

### ☑️ Étape 1 : Migration Exécutée
- [ ] J'ai ouvert l'outil de migration (http://127.0.0.1:50382/)
- [ ] J'ai cliqué sur "Lancer la Migration"
- [ ] La console affiche un résumé (nombre d'événements corrigés)

**Résultat attendu** :
```
✅ Événements corrigés: X
✓  Déjà OK: Y
❌ Erreurs: 0
```

---

### ☑️ Étape 2 : Vérification Visuelle dans le Calendrier

#### 2.1 Ouvrir l'Application
```bash
# Si pas déjà lancée
flutter run -d chrome
```

#### 2.2 Naviguer vers le Calendrier
- [ ] Aller dans **Module Événements**
- [ ] Ouvrir la **vue Calendrier**

#### 2.3 Chercher un Événement Récurrent
- [ ] Identifier un événement récurrent (ex: "Culte Dominical")
- [ ] Vérifier qu'il a une icône de récurrence (🔄)

#### 2.4 Vérifier les Occurrences
- [ ] **Naviguer vers les semaines/mois futurs**
- [ ] Les occurrences doivent apparaître aux dates prévues
- [ ] Chaque occurrence est cliquable
- [ ] Les détails s'affichent correctement

**Exemple** : 
- Culte Dominical tous les dimanches
  - ✅ 13 octobre 2025
  - ✅ 20 octobre 2025
  - ✅ 27 octobre 2025
  - ✅ 3 novembre 2025
  - etc.

---

### ☑️ Étape 3 : Vérification Technique

#### 3.1 Console Développeur (Facultatif)
- [ ] Ouvrir DevTools (F12 dans Chrome)
- [ ] Onglet "Console"
- [ ] Pas d'erreurs JavaScript/Dart liées aux événements

#### 3.2 Firestore Console (Facultatif)
1. [ ] Ouvrir [Firebase Console](https://console.firebase.google.com)
2. [ ] Naviguer vers Firestore Database
3. [ ] Collection `events`
4. [ ] Filtrer : `isRecurring == true`
5. [ ] Cliquer sur un document
6. [ ] **Vérifier** : Champ `recurrence` présent et rempli

**Format attendu** :
```json
{
  "isRecurring": true,
  "recurrence": {
    "frequency": "weekly",
    "interval": 1,
    "daysOfWeek": ["sunday"],
    "endType": "never"
  }
}
```

---

## 🐛 Résolution des Problèmes

### ❌ Problème 1 : "Aucun événement récurrent trouvé"

**Cause** : Pas d'événements récurrents dans la base

**Solution** :
1. Créer un nouveau service récurrent via l'interface
2. Vérifier qu'il apparaît dans le calendrier
3. Si oui → Tout fonctionne ✅
4. Si non → Continuer le diagnostic

---

### ❌ Problème 2 : Migration OK mais pas d'occurrences

**Vérifications** :

#### A. Date de l'Événement
- [ ] L'événement a-t-il commencé dans le passé ?
- [ ] Naviguez vers des dates **futures** dans le calendrier
- [ ] Les occurrences doivent apparaître dans le futur

#### B. Filtre de Recherche/Type
- [ ] Y a-t-il des filtres actifs dans le calendrier ?
- [ ] Désactivez tous les filtres
- [ ] Réessayez

#### C. Cache du Navigateur
- [ ] Recharger la page (Cmd+R ou Ctrl+R)
- [ ] Vider le cache (Cmd+Shift+R ou Ctrl+Shift+R)
- [ ] Réessayer

---

### ❌ Problème 3 : Erreurs dans la Migration

**Si la console affiche des erreurs** :

#### Erreur : "Aucune règle de récurrence trouvée"
**Cause** : L'événement n'a pas de document correspondant dans `event_recurrences`

**Solution** :
1. Ouvrir Firestore Console
2. Vérifier la collection `event_recurrences`
3. Option A : Créer manuellement la règle
4. Option B : Supprimer l'événement et le recréer

#### Erreur : "Permission denied"
**Cause** : Règles Firestore restrictives

**Solution** :
1. Vérifier les règles Firestore
2. S'assurer que vous êtes connecté en tant qu'admin
3. Vérifier les permissions d'écriture sur la collection `events`

---

## ✅ Validation Finale

### Test Complet

1. **Créer un Nouvel Événement Récurrent** :
   - [ ] Aller dans Services
   - [ ] Créer un nouveau service récurrent (ex: "Test Hebdomadaire")
   - [ ] Pattern : Chaque semaine, le mercredi
   - [ ] Sauvegarder

2. **Vérifier dans le Calendrier** :
   - [ ] Ouvrir le calendrier
   - [ ] Naviguer vers les prochains mercredis
   - [ ] ✅ Les occurrences doivent apparaître immédiatement

**Si ce test fonctionne** → ✅ **TOUT EST OPÉRATIONNEL !**

---

## 📊 Résumé des États Possibles

| État | Description | Action |
|------|-------------|--------|
| ✅ **Tout fonctionne** | Migration OK + Occurrences visibles | Rien à faire ! |
| ⚠️ **Anciens OK, nouveaux NON** | Migration OK mais code non déployé | Redémarrer l'app principale |
| ⚠️ **Nouveaux OK, anciens NON** | Code OK mais migration non exécutée | Relancer la migration |
| ❌ **Rien ne fonctionne** | Problème de configuration | Voir diagnostic ci-dessus |

---

## 🎉 Confirmation de Succès

Vous saurez que tout fonctionne quand :

1. ✅ **Migration terminée sans erreur**
2. ✅ **Nouveaux événements** → Occurrences visibles immédiatement
3. ✅ **Anciens événements** → Occurrences visibles après migration
4. ✅ **Calendrier fluide** → Aucune erreur console
5. ✅ **Tous les types** → Daily/Weekly/Monthly/Yearly fonctionnent

---

## 📞 Si Problème Persiste

**Informations à fournir pour le support** :

1. Logs de la console de migration
2. Capture d'écran du calendrier
3. Un exemple d'événement récurrent (ID Firestore)
4. Les erreurs dans la console développeur (F12)

---

## 🚀 Prochaines Étapes

Une fois que tout fonctionne :

- [ ] Fermer l'outil de migration
- [ ] Supprimer le fichier `run_recurrence_migration.dart` (optionnel)
- [ ] Documenter la procédure pour votre équipe
- [ ] Monitorer les nouveaux événements créés

---

**Date de Vérification** : 9 octobre 2025
**Status** : ☐ En attente ☐ Réussi ☐ Problème détecté

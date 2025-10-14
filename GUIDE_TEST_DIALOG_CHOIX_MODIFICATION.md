# 🧪 Guide de Test - Dialog de Choix de Modification

**Date**: 13 octobre 2025  
**Temps estimé**: 5 minutes  
**Prérequis**: App en cours d'exécution, service récurrent existant

---

## 🎯 Test rapide (2 minutes)

### Étape 1 : Accéder aux occurrences

```
1. Ouvrir l'app
2. Aller dans Services
3. Trouver un service récurrent (badge 🔁 X)
4. Cliquer sur le badge 🔁
   → Modal des occurrences s'ouvre
```

### Étape 2 : Tester le dialog de choix

```
5. Cliquer sur une occurrence dans la liste
   → Dialog "Modifier un service récurrent" s'affiche
6. Vérifier les éléments affichés :
   ✅ Titre : "Modifier un service récurrent"
   ✅ Icon 🔁 bleu
   ✅ Message info : "Ce service se répète..."
   ✅ Nom du service affiché
   ✅ Date de l'occurrence affichée
   ✅ 2 options avec radio buttons
```

### Étape 3 : Tester "Cette occurrence uniquement"

```
7. Option "Cette occurrence uniquement" est pré-sélectionnée
8. Cliquer sur [Continuer]
   → Modal des occurrences se ferme
   → EventDetailPage s'ouvre
   → Bonne occurrence affichée
9. Modifier le titre (exemple : "Culte Spécial")
10. Sauvegarder
11. Retourner au modal occurrences
    → ✅ Vérifier : Seule cette occurrence a changé
```

### Étape 4 : Tester "Toutes les occurrences"

```
12. Cliquer sur une autre occurrence
    → Dialog s'affiche
13. Sélectionner "Toutes les occurrences"
14. Cliquer sur [Continuer]
    → ServiceDetailPage s'ouvre
15. Modifier le lieu (exemple : "Grande Salle")
16. Sauvegarder
17. Retourner au modal occurrences
    → ✅ Vérifier : TOUTES les occurrences ont le nouveau lieu
```

---

## 🎨 Test visuel détaillé (3 minutes)

### Test 1 : États visuels

```
Option sélectionnée :
  ✅ Border bleu 2px
  ✅ Background bleu clair
  ✅ Icon container bleu clair
  ✅ Icon bleu
  ✅ Text gras

Option non sélectionnée :
  ✅ Border gris 1px
  ✅ Background transparent
  ✅ Icon container gris
  ✅ Icon gris
  ✅ Text normal
```

### Test 2 : Interactions

```
✅ Radio button : Clic change sélection
✅ Toute l'option : Clic change sélection
✅ Ripple effect : Animation visible sur clic
✅ Border : Transition smooth lors changement
✅ Bouton Annuler : Ferme dialog sans action
✅ Bouton Continuer : Navigue selon choix
```

### Test 3 : Formatage date

```
Aujourd'hui :
  ✅ "📍 Aujourd'hui · dimanche 13 octobre 2025"

Demain :
  ✅ "📅 Demain · lundi 14 octobre 2025"

Dans 3 jours :
  ✅ "📅 Dans 3 jours · mercredi 16 octobre 2025"

Plus de 7 jours :
  ✅ "dimanche 27 octobre 2025"
```

---

## ✅ Checklist de validation

### Fonctionnel

- [ ] Dialog s'affiche au clic sur occurrence
- [ ] "Cette occurrence uniquement" pré-sélectionnée
- [ ] Changement de sélection fonctionne
- [ ] Bouton Annuler ferme dialog
- [ ] Bouton Continuer navigue correctement
- [ ] thisOnly → EventDetailPage
- [ ] all → ServiceDetailPage
- [ ] Modifications enregistrées correctement

### Visuel

- [ ] Dialog bien centré
- [ ] Width 400px correct
- [ ] Couleurs Material Design 3
- [ ] Icons affichés correctement
- [ ] Radio buttons alignés
- [ ] Texte lisible et bien espacé
- [ ] Borders et backgrounds corrects

### UX

- [ ] Message clair et compréhensible
- [ ] Distinction claire entre les 2 options
- [ ] Feedback visuel sur sélection
- [ ] Navigation logique et prévisible
- [ ] Aucune action accidentelle possible

---

## 🐛 Points de vigilance

### ⚠️ Vérifier spécifiquement

1. **Occurrence correcte passée** :
   ```dart
   // Dans ServiceOccurrencesDialog
   EventDetailPage(event: event) // ← Doit être le bon event
   ```

2. **Service correct passé** :
   ```dart
   // Dans ServiceOccurrencesDialog
   ServiceDetailPage(service: widget.service) // ← Doit être le bon service
   ```

3. **Navigation stack** :
   ```dart
   Navigator.of(context).pop(); // Ferme modal AVANT navigation
   Navigator.of(context).push(...); // Puis navigue
   ```

4. **Mounted check** :
   ```dart
   if (!mounted) return; // Important après async
   ```

---

## 📊 Scénarios de test complets

### Scénario 1 : Modification ponctuelle

```
Objectif : Créer un culte spécial Halloween

1. Service : "Culte Dominical" (tous les dimanches)
2. Cliquer badge 🔁 26
3. Cliquer sur occurrence du 27 octobre
4. Dialog s'affiche
5. "Cette occurrence uniquement" déjà sélectionné
6. [Continuer]
7. EventDetailPage s'ouvre
8. Changer titre → "🎃 Culte Spécial Halloween"
9. Changer description → "Célébration thématique"
10. [Sauvegarder]

Résultat attendu :
✅ 27 oct : "🎃 Culte Spécial Halloween"
✅ 3 nov : "Culte Dominical" (inchangé)
✅ 10 nov : "Culte Dominical" (inchangé)
✅ Toutes autres dates : "Culte Dominical" (inchangé)
```

### Scénario 2 : Changement global

```
Objectif : Déménager tous les cultes vers la grande salle

1. Service : "Culte Dominical"
2. Cliquer badge 🔁 26
3. Cliquer sur n'importe quelle occurrence
4. Dialog s'affiche
5. Sélectionner "Toutes les occurrences"
6. [Continuer]
7. ServiceDetailPage s'ouvre
8. Changer lieu → "Grande Salle"
9. [Sauvegarder]

Résultat attendu :
✅ TOUTES les 26 occurrences : lieu = "Grande Salle"
✅ Message confirmation : "✅ 26 événements mis à jour"
```

### Scénario 3 : Annulation

```
Objectif : Vérifier qu'annuler ne fait rien

1. Cliquer sur occurrence
2. Dialog s'affiche
3. Changer la sélection plusieurs fois
4. [Annuler]

Résultat attendu :
✅ Dialog se ferme
✅ Modal des occurrences reste ouvert
✅ Aucune navigation
✅ Aucune modification
```

---

## 🚀 Test de performance

### Temps de réponse attendus

```
Clic occurrence → Dialog apparaît : < 100ms
Changement sélection : < 50ms
[Continuer] → Navigation : < 200ms
Chargement EventDetailPage : < 500ms
Chargement ServiceDetailPage : < 300ms
```

### Test avec beaucoup d'occurrences

```
Service avec 52 occurrences (1 an hebdo) :
  ✅ Dialog s'affiche rapidement
  ✅ Navigation fluide
  ✅ Modification globale < 3s
```

---

## 📝 Rapport de test

### Template de rapport

```markdown
Date : _______________
Testeur : _______________
Version : _______________

### Résultats

Dialog de choix :
  ☐ ✅ Pass  ☐ ❌ Fail

Modification occurrence unique :
  ☐ ✅ Pass  ☐ ❌ Fail

Modification série complète :
  ☐ ✅ Pass  ☐ ❌ Fail

Annulation :
  ☐ ✅ Pass  ☐ ❌ Fail

### Bugs trouvés

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Commentaires

___________________________________________________
___________________________________________________
___________________________________________________
```

---

## 🎯 Résumé

| Test | Temps | Priorité |
|------|-------|----------|
| Ouverture dialog | 30s | 🔴 Critique |
| Sélection option | 30s | 🔴 Critique |
| Navigation thisOnly | 1min | 🔴 Critique |
| Navigation all | 1min | 🔴 Critique |
| Modification occurrence | 1min | 🟡 Important |
| Modification série | 1min | 🟡 Important |
| Annulation | 30s | 🟢 Normal |

**Total** : ~5 minutes pour tests critiques

---

## 🔄 Commandes utiles

### Vérifier Firestore après modifications

```bash
# Dans Firebase Console
# Collections → events → Filtrer par linkedServiceId
```

### Hot restart si problème

```bash
# Dans le terminal Flutter
r  # Hot reload
R  # Hot restart (si problème de state)
```

### Logs utiles

```dart
// Dans _openOccurrenceDetail
print('🎯 Scope choisi: $scope');
print('📅 Event: ${event.id} - ${event.title}');
print('🔁 Service: ${widget.service.id} - ${widget.service.name}');
```

---

**Résultat attendu** : ✅ Tous les tests passent, dialog fonctionne comme Google Calendar !

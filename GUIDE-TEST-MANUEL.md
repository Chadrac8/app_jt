# Guide de Test Manuel - Ajout de Passages Bibliques

## 🎯 Objectif
Tester l'ajout de versets bibliques dans les "Passages thématiques" depuis l'interface utilisateur principale.

## 📋 Prérequis Vérifiés
✅ Firebase configuré et opérationnel
✅ Authentification anonyme activée
✅ Service ThematicPassageService fonctionnel (testé automatiquement)
✅ Composants UI AddPassageDialog et ThemeCreationDialog améliorés

## 🧪 Tests à Effectuer

### Test 1: Authentification
1. Ouvrez l'application principale (`flutter run -d chrome`)
2. Observez si vous voyez des erreurs d'authentification
3. **Résultat attendu**: Connexion automatique silencieuse

### Test 2: Création de Thème
1. Naviguez vers la section "Passages thématiques"
2. Cliquez sur "Créer un nouveau thème"
3. Remplissez les champs requis
4. **Résultat attendu**: Thème créé avec succès

### Test 3: Ajout de Passage - Cas Simple
1. Sélectionnez un thème existant ou nouvellement créé
2. Cliquez sur "Ajouter un passage"
3. Saisissez: `Jean 3:16`
4. **Résultat attendu**: Passage ajouté avec le texte complet

### Test 4: Ajout de Passage - Plage de Versets
1. Dans le même thème
2. Cliquez sur "Ajouter un passage"
3. Saisissez: `Matthieu 5:3-5`
4. **Résultat attendu**: Les 3 versets ajoutés ensemble

### Test 5: Gestion d'Erreurs
1. Essayez d'ajouter une référence invalide: `Livre 999:999`
2. **Résultat attendu**: Message d'erreur clair et utile

## 🔍 Points d'Attention

### Messages d'Erreur à Surveiller
- **"admin-restricted-operation"**: L'authentification anonyme n'est pas activée
- **"permission-denied"**: Problème de règles Firestore
- **"network-request-failed"**: Problème de connectivité

### Comportements Attendus
1. **Dialog d'ajout**: Doit s'ouvrir sans erreur
2. **Validation**: La référence doit être validée en temps réel
3. **Prévisualisation**: Le texte du verset doit apparaître
4. **Sauvegarde**: Confirmation de succès claire

## 🛠️ Dépannage

### Si l'authentification échoue:
```bash
# Exécuter le script d'activation
./enable-anonymous-auth.sh
```

### Si les permissions sont refusées:
1. Vérifiez les règles Firestore dans la console Firebase
2. Assurez-vous que l'authentification anonyme est activée

### Si le texte biblique ne s'affiche pas:
1. Vérifiez que le fichier `assets/bible/lsg1910.json` existe
2. Contrôlez que le service BibleService fonctionne

## 📝 Rapport de Test

### Résultats Obtenus:
- [ ] Authentification: ✅ / ❌
- [ ] Création thème: ✅ / ❌  
- [ ] Ajout passage simple: ✅ / ❌
- [ ] Ajout plage versets: ✅ / ❌
- [ ] Gestion erreurs: ✅ / ❌

### Erreurs Rencontrées:
```
[Notez ici les erreurs exactes que vous voyez]
```

### Étapes qui Fonctionnent:
```
[Notez ici ce qui marche correctement]
```

## 🔧 Tests Automatisés Disponibles

Si vous préférez les tests automatisés:
```bash
# Test complet automatisé (prouvé fonctionnel)
flutter run test_final_passages.dart -d chrome

# Diagnostic Firebase simple
flutter run diagnostic_simple.dart -d chrome
```

## 📞 Support
Si les tests révèlent des problèmes spécifiques, notez:
1. L'erreur exacte affichée
2. À quelle étape elle survient  
3. Le navigateur utilisé
4. Les messages dans la console développeur (F12)

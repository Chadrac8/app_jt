# 📖 Guide Utilisateur Final - Intégration Groupes ↔ Événements

> **Version:** 1.0  
> **Date:** 14 octobre 2025  
> **Planning Center Online Groups Style**

---

## 🎯 Vue d'ensemble

Cette fonctionnalité permet de créer automatiquement des événements dans le calendrier à partir des réunions de groupe récurrentes, comme dans Planning Center Online Groups.

### Avantages
- ✅ **Visibilité accrue** : Les réunions de groupe apparaissent dans le calendrier principal
- ✅ **Gestion unifiée** : Modifier une réunion met à jour l'événement correspondant
- ✅ **Planification flexible** : Récurrence quotidienne, hebdomadaire, mensuelle ou annuelle
- ✅ **Navigation bidirectionnelle** : Passer rapidement du groupe à l'événement et vice-versa

---

## 🚀 Activation de la génération d'événements

### Étape 1 : Créer ou éditer un groupe

1. Allez dans **Groupes** → **Nouveau groupe** (ou éditez un groupe existant)
2. Remplissez les informations de base :
   - Nom du groupe
   - Description
   - Type
   - Lieu de rencontre
   - Responsables

### Étape 2 : Activer la génération d'événements

3. Cochez **"Générer des événements automatiquement"**
4. Une nouvelle section **Configuration de récurrence** apparaît

---

## ⚙️ Configuration de la récurrence

### Fréquence : Quotidien

**Exemple :** Prière matinale chaque jour à 7h

1. Sélectionnez **Quotidien**
2. Configurez :
   - **Intervalle** : `1` (chaque jour) ou `2` (tous les 2 jours)
   - **Heure de début** : `07:00`
   - **Durée** : `60` minutes

```
Résultat : Événements créés du lundi au dimanche
```

---

### Fréquence : Hebdomadaire

**Exemple :** Jeunes Adultes le mardi et jeudi à 19h30

1. Sélectionnez **Hebdomadaire**
2. Configurez :
   - **Intervalle** : `1` (chaque semaine) ou `2` (toutes les 2 semaines)
   - **Jours de la semaine** : Cochez `Mardi` et `Jeudi`
   - **Heure de début** : `19:30`
   - **Durée** : `120` minutes

```
Résultat : 
- Mardi 14 oct 2025 à 19:30
- Jeudi 16 oct 2025 à 19:30
- Mardi 21 oct 2025 à 19:30
- ...
```

---

### Fréquence : Mensuelle

#### Option A : Jour du mois (ex: le 14 de chaque mois)

**Exemple :** Comité de direction le 14 de chaque mois

1. Sélectionnez **Mensuel**
2. Choisissez **"Le 14 de chaque mois"**
3. Configurez :
   - **Intervalle** : `1` (chaque mois) ou `3` (tous les 3 mois)
   - **Heure de début** : `19:00`
   - **Durée** : `90` minutes

```
Résultat : 
- 14 oct 2025
- 14 nov 2025
- 14 déc 2025
- ...
```

#### Option B : Jour de la semaine (ex: 2ème mardi du mois)

**Exemple :** Réunion leaders le 2ème mardi de chaque mois

1. Sélectionnez **Mensuel**
2. Choisissez **"Le 2ème mardi"**
3. Configurez :
   - **Semaine du mois** : `2ème`
   - **Jour de la semaine** : `Mardi`
   - **Heure de début** : `20:00`

```
Résultat : 
- Mardi 14 oct 2025 (2ème mardi)
- Mardi 11 nov 2025 (2ème mardi)
- Mardi 9 déc 2025 (2ème mardi)
- ...
```

---

### Fréquence : Annuelle

**Exemple :** Assemblée générale chaque 14 octobre

1. Sélectionnez **Annuel**
2. Configurez :
   - **Intervalle** : `1` (chaque année)
   - **Date de début** : `14 octobre 2025`
   - **Heure de début** : `14:00`

```
Résultat : 
- 14 oct 2025
- 14 oct 2026
- 14 oct 2027
- ...
```

---

## ⏰ Configuration de la fin

### Option 1 : Jamais

Les événements sont créés indéfiniment (limite pratique : 2 ans à l'avance).

```
✅ Idéal pour : Groupes permanents (Jeunes, Prière, Étude biblique)
```

---

### Option 2 : Le (date spécifique)

Arrête la génération à une date précise.

**Exemple :** Groupe temporaire jusqu'au 31 décembre 2025

1. Sélectionnez **"Le"**
2. Choisissez la date : `31 décembre 2025`

```
Résultat : Aucun événement créé après le 31 décembre 2025
```

---

### Option 3 : Après X occurrences

Crée un nombre fixe de réunions.

**Exemple :** Série de 8 rencontres

1. Sélectionnez **"Après"**
2. Entrez le nombre : `8`

```
Résultat : Génère exactement 8 événements puis s'arrête
```

---

## 🚫 Exclure des dates (Vacances / Jours fériés)

### Ajouter une exclusion

1. Dans la section **Dates exclues**, cliquez sur **"Ajouter une date"**
2. Sélectionnez la date à exclure
3. Répétez pour chaque date

**Exemple :** Exclure les vacances de Noël

```
Exclure :
- 25 décembre 2025
- 1er janvier 2026
```

**Résultat :** Aucun événement créé ces jours-là.

---

## 🎨 Interface Groupe - Page Détails

### Onglet "Informations"

Si **generateEvents = true**, vous verrez une carte statistiques :

```
┌─────────────────────────────────────────┐
│  📅 Événements générés                 │
│                                         │
│  📊 Total : 24 événements              │
│  🔜 À venir : 18                       │
│  ✅ Passés : 6                         │
│                                         │
│  [Voir tous les événements]            │
│  [•••] → Désactiver génération         │
└─────────────────────────────────────────┘
```

**Actions disponibles :**
- **Voir tous** : Ouvre liste complète des événements générés
- **Désactiver** : Arrête la génération (événements existants conservés)

---

### Onglet "Réunions"

Timeline verticale des réunions passées et futures :

```
🔜 À venir

┌─────────────────────────────────────────┐
│  AUJOURD'HUI                            │
│  📅 Mar 14 octobre 2025 à 19:30        │
│  📍 Salle 3                            │
│  🔗 → Événement lié                    │
├─────────────────────────────────────────┤
│  📅 Jeu 16 octobre 2025 à 19:30        │
│  📍 Salle 3                            │
│  🔗 → Événement lié                    │
└─────────────────────────────────────────┘

📜 Passées

┌─────────────────────────────────────────┐
│  📅 Mar 7 octobre 2025 à 19:30         │
│  📍 Salle 3                            │
│  ✅ Terminée                           │
└─────────────────────────────────────────┘
```

**Badge événement lié :**
- Cliquez sur `🔗 → Événement lié` pour naviguer vers l'événement
- Le badge affiche le titre de l'événement

---

## 📅 Interface Événement - Page Détails

Si l'événement est généré par un groupe, vous verrez un badge :

```
┌─────────────────────────────────────────┐
│  Jeunes Adultes - Réunion              │
│                                         │
│  📅 14 octobre 2025 à 19:30            │
│  📍 Salle 3                            │
│                                         │
│  ┌────────────────────────────────┐   │
│  │ 👥 Réunion du groupe           │   │
│  │ Jeunes Adultes                 │   │
│  │ [Voir le groupe →]             │   │
│  └────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Actions disponibles :**
- **Voir le groupe** : Navigation vers page détails du groupe
- Affichage cohérent avec l'identité visuelle du groupe

---

## ✏️ Modifier une réunion récurrente

### Scénario : Changement d'heure pour une réunion

1. Allez dans **Groupe** → **Détails** → Onglet **Réunions**
2. Cliquez sur une réunion future
3. Cliquez sur **Modifier**

### Dialog de choix apparaît :

```
┌───────────────────────────────────────────────┐
│  🔁 Modifier une réunion récurrente           │
│                                               │
│  ℹ️ Cette réunion fait partie d'une série    │
│     récurrente.                               │
│                                               │
│  ◉ Cette occurrence uniquement               │
│    Modifier uniquement la réunion du         │
│    14 octobre 2025                            │
│                                               │
│  ○ Cette occurrence et les suivantes         │
│    Modifier cette réunion et toutes          │
│    les réunions futures                       │
│                                               │
│  ○ Toutes les occurrences                    │
│    Modifier toutes les réunions passées      │
│    et futures de cette série                  │
│                                               │
│              [Annuler]  [Continuer]           │
└───────────────────────────────────────────────┘
```

### Options expliquées :

#### Option 1 : Cette occurrence uniquement
**Usage :** Changement ponctuel (réunion spéciale, invité externe)

**Exemple :**
```
Réunion du 14 octobre passe de 19:30 à 20:00

Résultat :
- 7 oct : 19:30 ✅ (inchangé)
- 14 oct : 20:00 ✅ (modifié)
- 21 oct : 19:30 ✅ (inchangé)
```

---

#### Option 2 : Cette occurrence et les suivantes
**Usage :** Changement définitif à partir d'une date (nouveau lieu, nouvel horaire)

**Exemple :**
```
À partir du 14 octobre, lieu change "Salle 3" → "Salle 5"

Résultat :
- 7 oct : Salle 3 ✅ (passée, inchangée)
- 14 oct : Salle 5 ✅ (modifié)
- 21 oct : Salle 5 ✅ (modifié)
- 28 oct : Salle 5 ✅ (modifié)
```

---

#### Option 3 : Toutes les occurrences
**Usage :** Changement global de configuration (fréquence, heure standard)

**Exemple :**
```
Passer de mardi/jeudi à seulement mardi

Résultat :
- TOUTES les réunions jeudi sont supprimées
- TOUTES les réunions mardi restent (avec nouvel horaire si modifié)
```

---

## 🔄 Synchronisation bidirectionnelle

### Modifier l'événement met à jour la réunion

**Scénario :** Vous éditez l'événement depuis le calendrier

1. Allez dans **Calendrier** → Cliquez sur événement groupe
2. Modifiez lieu : `Salle 3` → `Salle 5`
3. Enregistrez

**Résultat automatique :**
- ✅ Événement mis à jour : Salle 5
- ✅ Réunion correspondante mise à jour : Salle 5
- ✅ Badge "🔗 Synchronisé" affiché

---

### Modifier la réunion met à jour l'événement

**Scénario :** Vous éditez la réunion depuis le groupe

1. Allez dans **Groupe** → **Réunions** → Cliquez sur réunion
2. Modifiez heure : `19:30` → `20:00`
3. Choisissez portée modification (dialog ci-dessus)
4. Enregistrez

**Résultat automatique :**
- ✅ Réunion mise à jour : 20:00
- ✅ Événement correspondant mis à jour : 20:00
- ✅ Participants événement notifiés (si notifications actives)

---

## 🧪 Cas d'usage complets

### Cas 1 : Groupe de Jeunes Adultes

**Configuration :**
- Fréquence : Hebdomadaire
- Jours : Mardi et Jeudi
- Heure : 19:30
- Durée : 2h
- Fin : Jamais
- Lieu : Salle 3

**Résultat :**
```
Octobre 2025 :
- Mar 14 oct à 19:30 (2h) - Salle 3
- Jeu 16 oct à 19:30 (2h) - Salle 3
- Mar 21 oct à 19:30 (2h) - Salle 3
- Jeu 23 oct à 19:30 (2h) - Salle 3
...
```

**Timeline visible dans :**
- 📅 Calendrier principal (vue mois/semaine)
- 👥 Page détails du groupe (onglet Réunions)
- 🔔 Notifications avant réunion (si activées)

---

### Cas 2 : Prière matinale quotidienne

**Configuration :**
- Fréquence : Quotidien
- Intervalle : 1 (chaque jour)
- Heure : 07:00
- Durée : 1h
- Fin : Jamais
- Lieu : En ligne (Zoom)

**Résultat :**
```
Chaque jour à 7h :
- Lun 13 oct 2025 à 07:00
- Mar 14 oct 2025 à 07:00
- Mer 15 oct 2025 à 07:00
- Jeu 16 oct 2025 à 07:00
- Ven 17 oct 2025 à 07:00
- Sam 18 oct 2025 à 07:00
- Dim 19 oct 2025 à 07:00
...
```

**Exclusions typiques :**
- Jours fériés
- Congés pastoraux
- Événements spéciaux

---

### Cas 3 : Comité mensuel (2ème mardi)

**Configuration :**
- Fréquence : Mensuel
- Type : Jour de la semaine
- Semaine : 2ème
- Jour : Mardi
- Heure : 20:00
- Durée : 1h30
- Fin : Jamais

**Résultat :**
```
2ème mardi de chaque mois :
- Mar 14 oct 2025 à 20:00
- Mar 11 nov 2025 à 20:00
- Mar 9 déc 2025 à 20:00
- Mar 13 jan 2026 à 20:00
...
```

**Avantage :** S'adapte automatiquement au calendrier (le 2ème mardi n'est pas toujours le même jour du mois).

---

### Cas 4 : Série limitée de 8 rencontres

**Configuration :**
- Fréquence : Hebdomadaire
- Jour : Dimanche
- Heure : 15:00
- Durée : 2h
- Fin : Après 8 occurrences
- Description : Série "Fondamentaux de la foi"

**Résultat :**
```
8 dimanches consécutifs :
1. Dim 12 oct 2025 à 15:00
2. Dim 19 oct 2025 à 15:00
3. Dim 26 oct 2025 à 15:00
4. Dim 2 nov 2025 à 15:00
5. Dim 9 nov 2025 à 15:00
6. Dim 16 nov 2025 à 15:00
7. Dim 23 nov 2025 à 15:00
8. Dim 30 nov 2025 à 15:00

❌ Plus d'événements après le 30 nov
```

**Usage :** Séries thématiques, cours, formations temporaires.

---

## 🛠️ Gestion avancée

### Désactiver la génération d'événements

**Scénario :** Le groupe existe toujours mais vous ne voulez plus créer d'événements.

1. Allez dans **Groupe** → **Détails** → Onglet **Informations**
2. Cliquez sur menu `•••` de la carte **Événements générés**
3. Sélectionnez **"Désactiver génération automatique"**

**Résultat :**
- ✅ Événements futurs supprimés
- ✅ Événements passés conservés (historique)
- ✅ Réunions du groupe non affectées
- ✅ Badge `generateEvents = false`

---

### Réactiver la génération

1. Éditez le groupe
2. Cochez **"Générer des événements automatiquement"**
3. Reconfigurez la récurrence (elle n'est pas sauvegardée si désactivée)
4. Enregistrez

**Résultat :** Nouveaux événements créés selon nouvelle configuration.

---

### Supprimer un groupe avec événements liés

**Dialog de confirmation apparaît :**

```
┌───────────────────────────────────────────────┐
│  ⚠️ Supprimer le groupe ?                     │
│                                               │
│  Ce groupe a 24 événements liés.              │
│                                               │
│  ◉ Supprimer groupe et événements            │
│    Supprime tout (recommandé)                 │
│                                               │
│  ○ Supprimer groupe uniquement               │
│    Conserve les événements comme événements   │
│    normaux (déconnectés)                      │
│                                               │
│              [Annuler]  [Supprimer]           │
└───────────────────────────────────────────────┘
```

---

## 📊 Statistiques et rapports

### Depuis la page Groupe

```
Carte Événements générés :

📊 Total : 24 événements
🔜 À venir : 18
✅ Passés : 6

Détails :
- Taux participation : 85% (si suivi activé)
- Présence moyenne : 12 personnes
- Prochaine réunion : Mar 14 oct à 19:30
```

---

### Depuis le Calendrier

**Vue mois :**
- Les événements groupe ont une couleur spécifique
- Badge `👥` indique événement groupe
- Click → Détails événement + lien groupe

**Vue semaine :**
- Affichage durée exacte (2h)
- Lieu affiché sous le titre
- Badge groupe visible

---

## ❓ FAQ

### Q: Puis-je avoir plusieurs récurrences pour un même groupe ?

**R:** Non, un groupe a une seule configuration de récurrence. Si vous avez besoin de deux horaires différents (ex: mardi jeunes + vendredi leaders), créez deux groupes distincts.

---

### Q: Que se passe-t-il si je modifie manuellement un événement généré ?

**R:** L'événement devient "découplé" du groupe. Les futures modifications de la réunion ne l'affecteront plus. Un badge ⚠️ "Modifié manuellement" apparaît.

---

### Q: Les participants peuvent-ils voir les réunions de groupe dans leur calendrier ?

**R:** Oui, si :
- Le groupe est **Public**
- L'événement est **Publié**
- Ils ont l'application mobile ou accès web

---

### Q: Comment exclure les vacances scolaires ?

**R:** Deux méthodes :

**Méthode 1 : Exclusions manuelles**
1. Éditez le groupe
2. Section "Dates exclues"
3. Ajoutez chaque date de vacances

**Méthode 2 : Arrêt temporaire**
1. Avant les vacances : Désactivez génération
2. Après les vacances : Réactivez avec nouvelle date de début

---

### Q: Puis-je créer des événements pour plusieurs années ?

**R:** L'application génère automatiquement jusqu'à **2 ans à l'avance**. Au-delà, un processus automatique régénère les événements futurs.

---

### Q: Les événements sont-ils synchronisés avec Google Calendar ?

**R:** Pas encore implémenté dans cette version. Prévu dans une future mise à jour.

---

## 🆘 Dépannage

### Problème : Les événements ne sont pas créés

**Solutions :**

1. ✅ Vérifiez que **generateEvents = true**
2. ✅ Vérifiez la configuration récurrence (champs obligatoires remplis)
3. ✅ Date de début doit être dans le futur
4. ✅ Si "Fin : Le", date de fin doit être après date de début

---

### Problème : Trop d'événements créés

**Solutions :**

1. ✅ Vérifiez l'intervalle (ex: `interval = 1` pour chaque semaine, pas `7`)
2. ✅ Vérifiez la fin (configurez "Après X occurrences" pour limiter)
3. ✅ Supprimez manuellement les événements en trop
4. ✅ Éditez le groupe et reconfigurez la récurrence

---

### Problème : Badge "Événement lié" ne fonctionne pas

**Solutions :**

1. ✅ Vérifiez que l'événement n'a pas été supprimé
2. ✅ Rafraîchissez la page (Pull to refresh)
3. ✅ Si le problème persiste, contactez l'administrateur

---

## 📝 Notes de version

### Version 1.0 (14 octobre 2025)

**Fonctionnalités :**
- ✅ Génération événements récurrents (daily, weekly, monthly, yearly)
- ✅ Dialog choix modification portée (Google Calendar style)
- ✅ Synchronisation bidirectionnelle groupe ↔ événement
- ✅ Timeline réunions dans page groupe
- ✅ Badge groupe dans événement
- ✅ Statistiques événements générés
- ✅ Exclusion dates (vacances)
- ✅ 3 options fin : Jamais, Le, Après

**Limitations connues :**
- Pas de synchronisation Google Calendar
- Pas de gestion conflits horaires automatique
- Génération limitée à 2 ans à l'avance

---

## 📞 Support

**Besoin d'aide ?**
- 📧 Email: support@jubiletabernacle.fr
- 📱 WhatsApp: +33 6 XX XX XX XX
- 💬 Forum communauté: forum.jubiletabernacle.fr

**Ressources :**
- 🎥 Vidéo tutoriel: youtube.com/watch?v=xxx
- 📖 Documentation technique: docs.jubiletabernacle.fr
- 🐛 Signaler un bug: github.com/JubileTabernacle/issues

---

**Merci d'utiliser l'application Jubilé Tabernacle de France ! 🙏**

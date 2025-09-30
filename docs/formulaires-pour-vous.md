# Formulaires "Pour vous" - Guide d'implémentation

## 📋 Vue d'ensemble

L'onglet "Pour vous" du module Vie de l'église contient 8 actions spécifiques qui sont liées au module Formulaires. Chaque action recherche un formulaire correspondant dans la base de données et redirige l'utilisateur vers ce formulaire.

## 🔄 Fonctionnement

Quand un utilisateur clique sur une action, le système :
1. Recherche un formulaire publié avec le titre exact correspondant
2. Si trouvé : Redirige vers le formulaire
3. Si non trouvé : Affiche un message d'erreur et propose de demander la création

## 📝 Formulaires à créer

Les administrateurs doivent créer les formulaires suivants dans le module Formulaires :

### 1. Relation avec Le Seigneur

#### **Demande de baptême d'eau**
- **Titre exact** : `Demande de baptême d'eau`
- **Description** : Formulaire de demande pour le baptême d'eau selon les enseignements bibliques
- **Champs suggérés** :
  - Motivation pour le baptême (texte long, requis)
  - Témoignage de foi (texte long, requis)
  - Préférence de contact (radio : Téléphone/Email/Après le culte)
  - Disponibilités (texte long, optionnel)

#### **Rejoindre une équipe**
- **Titre exact** : `Rejoindre une équipe`
- **Description** : Formulaire pour rejoindre une équipe de service dans l'église
- **Champs suggérés** :
  - Équipes d'intérêt (choix multiple : Louange, Technique, Accueil, Enfants, etc.)
  - Expérience (texte long, optionnel)
  - Jours de disponibilité (choix multiple)
  - Niveau d'engagement (radio : Occasionnel/Mensuel/Hebdomadaire)

### 2. Relation avec le pasteur

#### **Questions pour le pasteur**
- **Titre exact** : `Questions pour le pasteur`
- **Description** : Posez vos questions bibliques, spirituelles ou personnelles au pasteur
- **Champs suggérés** :
  - Type de question (radio : Biblique/Spirituelle/Conseil personnel/Autre)
  - Question (texte long, requis)
  - Urgence (radio : Non urgent/Modéré/Urgent)
  - Préférence de réponse (radio : Email/Appel/Rendez-vous/Réponse publique)

### 3. Participation au culte

#### **Proposition de chant spécial**
- **Titre exact** : `Proposition de chant spécial`
- **Description** : Proposez un chant spécial pour le culte
- **Champs suggérés** :
  - Titre du chant (texte court, requis)
  - Artiste/Compositeur (texte court, optionnel)
  - Type de prestation (radio : Solo/Duo/Groupe/Instrumental/Chorale)
  - Participants (texte court, requis)
  - Occasion (radio : Culte dominical/Événement spécial/Pas de préférence)
  - Temps de préparation (radio : 1 semaine/2 semaines/1 mois/Plus)

#### **Partager un témoignage**
- **Titre exact** : `Partager un témoignage`
- **Description** : Partagez votre témoignage pour encourager l'assemblée
- **Champs suggérés** :
  - Témoignage (texte long, requis)
  - Type (radio : Guérison/Conversion/Prière/Fidélité/Autre)
  - Mode de partage (radio : Oral/Écrit/Les deux)
  - Confort avec le public (radio : Très à l'aise/Moyennement/Préfère éviter)

### 4. Amélioration

#### **Proposer une idée**
- **Titre exact** : `Proposer une idée`
- **Description** : Proposez une idée pour améliorer la vie de l'église
- **Champs suggérés** :
  - Catégorie (radio : Culte/Événements/Communication/Infrastructure/etc.)
  - Description de l'idée (texte long, requis)
  - Bénéfices attendus (texte long, optionnel)
  - Suggestions de mise en œuvre (texte long, optionnel)
  - Disponibilité pour aider (radio : Oui activement/Occasionnellement/Non)

#### **Signaler un problème**
- **Titre exact** : `Signaler un problème`
- **Description** : Signalez un problème ou dysfonctionnement dans l'église
- **Champs suggérés** :
  - Type de problème (radio : Technique/Infrastructure/App/Organisation/Autre)
  - Description (texte long, requis)
  - Lieu (texte court, optionnel)
  - Niveau d'urgence (radio : Faible/Moyen/Élevé/Critique)
  - Solution suggérée (texte long, optionnel)

## ⚙️ Configuration des formulaires

### Paramètres recommandés :
- **Statut** : `Publié`
- **Accessibilité** : `Membres connectés`
- **Limite de soumissions** : Aucune (sauf cas spéciaux)
- **Soumissions multiples** : Autorisées
- **Confirmation** : Personnaliser le message de confirmation pour chaque formulaire

### Notifications :
Configurer les notifications pour que les responsables appropriés reçoivent les soumissions :
- Baptême → Pasteur + Responsable baptêmes
- Équipes → Responsables d'équipes concernées
- Questions pasteur → Pasteur
- Chant spécial → Responsable louange
- Témoignage → Pasteur + Responsable communication
- Idées → Direction de l'église
- Problèmes → Administrateurs techniques

## 🔗 Intégration

Une fois les formulaires créés avec les titres exacts, l'onglet "Pour vous" fonctionnera automatiquement. Les utilisateurs seront redirigés vers les formulaires appropriés en cliquant sur chaque action.

## 📞 Action spéciale : Rendez-vous

L'action "Rendez-vous" ne nécessite pas de formulaire. Elle redirige directement vers la page des rendez-vous membres (`MemberAppointmentsPage`).

## 🚀 Déploiement

1. Créer tous les formulaires listés ci-dessus dans le module Formulaires
2. S'assurer que les titres correspondent exactement
3. Publier les formulaires
4. Tester chaque action dans l'onglet "Pour vous"
5. Configurer les notifications et workflows selon les besoins de l'église
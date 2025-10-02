# Guide de Synchronisation Profil ↔ Module Personnes

## 🎯 Objectif
Permettre au profil utilisateur de récupérer automatiquement les informations depuis le module Personnes pour maintenir une source unique de vérité.

## 🔄 Fonctionnement

### Principe de Synchronisation
1. **Source de vérité** : Le module Personnes est la source principale des données
2. **Synchronisation automatique** : À chaque ouverture du profil, l'application vérifie s'il existe une personne correspondante dans le module Personnes
3. **Mapping par email** : La correspondance se fait par l'adresse email de l'utilisateur connecté
4. **Priorité des données** : Les données du module Personnes remplacent celles du profil utilisateur

### Champs Synchronisés
- ✅ **Prénom** : `firstName`
- ✅ **Nom** : `lastName`  
- ✅ **Téléphone** : `phone`
- ✅ **Pays** : `country`
- ✅ **Date de naissance** : `birthDate`
- ✅ **Genre** : `gender`
- ✅ **Statut marital** : `maritalStatus`
- ✅ **Adresse complète** : construite depuis `address`, `additionalAddress`, `zipCode`, `city`
- ✅ **Photo de profil** : `profileImageUrl`

### Champs NON Synchronisés
- ❌ **Email** : Reste celui du compte utilisateur (source Firebase Auth)
- ❌ **UID** : Identifiant unique Firebase Auth
- ❌ **Données de famille** : Gérées séparément

## 🚀 Implémentation

### 1. Structure des Modèles

#### PersonModel (Profil Utilisateur)
```dart
class PersonModel {
  final String id;
  final String? uid;        // Firebase Auth UID
  final String firstName;
  final String lastName;
  final String email;       // Email du compte utilisateur
  final String? phone;
  final String? country;
  final DateTime? birthDate;
  final String? address;    // Adresse complète
  // ... autres champs
}
```

#### Person (Module Personnes)
```dart
class Person {
  final String? id;
  final String firstName;
  final String lastName;
  final String? email;      // Email pour correspondance
  final String? phone;
  final String? country;
  final DateTime? birthDate;
  final String? address;           // Rue
  final String? additionalAddress; // Complément
  final String? zipCode;           // Code postal
  final String? city;              // Ville
  // ... autres champs
}
```

### 2. Service de Synchronisation

#### Méthodes Ajoutées dans MemberProfilePage
- `_synchronizeWithPeopleModule()` : Point d'entrée de la synchronisation
- `_buildAddressFromPeopleModule()` : Construction de l'adresse complète
- `_hasChanges()` : Détection des changements
- `_parseExistingAddressFromPeopleModule()` : Parse les champs d'adresse séparés

#### Processus de Synchronisation
1. **Recherche** : `PeopleModuleService.findByEmail(userEmail)`
2. **Mapping** : Conversion des champs du module Personnes vers PersonModel
3. **Comparaison** : Détection des différences avec `_hasChanges()`
4. **Mise à jour** : `FirebaseService.updatePerson()` si nécessaire
5. **Interface** : Affichage de l'indicateur de synchronisation

### 3. Interface Utilisateur

#### Indicateur de Synchronisation
Un widget informatif apparaît en haut de l'onglet "Informations" quand la synchronisation est active :

```dart
Widget _buildSyncIndicator() {
  return Container(
    // Style vert avec icône sync
    child: Text('Données synchronisées avec le module Personnes')
  );
}
```

## 📋 Utilisation

### Pour l'Utilisateur Final
1. **Connexion** : Se connecter avec son compte utilisateur
2. **Accès profil** : Aller dans "Profil > Informations"
3. **Vérification** : Si un bandeau vert apparaît, les données sont synchronisées
4. **Modification** : Les modifications doivent être faites dans le module Personnes

### Pour l'Administrateur
1. **Création personne** : Créer la personne dans le module Personnes avec le même email que le compte utilisateur
2. **Remplissage données** : Compléter toutes les informations dans le module Personnes
3. **Synchronisation automatique** : À la prochaine ouverture du profil, les données seront synchronisées

## 🔧 Configuration Requise

### Base de Données
- Collection `persons` (module Personnes) accessible via `PeopleModuleService`
- Collection `people` (profils utilisateurs) accessible via `FirebaseService`

### Services
- `PeopleModuleService` : Gestion du module Personnes
- `FirebaseService` : Gestion des profils utilisateurs
- `AuthService` : Authentification et profil utilisateur courant

### Imports Nécessaires
```dart
import '../services/people_module_service.dart';
import '../models/person_module_model.dart' as PeopleModule;
```

## 🐛 Dépannage

### Problèmes Courants

#### 1. Synchronisation ne fonctionne pas
- ✅ Vérifier que l'email du compte utilisateur correspond exactement à celui dans le module Personnes
- ✅ Vérifier que la personne existe et est active dans le module Personnes
- ✅ Consulter les logs : rechercher "Synchronisation avec le module Personnes"

#### 2. Données partiellement synchronisées
- ✅ Vérifier que tous les champs sont remplis dans le module Personnes
- ✅ Vérifier les mappings de champs dans `_buildAddressFromPeopleModule()`

#### 3. Erreurs de synchronisation
- ✅ Vérifier les permissions Firestore sur la collection `persons`
- ✅ Vérifier la connectivité réseau
- ✅ Consulter les logs d'erreur dans la console

### Logs de Debug
```
🔄 Synchronisation avec le module Personnes...
✅ Personne trouvée dans le module Personnes: John Doe
🔄 Mise à jour du profil utilisateur avec les données du module Personnes...
✅ Profil utilisateur synchronisé
```

## 📈 Avantages

### Pour l'Organisation
- ✅ **Source unique de vérité** : Toutes les données dans le module Personnes
- ✅ **Cohérence** : Évite les doublons et incohérences
- ✅ **Maintenance simplifiée** : Une seule base de données à maintenir

### Pour l'Utilisateur
- ✅ **Automatisation** : Pas besoin de ressaisir les informations
- ✅ **Actualisation** : Données toujours à jour
- ✅ **Transparence** : Indicateur visuel de synchronisation

## 🚀 Évolutions Futures

### Améliorations Possibles
- 🔄 **Synchronisation bidirectionnelle** : Permettre la modification depuis le profil
- 📸 **Upload photo** : Synchroniser les photos de profil
- 🔔 **Notifications** : Alerter en cas de désynchronisation
- ⏰ **Synchronisation périodique** : Vérifier automatiquement les mises à jour

### Intégrations
- 📱 **Notifications push** : Alertes de mise à jour
- 🔐 **Gestion des permissions** : Contrôler qui peut modifier quoi
- 📊 **Analytics** : Suivre l'utilisation de la synchronisation
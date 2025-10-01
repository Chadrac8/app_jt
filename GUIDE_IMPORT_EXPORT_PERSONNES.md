# 📋 Guide Import/Export Module Personnes

## 🎯 Vue d'ensemble

Ce guide décrit les fonctionnalités complètes d'import et d'export pour le module Personnes de l'application Jubilé Tabernacle. Ces fonctionnalités permettent de gérer facilement les données des membres en important depuis des sources externes ou en exportant vers différents formats.

## ✨ Fonctionnalités

### 📤 Export
- **Export complet** : Toutes les personnes de la base
- **Export sélectif** : Personnes sélectionnées uniquement  
- **Export filtré** : Par critères (rôle, statut, date de naissance, etc.)
- **Formats supportés** : CSV, JSON, Excel (en développement)
- **Configuration flexible** : Choix des champs, inclusion/exclusion des inactifs

### 📥 Import
- **Formats supportés** : CSV, JSON, TXT
- **Templates prédéfinis** : Default, MailChimp, Google Contacts
- **Validation automatique** : Emails, téléphones, champs requis
- **Gestion des doublons** : Detection et options de traitement
- **Mise à jour** : Possibilité de mettre à jour les enregistrements existants

## 🚀 Utilisation

### Accès aux fonctionnalités

1. **Via la page principale Personnes** :
   - Boutons Import/Export dans la barre d'outils
   - Actions rapides dans le widget dédié

2. **Page dédiée Import/Export** :
   - Interface complète avec tous les paramètres
   - Onglets séparés pour Import et Export
   - Configuration avancée

### Export étape par étape

1. **Sélectionner le type d'export** :
   ```
   - Toutes les personnes
   - Sélection (si des personnes sont sélectionnées)
   - Export avec filtres
   ```

2. **Choisir le format** :
   ```
   - CSV : Compatible Excel/Google Sheets
   - JSON : Format structuré complet
   - Excel : Format natif (à venir)
   ```

3. **Configuration** :
   ```
   - Inclure les personnes inactives
   - Sélectionner les champs à exporter
   - Exclure certains champs si nécessaire
   ```

4. **Export et partage** :
   ```
   - Génération du fichier
   - Option de partage direct
   - Sauvegarde locale
   ```

### Import étape par étape

1. **Préparation du fichier** :
   ```
   - Télécharger un template si nécessaire
   - Vérifier l'encodage UTF-8
   - S'assurer des champs requis (firstName, lastName)
   ```

2. **Sélection du fichier** :
   ```
   - Formats acceptés : .csv, .json, .txt
   - Taille recommandée : < 10MB
   ```

3. **Configuration d'import** :
   ```
   - Choisir un template de mapping
   - Activer/désactiver les validations
   - Gérer les doublons et mises à jour
   ```

4. **Validation et import** :
   ```
   - Aperçu des erreurs potentielles
   - Rapport d'import détaillé
   - Gestion des échecs
   ```

## 📊 Formats et Structures

### Format CSV Standard

```csv
firstName,lastName,email,phone,address,birthDate,roles
Jean,Dupont,jean.dupont@email.com,0123456789,"123 Rue de la Paix, 75001 Paris",1990-01-01,"membre,leader"
Marie,Martin,marie.martin@email.com,0198765432,"456 Avenue des Champs, 69000 Lyon",1985-05-15,membre
```

### Format JSON

```json
{
  "exportDate": "2025-01-01T10:00:00.000Z",
  "totalRecords": 2,
  "people": [
    {
      "firstName": "Jean",
      "lastName": "Dupont",
      "email": "jean.dupont@email.com",
      "phone": "0123456789",
      "address": "123 Rue de la Paix, 75001 Paris",
      "birthDate": "1990-01-01",
      "roles": ["membre", "leader"],
      "customFields": {
        "profession": "Ingénieur"
      },
      "isActive": true
    }
  ]
}
```

### Templates de Mapping

#### Template MailChimp
```csv
FNAME,LNAME,EMAIL,PHONE,ADDRESS
Jean,Dupont,jean.dupont@email.com,0123456789,"123 Rue de la Paix"
```

#### Template Google Contacts
```csv
"Given Name","Family Name","E-mail Address","Phone Number","Address"
"Jean","Dupont","jean.dupont@email.com","0123456789","123 Rue de la Paix"
```

## ⚙️ Configuration

### Options d'Export

| Option | Description | Défaut |
|--------|-------------|---------|
| `includeInactive` | Inclure les personnes inactives | `false` |
| `includeFields` | Liste des champs à inclure | Tous |
| `excludeFields` | Liste des champs à exclure | Aucun |

### Options d'Import

| Option | Description | Défaut |
|--------|-------------|---------|
| `validateEmails` | Valider le format des emails | `true` |
| `validatePhones` | Valider le format des téléphones | `true` |
| `allowDuplicateEmail` | Autoriser les emails dupliqués | `false` |
| `updateExisting` | Mettre à jour les existants | `false` |

## 🔧 API du Service

### PersonImportExportService

```dart
// Export
final result = await service.exportAll(
  format: ExportFormat.csv,
  config: ImportExportConfig(
    includeInactive: false,
    includeFields: ['firstName', 'lastName', 'email'],
  ),
);

// Import
final result = await service.importFromFile(
  config: ImportExportConfig(
    validateEmails: true,
    updateExisting: false,
  ),
  templateName: 'mailchimp',
);
```

### Résultats

```dart
// Résultat d'export
class ExportResult {
  final bool success;
  final String? filePath;
  final int recordCount;
  final String? message;
  final String? error;
}

// Résultat d'import
class ImportResult {
  final bool success;
  final int totalRecords;
  final int importedRecords;
  final int skippedRecords;
  final List<String> errors;
  final double successRate;
}
```

## 🛠️ Fichiers Créés

### Services
- `lib/modules/personnes/services/person_import_export_service.dart`
  - Service principal avec toute la logique d'import/export
  - Gestion des formats CSV, JSON, Excel
  - Validation et transformation des données

### Pages
- `lib/modules/personnes/pages/person_import_export_page.dart`
  - Interface utilisateur complète
  - Onglets Export et Import
  - Configuration avancée

### Widgets
- `lib/modules/personnes/widgets/person_import_export_actions.dart`
  - Actions rapides d'import/export
  - Statistiques et aide contextuelle
  - Intégration dans les pages existantes

### Scripts
- `generate_import_export_examples.sh`
  - Génération de fichiers d'exemple
  - Templates pour tous les formats
  - Documentation d'utilisation

## 📝 Validation des Données

### Champs Requis
- `firstName` : Prénom (obligatoire, non vide)
- `lastName` : Nom de famille (obligatoire, non vide)

### Validation Email
- Format : `utilisateur@domaine.extension`
- Vérification de la structure
- Option de désactivation

### Validation Téléphone
- Caractères autorisés : chiffres, espaces, +, -, (, ), .
- Longueur minimale : 8 caractères
- Option de désactivation

### Formats de Date
- ISO 8601 : `1990-01-01`
- Format français : `01/01/1990`
- Format avec tirets : `01-01-1990`

## 🔍 Gestion des Erreurs

### Types d'erreurs courantes

1. **Format de fichier invalide**
   - Extension non supportée
   - Encodage incorrect
   - Structure JSON invalide

2. **Données invalides**
   - Champs requis manquants
   - Format email invalide
   - Format date invalide

3. **Doublons**
   - Email déjà existant
   - Options de traitement configurables

4. **Erreurs de validation**
   - Téléphone invalide
   - Champs vides pour les requis

### Rapport d'erreurs

```
Résultat d'import :
- Total : 100 enregistrements
- Importés : 85 enregistrements  
- Ignorés : 15 enregistrements
- Taux de réussite : 85%

Erreurs détaillées :
• Ligne 12 : Email invalide
• Ligne 25 : Prénom manquant
• Ligne 48 : Email dupliqué
...
```

## 🎯 Bonnes Pratiques

### Préparation des fichiers
1. **Encodage UTF-8** pour les caractères spéciaux
2. **En-têtes clairs** en première ligne
3. **Test avec un petit fichier** avant import massif
4. **Sauvegarde** avant gros import

### Performance
1. **Fichiers < 10MB** recommandés
2. **Import par lots** pour gros volumes  
3. **Validation préalable** des données

### Sécurité
1. **Vérification des sources** de données
2. **Validation des permissions** utilisateur
3. **Audit des imports** massifs

## 🆘 Dépannage

### Problèmes courants

**Erreur d'encodage** :
```
Solution : Sauvegarder le fichier en UTF-8
```

**Champs non reconnus** :
```
Solution : Utiliser le bon template ou configurer le mapping
```

**Validation échouée** :
```
Solution : Vérifier le format des emails/téléphones
```

**Performance lente** :
```
Solution : Réduire la taille du fichier ou désactiver certaines validations
```

## 🔮 Évolutions Futures

### Fonctionnalités prévues
- **Export Excel natif** avec formatage
- **Import depuis Google Sheets** direct
- **Synchronisation automatique** avec services externes
- **Templates personnalisés** configurables
- **Import par API** REST
- **Planification d'exports** automatiques

### Améliorations techniques
- **Streaming** pour gros fichiers
- **Compression** des exports
- **Cache** des templates
- **Notifications** push pour imports longs

---

## 📞 Support

Pour toute question ou problème avec les fonctionnalités d'import/export :

1. **Documentation** : Consultez ce guide
2. **Exemples** : Utilisez le script `generate_import_export_examples.sh`
3. **Tests** : Commencez par de petits fichiers
4. **Aide contextuelle** : Bouton "Aide" dans l'interface

**Dernière mise à jour** : 1er octobre 2025  
**Version** : 1.0.0
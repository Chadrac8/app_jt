# Intégration Import/Export dans le Module Personnes

## Modifications Effectuées

### 1. **Page Principale des Personnes** (`lib/pages/people_home_page.dart`)

#### **Import ajouté :**
```dart
import '../modules/personnes/pages/person_import_export_page.dart';
```

#### **Nouveau cas dans le switch du menu :**
```dart
case 'import_export':
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PersonImportExportPage(),
    ),
  );
  break;
```

#### **Nouvel élément dans le PopupMenuButton :**
```dart
const PopupMenuItem(
  value: 'import_export',
  child: ListTile(
    leading: Icon(Icons.import_export),
    title: Text('Import/Export'),
    subtitle: Text('Importer et exporter des personnes'),
    contentPadding: EdgeInsets.zero,
  ),
),
```

## Localisation des Boutons Import/Export

### **Interface Utilisateur :**
1. **Page Principale :** `Personnes`
2. **Emplacement :** Menu `⋮` (trois points verticaux) en haut à droite
3. **Option :** `Import/Export` - Importer et exporter des personnes

### **Navigation :**
```
Page Personnes → Menu ⋮ → Import/Export → PersonImportExportPage
```

## Fonctionnalités Disponibles

### **Page Import/Export :**
- **Onglet Export :**
  - Export CSV avec sélection des champs
  - Export JSON complet
  - Configuration des options d'export
  - Prévisualisation des données

- **Onglet Import :**
  - Import depuis fichiers CSV/JSON
  - Validation des données
  - Options de traitement des doublons
  - Rapport d'import détaillé

### **Formats Supportés :**
- **CSV :** Délimiteur configurable, encodage UTF-8
- **JSON :** Format structuré complet

### **Validation :**
- Vérification des formats de données
- Détection des doublons
- Rapport d'erreurs détaillé

## Services Associés

### **PersonImportExportService :**
- Service principal pour les opérations d'import/export
- Localisation : `lib/modules/personnes/services/person_import_export_service.dart`

### **Widgets :**
- **PersonImportExportActions :** Actions rapides
- **PersonImportExportPage :** Page complète d'import/export

## Test de l'Intégration

### **Pour tester :**
1. Ouvrir l'application
2. Naviguer vers le module `Personnes`
3. Cliquer sur le menu `⋮` en haut à droite
4. Sélectionner `Import/Export`
5. Utiliser les onglets Export/Import

### **Vérifications :**
- ✅ Bouton Import/Export visible dans le menu
- ✅ Navigation vers PersonImportExportPage
- ✅ Fonctionnalités d'export opérationnelles
- ✅ Fonctionnalités d'import opérationnelles

## Status

**✅ INTÉGRATION COMPLÈTE**
- Les boutons Import/Export sont maintenant visibles dans l'interface principale des Personnes
- L'accès se fait via le menu contextuel (trois points) en haut à droite
- Toutes les fonctionnalités d'import/export sont opérationnelles
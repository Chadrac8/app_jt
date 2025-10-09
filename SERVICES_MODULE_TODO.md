# Fonctionnalités Non Implémentées - Module Services

## 📋 Vue d'ensemble

Ce document recense toutes les fonctionnalités du module Services qui sont marquées comme "TODO" ou "à implémenter" dans le code.

---

## 🔴 Priorité Haute

### 1. **Authentification Utilisateur dans Formulaires**
**Fichier**: `lib/modules/services/views/service_form_view.dart:817`

**État**: TODO marqué
```dart
createdBy: widget.service?.createdBy ?? 'current_user', // TODO: Utiliser l'ID utilisateur réel
```

**Impact**: Les services créés ne sont pas correctement attribués à l'utilisateur actuel.

**Solution suggérée**:
```dart
import '../../auth/auth_service.dart';

// Dans _saveService()
createdBy: widget.service?.createdBy ?? AuthService.currentUser?.uid ?? 'unknown',
```

---

### 2. **ID Utilisateur dans Services Member View**
**Fichier**: `lib/modules/services/views/services_member_view.dart:53`

**État**: TODO marqué
```dart
// TODO: Remplacer par l'ID utilisateur actuel
final assignments = await _servicesService.getMemberAssignments('current_user_id');
```

**Impact**: Les affectations de services ne sont pas chargées pour l'utilisateur correct.

**Solution suggérée**:
```dart
import '../../auth/auth_service.dart';

// Dans _loadData()
final userId = AuthService.currentUser?.uid;
if (userId != null) {
  final assignments = await _servicesService.getMemberAssignments(userId);
} else {
  // Gérer le cas où l'utilisateur n'est pas connecté
  final assignments = <ServiceAssignment>[];
}
```

---

### 3. **Affichage des Noms de Services et Positions**
**Fichier**: `lib/modules/services/views/member_services_page.dart:439,447`

**État**: TODO - Affichage ID au lieu du nom
```dart
Text(
  'Service ID: ${assignment.serviceId}', // TODO: Charger le nom du service
  style: const TextStyle(
    fontSize: AppTheme.fontSize16,
    fontWeight: AppTheme.fontBold,
    color: AppTheme.textPrimaryColor,
  ),
),
Text(
  'Position ID: ${assignment.positionId}', // TODO: Charger le nom de la position
  style: const TextStyle(
    color: AppTheme.textSecondaryColor,
  ),
),
```

**Impact**: Les utilisateurs voient des IDs au lieu de noms lisibles.

**Solution suggérée**: Créer des méthodes de résolution ou enrichir le modèle
```dart
// Option 1: Ajouter dans ServiceAssignmentModel
class ServiceAssignmentModel {
  final String serviceId;
  final String? serviceName; // Nouveau champ
  final String positionId;
  final String? positionName; // Nouveau champ
  // ...
}

// Option 2: Méthodes de résolution
Future<String> _getServiceName(String serviceId) async {
  try {
    final service = await ServicesFirebaseService.getService(serviceId);
    return service?.name ?? 'Service inconnu';
  } catch (e) {
    return 'Service #$serviceId';
  }
}

Future<String> _getPositionName(String positionId) async {
  try {
    final position = await ServicesFirebaseService.getPosition(positionId);
    return position?.name ?? 'Position inconnue';
  } catch (e) {
    return 'Position #$positionId';
  }
}

// Utilisation avec FutureBuilder
FutureBuilder<String>(
  future: _getServiceName(assignment.serviceId),
  builder: (context, snapshot) {
    return Text(
      snapshot.data ?? 'Chargement...',
      style: const TextStyle(
        fontSize: AppTheme.fontSize16,
        fontWeight: AppTheme.fontBold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  },
)
```

---

## 🟠 Priorité Moyenne

### 4. **Dialogue d'Assignation de Membre**
**Fichier**: `lib/modules/services/views/service_detail_view.dart:774`

**État**: TODO - Fonction non implémentée
```dart
void _showAssignMemberDialog() {
  // TODO: Implémenter le dialogue d'assignation
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fonctionnalité en cours de développement')),
  );
}
```

**Impact**: Impossible d'assigner des membres à un service depuis l'interface.

**Solution suggérée**:
```dart
Future<void> _showAssignMemberDialog() async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AssignMemberDialog(
      serviceId: widget.service.id!,
      availablePositions: widget.service.positions ?? [],
    ),
  );
  
  if (result != null) {
    try {
      final assignment = ServiceAssignment(
        id: '',
        serviceId: widget.service.id!,
        positionId: result['positionId'],
        memberId: result['memberId'],
        memberName: result['memberName'],
        status: 'pending',
        assignedAt: DateTime.now(),
      );
      
      await _servicesService.createAssignment(assignment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membre assigné avec succès')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

**Widget à créer**: `AssignMemberDialog`

---

### 5. **Édition d'Assignation**
**Fichier**: `lib/modules/services/views/service_detail_view.dart:732`

**État**: TODO - Fonction non implémentée
```dart
void _editAssignment(ServiceAssignment assignment) {
  // TODO: Implémenter l'édition d'assignation
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fonctionnalité en cours de développement')),
  );
}
```

**Impact**: Impossible de modifier une assignation existante.

**Solution suggérée**:
```dart
Future<void> _editAssignment(ServiceAssignment assignment) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => EditAssignmentDialog(
      assignment: assignment,
      availablePositions: widget.service.positions ?? [],
    ),
  );
  
  if (result != null) {
    try {
      final updatedAssignment = assignment.copyWith(
        positionId: result['positionId'],
        status: result['status'],
        notes: result['notes'],
      );
      
      await _servicesService.updateAssignment(
        assignment.id!,
        updatedAssignment,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignation modifiée')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

---

### 6. **Page de Statistiques**
**Fichier**: `lib/modules/services/views/services_home_page.dart:143`

**État**: TODO - Page non créée
```dart
Future<void> _navigateToStatistics() async {
  // TODO: Implement statistics page
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fonctionnalité des statistiques en cours de développement')),
  );
}
```

**Impact**: Aucune vue des statistiques de services disponible.

**Solution suggérée**: Créer une page de statistiques complète
```dart
Future<void> _navigateToStatistics() async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ServicesStatisticsPage(),
    ),
  );
}
```

**Page à créer**: `ServicesStatisticsPage` avec :
- Nombre total de services
- Services par type
- Taux de participation
- Membres les plus actifs
- Graphiques de tendances
- Export de données

---

### 7. **Gestion des Disponibilités**
**Fichier**: `lib/modules/services/views/member_services_page.dart:165`

**État**: TODO - Fonction non implémentée
```dart
ElevatedButton(
  onPressed: () {
    Navigator.pop(context);
    // TODO: Implémenter la gestion des disponibilités
  },
  child: const Text('Gérer'),
),
```

**Impact**: Les membres ne peuvent pas gérer leurs disponibilités.

**Solution suggérée**:
```dart
ElevatedButton(
  onPressed: () async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberAvailabilityPage(
          memberId: AuthService.currentUser?.uid,
        ),
      ),
    );
    if (result == true) {
      _loadAssignments(); // Recharger
    }
  },
  child: const Text('Gérer'),
),
```

**Page à créer**: `MemberAvailabilityPage` avec :
- Calendrier de disponibilités
- Blocage de dates
- Jours/heures préférés
- Raisons d'indisponibilité
- Synchronisation avec affectations

---

### 8. **Voir la Feuille de Service**
**Fichier**: `lib/modules/services/views/member_services_page.dart:584`

**État**: TODO - Navigation non implémentée
```dart
OutlinedButton.icon(
  onPressed: () {
    // TODO: Voir la feuille de service
  },
  icon: const Icon(Icons.description, size: 18),
  label: const Text('Voir la feuille de service'),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppTheme.primaryColor,
  ),
),
```

**Impact**: Les membres ne peuvent pas consulter la feuille de service.

**Solution suggérée**:
```dart
OutlinedButton.icon(
  onPressed: () async {
    try {
      final service = await ServicesFirebaseService.getService(
        assignment.serviceId,
      );
      
      if (service == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service non trouvé')),
        );
        return;
      }
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceSheetPage(
            service: service,
            assignment: assignment,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  },
  icon: const Icon(Icons.description, size: 18),
  label: const Text('Voir la feuille de service'),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppTheme.primaryColor,
  ),
),
```

**Widget existant**: Le widget `ServiceSheetEditor` existe déjà et peut être utilisé.

---

## 🟡 Priorité Basse

### 9. **Navigation selon Rôle Utilisateur**
**Fichier**: `lib/modules/services/services_module.dart:208`

**État**: TODO - Route par défaut uniquement
```dart
void _navigateToModule(BuildContext context) {
  // TODO: Déterminer le rôle de l'utilisateur et naviguer vers la vue appropriée
  // Pour l'instant, on navigue vers la vue membre
  Navigator.of(context).pushNamed('/member/services');
}
```

**Impact**: Tous les utilisateurs accèdent à la vue membre par défaut.

**Solution suggérée**:
```dart
Future<void> _navigateToModule(BuildContext context) async {
  try {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }
    
    // Récupérer le rôle depuis Firestore ou custom claims
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final role = userDoc.data()?['role'] ?? 'member';
    
    switch (role) {
      case 'admin':
      case 'leader':
        Navigator.of(context).pushNamed('/admin/services');
        break;
      case 'coordinator':
        Navigator.of(context).pushNamed('/coordinator/services');
        break;
      default:
        Navigator.of(context).pushNamed('/member/services');
    }
  } catch (e) {
    print('Erreur navigation: $e');
    // Fallback vers vue membre
    Navigator.of(context).pushNamed('/member/services');
  }
}
```

---

### 10. **Gestion des Modèles de Service (Templates)**

#### 10a. **Création de Modèle**
**Fichier**: `lib/modules/services/views/services_admin_view.dart:665`

**État**: TODO - Navigation non implémentée
```dart
FloatingActionButton(
  onPressed: () {
    // TODO: Naviguer vers création de modèle
  },
  child: const Icon(Icons.add),
),
```

#### 10b. **Édition de Modèle**
**Fichier**: `lib/modules/services/views/services_admin_view.dart:802`

**État**: TODO - Navigation non implémentée
```dart
onTap: () {
  // TODO: Naviguer vers édition de modèle
},
```

#### 10c. **Duplication de Modèle**
**Fichier**: `lib/modules/services/views/services_admin_view.dart:805`

**État**: TODO - Fonction non implémentée
```dart
onTap: () {
  // TODO: Dupliquer le modèle
},
```

#### 10d. **Suppression de Modèle**
**Fichier**: `lib/modules/services/views/services_admin_view.dart:944`

**État**: TODO - Fonction non implémentée
```dart
if (confirmed == true) {
  // TODO: Implémenter suppression de modèle
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Modèle supprimé')),
  );
  _loadData();
}
```

**Impact**: Gestion complète des modèles non fonctionnelle.

**Solution suggérée**:

```dart
// Créer page de formulaire de modèle
class ServiceTemplateFormPage extends StatefulWidget {
  final ServiceTemplate? template;
  
  const ServiceTemplateFormPage({Key? key, this.template}) : super(key: key);
  
  @override
  State<ServiceTemplateFormPage> createState() => _ServiceTemplateFormPageState();
}

// Créer service pour les modèles
class ServiceTemplateService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'service_templates';
  
  static Future<String> createTemplate(ServiceTemplate template) async {
    final docRef = await _firestore.collection(_collection).add(template.toFirestore());
    return docRef.id;
  }
  
  static Future<void> updateTemplate(String id, ServiceTemplate template) async {
    await _firestore.collection(_collection).doc(id).update(template.toFirestore());
  }
  
  static Future<void> deleteTemplate(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
  
  static Future<String> duplicateTemplate(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) throw Exception('Modèle non trouvé');
    
    final template = ServiceTemplate.fromFirestore(doc);
    final duplicated = template.copyWith(
      id: '',
      name: '${template.name} (Copie)',
      createdAt: DateTime.now(),
    );
    
    return await createTemplate(duplicated);
  }
}

// Implémentation dans services_admin_view.dart
void _createTemplate() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ServiceTemplateFormPage(),
    ),
  );
  
  if (result == true) {
    _loadData();
  }
}

void _editTemplate(ServiceTemplate template) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServiceTemplateFormPage(template: template),
    ),
  );
  
  if (result == true) {
    _loadData();
  }
}

Future<void> _duplicateTemplate(ServiceTemplate template) async {
  try {
    await ServiceTemplateService.duplicateTemplate(template.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modèle dupliqué avec succès')),
    );
    _loadData();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}

Future<void> _deleteTemplate(ServiceTemplate template) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer le modèle'),
      content: Text('Êtes-vous sûr de vouloir supprimer "${template.name}" ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ServiceTemplateService.deleteTemplate(template.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modèle supprimé')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

---

## 📊 Résumé par Priorité

### 🔴 Haute (À implémenter rapidement)
1. Authentification utilisateur dans formulaires
2. ID utilisateur dans services member view
3. Affichage noms services/positions au lieu d'IDs

### 🟠 Moyenne (Améliore significativement l'UX)
4. Dialogue d'assignation de membre
5. Édition d'assignation
6. Page de statistiques
7. Gestion des disponibilités
8. Voir feuille de service

### 🟡 Basse (Nice-to-have)
9. Navigation selon rôle utilisateur
10. Gestion complète des modèles (CRUD)

---

## 🎯 Plan d'Implémentation Suggéré

### Phase 1 (Priorité Haute) - 2-3h
1. ✅ Fixer authentification utilisateur (30 min)
2. ✅ Fixer ID utilisateur member view (30 min)
3. 📊 Résolution noms services/positions (1-2h)

### Phase 2 (Priorité Moyenne) - 6-8h
4. 👥 Dialogue d'assignation membre (2h)
5. ✏️ Édition d'assignation (1h)
6. 📈 Page de statistiques (2-3h)
7. 📅 Gestion disponibilités (2h)
8. 📄 Navigation feuille de service (30 min)

### Phase 3 (Priorité Basse) - 4-6h
9. 🔐 Navigation par rôle (1-2h)
10. 📋 CRUD complet modèles (3-4h)

---

## 📦 Nouveaux Fichiers à Créer

1. **`lib/modules/services/widgets/assign_member_dialog.dart`**
   - Dialogue pour assigner un membre à un service

2. **`lib/modules/services/widgets/edit_assignment_dialog.dart`**
   - Dialogue pour modifier une assignation

3. **`lib/modules/services/pages/services_statistics_page.dart`**
   - Page complète de statistiques

4. **`lib/modules/services/pages/member_availability_page.dart`**
   - Gestion des disponibilités membre

5. **`lib/modules/services/pages/service_sheet_page.dart`**
   - Vue de la feuille de service pour membres

6. **`lib/modules/services/pages/service_template_form_page.dart`**
   - Formulaire CRUD pour modèles

7. **`lib/modules/services/services/service_template_service.dart`**
   - Service Firestore pour modèles

---

## ✅ Recommandations Immédiates

### Quick Wins (< 30 min chacun)
1. ✅ Fixer authentification utilisateur
2. ✅ Fixer ID utilisateur member view
3. ✅ Utiliser ServiceSheetEditor existant pour feuille

### Valeur Business (2-3h chacune)
- 📊 Résolution noms au lieu d'IDs (meilleure UX)
- 👥 Dialogue d'assignation (core feature)
- 📈 Page statistiques (insights précieux)

### Long Terme (3-4h)
- 📋 Système complet de modèles
- 📅 Gestion disponibilités avancée

---

## 🔗 Dépendances avec Autres Modules

### Module Événements ✅
- Intégration Services ↔ Events déjà implémentée
- `ServiceEventIntegrationService` opérationnel

### Module Personnes 👥
- Besoin de `PersonSelectorWidget` pour assignations
- Récupération infos membres depuis Firestore

### Module Notifications 📧
- Envoi notifications lors d'assignations
- Rappels avant services
- Confirmations de réponses

---

## 🎉 Conclusion

Le module Services a **10 fonctionnalités non implémentées** :
- **3 priorité haute** (authentification, IDs)
- **5 priorité moyenne** (assignations, stats, disponibilités)
- **2 priorité basse** (navigation rôle, modèles)

**Temps total estimé** : 12-17 heures pour tout implémenter

**Impact utilisateur** : Les fonctionnalités manquantes sont principalement des améliorations UX et des outils administratifs. Le module est fonctionnel pour l'usage de base mais manque de polish et d'outils avancés.

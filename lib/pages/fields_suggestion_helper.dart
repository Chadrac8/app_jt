/// Helper pour suggestions de champs standards et personnalisés
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/custom_fields_firebase_service.dart';

class FieldsSuggestionHelper {

  /// Récupère tous les tags distincts utilisés dans la collection persons
  static Future<List<String>> getAllTags() async {
    final snapshot = await FirebaseFirestore.instance.collection('persons').get();
    final tags = <String>{};
    for (final doc in snapshot.docs) {
      final personTags = List<String>.from(doc['tags'] ?? []);
      tags.addAll(personTags);
    }
    return tags.toList()..sort();
  }

  /// Récupère tous les rôles distincts utilisés dans la collection roles
  static Future<List<String>> getAllRoles() async {
    final snapshot = await FirebaseFirestore.instance.collection('roles').get();
    final roles = <String>[];
    for (final doc in snapshot.docs) {
      final name = doc['name'] ?? '';
      if (name.isNotEmpty) roles.add(name);
    }
    roles.sort();
    return roles;
  }
  static const List<Map<String, dynamic>> standardFields = [
    {'name': 'firstName', 'label': 'Prénom', 'type': 'text'},
    {'name': 'lastName', 'label': 'Nom', 'type': 'text'},
    {'name': 'email', 'label': 'Email', 'type': 'email'},
    {'name': 'phone', 'label': 'Téléphone', 'type': 'phone'},
    {'name': 'gender', 'label': 'Genre', 'type': 'select', 'options': ['Masculin', 'Féminin', 'Autre']},
    {'name': 'roles', 'label': 'Rôles', 'type': 'multiselect'},
    {'name': 'tags', 'label': 'Tags', 'type': 'multiselect'},
    {'name': 'isActive', 'label': 'Actif', 'type': 'boolean'},
    {'name': 'birthDate', 'label': 'Date de naissance', 'type': 'date'},
    {'name': 'age', 'label': 'Âge', 'type': 'number'},
  ];

  static Future<List<Map<String, dynamic>>> getAllFields() async {
    final customFieldsService = CustomFieldsFirebaseService();
    final customFields = await customFieldsService.getCustomFields();
    final customFieldMaps = customFields.map((f) => {
      'name': 'customFields.${f.name}',
      'label': f.label,
      'type': f.type.toString().split('.').last,
      'options': f.options,
    }).toList();
    return [...standardFields, ...customFieldMaps];
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/people_lists_page.dart';

/// Service Firestore pour la gestion des listes de personnes (CRUD)
// ...existing code...

class PeopleListsFirebaseService {
  static final _listsRef = FirebaseFirestore.instance.collection('people_lists');

  static Future<List<PeopleListModel>> getLists() async {
    final snapshot = await _listsRef.get();
    return snapshot.docs.map((doc) => PeopleListModel(
      id: doc.id,
      name: doc['name'] ?? '',
      filters: (doc['filters'] as List<dynamic>? ?? []).map((f) => PeopleListFilter(
        field: f['field'],
        operator: f['operator'],
        value: f['value'],
      )).toList(),
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
    )).toList();
  }

  static Future<void> addList(PeopleListModel list) async {
    await _listsRef.add({
      'name': list.name,
      'filters': list.filters.map((f) => {
        'field': f.field,
        'operator': f.operator,
        'value': f.value,
      }).toList(),
      'createdAt': list.createdAt,
      'updatedAt': list.updatedAt,
    });
  }

  static Future<void> updateList(PeopleListModel list) async {
    await _listsRef.doc(list.id).update({
      'name': list.name,
      'filters': list.filters.map((f) => {
        'field': f.field,
        'operator': f.operator,
        'value': f.value,
      }).toList(),
      'updatedAt': list.updatedAt,
    });
  }

  static Future<void> deleteList(String id) async {
    await _listsRef.doc(id).delete();
  }

  /// Met à jour une liste par id (nom et filtres)
  static Future<void> updateListById(String id, String name, List<Map<String, dynamic>> filters) async {
    await _listsRef.doc(id).update({
      'name': name,
      'filters': filters,
      'updatedAt': DateTime.now(),
    });
  }

  static Future<void> createList(String name, List<Map<String, dynamic>> filters) async {
    await _listsRef.add({
      'name': name,
      'filters': filters,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });
  }
}

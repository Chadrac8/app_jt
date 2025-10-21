import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';

class FamilyService {
  static const String _familiesCollection = 'families';
  static const String _personsCollection = 'persons';
  static const String _familyHistoryCollection = 'family_history';
  static const String _familyNotificationsCollection = 'family_notifications';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Create family from map data
  static Future<String?> createFamilyFromMap(Map<String, dynamic> familyData, {String? createdBy}) async {
    try {
      DocumentReference docRef = await _firestore.collection(_familiesCollection).add({
        ...familyData,
        'createdAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });
      
      return docRef.id;
    } catch (e) {
      print('Error creating family from map: $e');
      return null;
    }
  }

  // Update family from map data
  static Future<bool> updateFamilyFromMap(String familyId, Map<String, dynamic> familyData, {String? modifiedBy}) async {
    try {
      await _firestore.collection(_familiesCollection).doc(familyId).update({
        ...familyData,
        'lastModified': FieldValue.serverTimestamp(),
        'lastModifiedBy': modifiedBy,
      });
      
      return true;
    } catch (e) {
      print('Error updating family from map: $e');
      return false;
    }
  }

  // Create a family
  static Future<String> createFamily(FamilyModel family, {String? createdBy}) async {
    try {
      final familyData = family.copyWith(
        createdBy: createdBy,
        lastModifiedBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final docRef = await _firestore
          .collection(_familiesCollection)
          .add(familyData.toFirestore());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create family: $e');
    }
  }

  // Update an existing family
  static Future<void> updateFamily(FamilyModel family, {String? modifiedBy}) async {
    try {
      final familyData = family.copyWith(
        lastModifiedBy: modifiedBy,
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(_familiesCollection)
          .doc(family.id)
          .update(familyData.toFirestore());
    } catch (e) {
      throw Exception('Failed to update family: $e');
    }
  }

  // Get a family by ID
  static Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final doc = await _firestore
          .collection(_familiesCollection)
          .doc(familyId)
          .get();
      
      if (doc.exists) {
        return FamilyModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get family: $e');
    }
  }

  // Delete a family
  static Future<void> deleteFamily(String familyId) async {
    try {
      final batch = _firestore.batch();
      
      // Remove familyId from all persons who belong to this family
      final personsQuery = await _firestore
          .collection(_personsCollection)
          .where('familyId', isEqualTo: familyId)
          .get();
      
      for (final doc in personsQuery.docs) {
        batch.update(doc.reference, {
          'familyId': null,
          'familyRole': FamilyRole.other.toString().split('.').last,
          'updatedAt': DateTime.now(),
        });
      }
      
      // Delete the family document
      batch.delete(_firestore.collection(_familiesCollection).doc(familyId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete family: $e');
    }
  }

  // Get all families stream
  static Stream<List<FamilyModel>> getFamiliesStream({
    FamilyStatus? status,
    bool activeOnly = true,
  }) {
    Query query = _firestore
        .collection(_familiesCollection)
        .orderBy('name');
    
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => FamilyModel.fromFirestore(doc)).toList());
  }

  // Get family members
  static Future<List<PersonModel>> getFamilyMembers(String familyId) async {
    try {
      final query = await _firestore
          .collection(_personsCollection)
          .where('familyId', isEqualTo: familyId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return query.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family members: $e');
    }
  }

  // Get family members stream
  static Stream<List<PersonModel>> getFamilyMembersStream(String familyId) {
    return _firestore
        .collection(_personsCollection)
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .orderBy('familyRole')
        .orderBy('birthDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PersonModel.fromFirestore(doc)).toList());
  }

  // Add person to family
  static Future<void> addPersonToFamily(
    String personId,
    String familyId, {
    FamilyRole role = FamilyRole.other,
    String? modifiedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Update person
      final personRef = _firestore.collection(_personsCollection).doc(personId);
      batch.update(personRef, {
        'familyId': familyId,
        'familyRole': role.toString().split('.').last,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      // Update family member list
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayUnion([personId]),
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add person to family: $e');
    }
  }

  // Remove person from family
  static Future<void> removePersonFromFamily(
    String personId,
    String familyId, {
    String? modifiedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Update person
      final personRef = _firestore.collection(_personsCollection).doc(personId);
      batch.update(personRef, {
        'familyId': null,
        'familyRole': FamilyRole.other.toString().split('.').last,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      // Update family member list
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayRemove([personId]),
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove person from family: $e');
    }
  }

  // Update person's family role
  static Future<void> updatePersonFamilyRole(
    String personId,
    FamilyRole role, {
    String? modifiedBy,
  }) async {
    try {
      await _firestore.collection(_personsCollection).doc(personId).update({
        'familyRole': role.toString().split('.').last,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
    } catch (e) {
      throw Exception('Failed to update person family role: $e');
    }
  }

  // Set family head
  static Future<void> setFamilyHead(
    String familyId,
    String personId, {
    String? modifiedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Update family
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'headOfFamilyId': personId,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      // Update person role to head
      final personRef = _firestore.collection(_personsCollection).doc(personId);
      batch.update(personRef, {
        'familyRole': FamilyRole.head.toString().split('.').last,
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set family head: $e');
    }
  }

  // Search families by name
  static Future<List<FamilyModel>> searchFamilies(String searchTerm) async {
    try {
      final query = await _firestore
          .collection(_familiesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([searchTerm])
          .endAt([searchTerm + '\uf8ff'])
          .get();
      
      return query.docs
          .map((doc) => FamilyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search families: $e');
    }
  }

  // Get families by status
  static Future<List<FamilyModel>> getFamiliesByStatus(FamilyStatus status) async {
    try {
      final query = await _firestore
          .collection(_familiesCollection)
          .where('status', isEqualTo: status.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      return query.docs
          .map((doc) => FamilyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get families by status: $e');
    }
  }

  // Get all families with pagination
  static Future<List<Map<String, dynamic>>> getAllFamilies({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_familiesCollection)
          .orderBy('familyName')
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting all families: $e');
      return [];
    }
  }

  // Get family statistics
  static Future<Map<String, dynamic>> getFamilyStatistics() async {
    try {
      final allFamilies = await _firestore
          .collection(_familiesCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final Map<FamilyStatus, int> statusCounts = {};
      int totalMembers = 0;
      
      for (final doc in allFamilies.docs) {
        final family = FamilyModel.fromFirestore(doc);
        statusCounts[family.status] = (statusCounts[family.status] ?? 0) + 1;
        totalMembers += family.memberIds.length;
      }
      
      return {
        'totalFamilies': allFamilies.docs.length,
        'totalMembers': totalMembers,
        'averageFamilySize': allFamilies.docs.isEmpty 
            ? 0.0 
            : totalMembers / allFamilies.docs.length,
        'statusCounts': statusCounts.map(
          (key, value) => MapEntry(key.toString().split('.').last, value),
        ),
      };
    } catch (e) {
      throw Exception('Failed to get family statistics: $e');
    }
  }

  // Merge families
  static Future<void> mergeFamilies(
    String primaryFamilyId,
    String secondaryFamilyId, {
    String? modifiedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Get both families
      final primaryFamily = await getFamily(primaryFamilyId);
      final secondaryFamily = await getFamily(secondaryFamilyId);
      
      if (primaryFamily == null || secondaryFamily == null) {
        throw Exception('One or both families not found');
      }
      
      // Move all members from secondary to primary family
      for (final memberId in secondaryFamily.memberIds) {
        final personRef = _firestore.collection(_personsCollection).doc(memberId);
        batch.update(personRef, {
          'familyId': primaryFamilyId,
          'updatedAt': DateTime.now(),
          'lastModifiedBy': modifiedBy,
        });
      }
      
      // Update primary family member list
      final primaryFamilyRef = _firestore.collection(_familiesCollection).doc(primaryFamilyId);
      batch.update(primaryFamilyRef, {
        'memberIds': FieldValue.arrayUnion(secondaryFamily.memberIds),
        'updatedAt': DateTime.now(),
        'lastModifiedBy': modifiedBy,
      });
      
      // Delete secondary family
      batch.delete(_firestore.collection(_familiesCollection).doc(secondaryFamilyId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to merge families: $e');
    }
  }

  // Get family history
  static Future<List<Map<String, dynamic>>> getFamilyHistory(String familyId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_familyHistoryCollection)
          .where('familyId', isEqualTo: familyId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting family history: $e');
      return [];
    }
  }

  // Log family history
  static Future<void> logFamilyHistory(String familyId, String action, String description, {Map<String, dynamic>? metadata}) async {
    try {
      await _firestore.collection(_familyHistoryCollection).add({
        'familyId': familyId,
        'action': action,
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging family history: $e');
    }
  }

  // Send family notification
  static Future<void> sendFamilyNotification(String familyId, String title, String message, {String? type}) async {
    try {
      await _firestore.collection(_familyNotificationsCollection).add({
        'familyId': familyId,
        'title': title,
        'message': message,
        'type': type ?? 'info',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending family notification: $e');
    }
  }

  // Get family notifications
  static Future<List<Map<String, dynamic>>> getFamilyNotifications(String familyId, {bool unreadOnly = false}) async {
    try {
      Query query = _firestore
          .collection(_familyNotificationsCollection)
          .where('familyId', isEqualTo: familyId);
      
      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }
      
      QuerySnapshot snapshot = await query
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting family notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_familyNotificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get families by type
  static Future<List<Map<String, dynamic>>> getFamiliesByType(String familyType) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_familiesCollection)
          .where('familyType', isEqualTo: familyType)
          .orderBy('familyName')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting families by type: $e');
      return [];
    }
  }

  // Get families by size range
  static Future<List<Map<String, dynamic>>> getFamiliesBySize(int minSize, int maxSize) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_familiesCollection)
          .where('memberCount', isGreaterThanOrEqualTo: minSize)
          .where('memberCount', isLessThanOrEqualTo: maxSize)
          .orderBy('memberCount')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting families by size: $e');
      return [];
    }
  }

  // Get families by location
  static Future<List<Map<String, dynamic>>> getFamiliesByLocation(String city, {String? region}) async {
    try {
      Query query = _firestore
          .collection(_familiesCollection)
          .where('address.city', isEqualTo: city);
      
      if (region != null) {
        query = query.where('address.region', isEqualTo: region);
      }
      
      QuerySnapshot snapshot = await query
          .orderBy('familyName')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting families by location: $e');
      return [];
    }
  }

  // Bulk update families
  static Future<bool> bulkUpdateFamilies(List<String> familyIds, Map<String, dynamic> updates) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String familyId in familyIds) {
        DocumentReference familyRef = _firestore.collection(_familiesCollection).doc(familyId);
        batch.update(familyRef, {
          ...updates,
          'lastModified': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Log bulk operation
      for (String familyId in familyIds) {
        await logFamilyHistory(familyId, 'bulk_update', 'Family updated via bulk operation', metadata: updates);
      }
      
      return true;
    } catch (e) {
      print('Error in bulk update: $e');
      return false;
    }
  }

  // Bulk delete families
  static Future<bool> bulkDeleteFamilies(List<String> familyIds) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String familyId in familyIds) {
        DocumentReference familyRef = _firestore.collection(_familiesCollection).doc(familyId);
        batch.delete(familyRef);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error in bulk delete: $e');
      return false;
    }
  }

  // Get family tree data
  static Future<Map<String, dynamic>> getFamilyTree(String familyId) async {
    try {
      DocumentSnapshot familyDoc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!familyDoc.exists) return {};
      
      Map<String, dynamic> familyData = familyDoc.data() as Map<String, dynamic>;
      List<String> memberIds = List<String>.from(familyData['memberIds'] ?? []);
      
      List<Map<String, dynamic>> members = [];
      for (String memberId in memberIds) {
        DocumentSnapshot memberDoc = await _firestore.collection(_personsCollection).doc(memberId).get();
        if (memberDoc.exists) {
          Map<String, dynamic> memberData = memberDoc.data() as Map<String, dynamic>;
          members.add({
            'id': memberDoc.id,
            ...memberData,
          });
        }
      }
      
      return {
        'family': {'id': familyDoc.id, ...familyData},
        'members': members,
      };
    } catch (e) {
      print('Error getting family tree: $e');
      return {};
    }
  }

  // Export family data
  static Future<Map<String, dynamic>> exportFamilyData(String familyId) async {
    try {
      Map<String, dynamic> familyTree = await getFamilyTree(familyId);
      List<Map<String, dynamic>> history = await getFamilyHistory(familyId);
      List<Map<String, dynamic>> notifications = await getFamilyNotifications(familyId);
      
      return {
        'family': familyTree['family'],
        'members': familyTree['members'],
        'history': history,
        'notifications': notifications,
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error exporting family data: $e');
      return {};
    }
  }

  // Import family data
  static Future<String?> importFamilyData(Map<String, dynamic> familyData) async {
    try {
      Map<String, dynamic> family = familyData['family'];
      List<dynamic> members = familyData['members'] ?? [];
      
      // Create family
      DocumentReference familyRef = await _firestore.collection(_familiesCollection).add({
        ...family,
        'createdAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      String familyId = familyRef.id;
      
      // Create members
      List<String> memberIds = [];
      for (Map<String, dynamic> member in members) {
        DocumentReference memberRef = await _firestore.collection(_personsCollection).add({
          ...member,
          'familyId': familyId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        memberIds.add(memberRef.id);
      }
      
      // Update family with member IDs
      await familyRef.update({'memberIds': memberIds});
      
      await logFamilyHistory(familyId, 'import', 'Family data imported');
      
      return familyId;
    } catch (e) {
      print('Error importing family data: $e');
      return null;
    }
  }

  // Archive family
  static Future<bool> archiveFamily(String familyId) async {
    try {
      await _firestore.collection(_familiesCollection).doc(familyId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      await logFamilyHistory(familyId, 'archive', 'Family archived');
      return true;
    } catch (e) {
      print('Error archiving family: $e');
      return false;
    }
  }

  // Restore family from archive
  static Future<bool> restoreFamily(String familyId) async {
    try {
      await _firestore.collection(_familiesCollection).doc(familyId).update({
        'isArchived': false,
        'archivedAt': FieldValue.delete(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      await logFamilyHistory(familyId, 'restore', 'Family restored from archive');
      return true;
    } catch (e) {
      print('Error restoring family: $e');
      return false;
    }
  }

  // Get archived families
  static Future<List<Map<String, dynamic>>> getArchivedFamilies() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_familiesCollection)
          .where('isArchived', isEqualTo: true)
          .orderBy('archivedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error getting archived families: $e');
      return [];
    }
  }

  // Advanced family validation
  static Future<Map<String, dynamic>> validateFamilyData(Map<String, dynamic> familyData) async {
    Map<String, dynamic> result = {
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };
    
    try {
      // Required fields validation
      if (familyData['familyName'] == null || familyData['familyName'].toString().trim().isEmpty) {
        result['errors'].add('Family name is required');
        result['isValid'] = false;
      }
      
      // Phone number validation
      if (familyData['phone'] != null) {
        String phone = familyData['phone'].toString();
        if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phone)) {
          result['warnings'].add('Phone number format may be invalid');
        }
      }
      
      // Email validation
      if (familyData['email'] != null) {
        String email = familyData['email'].toString();
        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
          result['errors'].add('Invalid email format');
          result['isValid'] = false;
        }
      }
      
      // Check for duplicate family name
      QuerySnapshot existingFamilies = await _firestore
          .collection(_familiesCollection)
          .where('familyName', isEqualTo: familyData['familyName'])
          .get();
      
      if (existingFamilies.docs.isNotEmpty) {
        // If updating, check if it's the same family
        String? currentFamilyId = familyData['id'];
        bool isDuplicate = existingFamilies.docs.any((doc) => doc.id != currentFamilyId);
        
        if (isDuplicate) {
          result['warnings'].add('A family with this name already exists');
        }
      }
      
      // Member count validation
      if (familyData['memberIds'] != null) {
        List<dynamic> memberIds = familyData['memberIds'];
        if (memberIds.length > 20) {
          result['warnings'].add('Family has unusually large number of members (${memberIds.length})');
        }
      }
      
    } catch (e) {
      result['errors'].add('Validation error: $e');
      result['isValid'] = false;
    }
    
    return result;
  }

  // Get family communication preferences
  static Future<Map<String, dynamic>> getFamilyCommunicationPreferences(String familyId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!doc.exists) return {};
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['communicationPreferences'] ?? {};
    } catch (e) {
      print('Error getting communication preferences: $e');
      return {};
    }
  }

  // Update family communication preferences
  static Future<bool> updateFamilyCommunicationPreferences(String familyId, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection(_familiesCollection).doc(familyId).update({
        'communicationPreferences': preferences,
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      await logFamilyHistory(familyId, 'communication_update', 'Communication preferences updated');
      return true;
    } catch (e) {
      print('Error updating communication preferences: $e');
      return false;
    }
  }

  // Get family events
  static Future<List<Map<String, dynamic>>> getFamilyEvents(String familyId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!doc.exists) return [];
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> events = data['familyEvents'] ?? [];
      
      List<Map<String, dynamic>> familyEvents = events.map((e) => Map<String, dynamic>.from(e)).toList();
      
      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        familyEvents = familyEvents.where((event) {
          DateTime eventDate = DateTime.parse(event['date']);
          bool afterStart = startDate == null || eventDate.isAfter(startDate) || eventDate.isAtSameMomentAs(startDate);
          bool beforeEnd = endDate == null || eventDate.isBefore(endDate) || eventDate.isAtSameMomentAs(endDate);
          return afterStart && beforeEnd;
        }).toList();
      }
      
      // Sort by date
      familyEvents.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
      
      return familyEvents;
    } catch (e) {
      print('Error getting family events: $e');
      return [];
    }
  }

  // Add family event
  static Future<bool> addFamilyEvent(String familyId, Map<String, dynamic> eventData) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!doc.exists) return false;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> events = List.from(data['familyEvents'] ?? []);
      
      events.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        ...eventData,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await _firestore.collection(_familiesCollection).doc(familyId).update({
        'familyEvents': events,
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      await logFamilyHistory(familyId, 'event_added', 'Family event added: ${eventData['title']}');
      return true;
    } catch (e) {
      print('Error adding family event: $e');
      return false;
    }
  }

  // Get family notes
  static Future<List<Map<String, dynamic>>> getFamilyNotes(String familyId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!doc.exists) return [];
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> notes = data['familyNotes'] ?? [];
      
      List<Map<String, dynamic>> familyNotes = notes.map((n) => Map<String, dynamic>.from(n)).toList();
      
      // Sort by creation date (newest first)
      familyNotes.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
      
      return familyNotes;
    } catch (e) {
      print('Error getting family notes: $e');
      return [];
    }
  }

  // Add family note
  static Future<bool> addFamilyNote(String familyId, Map<String, dynamic> noteData) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!doc.exists) return false;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> notes = List.from(data['familyNotes'] ?? []);
      
      notes.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        ...noteData,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await _firestore.collection(_familiesCollection).doc(familyId).update({
        'familyNotes': notes,
        'lastModified': FieldValue.serverTimestamp(),
      });
      
      await logFamilyHistory(familyId, 'note_added', 'Family note added');
      return true;
    } catch (e) {
      print('Error adding family note: $e');
      return false;
    }
  }

  // Get families with upcoming events
  static Future<List<Map<String, dynamic>>> getFamiliesWithUpcomingEvents({int daysAhead = 30}) async {
    try {
      DateTime startDate = DateTime.now();
      DateTime endDate = startDate.add(Duration(days: daysAhead));
      
      QuerySnapshot snapshot = await _firestore
          .collection(_familiesCollection)
          .where('isArchived', isNotEqualTo: true)
          .get();
      
      List<Map<String, dynamic>> familiesWithEvents = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> familyData = doc.data() as Map<String, dynamic>;
        List<dynamic> events = familyData['familyEvents'] ?? [];
        
        List<Map<String, dynamic>> upcomingEvents = events
            .map((e) => Map<String, dynamic>.from(e))
            .where((event) {
              DateTime eventDate = DateTime.parse(event['date']);
              return eventDate.isAfter(startDate) && eventDate.isBefore(endDate);
            }).toList();
        
        if (upcomingEvents.isNotEmpty) {
          familiesWithEvents.add({
            'id': doc.id,
            'familyName': familyData['familyName'],
            'upcomingEvents': upcomingEvents,
          });
        }
      }
      
      return familiesWithEvents;
    } catch (e) {
      print('Error getting families with upcoming events: $e');
      return [];
    }
  }

  // Get advanced family statistics
  static Future<Map<String, dynamic>> getAdvancedFamilyStatistics() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_familiesCollection)
          .where('isArchived', isNotEqualTo: true)
          .get();
      
      int totalFamilies = snapshot.docs.length;
      int totalMembers = 0;
      Map<String, int> familyTypeStats = {};
      Map<String, int> locationStats = {};
      Map<String, int> sizeStats = {};
      List<int> memberCounts = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Member count
        int memberCount = (data['memberIds'] as List?)?.length ?? 0;
        totalMembers += memberCount;
        memberCounts.add(memberCount);
        
        // Family type statistics
        String familyType = data['familyType'] ?? 'Unknown';
        familyTypeStats[familyType] = (familyTypeStats[familyType] ?? 0) + 1;
        
        // Location statistics
        Map<String, dynamic>? address = data['address'];
        if (address != null && address['city'] != null) {
          String city = address['city'];
          locationStats[city] = (locationStats[city] ?? 0) + 1;
        }
        
        // Size statistics
        String sizeCategory;
        if (memberCount == 1) sizeCategory = 'Single';
        else if (memberCount == 2) sizeCategory = 'Couple';
        else if (memberCount <= 4) sizeCategory = 'Small (3-4)';
        else if (memberCount <= 6) sizeCategory = 'Medium (5-6)';
        else sizeCategory = 'Large (7+)';
        
        sizeStats[sizeCategory] = (sizeStats[sizeCategory] ?? 0) + 1;
      }
      
      // Calculate averages
      double averageFamilySize = totalFamilies > 0 ? totalMembers / totalFamilies : 0;
      
      return {
        'totalFamilies': totalFamilies,
        'totalMembers': totalMembers,
        'averageFamilySize': averageFamilySize,
        'familyTypeDistribution': familyTypeStats,
        'locationDistribution': locationStats,
        'sizeDistribution': sizeStats,
        'memberCounts': memberCounts,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting advanced statistics: $e');
      return {};
    }
  }

  // Backup all family data
  static Future<Map<String, dynamic>> backupAllFamilyData() async {
    try {
      QuerySnapshot familiesSnapshot = await _firestore.collection(_familiesCollection).get();
      QuerySnapshot personsSnapshot = await _firestore.collection(_personsCollection).get();
      
      List<Map<String, dynamic>> families = familiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      
      List<Map<String, dynamic>> persons = personsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      
      return {
        'families': families,
        'persons': persons,
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      print('Error creating backup: $e');
      return {};
    }
  }

  // Restore from backup
  static Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      List<dynamic> families = backupData['families'] ?? [];
      List<dynamic> persons = backupData['persons'] ?? [];
      
      WriteBatch batch = _firestore.batch();
      
      // Restore families
      for (Map<String, dynamic> family in families) {
        String familyId = family['id'];
        family.remove('id');
        DocumentReference familyRef = _firestore.collection(_familiesCollection).doc(familyId);
        batch.set(familyRef, family);
      }
      
      // Restore persons
      for (Map<String, dynamic> person in persons) {
        String personId = person['id'];
        person.remove('id');
        DocumentReference personRef = _firestore.collection(_personsCollection).doc(personId);
        batch.set(personRef, person);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }
}
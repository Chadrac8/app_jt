import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wb_sermon.dart';

/// Service pour gérer les sermons dans Firestore
class WBSermonFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'wb_sermons';

  /// Ajoute un nouveau sermon
  static Future<void> addSermon(WBSermon sermon) async {
    await _firestore.collection(_collection).doc(sermon.id).set(sermon.toJson());
  }

  /// Met à jour un sermon existant
  static Future<void> updateSermon(WBSermon sermon) async {
    await _firestore.collection(_collection).doc(sermon.id).update(sermon.toJson());
  }

  /// Supprime un sermon
  static Future<void> deleteSermon(String sermonId) async {
    await _firestore.collection(_collection).doc(sermonId).delete();
  }

  /// Récupère tous les sermons depuis Firestore
  static Future<List<WBSermon>> getAllSermons() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('publishedDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WBSermon.fromJson(doc.data()))
        .toList();
  }

  /// Récupère un sermon par son ID
  static Future<WBSermon?> getSermonById(String sermonId) async {
    final doc = await _firestore.collection(_collection).doc(sermonId).get();
    
    if (!doc.exists) {
      return null;
    }
    
    return WBSermon.fromJson(doc.data()!);
  }

  /// Écoute les changements en temps réel
  static Stream<List<WBSermon>> watchSermons() {
    return _firestore
        .collection(_collection)
        .orderBy('publishedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WBSermon.fromJson(doc.data()))
            .toList());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/sermon_note.dart';
import '../models/sermon_highlight.dart';

/// Service de synchronisation cloud pour les notes et surlignements
class NotesHighlightsCloudService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _notesCollection = 'wb_sermon_notes';
  static const String _highlightsCollection = 'wb_sermon_highlights';

  /// Vérifie si l'utilisateur est authentifié
  static bool get isAuthenticated => _auth.currentUser != null;

  /// ID de l'utilisateur actuel
  static String? get currentUserId => _auth.currentUser?.uid;

  // ==================== NOTES ====================

  /// Upload une note vers Firestore
  static Future<void> uploadNote(SermonNote note) async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final data = {
        ...note.toJson(),
        'userId': currentUserId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_notesCollection)
          .doc(note.id)
          .set(data, SetOptions(merge: true));

      debugPrint('✅ Note uploadée: ${note.id}');
    } catch (e) {
      debugPrint('❌ Erreur upload note: $e');
      rethrow;
    }
  }

  /// Upload plusieurs notes en batch
  static Future<void> uploadNotes(List<SermonNote> notes) async {
    if (!isAuthenticated || notes.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final note in notes) {
        final data = {
          ...note.toJson(),
          'userId': currentUserId,
          'syncedAt': FieldValue.serverTimestamp(),
        };

        final docRef = _firestore.collection(_notesCollection).doc(note.id);
        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ ${notes.length} notes uploadées');
    } catch (e) {
      debugPrint('❌ Erreur upload batch notes: $e');
      rethrow;
    }
  }

  /// Télécharge toutes les notes de l'utilisateur depuis Firestore
  static Future<List<SermonNote>> downloadNotes() async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final snapshot = await _firestore
          .collection(_notesCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      final notes = snapshot.docs.map((doc) {
        final data = doc.data();
        data.remove('userId');
        data.remove('syncedAt');
        return SermonNote.fromJson(data);
      }).toList();

      debugPrint('✅ ${notes.length} notes téléchargées');
      return notes;
    } catch (e) {
      debugPrint('❌ Erreur download notes: $e');
      rethrow;
    }
  }

  /// Stream temps réel des notes de l'utilisateur
  static Stream<List<SermonNote>> streamNotes() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notesCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data.remove('userId');
            data.remove('syncedAt');
            return SermonNote.fromJson(data);
          }).toList();
        });
  }

  /// Supprime une note de Firestore
  static Future<void> deleteNote(String noteId) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection(_notesCollection)
          .doc(noteId)
          .delete();

      debugPrint('✅ Note supprimée du cloud: $noteId');
    } catch (e) {
      debugPrint('❌ Erreur suppression note cloud: $e');
      rethrow;
    }
  }

  // ==================== HIGHLIGHTS ====================

  /// Upload un surlignement vers Firestore
  static Future<void> uploadHighlight(SermonHighlight highlight) async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final data = {
        ...highlight.toJson(),
        'userId': currentUserId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_highlightsCollection)
          .doc(highlight.id)
          .set(data, SetOptions(merge: true));

      debugPrint('✅ Highlight uploadé: ${highlight.id}');
    } catch (e) {
      debugPrint('❌ Erreur upload highlight: $e');
      rethrow;
    }
  }

  /// Upload plusieurs surlignements en batch
  static Future<void> uploadHighlights(List<SermonHighlight> highlights) async {
    if (!isAuthenticated || highlights.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final highlight in highlights) {
        final data = {
          ...highlight.toJson(),
          'userId': currentUserId,
          'syncedAt': FieldValue.serverTimestamp(),
        };

        final docRef = _firestore.collection(_highlightsCollection).doc(highlight.id);
        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ ${highlights.length} highlights uploadés');
    } catch (e) {
      debugPrint('❌ Erreur upload batch highlights: $e');
      rethrow;
    }
  }

  /// Télécharge tous les surlignements de l'utilisateur depuis Firestore
  static Future<List<SermonHighlight>> downloadHighlights() async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final snapshot = await _firestore
          .collection(_highlightsCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      final highlights = snapshot.docs.map((doc) {
        final data = doc.data();
        data.remove('userId');
        data.remove('syncedAt');
        return SermonHighlight.fromJson(data);
      }).toList();

      debugPrint('✅ ${highlights.length} highlights téléchargés');
      return highlights;
    } catch (e) {
      debugPrint('❌ Erreur download highlights: $e');
      rethrow;
    }
  }

  /// Stream temps réel des surlignements de l'utilisateur
  static Stream<List<SermonHighlight>> streamHighlights() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_highlightsCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data.remove('userId');
            data.remove('syncedAt');
            return SermonHighlight.fromJson(data);
          }).toList();
        });
  }

  /// Supprime un surlignement de Firestore
  static Future<void> deleteHighlight(String highlightId) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection(_highlightsCollection)
          .doc(highlightId)
          .delete();

      debugPrint('✅ Highlight supprimé du cloud: $highlightId');
    } catch (e) {
      debugPrint('❌ Erreur suppression highlight cloud: $e');
      rethrow;
    }
  }

  // ==================== SYNCHRONISATION ====================

  /// Synchronise toutes les données locales vers le cloud
  static Future<void> syncToCloud({
    required List<SermonNote> localNotes,
    required List<SermonHighlight> localHighlights,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      // Upload notes
      await uploadNotes(localNotes);

      // Upload highlights
      await uploadHighlights(localHighlights);

      debugPrint('✅ Synchronisation vers le cloud terminée');
    } catch (e) {
      debugPrint('❌ Erreur sync vers cloud: $e');
      rethrow;
    }
  }

  /// Synchronise les données du cloud vers local
  static Future<({
    List<SermonNote> notes,
    List<SermonHighlight> highlights,
  })> syncFromCloud() async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      // Download notes
      final notes = await downloadNotes();

      // Download highlights
      final highlights = await downloadHighlights();

      debugPrint('✅ Synchronisation depuis le cloud terminée');
      
      return (notes: notes, highlights: highlights);
    } catch (e) {
      debugPrint('❌ Erreur sync depuis cloud: $e');
      rethrow;
    }
  }

  /// Synchronisation bidirectionnelle avec gestion des conflits
  static Future<({
    List<SermonNote> notes,
    List<SermonHighlight> highlights,
  })> syncBidirectional({
    required List<SermonNote> localNotes,
    required List<SermonHighlight> localHighlights,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      // 1. Télécharger les données du cloud
      final cloudData = await syncFromCloud();

      // 2. Fusionner les données (les plus récentes gagnent)
      final mergedNotes = _mergeNotes(localNotes, cloudData.notes);
      final mergedHighlights = _mergeHighlights(localHighlights, cloudData.highlights);

      // 3. Uploader les données fusionnées vers le cloud
      await syncToCloud(
        localNotes: mergedNotes,
        localHighlights: mergedHighlights,
      );

      debugPrint('✅ Synchronisation bidirectionnelle terminée');
      debugPrint('   Notes: ${mergedNotes.length}, Highlights: ${mergedHighlights.length}');

      return (notes: mergedNotes, highlights: mergedHighlights);
    } catch (e) {
      debugPrint('❌ Erreur sync bidirectionnelle: $e');
      rethrow;
    }
  }

  /// Fusionne les notes locales et cloud (les plus récentes gagnent)
  static List<SermonNote> _mergeNotes(List<SermonNote> local, List<SermonNote> cloud) {
    final Map<String, SermonNote> notesMap = {};

    // Ajouter les notes locales
    for (final note in local) {
      notesMap[note.id] = note;
    }

    // Ajouter ou remplacer avec les notes cloud si plus récentes
    for (final note in cloud) {
      final existing = notesMap[note.id];
      if (existing == null) {
        notesMap[note.id] = note;
      } else {
        // Comparer les dates de modification
        final existingDate = existing.updatedAt ?? existing.createdAt;
        final cloudDate = note.updatedAt ?? note.createdAt;
        
        if (cloudDate.isAfter(existingDate)) {
          notesMap[note.id] = note;
        }
      }
    }

    return notesMap.values.toList();
  }

  /// Fusionne les surlignements locaux et cloud (les plus récentes gagnent)
  static List<SermonHighlight> _mergeHighlights(
    List<SermonHighlight> local,
    List<SermonHighlight> cloud,
  ) {
    final Map<String, SermonHighlight> highlightsMap = {};

    // Ajouter les highlights locaux
    for (final highlight in local) {
      highlightsMap[highlight.id] = highlight;
    }

    // Ajouter ou remplacer avec les highlights cloud si plus récents
    for (final highlight in cloud) {
      final existing = highlightsMap[highlight.id];
      if (existing == null) {
        highlightsMap[highlight.id] = highlight;
      } else {
        // Comparer les dates de modification
        final existingDate = existing.updatedAt ?? existing.createdAt;
        final cloudDate = highlight.updatedAt ?? highlight.createdAt;
        
        if (cloudDate.isAfter(existingDate)) {
          highlightsMap[highlight.id] = highlight;
        }
      }
    }

    return highlightsMap.values.toList();
  }

  // ==================== STATISTIQUES ====================

  /// Obtient les statistiques de synchronisation
  static Future<Map<String, dynamic>> getSyncStats() async {
    if (!isAuthenticated) {
      return {
        'authenticated': false,
        'notesCount': 0,
        'highlightsCount': 0,
      };
    }

    try {
      final notesSnapshot = await _firestore
          .collection(_notesCollection)
          .where('userId', isEqualTo: currentUserId)
          .count()
          .get();

      final highlightsSnapshot = await _firestore
          .collection(_highlightsCollection)
          .where('userId', isEqualTo: currentUserId)
          .count()
          .get();

      return {
        'authenticated': true,
        'userId': currentUserId,
        'notesCount': notesSnapshot.count,
        'highlightsCount': highlightsSnapshot.count,
      };
    } catch (e) {
      debugPrint('❌ Erreur stats sync: $e');
      return {
        'authenticated': true,
        'error': e.toString(),
      };
    }
  }

  /// Supprime toutes les données cloud de l'utilisateur
  static Future<void> clearCloudData() async {
    if (!isAuthenticated) return;

    try {
      // Supprimer toutes les notes
      final notesSnapshot = await _firestore
          .collection(_notesCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch1 = _firestore.batch();
      for (final doc in notesSnapshot.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();

      // Supprimer tous les highlights
      final highlightsSnapshot = await _firestore
          .collection(_highlightsCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch2 = _firestore.batch();
      for (final doc in highlightsSnapshot.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();

      debugPrint('✅ Données cloud supprimées');
    } catch (e) {
      debugPrint('❌ Erreur suppression données cloud: $e');
      rethrow;
    }
  }
}

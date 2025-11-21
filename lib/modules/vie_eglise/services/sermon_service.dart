import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sermon.dart';

class SermonService {
  static const String _collection = 'sermons';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _sermonsCollection =>
      _firestore.collection(_collection);

  // Récupérer tous les sermons
  static Stream<List<Sermon>> getSermons() {
    return _sermonsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Sermon.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Récupérer un sermon par ID
  static Future<Sermon?> getSermonById(String id) async {
    try {
      final doc = await _sermonsCollection.doc(id).get();
      if (doc.exists) {
        return Sermon.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du sermon: $e');
      return null;
    }
  }

  // Ajouter un nouveau sermon
  static Future<String?> addSermon(Sermon sermon) async {
    try {
      final docRef = await _sermonsCollection.add(sermon.toMap());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout du sermon: $e');
      return null;
    }
  }

  // Mettre à jour un sermon
  static Future<bool> updateSermon(String id, Sermon sermon) async {
    try {
      await _sermonsCollection.doc(id).update(sermon.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du sermon: $e');
      return false;
    }
  }

  // Supprimer un sermon
  static Future<bool> deleteSermon(String id) async {
    try {
      await _sermonsCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du sermon: $e');
      return false;
    }
  }

  // Rechercher des sermons
  static Stream<List<Sermon>> searchSermons(String query) {
    if (query.isEmpty) {
      return getSermons();
    }
    
    return _sermonsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Sermon.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((sermon) {
            final searchTerm = query.toLowerCase();
            return sermon.titre.toLowerCase().contains(searchTerm) ||
                   sermon.orateur.toLowerCase().contains(searchTerm) ||
                   sermon.tags.any((tag) => tag.toLowerCase().contains(searchTerm));
          })
          .toList();
    });
  }

  // Récupérer les sermons par orateur
  static Stream<List<Sermon>> getSermonsByOrateur(String orateur) {
    return _sermonsCollection
        .where('orateur', isEqualTo: orateur)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Sermon.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Récupérer les orateurs uniques
  static Future<List<String>> getOrateurs() async {
    try {
      final snapshot = await _sermonsCollection.get();
      final orateurs = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final orateur = data['orateur'] as String?;
        if (orateur != null && orateur.isNotEmpty) {
          orateurs.add(orateur);
        }
      }
      
      final orateursList = orateurs.toList();
      orateursList.sort();
      return orateursList;
    } catch (e) {
      print('Erreur lors de la récupération des orateurs: $e');
      return [];
    }
  }

  // Récupérer tous les tags uniques
  static Future<List<String>> getTags() async {
    try {
      final snapshot = await _sermonsCollection.get();
      final tags = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final sermonTags = data['tags'] as List<dynamic>?;
        if (sermonTags != null) {
          tags.addAll(sermonTags.cast<String>());
        }
      }
      
      final tagsList = tags.toList();
      tagsList.sort();
      return tagsList;
    } catch (e) {
      print('Erreur lors de la récupération des tags: $e');
      return [];
    }
  }
}

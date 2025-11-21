import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pepite_or_model.dart';
import '../auth/auth_service.dart';

class PepiteOrFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String collection = 'pepites_or';

  /// Créer une nouvelle pépite d'or
  static Future<String> creerPepiteOr(PepiteOrModel pepite) async {
    try {
      print('🔄 Début création pépite: ${pepite.theme}');
      
      final currentUser = await AuthService.getCurrentUserProfile();
      if (currentUser == null) {
        print('❌ Utilisateur non connecté');
        throw Exception('Utilisateur non connecté');
      }

      print('👤 Utilisateur connecté: ${currentUser.firstName} ${currentUser.lastName}');

      final pepiteAvecAuteur = pepite.copyWith(
        auteur: currentUser.id,
        nomAuteur: '${currentUser.firstName} ${currentUser.lastName}',
        dateCreation: DateTime.now(),
      );

      print('📝 Données à sauvegarder: ${pepiteAvecAuteur.toFirestore()}');

      final docRef = await _firestore
          .collection(collection)
          .add(pepiteAvecAuteur.toFirestore());

      print('✅ Pépite créée avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création de la pépite d\'or: $e');
      rethrow;
    }
  }

  /// Modifier une pépite d'or existante
  static Future<void> modifierPepiteOr(PepiteOrModel pepite) async {
    try {
      await _firestore
          .collection(collection)
          .doc(pepite.id)
          .update(pepite.toFirestore());
    } catch (e) {
      print('❌ Erreur lors de la modification de la pépite d\'or: $e');
      rethrow;
    }
  }

  /// Supprimer une pépite d'or
  static Future<void> supprimerPepiteOr(String pepiteId) async {
    try {
      await _firestore
          .collection(collection)
          .doc(pepiteId)
          .delete();
    } catch (e) {
      print('❌ Erreur lors de la suppression de la pépite d\'or: $e');
      rethrow;
    }
  }

  /// Obtenir une pépite d'or par ID
  static Future<PepiteOrModel?> obtenirPepiteOr(String pepiteId) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(pepiteId)
          .get();

      if (doc.exists) {
        return PepiteOrModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la pépite d\'or: $e');
      rethrow;
    }
  }

  /// Stream de toutes les pépites d'or (pour admin)
  static Stream<List<PepiteOrModel>> obtenirToutesPepitesOrStream() {
    return _firestore
        .collection(collection)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PepiteOrModel.fromFirestore(doc))
            .toList());
  }

  /// Stream des pépites d'or publiées (pour membres)
  static Stream<List<PepiteOrModel>> obtenirPepitesOrPublieesStream() {
    print('🔍 Début récupération stream pépites publiées...');
    return _firestore
        .collection(collection)
        .where('estPubliee', isEqualTo: true)
        .orderBy('datePublication', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Snapshot reçu: ${snapshot.docs.length} documents');
          final pepites = snapshot.docs
              .map((doc) {
                try {
                  print('📄 Traitement document: ${doc.id}');
                  return PepiteOrModel.fromFirestore(doc);
                } catch (e) {
                  print('❌ Erreur parsing document ${doc.id}: $e');
                  print('📄 Données: ${doc.data()}');
                  return null;
                }
              })
              .where((pepite) => pepite != null)
              .cast<PepiteOrModel>()
              .toList();
          print('✅ ${pepites.length} pépites publiées récupérées');
          return pepites;
        });
  }

  /// Obtenir les pépites d'or par page (pagination)
  static Future<List<PepiteOrModel>> obtenirPepitesOrParPage({
    required int limite,
    DocumentSnapshot? dernierDocument,
    bool seulementPubliees = true,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (seulementPubliees) {
        query = query.where('estPubliee', isEqualTo: true);
        query = query.orderBy('datePublication', descending: true);
      } else {
        query = query.orderBy('dateCreation', descending: true);
      }

      if (dernierDocument != null) {
        query = query.startAfterDocument(dernierDocument);
      }

      query = query.limit(limite);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PepiteOrModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des pépites d\'or: $e');
      rethrow;
    }
  }

  /// Publier/dépublier une pépite d'or
  static Future<void> publierPepiteOr(String pepiteId, bool publier) async {
    try {
      final updateData = <String, dynamic>{
        'estPubliee': publier,
      };

      if (publier) {
        updateData['datePublication'] = Timestamp.fromDate(DateTime.now());
      } else {
        updateData['datePublication'] = null;
      }

      await _firestore
          .collection(collection)
          .doc(pepiteId)
          .update(updateData);
    } catch (e) {
      print('❌ Erreur lors de la publication de la pépite d\'or: $e');
      rethrow;
    }
  }

  /// Ajouter/retirer des favoris
  static Future<void> toggleFavori(String pepiteId, bool estFavori) async {
    try {
      await _firestore
          .collection(collection)
          .doc(pepiteId)
          .update({'estFavorite': estFavori});
    } catch (e) {
      print('❌ Erreur lors de la modification des favoris: $e');
      rethrow;
    }
  }

  /// Incrémenter le nombre de vues
  static Future<void> incrementerVues(String pepiteId) async {
    try {
      await _firestore
          .collection(collection)
          .doc(pepiteId)
          .update({'nbVues': FieldValue.increment(1)});
    } catch (e) {
      print('❌ Erreur lors de l\'incrémentation des vues: $e');
      // Ne pas rethrow pour ne pas bloquer l'affichage
    }
  }

  /// Incrémenter le nombre de partages
  static Future<void> incrementerPartages(String pepiteId) async {
    try {
      await _firestore
          .collection(collection)
          .doc(pepiteId)
          .update({'nbPartages': FieldValue.increment(1)});
    } catch (e) {
      print('❌ Erreur lors de l\'incrémentation des partages: $e');
      // Ne pas rethrow pour ne pas bloquer le partage
    }
  }

  /// Rechercher des pépites d'or par thème ou tags
  static Future<List<PepiteOrModel>> rechercherPepitesOr({
    required String recherche,
    bool seulementPubliees = true,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (seulementPubliees) {
        query = query.where('estPubliee', isEqualTo: true);
      }

      final snapshot = await query.get();
      final pepites = snapshot.docs
          .map((doc) => PepiteOrModel.fromFirestore(doc))
          .toList();

      // Filtrer côté client pour la recherche textuelle
      final rechercheLower = recherche.toLowerCase();
      return pepites.where((pepite) {
        return pepite.theme.toLowerCase().contains(rechercheLower) ||
               pepite.description.toLowerCase().contains(rechercheLower) ||
               pepite.tags.any((tag) => tag.toLowerCase().contains(rechercheLower));
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche de pépites d\'or: $e');
      rethrow;
    }
  }

  /// Obtenir les statistiques des pépites d'or
  static Future<Map<String, dynamic>> obtenirStatistiques() async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final pepites = snapshot.docs
          .map((doc) => PepiteOrModel.fromFirestore(doc))
          .toList();

      final totalPepites = pepites.length;
      final pepitesPubliees = pepites.where((p) => p.estPubliee).length;
      final totalVues = pepites.fold<int>(0, (sum, p) => sum + p.nbVues);
      final totalPartages = pepites.fold<int>(0, (sum, p) => sum + p.nbPartages);

      return {
        'totalPepites': totalPepites,
        'pepitesPubliees': pepitesPubliees,
        'pepitesBrouillons': totalPepites - pepitesPubliees,
        'totalVues': totalVues,
        'totalPartages': totalPartages,
        'moyenneVuesParPepite': totalPepites > 0 ? totalVues / totalPepites : 0,
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// Obtenir les tags les plus utilisés
  static Future<List<String>> obtenirTagsPopulaires({int limite = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('estPubliee', isEqualTo: true)
          .get();

      final tagCount = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final pepite = PepiteOrModel.fromFirestore(doc);
        for (final tag in pepite.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }

      final sortedTags = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags
          .take(limite)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des tags populaires: $e');
      return [];
    }
  }
}

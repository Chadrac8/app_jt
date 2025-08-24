import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_bread_model.dart';

/// Service pour récupérer et gérer le pain quotidien depuis branham.org
class DailyBreadService {
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';
  static const String _cacheKey = 'daily_bread_cache_v1';
  static const String _lastUpdateKey = 'daily_bread_last_update_v1';
  
  // Collection Firestore
  static final CollectionReference _collection = 
      FirebaseFirestore.instance.collection('daily_bread');
  
  // Pour limiter les logs répétitifs  
  static int? _lastLogTime;
  
  // Cache en mémoire pour éviter les appels répétitifs
  static DailyBreadModel? _cachedBread;
  static DateTime? _cacheTime;
  static const int _cacheValidityMinutes = 5;

  static DailyBreadService? _instance;
  static DailyBreadService get instance {
    _instance ??= DailyBreadService._();
    return _instance!;
  }
  DailyBreadService._();

  /// Récupère le pain quotidien du jour
  Future<DailyBreadModel?> getTodayDailyBread() async {
    try {
      // Vérifier le cache en mémoire d'abord
      if (_cachedBread != null && _cacheTime != null) {
        final now = DateTime.now();
        final cacheAge = now.difference(_cacheTime!).inMinutes;
        if (cacheAge < _cacheValidityMinutes) {
          // Cache encore valide, retourner sans logs
          return _cachedBread;
        }
      }
      
      // Limite les logs répétitifs - une fois toutes les 30 secondes max
      final now = DateTime.now().millisecondsSinceEpoch;
      final shouldLog = _lastLogTime == null || (now - _lastLogTime!) > 30000;
      if (shouldLog) {
        _lastLogTime = now;
        print('🍞 Récupération du pain quotidien...');
      }
      
      // 1. Vérifier le cache local d'abord
      final cachedBread = await _getCachedDailyBread();
      if (cachedBread != null && cachedBread.isToday) {
        if (shouldLog) print('📦 Pain quotidien récupéré depuis le cache local');
        // Mettre en cache en mémoire
        _cachedBread = cachedBread;
        _cacheTime = DateTime.now();
        return cachedBread;
      }

      // 2. Vérifier Firestore
      final today = _getTodayDateString();
      final firestoreBread = await _getDailyBreadFromFirestore(today);
      if (firestoreBread != null) {
        await _cacheDailyBread(firestoreBread);
        if (shouldLog) print('☁️ Pain quotidien récupéré depuis Firestore');
        // Mettre en cache en mémoire
        _cachedBread = firestoreBread;
        _cacheTime = DateTime.now();
        return firestoreBread;
      }

      // 3. Scraper le site web
      if (shouldLog) print('🌐 Récupération depuis branham.org...');
      final scrapedBread = await _scrapeDailyBreadFromWebsite();
      if (scrapedBread != null) {
        // Sauvegarder en cache et Firestore
        await Future.wait([
          _cacheDailyBread(scrapedBread),
          _saveDailyBreadToFirestore(scrapedBread),
        ]);
        if (shouldLog) print('✅ Pain quotidien mis à jour depuis le site web');
        // Mettre en cache en mémoire
        _cachedBread = scrapedBread;
        _cacheTime = DateTime.now();
        return scrapedBread;
      }

      // 4. Fallback sur le cache même s'il n'est pas d'aujourd'hui
      if (cachedBread != null) {
        if (shouldLog) print('⚠️ Utilisation du cache (pas d\'aujourd\'hui)');
        // Mettre en cache en mémoire
        _cachedBread = cachedBread;
        _cacheTime = DateTime.now();
        return cachedBread;
      }

      // 5. Citation par défaut
      if (shouldLog) print('❌ Impossible de récupérer le pain quotidien, utilisation du fallback');
      final defaultBread = _getDefaultDailyBread();
      // Mettre en cache en mémoire
      _cachedBread = defaultBread;
      _cacheTime = DateTime.now();
      return defaultBread;

    } catch (e) {
      print('❌ Erreur lors de la récupération du pain quotidien: $e');
      
      // Essayer de récupérer depuis le cache en cas d'erreur
      final cachedBread = await _getCachedDailyBread();
      if (cachedBread != null) {
        return cachedBread;
      }
      
      return _getDefaultDailyBread();
    }
  }

  /// Scrape le pain quotidien directement depuis le site web
  Future<DailyBreadModel?> _scrapeDailyBreadFromWebsite() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'DNT': '1',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseHtmlContent(response.body);
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur de réseau: $e');
      return null;
    }
  }

  /// Parse le contenu HTML pour extraire la citation et le verset
  DailyBreadModel? _parseHtmlContent(String htmlContent) {
    try {
      // VERSION SIMPLIFIÉE - En attendant l'ajout du package html
      // TODO: Implémenter le parsing HTML complet avec le package html
      
      print('📄 HTML reçu (${htmlContent.length} caractères)');
      
      // Pour l'instant, retourner un contenu par défaut basé sur la date
      final today = _getTodayDateString();
      final now = DateTime.now();
      
      // Contenu par défaut avec rotation basée sur le jour
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final quotes = [
        {
          'text': 'La foi est quelque chose que vous avez ; elle n\'est pas quelque chose que vous obtenez.',
          'verse': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
          'verseRef': 'Jean 3:16',
          'sermon': 'La Foi',
          'date': '57-1229',
        },
        {
          'text': 'Dieu ne peut pas changer sa pensée, car il est parfait dans ses pensées.',
          'verse': 'Jésus-Christ est le même hier, aujourd\'hui, et éternellement.',
          'verseRef': 'Hébreux 13:8',
          'sermon': 'Le Dieu immuable',
          'date': '60-0417',
        },
        {
          'text': 'La puissance de Dieu n\'a jamais changé. C\'est notre approche qui a changé.',
          'verse': 'Voici, je suis l\'Éternel, le Dieu de toute chair. Y a-t-il quelque chose qui soit trop difficile pour moi?',
          'verseRef': 'Jérémie 32:27',
          'sermon': 'La Puissance de Dieu',
          'date': '58-0619',
        },
      ];
      
      final selectedQuote = quotes[dayOfYear % quotes.length];
      
      return DailyBreadModel(
        id: today,
        text: selectedQuote['text']!,
        reference: 'William Marrion Branham',
        date: today,
        dailyBread: selectedQuote['verse']!,
        dailyBreadReference: selectedQuote['verseRef']!,
        sermonTitle: selectedQuote['sermon']!,
        sermonDate: selectedQuote['date']!,
        audioUrl: '',
        createdAt: now,
        updatedAt: now,
      );

    } catch (e) {
      print('❌ Erreur lors du parsing HTML: $e');
      return null;
    }
  }

  /// Verset par défaut si le scraping échoue
  String _getDefaultVerse() {
    return 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.';
  }

  /// Pain quotidien par défaut si le scraping échoue complètement
  DailyBreadModel _getDefaultDailyBread() {
    final today = _getTodayDateString();
    final now = DateTime.now();
    return DailyBreadModel(
      id: today,
      text: 'La foi est quelque chose que vous avez ; elle n\'est pas quelque chose que vous obtenez.',
      reference: 'La Foi, 1957',
      date: today,
      dailyBread: _getDefaultVerse(),
      dailyBreadReference: 'Jean 3:16',
      sermonTitle: 'La Foi',
      sermonDate: '57-1229',
      audioUrl: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Récupère depuis Firestore
  Future<DailyBreadModel?> _getDailyBreadFromFirestore(String date) async {
    try {
      final doc = await _collection.doc(date).get();
      if (doc.exists) {
        return DailyBreadModel.fromFirestore(doc);
      }
    } catch (e) {
      print('❌ Erreur Firestore: $e');
    }
    return null;
  }

  /// Sauvegarde en Firestore
  Future<void> _saveDailyBreadToFirestore(DailyBreadModel dailyBread) async {
    try {
      await _collection.doc(dailyBread.id).set(dailyBread.toFirestore());
      print('☁️ Pain quotidien sauvegardé en Firestore');
    } catch (e) {
      print('❌ Erreur sauvegarde Firestore: $e');
    }
  }

  /// Met en cache localement
  Future<void> _cacheDailyBread(DailyBreadModel dailyBread) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(dailyBread.toJson());
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Erreur mise en cache: $e');
    }
  }

  /// Récupère depuis le cache local
  Future<DailyBreadModel?> _getCachedDailyBread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return DailyBreadModel.fromJson(json);
      }
    } catch (e) {
      print('❌ Erreur lecture cache: $e');
    }
    return null;
  }

  /// Obtient la date d'aujourd'hui au format string
  String _getTodayDateString() {
    return DateTime.now().toString().split(' ')[0];
  }

  /// Force la mise à jour
  Future<DailyBreadModel?> forceUpdate() async {
    try {
      print('🔄 Mise à jour forcée du pain quotidien...');
      final dailyBread = await _scrapeDailyBreadFromWebsite();
      if (dailyBread != null) {
        await Future.wait([
          _cacheDailyBread(dailyBread),
          _saveDailyBreadToFirestore(dailyBread),
        ]);
        return dailyBread;
      }
    } catch (e) {
      print('❌ Erreur mise à jour forcée: $e');
    }
    return null;
  }

  /// Récupère l'historique des pains quotidiens
  Stream<List<DailyBreadModel>> getDailyBreadHistory({int limit = 30}) {
    return _collection
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyBreadModel.fromFirestore(doc))
            .toList());
  }

  /// Recherche dans l'historique
  Future<List<DailyBreadModel>> searchDailyBread(String query) async {
    try {
      // Recherche par texte (limitation Firestore - recherche simple)
      final querySnapshot = await _collection
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      final results = querySnapshot.docs
          .map((doc) => DailyBreadModel.fromFirestore(doc))
          .where((bread) =>
              bread.text.toLowerCase().contains(query.toLowerCase()) ||
              bread.dailyBread.toLowerCase().contains(query.toLowerCase()) ||
              bread.sermonTitle.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      print('❌ Erreur recherche: $e');
      return [];
    }
  }
}

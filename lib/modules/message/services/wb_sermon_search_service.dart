import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wb_sermon.dart';
import '../models/search_result.dart';
import '../models/search_filter.dart';
import 'wb_sermon_firestore_service.dart';

/// Service principal pour la recherche de sermons William Branham
/// Inspiré de La Table VGR et MessageHub
class WBSermonSearchService {
  // URLs des APIs publiques (à adapter selon les sources disponibles)
  static const String _tableVgrApiBase = 'https://table.branham.fr/api';
  static const String _messageHubApiBase = 'https://messagehub.info/api';
  
  static const String _cacheKeySermons = 'wb_search_sermons_cache';
  static const String _cacheKeyLastUpdate = 'wb_search_last_update';
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Cache mémoire
  static List<WBSermon>? _cachedSermons;
  static DateTime? _lastFetchTime;

  /// Récupère tous les sermons avec mise en cache
  static Future<List<WBSermon>> getAllSermons({
    bool forceRefresh = false,
  }) async {
    try {
      // Vérifier le cache mémoire
      if (!forceRefresh && _cachedSermons != null && _lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceLastFetch < _cacheExpiry) {
          return _cachedSermons!;
        }
      }

      // Charger depuis Firestore en priorité
      List<WBSermon> sermons = [];
      try {
        sermons = await WBSermonFirestoreService.getAllSermons();
        debugPrint('✅ Chargé ${sermons.length} sermons depuis Firestore');
      } catch (e) {
        debugPrint('⚠️ Erreur Firestore: $e');
      }

      // Si pas de sermons dans Firestore, charger les démos
      if (sermons.isEmpty) {
        debugPrint('ℹ️ Aucun sermon dans Firestore, chargement des démos...');
        sermons = _getDemoSermons();
      }
      
      // Mettre en cache
      await _cacheSermons(sermons);
      _cachedSermons = sermons;
      _lastFetchTime = DateTime.now();

      return sermons;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des sermons: $e');
      // Retourner le cache même expiré en cas d'erreur, sinon les démos
      return _cachedSermons ?? _getDemoSermons();
    }
  }

  /// Recherche dans les sermons avec filtres
  static Future<List<SearchResult>> searchSermons({
    required SearchFilter filter,
  }) async {
    try {
      // Si pas de query, retourner liste vide
      if (filter.query == null || filter.query!.isEmpty) {
        return [];
      }

      // Appel API de recherche (à adapter selon l'API disponible)
      final response = await http.post(
        Uri.parse('$_tableVgrApiBase/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': filter.query,
          'languages': filter.languages,
          'years': filter.years,
          'series': filter.series,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>)
            .map((json) => SearchResult.fromJson(json as Map<String, dynamic>))
            .toList();

        return results;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      // Fallback: recherche locale dans le cache
      return _searchLocally(filter);
    }
  }

  /// Recherche locale dans les sermons en cache
  static Future<List<SearchResult>> _searchLocally(SearchFilter filter) async {
    final sermons = await getAllSermons();
    final query = filter.query?.toLowerCase() ?? '';
    
    final results = <SearchResult>[];
    
    for (final sermon in sermons) {
      // Filtrer par critères
      if (!_matchesFilter(sermon, filter)) continue;

      // Recherche simple dans le titre et description
      final titleMatch = sermon.title.toLowerCase().contains(query);
      final descMatch = sermon.description?.toLowerCase().contains(query) ?? false;

      if (titleMatch || descMatch) {
        results.add(SearchResult(
          sermonId: sermon.id,
          sermonTitle: sermon.title,
          sermonDate: sermon.date,
          matchedText: titleMatch ? sermon.title : (sermon.description ?? ''),
          relevanceScore: titleMatch ? 1.0 : 0.7,
        ));
      }
    }

    // Trier par pertinence
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    return results;
  }

  /// Vérifie si un sermon correspond aux filtres
  static bool _matchesFilter(WBSermon sermon, SearchFilter filter) {
    if (filter.languages.isNotEmpty && !filter.languages.contains(sermon.language)) {
      return false;
    }
    if (filter.years.isNotEmpty && !filter.years.contains(sermon.year)) {
      return false;
    }
    if (filter.series.isNotEmpty) {
      final hasMatchingSeries = sermon.series.any((s) => filter.series.contains(s));
      if (!hasMatchingSeries) return false;
    }
    if (filter.hasAudio == true && sermon.audioUrl == null) {
      return false;
    }
    if (filter.hasVideo == true && sermon.videoUrl == null) {
      return false;
    }
    if (filter.hasPdf == true && sermon.pdfUrl == null) {
      return false;
    }
    if (filter.hasText == true && sermon.textContent == null) {
      return false;
    }
    if (filter.isFavorite == true && !sermon.isFavorite) {
      return false;
    }
    return true;
  }

  /// Récupère les sermons depuis l'API
  static Future<List<WBSermon>> _fetchSermonsFromApi() async {
    // Essayer d'abord La Table VGR
    try {
      final response = await http.get(
        Uri.parse('$_tableVgrApiBase/sermons?language=fr'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return await compute(_parseSermonsList, response.body);
      }
    } catch (e) {
      debugPrint('Erreur Table VGR: $e');
    }

    // Fallback: MessageHub
    try {
      final response = await http.get(
        Uri.parse('$_messageHubApiBase/sermons?lang=fr'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return await compute(_parseSermonsList, response.body);
      }
    } catch (e) {
      debugPrint('Erreur MessageHub: $e');
    }

    // Si toutes les APIs échouent, retourner des données de démo
    return _getDemoSermons();
  }

  /// Parse la liste de sermons dans un isolate
  static List<WBSermon> _parseSermonsList(String responseBody) {
    final data = json.decode(responseBody);
    final sermonsJson = data is List ? data : (data['sermons'] as List? ?? []);
    return sermonsJson
        .map((json) => WBSermon.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les sermons depuis le cache local
  static Future<List<WBSermon>> _getCachedSermons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKeySermons);
      final lastUpdate = prefs.getString(_cacheKeyLastUpdate);

      if (cachedJson != null && lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        final timeSinceUpdate = DateTime.now().difference(lastUpdateTime);

        if (timeSinceUpdate < _cacheExpiry) {
          final List<dynamic> jsonList = json.decode(cachedJson);
          return jsonList
              .map((json) => WBSermon.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Erreur lecture cache: $e');
    }
    return [];
  }

  /// Met en cache les sermons
  static Future<void> _cacheSermons(List<WBSermon> sermons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sermons.map((s) => s.toJson()).toList();
      await prefs.setString(_cacheKeySermons, json.encode(jsonList));
      await prefs.setString(_cacheKeyLastUpdate, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Erreur mise en cache: $e');
    }
  }

  /// Retourne des sermons de démo pour le développement
  static List<WBSermon> _getDemoSermons() {
    const demoText1 = '''<h1>LE DIEU DE CET ÂGE MAUVAIS</h1>
<p><strong>Date:</strong> 17 Mars 1963 (Dimanche soir)</p>
<p><strong>Lieu:</strong> Branham Tabernacle, Jeffersonville, Indiana, USA</p>

<p>[1] Bonsoir, amis. C'est vraiment un privilège d'être ici ce soir et de pouvoir partager la Parole de Dieu avec vous.</p>
<br>
<p>[2] Père Céleste, nous Te remercions ce soir pour ce privilège de nous rassembler à nouveau au Nom du Seigneur Jésus.</p>
<br>
<p>[3] Ce soir, j'aimerais parler d'un sujet très important : "Le Dieu de cet âge mauvais". La Bible nous dit dans 2 Corinthiens 4:4 : "Pour les incrédules dont le dieu de ce siècle a aveuglé l'intelligence..."</p>''';

    const demoText1En = '''<h1>THE GOD OF THIS EVIL AGE</h1>
<p><strong>Date:</strong> March 17, 1963 (Sunday Evening)</p>
<p><strong>Location:</strong> Branham Tabernacle, Jeffersonville, Indiana, USA</p>

<p>[1] Good evening, friends. It's truly a privilege to be here tonight and to share God's Word with you.</p>
<br>
<p>[2] Heavenly Father, we thank You tonight for this privilege of gathering again in the Name of the Lord Jesus.</p>
<br>
<p>[3] Tonight, I would like to speak on a very important subject: "The God of This Evil Age". The Bible tells us in 2 Corinthians 4:4: "In whom the god of this world hath blinded the minds of them which believe not..."</p>''';

    const demoText2 = '''<h1>LE RAPPORT DU RÉVEIL</h1>
<p><strong>Date:</strong> 25 Novembre 1965</p>
<p><strong>Lieu:</strong> Shreveport, Louisiana, USA</p>

<p>[1] Bonsoir. C'est un privilège d'être ici ce soir pour témoigner de ce que Dieu a fait durant ces campagnes de réveil.</p>
<br>
<p>[2] Nous avons vu Dieu se mouvoir avec puissance. Des miracles, des guérisons, des vies transformées par la puissance du Saint-Esprit.</p>
<br>
<p>[3] La restauration promise est en train de s'accomplir sous nos yeux. Dieu appelle Son peuple à revenir à la Parole originelle.</p>''';

    const demoText2En = '''<h1>THE RAPTURE</h1>
<p><strong>Date:</strong> November 25, 1965</p>
<p><strong>Location:</strong> Shreveport, Louisiana, USA</p>

<p>[1] Good evening. It's a privilege to be here tonight to testify of what God has done during these revival campaigns.</p>
<br>
<p>[2] We have seen God move with power. Miracles, healings, lives transformed by the power of the Holy Spirit.</p>
<br>
<p>[3] The promised restoration is taking place before our eyes. God is calling His people back to the original Word.</p>''';
    
    return [
      // Version VGR
      WBSermon(
        id: '63-0317E-VGR',
        title: 'Le Dieu de cet âge mauvais',
        date: '63-0317E',
        location: 'Jeffersonville, IN',
        language: 'fr',
        translator: 'VGR',
        durationMinutes: 120,
        pdfUrl: 'https://example.com/63-0317E.pdf',
        audioUrl: 'https://example.com/63-0317E.mp3',
        textContent: demoText1,
        series: ['Âge de l\'Église'],
        description: 'Message sur l\'identification du dieu de cet âge. Ce sermon explore en profondeur la nature spirituelle de notre époque et comment le dieu de ce monde aveugle les esprits de ceux qui ne croient pas.',
        publishedDate: DateTime(1963, 3, 17),
      ),
      // Version SHP
      WBSermon(
        id: '63-0317E-SHP',
        title: 'Le Dieu de cet âge mauvais',
        date: '63-0317E',
        location: 'Jeffersonville, IN',
        language: 'fr',
        translator: 'SHP',
        durationMinutes: 120,
        pdfUrl: 'https://example.com/63-0317E-shp.pdf',
        audioUrl: 'https://example.com/63-0317E-shp.mp3',
        textContent: demoText1,
        series: ['Âge de l\'Église'],
        description: 'Message sur l\'identification du dieu de cet âge. Ce sermon explore en profondeur la nature spirituelle de notre époque et comment le dieu de ce monde aveugle les esprits de ceux qui ne croient pas.',
        publishedDate: DateTime(1963, 3, 17),
      ),
      // Version anglaise VGR
      WBSermon(
        id: '63-0317E-VGR-EN',
        title: 'The God Of This Evil Age',
        date: '63-0317E',
        location: 'Jeffersonville, IN',
        language: 'en',
        translator: 'VGR',
        durationMinutes: 120,
        pdfUrl: 'https://example.com/63-0317E-en.pdf',
        audioUrl: 'https://example.com/63-0317E-en.mp3',
        textContent: demoText1En,
        series: ['Church Age'],
        description: 'Message on identifying the god of this age. This sermon explores in depth the spiritual nature of our time and how the god of this world blinds the minds of those who do not believe.',
        publishedDate: DateTime(1963, 3, 17),
      ),
      // Version VGR
      WBSermon(
        id: '65-1125-VGR',
        title: 'Le Rapport du Réveil',
        date: '65-1125',
        location: 'Shreveport, LA',
        language: 'fr',
        translator: 'VGR',
        durationMinutes: 90,
        pdfUrl: 'https://example.com/65-1125.pdf',
        audioUrl: 'https://example.com/65-1125.mp3',
        textContent: demoText2,
        series: ['Réveil'],
        description: 'Message sur le réveil et la restauration. Dans cette puissante prédication, frère Branham fait le rapport de ce que Dieu a accompli durant les campagnes de réveil.',
        publishedDate: DateTime(1965, 11, 25),
      ),
      // Version anglaise VGR
      WBSermon(
        id: '65-1125-VGR-EN',
        title: 'The Rapture',
        date: '65-1125',
        location: 'Shreveport, LA',
        language: 'en',
        translator: 'VGR',
        durationMinutes: 90,
        pdfUrl: 'https://example.com/65-1125-en.pdf',
        audioUrl: 'https://example.com/65-1125-en.mp3',
        textContent: demoText2En,
        series: ['Revival'],
        description: 'Message on revival and restoration. In this powerful sermon, Brother Branham reports what God has accomplished during revival campaigns.',
        publishedDate: DateTime(1965, 11, 25),
      ),
    ];
  }

  /// Vide le cache
  static Future<void> clearCache() async {
    _cachedSermons = null;
    _lastFetchTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeySermons);
    await prefs.remove(_cacheKeyLastUpdate);
  }
}

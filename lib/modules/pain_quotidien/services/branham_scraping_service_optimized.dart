import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

class BranhamScrapingServiceOptimized {
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';
  static const String _cacheKey = 'daily_bread_cache_optimized';
  static const String _dateKey = 'daily_bread_date_optimized';

  static Future<Map<String, dynamic>> getDailyBread() async {
    try {
      // Vérifier le cache d'abord
      final cached = await _getCachedData();
      if (cached != null) {
        return cached;
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        }
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = _parseHtmlContent(response.body);
        
        // Sauvegarder en cache seulement si on a du contenu valide
        if (data['dailyBread'] != 'Pain quotidien non disponible') {
          await _saveToCache(data);
        }
        
        return data;
      } else {
        throw Exception('Failed to load daily bread: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération du pain quotidien: $e');
      // Retourner les données en cache en cas d'erreur
      final cached = await _getCachedData(forceCache: true);
      if (cached != null) {
        return cached;
      }
      
      // Données par défaut en cas d'échec total
      return {
        'dailyBread': 'Pain quotidien temporairement indisponible',
        'reference': '',
        'citation': 'Verset du jour temporairement indisponible',
        'sermonTitle': '',
        'audioUrl': '',
        'error': true,
      };
    }
  }

  static Map<String, dynamic> _parseHtmlContent(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    
    // Variables pour les données
    String dailyBread = '';
    String reference = '';
    
    // Méthode 1: Chercher dans les éléments HTML spécifiques
    final allElements = [
      ...document.querySelectorAll('div'),
      ...document.querySelectorAll('p'),
      ...document.querySelectorAll('span'),
    ];
    
    for (final element in allElements) {
      final elementText = element.text.trim();
      
      // Chercher la référence biblique (ex: Ésaïe 1.18)
      if (reference.isEmpty) {
        final refMatch = RegExp(r'^([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)$')
            .firstMatch(elementText);
        if (refMatch != null) {
          reference = refMatch.group(1)?.trim() ?? '';
          continue;
        }
      }
      
      // Chercher le texte du verset (phrases bibliques longues)
      if (dailyBread.isEmpty && elementText.length > 50 && elementText.length < 1000) {
        if ((elementText.contains('dit l\'Éternel') || 
             elementText.contains('Dieu') ||
             elementText.contains('Seigneur') ||
             (elementText.contains(';') && elementText.contains(','))) &&
            !elementText.contains('Pain quotidien') &&
            !elementText.contains('Conference') &&
            !elementText.contains('DateTitre')) {
          
          // Nettoyer le texte du verset
          dailyBread = elementText
              .replaceAll(RegExp(r'\s+'), ' ')  // Remplacer multiples espaces
              .replaceAll(RegExp(r'^\s*$reference\s*'), '') // Enlever la référence du début si présente
              .trim();
          continue;
        }
      }
    }
    
    // Si pas trouvé, essayer la méthode texte brut
    if (dailyBread.isEmpty || reference.isEmpty) {
      final bodyText = document.body?.text ?? '';
      
      if (bodyText.contains('Pain quotidien')) {
        final painIndex = bodyText.indexOf('Pain quotidien');
        final painSection = bodyText.substring(painIndex, 
            painIndex + 1000 < bodyText.length ? painIndex + 1000 : bodyText.length);
        
        if (reference.isEmpty) {
          final refMatch = RegExp(r'([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)')
              .firstMatch(painSection);
          if (refMatch != null) {
            reference = refMatch.group(1)?.trim() ?? '';
          }
        }
        
        if (dailyBread.isEmpty && reference.isNotEmpty) {
          final refIndex = painSection.indexOf(reference);
          final afterRef = painSection.substring(refIndex + reference.length);
          final aujourdIndex = afterRef.indexOf('Aujourd\'hui');
          
          if (aujourdIndex != -1) {
            final verseText = afterRef.substring(0, aujourdIndex);
            dailyBread = verseText
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
          }
        }
      }
    }
    
    // Nettoyer le pain quotidien final
    if (dailyBread.isNotEmpty) {
      dailyBread = dailyBread
          .replaceAll(RegExp(r'^\s*$reference\s*'), '') // Enlever référence au début
          .replaceAll(RegExp(r'\s+'), ' ') // Normaliser les espaces
          .trim();
      
      // S'assurer qu'on n'a pas de doublons
      if (dailyBread.startsWith(reference)) {
        dailyBread = dailyBread.substring(reference.length).trim();
      }
    }
    
    // Extraire les informations de prédication
    String sermonTitle = '';
    String audioUrl = '';
    
    final tables = document.querySelectorAll('table');
    for (final table in tables) {
      final rows = table.querySelectorAll('tr');
      if (rows.length > 1) {
        final firstDataRow = rows[1];
        final cells = firstDataRow.querySelectorAll('td');
        if (cells.length >= 2) {
          final dateCell = cells[0].text.trim();
          final titleCell = cells[1].text.trim();
          
          if (RegExp(r'^\d{2}-\d{4}').hasMatch(dateCell)) {
            sermonTitle = '$dateCell $titleCell';
            break;
          }
        }
      }
    }
    
    // Chercher l'URL audio
    final audioLinks = document.querySelectorAll('a[href*=".m4a"]');
    if (audioLinks.isNotEmpty) {
      audioUrl = audioLinks.first.attributes['href'] ?? '';
      if (audioUrl.isNotEmpty && !audioUrl.startsWith('http')) {
        audioUrl = 'https://branham.org$audioUrl';
      }
    }
    
    return {
      'dailyBread': dailyBread.isNotEmpty ? dailyBread : 'Pain quotidien non disponible',
      'reference': reference,
      'citation': dailyBread.isNotEmpty ? dailyBread : 'Verset du jour non disponible',
      'sermonTitle': sermonTitle,
      'audioUrl': audioUrl,
      'error': false,
    };
  }

  static Future<Map<String, dynamic>?> _getCachedData({bool forceCache = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedDate = prefs.getString(_dateKey);
      
      if (cachedData != null && cachedDate != null) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        
        // Retourner les données en cache si c'est du jour ou si on force le cache
        if (forceCache || cachedDate == today) {
          return json.decode(cachedData);
        }
      }
    } catch (e) {
      print('Erreur lors de la lecture du cache: $e');
    }
    return null;
  }

  static Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setString(_dateKey, today);
    } catch (e) {
      print('Erreur lors de la sauvegarde en cache: $e');
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_dateKey);
    } catch (e) {
      print('Erreur lors de la suppression du cache: $e');
    }
  }
}

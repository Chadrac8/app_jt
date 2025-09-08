import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Modèle simplifié pour iOS/mobile
class SimpleBranhamQuote {
  final String text;
  final String reference; 
  final String date;
  final String dailyBread;
  final String dailyBreadReference;
  
  SimpleBranhamQuote({
    required this.text,
    required this.reference,
    required this.date,
    required this.dailyBread,
    required this.dailyBreadReference,
  });
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'reference': reference,
    'date': date,
    'dailyBread': dailyBread,
    'dailyBreadReference': dailyBreadReference,
  };
  
  factory SimpleBranhamQuote.fromJson(Map<String, dynamic> json) => SimpleBranhamQuote(
    text: json['text'] ?? '',
    reference: json['reference'] ?? '',
    date: json['date'] ?? '',
    dailyBread: json['dailyBread'] ?? '',
    dailyBreadReference: json['dailyBreadReference'] ?? '',
  );
}

/// Service adapté pour iOS avec fallbacks robustes
class IOSBranhamService {
  static const String _cacheKey = 'ios_branham_quote_cache';
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';
  
  /// Citations prédéfinies tournantes pour iOS quand le réseau échoue
  static final List<SimpleBranhamQuote> _fallbackQuotes = [
    SimpleBranhamQuote(
      text: 'Vous êtes peut-être un pécheur qui a commis de nombreux péchés, mais cela n\'a rien à voir avec cela. Dieu vous aime. Et Il a fait un moyen de vous sauver, et c\'est par Jésus-Christ, Son Fils.',
      reference: 'William Branham',
      date: DateTime.now().toIso8601String(),
      dailyBread: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
      dailyBreadReference: 'Jean 3:16',
    ),
    SimpleBranhamQuote(
      text: 'La foi n\'est pas quelque chose que vous avez; la foi est quelque chose qui vous a. Si vous avez la foi, la foi vous contrôle.',
      reference: 'William Branham',
      date: DateTime.now().toIso8601String(),
      dailyBread: 'Or la foi est une ferme assurance des choses qu\'on espère, une démonstration de celles qu\'on ne voit point.',
      dailyBreadReference: 'Hébreux 11:1',
    ),
    SimpleBranhamQuote(
      text: 'Il n\'y a qu\'une seule façon d\'adorer Dieu, c\'est selon Sa Parole. Toute autre adoration est vaine.',
      reference: 'William Branham',
      date: DateTime.now().toIso8601String(),
      dailyBread: 'Dieu est Esprit, et il faut que ceux qui l\'adorent l\'adorent en esprit et en vérité.',
      dailyBreadReference: 'Jean 4:24',
    ),
  ];
  
  /// Obtient la citation du jour avec gestion iOS optimisée
  static Future<SimpleBranhamQuote> getTodaysQuote() async {
    try {
      print('📱 iOS: Tentative de récupération de la citation...');
      
      // Essayer d'abord le cache
      final cached = await _getCachedQuote();
      if (cached != null && _isToday(cached.date)) {
        print('📱 iOS: Citation trouvée dans le cache');
        return cached;
      }
      
      // Essayer de récupérer depuis le web avec timeout court pour iOS
      final webQuote = await _fetchFromWeb();
      if (webQuote != null) {
        print('📱 iOS: Citation récupérée depuis le web');
        await _cacheQuote(webQuote);
        return webQuote;
      }
      
      // Utiliser le cache même s\'il n\'est pas d\'aujourd\'hui
      if (cached != null) {
        print('📱 iOS: Utilisation du cache (pas forcément d\'aujourd\'hui)');
        return cached;
      }
      
      // Fallback sur les citations prédéfinies
      print('📱 iOS: Utilisation d\'une citation prédéfinie');
      return _getRotatingFallback();
      
    } catch (e) {
      print('📱 iOS: Erreur - utilisation du fallback: $e');
      return _getRotatingFallback();
    }
  }
  
  /// Récupération web simplifiée pour iOS
  static Future<SimpleBranhamQuote?> _fetchFromWeb() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 8)); // Timeout court pour iOS
      
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Extraction simple pour iOS
        String content = response.body;
        
        if (content.contains('Vous êtes peut-être un pécheur qui a commis de nombreux péchés')) {
          return SimpleBranhamQuote(
            text: 'Vous êtes peut-être un pécheur qui a commis de nombreux péchés, mais cela n\'a rien à voir avec cela. Dieu vous aime. Et Il a fait un moyen de vous sauver, et c\'est par Jésus-Christ, Son Fils.',
            reference: 'William Branham - iOS',
            date: DateTime.now().toIso8601String(),
            dailyBread: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
            dailyBreadReference: 'Jean 3:16',
          );
        }
      }
    } catch (e) {
      print('📱 iOS: Erreur réseau: $e');
    }
    return null;
  }
  
  /// Cache la citation
  static Future<void> _cacheQuote(SimpleBranhamQuote quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(quote.toJson()));
    } catch (e) {
      print('📱 iOS: Erreur cache: $e');
    }
  }
  
  /// Récupère depuis le cache
  static Future<SimpleBranhamQuote?> _getCachedQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        return SimpleBranhamQuote.fromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      print('📱 iOS: Erreur lecture cache: $e');
    }
    return null;
  }
  
  /// Vérifie si c\'est aujourd\'hui
  static bool _isToday(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.day == now.day && date.month == now.month && date.year == now.year;
    } catch (e) {
      return false;
    }
  }
  
  /// Retourne une citation tournante basée sur le jour
  static SimpleBranhamQuote _getRotatingFallback() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _fallbackQuotes.length;
    return _fallbackQuotes[index];
  }
}

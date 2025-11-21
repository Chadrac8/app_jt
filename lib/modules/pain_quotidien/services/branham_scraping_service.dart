import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/encoding_fix_service.dart';

class BranhamQuoteModel {
  final String text;
  final String reference;
  final String date;
  final String dailyBread; // Pain quotidien (verset biblique)
  final String dailyBreadReference; // Référence du verset biblique
  final String sermonTitle; // Titre de la prédication
  final String sermonDate; // Date de la prédication
  final String audioUrl; // URL du fichier audio M4A

  BranhamQuoteModel({
    required this.text,
    required this.reference,
    required this.date,
    required this.dailyBread,
    required this.dailyBreadReference,
    this.sermonTitle = '',
    this.sermonDate = '',
    this.audioUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'reference': reference,
      'date': date,
      'dailyBread': dailyBread,
      'dailyBreadReference': dailyBreadReference,
      'sermonTitle': sermonTitle,
      'sermonDate': sermonDate,
      'audioUrl': audioUrl,
    };
  }

  factory BranhamQuoteModel.fromJson(Map<String, dynamic> json) {
    return BranhamQuoteModel(
      text: json['text'] ?? '',
      reference: json['reference'] ?? '',
      date: json['date'] ?? '',
      dailyBread: json['dailyBread'] ?? '',
      dailyBreadReference: json['dailyBreadReference'] ?? '',
      sermonTitle: json['sermonTitle'] ?? '',
      sermonDate: json['sermonDate'] ?? '',
      audioUrl: json['audioUrl'] ?? '');
  }

  String get shareText {
    return '''
📖 Pain quotidien - $date

VERSET DU JOUR :
$dailyBread
$dailyBreadReference

CITATION DU JOUR :
"$text"
${sermonTitle.isNotEmpty ? '\n$sermonTitle' : ''}
William Marrion Branham

Source : www.branham.org
    ''';
  }
}

class BranhamScrapingService {
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';
  static const String _cacheKey = 'branham_quote_cache_v2';
  static const String _lastUpdateKey = 'branham_last_update_v2';
  
  static BranhamScrapingService? _instance;
  static BranhamScrapingService get instance {
    _instance ??= BranhamScrapingService._();
    return _instance!;
  }
  BranhamScrapingService._();

  /// Récupère la citation du jour
  Future<BranhamQuoteModel?> getQuoteOfTheDay() async {
    try {
      print('🔄 Récupération de la citation du jour...');
      
      // Vérifier d'abord le cache
      final cachedQuote = await _getCachedQuote();
      if (cachedQuote != null && _isToday(cachedQuote.date)) {
        print('✅ Citation trouvée dans le cache');
        return cachedQuote;
      }

      // Essayer de récupérer depuis le web
      final webQuote = await _scrapeQuoteFromWebsite();
      if (webQuote != null) {
        await _cacheQuote(webQuote);
        return webQuote;
      }

      // Fallback sur le cache même s'il n'est pas d'aujourd'hui
      if (cachedQuote != null) {
        print('⚠️ Utilisation du cache (pas d\'aujourd\'hui)');
        return cachedQuote;
      }

      // Fallback sur une citation par défaut
      print('❌ Impossible de récupérer la citation, utilisation du fallback');
      return _getDefaultQuote();

    } catch (e) {
      print('❌ Erreur lors de la récupération de la citation: $e');
      
      // Essayer de récupérer depuis le cache en cas d'erreur
      final cachedQuote = await _getCachedQuote();
      if (cachedQuote != null) {
        return cachedQuote;
      }
      
      return _getDefaultQuote();
    }
  }

  /// Scrape la citation directement depuis le site web
  Future<BranhamQuoteModel?> _scrapeQuoteFromWebsite() async {
    try {
      print('🌐 Tentative de récupération depuis: $_baseUrl');
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ Page récupérée: ${response.body.length} caractères');
        return _parseHtmlContent(response.body);
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Erreur lors du scraping: $e');
      return null;
    }
  }

  /// Fonction pour décoder les entités HTML et nettoyer le texte - Version améliorée
  String _decodeHtmlEntities(String text) {
    return EncodingFixService.fixEncoding(text);
  }

  /// Parse le contenu HTML pour extraire la citation et le verset (distincts!)
  BranhamQuoteModel? _parseHtmlContent(String htmlContent) {
    try {
      List<String> lines = htmlContent.split('\n');
      
      String dailyBread = '';       // VERSET BIBLIQUE uniquement
      String dailyBreadRef = '';    // Référence biblique
      String quoteText = '';        // CITATION BRANHAM uniquement (différente!)
      String sermonTitle = '';
      String sermonCode = '';
      
      print('🔍 Extraction séparée du verset et de la citation...');
      
      for (String line in lines) {
        String trimmedLine = line.trim();
        
        // 1. RÉFÉRENCE BIBLIQUE (span id="scripturereference")
        if (trimmedLine.contains('<span id="scripturereference">')) {
          String cleanRef = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          dailyBreadRef = _decodeHtmlEntities(cleanRef);
          print('📍 Référence biblique extraite: $dailyBreadRef');
        }
        
        // 2. TEXTE BIBLIQUE (span id="scripturetext") - Pain quotidien
        if (trimmedLine.contains('<span id="scripturetext">')) {
          String cleanText = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          dailyBread = _decodeHtmlEntities(cleanText);
          print('📖 Verset biblique extrait: ${dailyBread.substring(0, 50)}...');
        }
        
        // 3. CITATION DE BRANHAM (span id="content") - Différente du verset!
        if (trimmedLine.contains('<span id="content">')) {
          String cleanQuote = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          quoteText = _decodeHtmlEntities(cleanQuote);
          print('💬 Citation Branham extraite: ${quoteText.substring(0, 50)}...');
        }
        
        // 4. TITRE DE PRÉDICATION (span id="summary")
        if (trimmedLine.contains('<span id="summary">')) {
          String cleanTitle = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          sermonTitle = _decodeHtmlEntities(cleanTitle);
          print('🎯 Titre extrait: $sermonTitle');
        }
        
        // 5. CODE DE PRÉDICATION (span id="title")
        if (trimmedLine.contains('<span id="title">')) {
          String cleanCode = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          sermonCode = _decodeHtmlEntities(cleanCode);
          print('🔢 Code extrait: $sermonCode');
        }
      }
      
      // VÉRIFICATION ANTI-DUPLICATION
      if (dailyBread.isNotEmpty && quoteText.isNotEmpty) {
        if (dailyBread == quoteText) {
          print('⚠️ ATTENTION: Verset et citation sont identiques - utilisation des fallbacks');
          quoteText = ''; // Forcer l'utilisation du fallback pour la citation
        } else {
          print('✅ Verset et citation sont différents - extraction réussie');
        }
      }
      
      // FALLBACKS DISTINCTS si extraction incomplète
      if (dailyBread.isEmpty) {
        dailyBread = 'Venez et plaidons! dit l\'Éternel. Si vos péchés sont comme le cramoisi, ils deviendront blancs comme la neige; s\'ils sont rouges comme la pourpre, ils deviendront comme la laine.';
        dailyBreadRef = 'Ésaïe 1.18';
        print('⚠️ Fallback verset biblique utilisé');
      }
      
      if (quoteText.isEmpty) {
        quoteText = 'Vous êtes peut-être un pécheur qui a commis de nombreux péchés. Vous avez peut-être tellement fumé que vous ne pouvez pas fumer une cigarette de plus, mais vous ne pouvez pas arrêter. Vous avez peut-être tellement bu que vous ne pouvez pas boire une goutte de plus, mais vous ne pouvez pas arrêter. Dieu est toujours prêt à venir vous faire entrer en conférence avec Lui.';
        print('⚠️ Fallback citation Branham utilisé');
      }
      
      if (sermonCode.isEmpty) {
        sermonCode = '59-1220M';
      }
      
      if (sermonTitle.isEmpty) {
        sermonTitle = 'Une conférence avec Dieu';
      }
      
      print('\n📊 RÉSUMÉ FINAL (VERSET ≠ CITATION):');
      print('📖 Verset: ${dailyBread.substring(0, 40)}...');
      print('💬 Citation: ${quoteText.substring(0, 40)}...');
      print('🎯 Titre: $sermonTitle');
      print('🔢 Code: $sermonCode');
      
      final now = DateTime.now();
      return BranhamQuoteModel(
        text: quoteText,              // Citation de Branham uniquement
        reference: sermonCode,
        date: now.toIso8601String(),
        dailyBread: dailyBread,       // Verset biblique uniquement  
        dailyBreadReference: dailyBreadRef,
        sermonTitle: '$sermonCode\n$sermonTitle',
        sermonDate: sermonCode,
        audioUrl: '',
      );
      
    } catch (e) {
      print('❌ Erreur lors du parsing HTML: $e');
      return null;
    }
  }

  /// Retourne une citation par défaut avec contenu DISTINCT
  BranhamQuoteModel _getDefaultQuote() {
    final today = DateTime.now().toString().split(' ')[0];
    return BranhamQuoteModel(
      // CITATION DE BRANHAM (distincte du verset)
      text: 'Vous êtes peut-être un pécheur qui a commis de nombreux péchés. Vous avez peut-être tellement fumé que vous ne pouvez pas arrêter. Dieu est toujours prêt à venir vous faire entrer en conférence avec Lui, pour en discuter avec vous.',
      reference: 'William Branham',
      date: today,
      // VERSET BIBLIQUE (distinct de la citation)
      dailyBread: 'Venez et plaidons! dit l\'Éternel. Si vos péchés sont comme le cramoisi, ils deviendront blancs comme la neige; s\'ils sont rouges comme la pourpre, ils deviendront comme la laine.',
      dailyBreadReference: 'Ésaïe 1.18',
      sermonTitle: 'Une conférence avec Dieu',
      sermonDate: '59-1220M',
      audioUrl: '',
    );
  }

  /// Met en cache la citation
  Future<void> _cacheQuote(BranhamQuoteModel quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(quote.toJson());
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Erreur lors de la mise en cache: $e');
    }
  }

  /// Récupère la citation depuis le cache
  Future<BranhamQuoteModel?> _getCachedQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return BranhamQuoteModel.fromJson(json);
      }
    } catch (e) {
      print('❌ Erreur lors de la lecture du cache: $e');
    }
    return null;
  }

  /// Vérifie si la date est aujourd'hui
  bool _isToday(String dateString) {
    try {
      final quoteDate = DateTime.parse(dateString);
      final today = DateTime.now();
      return quoteDate.year == today.year &&
             quoteDate.month == today.month &&
             quoteDate.day == today.day;
    } catch (e) {
      return false;
    }
  }
}

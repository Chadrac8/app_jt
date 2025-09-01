import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Récupère la citation du jour depuis le site Branham.org
  Future<BranhamQuoteModel?> getQuoteOfTheDay() async {
    try {
      // Vérifier le cache d'abord
      final cachedQuote = await _getCachedQuote();
      if (cachedQuote != null && _isToday(cachedQuote.date)) {
        print('📦 Citation récupérée depuis le cache');
        return cachedQuote;
      }

      print('🌐 Récupération de la citation depuis branham.org...');
      
      // Scraper le site web
      final quote = await _scrapeQuoteFromWebsite();
      if (quote != null) {
        await _cacheQuote(quote);
        print('✅ Citation mise à jour depuis le site web');
        return quote;
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
  BranhamQuoteModel? _parseHtmlContent(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      
      // Extraire la citation principale de William Branham (entièrement)
      String quoteText = '';
      String reference = '';
      
      // Méthode 1: Chercher les paragraphes de citation (plus robuste)
      final quoteParagraphs = document.querySelectorAll('p, div.quote, .citation, blockquote');
      for (final element in quoteParagraphs) {
        final text = element.text.trim();
        if (text.isNotEmpty && text.length > 80 && 
            !text.contains('Car le Père') && 
            !text.contains('Pain quotidien') &&
            !text.contains('Aujourd\'hui') &&
            !text.startsWith('Date') &&
            !text.startsWith('Titre') &&
            !text.contains('janvier') &&
            !text.contains('février') &&
            !text.contains('mars') &&
            !text.contains('avril') &&
            !text.contains('mai') &&
            !text.contains('juin') &&
            !text.contains('juillet') &&
            !text.contains('août') &&
            !text.contains('septembre') &&
            !text.contains('octobre') &&
            !text.contains('novembre') &&
            !text.contains('décembre') &&
            !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text)) {
          quoteText = text;
          break;
        }
      }
      
      // Méthode 2: Si pas trouvé, chercher dans tout le contenu texte
      if (quoteText.isEmpty) {
        final allText = document.body?.text ?? '';
        final paragraphs = allText.split('\n\n');
        for (final para in paragraphs) {
          final cleanPara = para.trim();
          if (cleanPara.length > 80 && 
              !cleanPara.contains('Pain quotidien') &&
              !cleanPara.contains('Aujourd\'hui') &&
              !cleanPara.contains('Car le Père') &&
              !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(cleanPara) &&
              !RegExp(r'(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)', caseSensitive: false).hasMatch(cleanPara)) {
            quoteText = cleanPara;
            break;
          }
        }
      }

      // Extraire la référence de la prédication
      final titleElements = document.querySelectorAll('td');
      for (final td in titleElements) {
        final text = td.text.trim();
        if (text.contains('-') && text.length < 100 && 
            (text.contains('19') || text.contains('20'))) {
          reference = text;
          break;
        }
      }

      // Extraire le pain quotidien (verset biblique uniquement)
      String dailyBread = '';
      String dailyBreadRef = '';
      
      // Chercher "Pain quotidien" et le verset qui suit
      final allText = document.body?.text ?? '';
      if (allText.contains('Pain quotidien')) {
        final painIndex = allText.indexOf('Pain quotidien');
        if (painIndex != -1) {
          final afterPain = allText.substring(painIndex + 'Pain quotidien'.length);
          
          // Extraire la référence biblique (ex: Jean 16.27-28)
          final refMatch = RegExp(r'([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)')
              .firstMatch(afterPain);
          if (refMatch != null) {
            dailyBreadRef = refMatch.group(1)?.trim() ?? '';
          }
          
          // Extraire UNIQUEMENT le texte du verset biblique (exclure "Aujourd'hui")
          final lines = afterPain.split('\n');
          final verseLines = <String>[];
          bool foundRef = false;
          
          for (final line in lines) {
            final cleanLine = line.trim();
            if (cleanLine.isEmpty) continue;
            
            // Arrêter dès qu'on voit "Aujourd'hui" car c'est un autre bloc
            if (cleanLine.contains('Aujourd\'hui') || cleanLine.contains('Today')) {
              break;
            }
            
            if (dailyBreadRef.isNotEmpty && cleanLine.contains(dailyBreadRef)) {
              foundRef = true;
              continue;
            }
            
            if (foundRef && cleanLine.isNotEmpty && 
                !cleanLine.contains('Date') &&
                !cleanLine.contains('Titre') &&
                !cleanLine.contains('janvier') &&
                !cleanLine.contains('février') &&
                !cleanLine.contains('mars') &&
                !cleanLine.contains('avril') &&
                !cleanLine.contains('mai') &&
                !cleanLine.contains('juin') &&
                !cleanLine.contains('juillet') &&
                !cleanLine.contains('août') &&
                !cleanLine.contains('septembre') &&
                !cleanLine.contains('octobre') &&
                !cleanLine.contains('novembre') &&
                !cleanLine.contains('décembre') &&
                !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(cleanLine) &&
                !RegExp(r'\d{1,2}\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)', caseSensitive: false).hasMatch(cleanLine) &&
                !RegExp(r'^\d{1,2}[\s,]').hasMatch(cleanLine) &&
                cleanLine.length > 10) { // Éviter les lignes trop courtes qui pourraient être des dates
              verseLines.add(cleanLine);
              // Limiter à 2-3 lignes max pour ne prendre que le verset
              if (verseLines.length >= 2) break;
            }
          }
          
          dailyBread = verseLines.join(' ').trim();
        }
      }

      // Extraire le titre de la prédication et l'URL audio
      String sermonTitle = '';
      String sermonDate = '';
      String audioUrl = '';
      
      // Chercher le titre de la prédication (ex: "64-1221 Pourquoi un berger")
      final audioElements = document.querySelectorAll('audio, [data-audio], .audio-player');
      if (audioElements.isNotEmpty) {
        // Chercher autour du lecteur audio pour le titre
        for (final audioEl in audioElements) {
          final parent = audioEl.parent;
          if (parent != null) {
            final titleText = parent.text;
            // Chercher un pattern comme "64-1221 Titre"
            final titleMatch = RegExp(r'(\d{2}-\d{4})\s+(.+?)(?=\n|\s{2,}|$)')
                .firstMatch(titleText);
            if (titleMatch != null) {
              sermonDate = titleMatch.group(1) ?? '';
              sermonTitle = titleMatch.group(2)?.trim() ?? '';
              break;
            }
          }
        }
      }
      
      // Si pas trouvé avec l'audio, chercher dans le texte général
      if (sermonTitle.isEmpty) {
        final allText = document.body?.text ?? '';
        final titleMatch = RegExp(r'(\d{2}-\d{4})\s+([^\n\r]+?)(?=\n|\r|\s{3,})')
            .firstMatch(allText);
        if (titleMatch != null) {
          sermonDate = titleMatch.group(1) ?? '';
          sermonTitle = titleMatch.group(2)?.trim() ?? '';
        }
      }
      
      // Chercher l'URL audio dans les liens M4A
      final links = document.querySelectorAll('a[href*=".m4a"], a[href*=".mp3"], source[src*=".m4a"], source[src*=".mp3"]');
      for (final link in links) {
        final href = link.attributes['href'] ?? link.attributes['src'] ?? '';
        if (href.isNotEmpty && (href.endsWith('.m4a') || href.endsWith('.mp3'))) {
          // Construire l'URL complète si c'est un chemin relatif
          if (href.startsWith('http')) {
            audioUrl = href;
          } else if (href.startsWith('/')) {
            audioUrl = 'https://branham.org$href';
          } else {
            audioUrl = 'https://branham.org/fr/$href';
          }
          break;
        }
      }
      
      // Chercher aussi dans les tableaux (où sont listés les fichiers audio)
      if (audioUrl.isEmpty) {
        final tables = document.querySelectorAll('table');
        for (final table in tables) {
          final rows = table.querySelectorAll('tr');
          for (final row in rows) {
            final cells = row.querySelectorAll('td');
            if (cells.length >= 4) { // Table avec Date, Titre, Lang, PDF, M4A
              for (final cell in cells) {
                final links = cell.querySelectorAll('a');
                for (final link in links) {
                  final href = link.attributes['href'] ?? '';
                  if (href.contains('.m4a') || href.contains('.mp3')) {
                    if (href.startsWith('http')) {
                      audioUrl = href;
                    } else if (href.startsWith('/')) {
                      audioUrl = 'https://branham.org$href';
                    } else {
                      audioUrl = 'https://branham.org/$href';
                    }
                    break;
                  }
                }
                if (audioUrl.isNotEmpty) break;
              }
              if (audioUrl.isNotEmpty) break;
            }
          }
          if (audioUrl.isNotEmpty) break;
        }
      }

      // Nettoyer et valider les données
      quoteText = _cleanText(quoteText);
      dailyBread = _cleanText(dailyBread);
      sermonTitle = _cleanText(sermonTitle);
      
      // Validation supplémentaire pour le verset biblique
      dailyBread = _validateDailyBread(dailyBread);
      
      if (quoteText.isEmpty) {
        print('❌ Impossible d\'extraire la citation');
        return null;
      }

      final today = DateTime.now().toString().split(' ')[0];
      
      print('🎵 Audio URL trouvée: $audioUrl');
      print('📖 Titre de la prédication: $sermonTitle');
      
      return BranhamQuoteModel(
        text: quoteText,
        reference: reference.isEmpty ? 'William Marrion Branham' : reference,
        date: today,
        dailyBread: dailyBread.isEmpty ? _getDefaultVerse() : dailyBread,
        dailyBreadReference: dailyBreadRef.isEmpty ? 'Jean 3:16' : dailyBreadRef,
        sermonTitle: sermonTitle,
        sermonDate: sermonDate,
        audioUrl: audioUrl);

    } catch (e) {
      print('❌ Erreur lors du parsing HTML: $e');
      return null;
    }
  }

  /// Nettoie le texte extrait
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        // Supprimer les patterns de dates courantes
        .replaceAll(RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'), '')
        .replaceAll(RegExp(r'\d{1,2}\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{2,4}', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\d{1,2}\s+'), '') // Supprimer les numéros en début de ligne
        .replaceAll(RegExp(r'\s+,\s+'), ', ') // Nettoyer les virgules avec espaces multiples
        .trim();
  }

  /// Valide et nettoie spécifiquement le verset biblique
  String _validateDailyBread(String dailyBread) {
    if (dailyBread.isEmpty) return dailyBread;
    
    // Supprimer tout contenu du bloc "Aujourd'hui" et autres parasites
    String cleaned = dailyBread
        .replaceAll(RegExp(r'\b\d{1,2}\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'), '')
        .replaceAll(RegExp(r'\b\d{4}\b'), '') // Années isolées
        .replaceAll(RegExp(r'^\d+[.,]\s*'), '') // Numéros en début avec point/virgule
        .replaceAll(RegExp(r'Aujourd.hui.*'), '') // Supprimer tout à partir d'"Aujourd'hui"
        .replaceAll(RegExp(r'Today.*'), '') // Supprimer tout à partir de "Today"
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Si le verset devient trop court après nettoyage ou contient encore des patterns suspects, utiliser le défaut
    if (cleaned.length < 20 || 
        RegExp(r'\d{1,2}[/-]\d{1,2}').hasMatch(cleaned) ||
        RegExp(r'^\d+\s').hasMatch(cleaned) ||
        cleaned.toLowerCase().contains('aujourd') ||
        cleaned.toLowerCase().contains('today')) {
      return '';
    }
    
    return cleaned;
  }

  /// Verset par défaut si le scraping échoue
  String _getDefaultVerse() {
    return 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.';
  }

  /// Citation par défaut si le scraping échoue complètement
  BranhamQuoteModel _getDefaultQuote() {
    final today = DateTime.now().toString().split(' ')[0];
    return BranhamQuoteModel(
      text: 'La foi est quelque chose que vous avez ; elle n\'est pas quelque chose que vous obtenez.',
      reference: 'La Foi, 1957',
      date: today,
      dailyBread: _getDefaultVerse(),
      dailyBreadReference: 'Jean 3:16',
      sermonTitle: 'La Foi',
      sermonDate: '57-1229',
      audioUrl: '');
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

  /// Force la mise à jour de la citation
  Future<BranhamQuoteModel?> forceUpdate() async {
    try {
      print('🔄 Mise à jour forcée de la citation...');
      final quote = await _scrapeQuoteFromWebsite();
      if (quote != null) {
        await _cacheQuote(quote);
        return quote;
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour forcée: $e');
    }
    return null;
  }
}

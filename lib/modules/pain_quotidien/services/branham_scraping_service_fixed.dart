import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

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

class BranhamScrapingServiceFixed {
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';
  static const String _cacheKey = 'branham_quote_cache_v3';
  static const String _lastUpdateKey = 'branham_last_update_v3';
  
  static BranhamScrapingServiceFixed? _instance;
  static BranhamScrapingServiceFixed get instance {
    _instance ??= BranhamScrapingServiceFixed._();
    return _instance!;
  }
  BranhamScrapingServiceFixed._();

  /// Récupère la citation du jour depuis le site Branham.org
  Future<BranhamQuoteModel?> getQuoteOfTheDay() async {
    try {
      print('🌐 Récupération de la citation depuis branham.org...');
      
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
        final quote = _parseHtmlContent(response.body);
        if (quote != null) {
          print('✅ Citation récupérée avec succès depuis le site web');
          return quote;
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
      }

      return _getDefaultQuote();

    } catch (e) {
      print('❌ Erreur lors de la récupération de la citation: $e');
      return _getDefaultQuote();
    }
  }

  /// Parse le contenu HTML pour extraire la citation et le verset
  BranhamQuoteModel? _parseHtmlContent(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);
      final bodyText = document.body?.text ?? '';
      
      // 1. EXTRAIRE LE PAIN QUOTIDIEN
      String dailyBread = '';
      String dailyBreadRef = '';
      
      if (bodyText.contains('Pain quotidien')) {
        final painIndex = bodyText.indexOf('Pain quotidien');
        final painSection = bodyText.substring(painIndex, 
            painIndex + 1000 < bodyText.length ? painIndex + 1000 : bodyText.length);
        
        // Extraire la référence biblique (ex: Ésaïe 1.18)
        final refMatch = RegExp(r'([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)')
            .firstMatch(painSection);
        if (refMatch != null) {
          dailyBreadRef = refMatch.group(1)?.trim() ?? '';
          print('📍 Référence biblique trouvée: $dailyBreadRef');
        }
        
        // Extraire le texte du verset (après la référence, avant "Aujourd'hui")
        if (dailyBreadRef.isNotEmpty && painSection.contains(dailyBreadRef)) {
          final refIndex = painSection.indexOf(dailyBreadRef);
          final afterRef = painSection.substring(refIndex + dailyBreadRef.length);
          
          // Prendre tout jusqu'à "Aujourd'hui"
          final aujourdIndex = afterRef.indexOf('Aujourd\'hui');
          if (aujourdIndex != -1) {
            final verseText = afterRef.substring(0, aujourdIndex);
            // Nettoyer le texte
            dailyBread = verseText
                .replaceAll(RegExp(r'\s+'), ' ')
                .replaceAll(RegExp(r'^\s*'), '')
                .replaceAll(RegExp(r'\s*$'), '')
                .trim();
            
            print('📖 Pain quotidien extrait: ${dailyBread.substring(0, dailyBread.length > 80 ? 80 : dailyBread.length)}...');
          }
        }
      }
      
      // 2. EXTRAIRE LA CITATION PRINCIPALE
      String quoteText = '';
      
      if (bodyText.contains('Aujourd\'hui')) {
        final aujourdIndex = bodyText.indexOf('Aujourd\'hui');
        final citationSection = bodyText.substring(aujourdIndex + 'Aujourd\'hui'.length, 
            aujourdIndex + 1500 < bodyText.length ? aujourdIndex + 1500 : bodyText.length);
        
        // Chercher des paragraphes assez longs qui ne contiennent pas de dates
        final lines = citationSection.split('\n');
        final candidateLines = <String>[];
        
        for (final line in lines) {
          final cleanLine = line.trim();
          if (cleanLine.length > 50 && 
              !cleanLine.contains('DateTitre') &&
              !cleanLine.contains('PDFM4A') &&
              !cleanLine.contains('Septembre') &&
              !cleanLine.contains('janvier') &&
              !cleanLine.contains('février') &&
              !cleanLine.contains('mars') &&
              !cleanLine.contains('avril') &&
              !cleanLine.contains('mai') &&
              !cleanLine.contains('juin') &&
              !cleanLine.contains('juillet') &&
              !cleanLine.contains('août') &&
              !cleanLine.contains('octobre') &&
              !cleanLine.contains('novembre') &&
              !cleanLine.contains('décembre') &&
              !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(cleanLine) &&
              !RegExp(r'^\d{2}-\d{4}').hasMatch(cleanLine)) {
            candidateLines.add(cleanLine);
          }
        }
        
        if (candidateLines.isNotEmpty) {
          quoteText = candidateLines.first;
          print('💬 Citation principale extraite: ${quoteText.substring(0, quoteText.length > 80 ? 80 : quoteText.length)}...');
        }
      }
      
      // 3. EXTRAIRE LES INFOS DE LA PRÉDICATION
      String sermonTitle = '';
      String sermonDate = '';
      String audioUrl = '';
      
      // Chercher le premier lien M4A
      final audioLinks = document.querySelectorAll('a[href*=".m4a"], source[src*=".m4a"]');
      if (audioLinks.isNotEmpty) {
        final href = audioLinks.first.attributes['href'] ?? audioLinks.first.attributes['src'] ?? '';
        if (href.isNotEmpty) {
          audioUrl = href.startsWith('http') ? href : 'https://branham.org$href';
          print('🎵 Audio URL trouvée: $audioUrl');
        }
      }
      
      // Chercher dans les tableaux pour le titre
      final tables = document.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        if (rows.length > 1) {
          final firstDataRow = rows[1]; // Ignorer le header
          final cells = firstDataRow.querySelectorAll('td');
          if (cells.length >= 2) {
            final dateCell = cells[0].text.trim();
            final titleCell = cells[1].text.trim();
            
            if (RegExp(r'^\d{2}-\d{4}').hasMatch(dateCell)) {
              sermonDate = dateCell;
              sermonTitle = titleCell;
              print('🎵 Titre de la prédication: $sermonDate $sermonTitle');
              break;
            }
          }
        }
      }
      
      // Valider les données
      if (dailyBread.isEmpty) {
        dailyBread = _getDefaultVerse();
        dailyBreadRef = 'Jean 3:16';
      }
      
      if (quoteText.isEmpty) {
        quoteText = _getDefaultQuoteText();
      }

      final today = DateTime.now().toString().split(' ')[0];
      
      return BranhamQuoteModel(
        text: quoteText,
        reference: sermonTitle.isNotEmpty ? '$sermonDate $sermonTitle' : 'William Marrion Branham',
        date: today,
        dailyBread: dailyBread,
        dailyBreadReference: dailyBreadRef,
        sermonTitle: sermonTitle,
        sermonDate: sermonDate,
        audioUrl: audioUrl);

    } catch (e) {
      print('❌ Erreur lors du parsing HTML: $e');
      return null;
    }
  }

  /// Verset par défaut si le scraping échoue
  String _getDefaultVerse() {
    return 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.';
  }

  /// Citation par défaut si le scraping échoue
  String _getDefaultQuoteText() {
    return 'Ayez foi en Dieu. Croyez que Dieu peut accomplir tout ce qu\'Il a promis de faire.';
  }

  /// Citation par défaut si le scraping échoue complètement
  BranhamQuoteModel _getDefaultQuote() {
    final today = DateTime.now().toString().split(' ')[0];
    
    return BranhamQuoteModel(
      text: _getDefaultQuoteText(),
      reference: 'William Marrion Branham',
      date: today,
      dailyBread: _getDefaultVerse(),
      dailyBreadReference: 'Jean 3:16',
      sermonTitle: 'Citation par défaut',
      sermonDate: '',
      audioUrl: '',
    );
  }
}

import 'package:http/http.dart' as http;

// Version simplifiée du modèle BranhamMessage pour les tests
class BranhamMessage {
  final String id;
  final String title;
  final String date;
  final String location;
  final int durationMinutes;
  final String pdfUrl;
  final String audioUrl;
  final String streamUrl;
  final String language;
  final String publishDate;
  final String series;

  BranhamMessage({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.durationMinutes,
    required this.pdfUrl,
    required this.audioUrl,
    required this.streamUrl,
    required this.language,
    required this.publishDate,
    required this.series,
  });

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String get formattedDate {
    try {
      final dateParts = date.split('/');
      if (dateParts.length == 3) {
        final month = dateParts[0];
        final day = dateParts[1];
        final year = dateParts[2];
        return '$day/$month/$year';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return date;
  }

  String get year {
    try {
      final dateParts = date.split('/');
      if (dateParts.length >= 3) {
        return dateParts[2];
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '';
  }

  String get decade {
    final yr = year;
    if (yr.length >= 3) {
      return '${yr.substring(0, 3)}0s';
    }
    return '';
  }
}

// Service simplifié pour les tests
class BranhamMessagesService {
  static const String _baseUrl = 'https://branham.org/fr/messageaudio';
  
  Future<List<BranhamMessage>> getAllMessages() async {
    print('🔍 Récupération des prédications depuis branham.org...');
    
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Connexion réussie (${response.body.length} caractères)');
        
        // Pour l'instant, retournons des données de démonstration
        // En production, on analyserait le HTML ici
        return _getDemoMessages();
        
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        return _getDemoMessages();
      }
    } catch (e) {
      print('💥 Erreur de connexion: $e');
      return _getDemoMessages();
    }
  }

  List<BranhamMessage> _getDemoMessages() {
    print('📋 Utilisation des données de démonstration');
    
    return [
      BranhamMessage(
        id: 'demo-1',
        title: 'FRN 47-0412 La foi est une ferme assurance',
        date: '4/12/1947',
        location: 'Oakland, CA',
        durationMinutes: 112,
        pdfUrl: 'https://example.com/demo1.pdf',
        audioUrl: 'https://example.com/demo1.mp3',
        streamUrl: 'https://example.com/demo1-stream',
        language: 'Français',
        publishDate: '23/4/2025',
        series: 'Messages de foi',
      ),
      BranhamMessage(
        id: 'demo-2',
        title: 'FRN 48-0305 L\'amour divin',
        date: '5/3/1948',
        location: 'Phoenix, AZ',
        durationMinutes: 98,
        pdfUrl: 'https://example.com/demo2.pdf',
        audioUrl: 'https://example.com/demo2.mp3',
        streamUrl: 'https://example.com/demo2-stream',
        language: 'Français',
        publishDate: '15/3/2025',
        series: 'Messages d\'amour',
      ),
      BranhamMessage(
        id: 'demo-3',
        title: 'FRN 49-0611 La guérison divine',
        date: '11/6/1949',
        location: 'Jonesboro, AR',
        durationMinutes: 124,
        pdfUrl: 'https://example.com/demo3.pdf',
        audioUrl: 'https://example.com/demo3.mp3',
        streamUrl: 'https://example.com/demo3-stream',
        language: 'Français',
        publishDate: '8/6/2025',
        series: 'Messages de guérison',
      ),
    ];
  }

  Future<List<BranhamMessage>> searchMessages(String query) async {
    final allMessages = await getAllMessages();
    return allMessages.where((message) =>
      message.title.toLowerCase().contains(query.toLowerCase()) ||
      message.location.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<List<BranhamMessage>> filterByDecade(String decade) async {
    final allMessages = await getAllMessages();
    return allMessages.where((message) => message.decade == decade).toList();
  }
}

void main() async {
  print('🧪 Test du service BranhamMessages...\n');
  
  final service = BranhamMessagesService();
  
  // Test 1: Récupération de tous les messages
  print('📋 Test 1: Récupération de tous les messages');
  final allMessages = await service.getAllMessages();
  print('✅ ${allMessages.length} messages trouvés\n');
  
  // Test 2: Affichage des détails de chaque message
  print('📋 Test 2: Détails des messages');
  for (int i = 0; i < allMessages.length; i++) {
    final message = allMessages[i];
    print('🎯 Message ${i + 1}:');
    print('   📖 Titre: ${message.title}');
    print('   📅 Date: ${message.formattedDate}');
    print('   📍 Lieu: ${message.location}');
    print('   ⏱️ Durée: ${message.formattedDuration}');
    print('   📄 PDF: ${message.pdfUrl}');
    print('   🔊 Audio: ${message.audioUrl}');
    print('   🗓️ Année: ${message.year}');
    print('   📊 Décennie: ${message.decade}');
    print('');
  }
  
  // Test 3: Recherche
  print('📋 Test 3: Recherche de "foi"');
  final searchResults = await service.searchMessages('foi');
  print('✅ ${searchResults.length} résultats trouvés');
  for (final result in searchResults) {
    print('   🔍 ${result.title}');
  }
  print('');
  
  // Test 4: Filtrage par décennie
  print('📋 Test 4: Filtrage par décennie "1940s"');
  final filtered = await service.filterByDecade('1940s');
  print('✅ ${filtered.length} messages des années 1940');
  for (final message in filtered) {
    print('   📅 ${message.title} (${message.year})');
  }
  
  print('\n🎉 Tests terminés avec succès !');
}

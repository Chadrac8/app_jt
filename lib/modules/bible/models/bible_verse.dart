class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String? translation;
  final Map<String, dynamic>? metadata;

  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.translation,
    this.metadata,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? 0,
      verse: json['verse'] ?? 0,
      text: json['text'] ?? '',
      translation: json['translation'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'translation': translation,
      'metadata': metadata,
    };
  }

  BibleVerse copyWith({
    String? book,
    int? chapter,
    int? verse,
    String? text,
    String? translation,
    Map<String, dynamic>? metadata,
  }) {
    return BibleVerse(
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters utiles
  String get reference => '$book $chapter:$verse';
  
  String get shortReference => '${_getBookAbbreviation(book)} $chapter:$verse';
  
  String get fullReference => '$book $chapter:$verse${translation != null ? ' ($translation)' : ''}';
  
  String get displayText => text;
  
  String get searchableText => text.toLowerCase();
  
  bool get isValid => book.isNotEmpty && chapter > 0 && verse > 0 && text.isNotEmpty;

  // Méthodes utiles
  bool contains(String query) {
    final lowercaseQuery = query.toLowerCase();
    return searchableText.contains(lowercaseQuery) ||
        book.toLowerCase().contains(lowercaseQuery) ||
        reference.toLowerCase().contains(lowercaseQuery);
  }

  bool isInRange(String bookName, int startChapter, int endChapter) {
    return book == bookName && chapter >= startChapter && chapter <= endChapter;
  }

  bool isInChapter(String bookName, int chapterNumber) {
    return book == bookName && chapter == chapterNumber;
  }

  bool isExactMatch(String bookName, int chapterNumber, int verseNumber) {
    return book == bookName && chapter == chapterNumber && verse == verseNumber;
  }

  String getFormattedText({
    bool includeReference = false,
    bool includeTranslation = false,
    String separator = ' - ',
  }) {
    String result = text;
    
    if (includeReference) {
      String ref = includeTranslation ? fullReference : reference;
      result = '$result$separator$ref';
    } else if (includeTranslation && translation != null) {
      result = '$result$separator($translation)';
    }
    
    return result;
  }

  List<String> getWords() {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  int getWordCount() {
    return getWords().length;
  }

  String _getBookAbbreviation(String bookName) {
    // Abréviations courantes pour les livres de la Bible
    final abbreviations = {
      'Genèse': 'Gn',
      'Exode': 'Ex',
      'Lévitique': 'Lv',
      'Nombres': 'Nb',
      'Deutéronome': 'Dt',
      'Josué': 'Jos',
      'Juges': 'Jg',
      'Ruth': 'Rt',
      '1 Samuel': '1S',
      '2 Samuel': '2S',
      '1 Rois': '1R',
      '2 Rois': '2R',
      '1 Chroniques': '1Ch',
      '2 Chroniques': '2Ch',
      'Esdras': 'Esd',
      'Néhémie': 'Né',
      'Esther': 'Est',
      'Job': 'Jb',
      'Psaumes': 'Ps',
      'Proverbes': 'Pr',
      'Ecclésiaste': 'Ec',
      'Cantique des Cantiques': 'Ct',
      'Ésaïe': 'Es',
      'Jérémie': 'Jr',
      'Lamentations': 'Lm',
      'Ézéchiel': 'Ez',
      'Daniel': 'Dn',
      'Osée': 'Os',
      'Joël': 'Jl',
      'Amos': 'Am',
      'Abdias': 'Ab',
      'Jonas': 'Jon',
      'Michée': 'Mi',
      'Nahum': 'Na',
      'Habakuk': 'Ha',
      'Sophonie': 'So',
      'Aggée': 'Ag',
      'Zacharie': 'Za',
      'Malachie': 'Ml',
      'Matthieu': 'Mt',
      'Marc': 'Mc',
      'Luc': 'Lc',
      'Jean': 'Jn',
      'Actes': 'Ac',
      'Romains': 'Rm',
      '1 Corinthiens': '1Co',
      '2 Corinthiens': '2Co',
      'Galates': 'Ga',
      'Éphésiens': 'Ep',
      'Philippiens': 'Ph',
      'Colossiens': 'Col',
      '1 Thessaloniciens': '1Th',
      '2 Thessaloniciens': '2Th',
      '1 Timothée': '1Tm',
      '2 Timothée': '2Tm',
      'Tite': 'Tt',
      'Philémon': 'Phm',
      'Hébreux': 'He',
      'Jacques': 'Jc',
      '1 Pierre': '1P',
      '2 Pierre': '2P',
      '1 Jean': '1Jn',
      '2 Jean': '2Jn',
      '3 Jean': '3Jn',
      'Jude': 'Jude',
      'Apocalypse': 'Ap',
    };
    
    return abbreviations[bookName] ?? bookName;
  }

  @override
  String toString() {
    return 'BibleVerse($reference: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleVerse &&
        other.book == book &&
        other.chapter == chapter &&
        other.verse == verse;
  }

  @override
  int get hashCode {
    return book.hashCode ^ chapter.hashCode ^ verse.hashCode;
  }
}

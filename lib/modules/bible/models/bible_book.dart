class BibleBook {
  final String name;
  final String abbreviation;
  final List<List<String>> chapters;
  final String testament; // 'old' ou 'new'
  final int bookNumber;
  final String? description;
  final String category;

  BibleBook({
    required this.name,
    required this.abbreviation,
    required this.chapters,
    required this.testament,
    required this.bookNumber,
    this.description,
    this.category = 'Général',
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((chapter) => List<String>.from(chapter))
          .toList() ?? [],
      testament: json['testament'] ?? 'old',
      bookNumber: json['bookNumber'] ?? 0,
      description: json['description'],
      category: json['category'] ?? 'Général',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'chapters': chapters,
      'testament': testament,
      'bookNumber': bookNumber,
      'description': description,
      'category': category,
    };
  }

  BibleBook copyWith({
    String? name,
    String? abbreviation,
    List<List<String>>? chapters,
    String? testament,
    int? bookNumber,
    String? description,
    String? category,
  }) {
    return BibleBook(
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      chapters: chapters ?? this.chapters,
      testament: testament ?? this.testament,
      bookNumber: bookNumber ?? this.bookNumber,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  // Getters utiles
  int get totalChapters => chapters.length;
  
  int get totalVerses => chapters.fold(0, (sum, chapter) => sum + chapter.length);
  
  bool get isOldTestament => testament == 'old';
  
  bool get isNewTestament => testament == 'new';
  
  String get displayName => name;
  
  String get shortName => abbreviation.isNotEmpty ? abbreviation : name;

  // Méthodes utiles
  List<String>? getChapter(int chapterNumber) {
    if (chapterNumber < 1 || chapterNumber > chapters.length) {
      return null;
    }
    return chapters[chapterNumber - 1];
  }

  String? getVerse(int chapterNumber, int verseNumber) {
    final chapter = getChapter(chapterNumber);
    if (chapter == null || verseNumber < 1 || verseNumber > chapter.length) {
      return null;
    }
    return chapter[verseNumber - 1];
  }

  bool hasChapter(int chapterNumber) {
    return chapterNumber >= 1 && chapterNumber <= chapters.length;
  }

  bool hasVerse(int chapterNumber, int verseNumber) {
    final chapter = getChapter(chapterNumber);
    return chapter != null && verseNumber >= 1 && verseNumber <= chapter.length;
  }

  @override
  String toString() {
    return 'BibleBook(name: $name, chapters: ${chapters.length}, testament: $testament)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BibleBook &&
        other.name == name &&
        other.bookNumber == bookNumber &&
        other.testament == testament;
  }

  @override
  int get hashCode {
    return name.hashCode ^ bookNumber.hashCode ^ testament.hashCode;
  }
}

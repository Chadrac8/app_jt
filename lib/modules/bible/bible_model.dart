/// Modèle pour un verset biblique
class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

/// Modèle pour un livre biblique
class BibleBook {
  final String name;
  final List<List<String>> chapters; // [chapter][verse]

  BibleBook({required this.name, required this.chapters});
}

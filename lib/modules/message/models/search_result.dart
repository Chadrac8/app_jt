/// Modèle représentant un résultat de recherche dans les sermons
class SearchResult {
  final String sermonId;
  final String sermonTitle;
  final String sermonDate;
  final String matchedText;
  final int? pageNumber;
  final double relevanceScore; // Score de pertinence (0-1)
  final String? contextBefore; // Contexte avant le match
  final String? contextAfter; // Contexte après le match

  const SearchResult({
    required this.sermonId,
    required this.sermonTitle,
    required this.sermonDate,
    required this.matchedText,
    this.pageNumber,
    required this.relevanceScore,
    this.contextBefore,
    this.contextAfter,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      sermonId: json['sermonId'] as String,
      sermonTitle: json['sermonTitle'] as String,
      sermonDate: json['sermonDate'] as String,
      matchedText: json['matchedText'] as String,
      pageNumber: json['pageNumber'] as int?,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      contextBefore: json['contextBefore'] as String?,
      contextAfter: json['contextAfter'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sermonId': sermonId,
      'sermonTitle': sermonTitle,
      'sermonDate': sermonDate,
      'matchedText': matchedText,
      'pageNumber': pageNumber,
      'relevanceScore': relevanceScore,
      'contextBefore': contextBefore,
      'contextAfter': contextAfter,
    };
  }

  /// Retourne le contexte complet (avant + match + après)
  String get fullContext {
    final parts = <String>[];
    if (contextBefore != null && contextBefore!.isNotEmpty) {
      parts.add(contextBefore!);
    }
    parts.add(matchedText);
    if (contextAfter != null && contextAfter!.isNotEmpty) {
      parts.add(contextAfter!);
    }
    return parts.join(' ');
  }
}

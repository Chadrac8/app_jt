/// Filtre de recherche pour les sermons
class SearchFilter {
  final String? query;
  final List<String> languages;
  final List<int> years;
  final List<String> series;
  final List<String> tags;
  final bool? hasAudio;
  final bool? hasVideo;
  final bool? hasPdf;
  final bool? hasText;
  final bool? isFavorite;
  final SortOption sortBy;
  final bool sortAscending;

  const SearchFilter({
    this.query,
    this.languages = const [],
    this.years = const [],
    this.series = const [],
    this.tags = const [],
    this.hasAudio,
    this.hasVideo,
    this.hasPdf,
    this.hasText,
    this.isFavorite,
    this.sortBy = SortOption.date,
    this.sortAscending = false,
  });

  SearchFilter copyWith({
    String? query,
    List<String>? languages,
    List<int>? years,
    List<String>? series,
    List<String>? tags,
    bool? hasAudio,
    bool? hasVideo,
    bool? hasPdf,
    bool? hasText,
    bool? isFavorite,
    SortOption? sortBy,
    bool? sortAscending,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      languages: languages ?? this.languages,
      years: years ?? this.years,
      series: series ?? this.series,
      tags: tags ?? this.tags,
      hasAudio: hasAudio ?? this.hasAudio,
      hasVideo: hasVideo ?? this.hasVideo,
      hasPdf: hasPdf ?? this.hasPdf,
      hasText: hasText ?? this.hasText,
      isFavorite: isFavorite ?? this.isFavorite,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters {
    return query != null && query!.isNotEmpty ||
        languages.isNotEmpty ||
        years.isNotEmpty ||
        series.isNotEmpty ||
        tags.isNotEmpty ||
        hasAudio != null ||
        hasVideo != null ||
        hasPdf != null ||
        hasText != null ||
        isFavorite != null;
  }

  /// Compte le nombre de filtres actifs
  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (languages.isNotEmpty) count++;
    if (years.isNotEmpty) count++;
    if (series.isNotEmpty) count++;
    if (tags.isNotEmpty) count++;
    if (hasAudio != null) count++;
    if (hasVideo != null) count++;
    if (hasPdf != null) count++;
    if (hasText != null) count++;
    if (isFavorite != null) count++;
    return count;
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'languages': languages,
      'years': years,
      'series': series,
      'tags': tags,
      'hasAudio': hasAudio,
      'hasVideo': hasVideo,
      'hasPdf': hasPdf,
      'hasText': hasText,
      'isFavorite': isFavorite,
      'sortBy': sortBy.name,
      'sortAscending': sortAscending,
    };
  }

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      query: json['query'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      years: (json['years'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      series: (json['series'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      hasAudio: json['hasAudio'] as bool?,
      hasVideo: json['hasVideo'] as bool?,
      hasPdf: json['hasPdf'] as bool?,
      hasText: json['hasText'] as bool?,
      isFavorite: json['isFavorite'] as bool?,
      sortBy: SortOption.values.firstWhere(
        (e) => e.name == json['sortBy'],
        orElse: () => SortOption.date,
      ),
      sortAscending: json['sortAscending'] as bool? ?? false,
    );
  }
}

/// Options de tri pour les sermons
enum SortOption {
  date,
  title,
  relevance,
  duration,
}

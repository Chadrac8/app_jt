/// Modèle représentant les statistiques d'un sermon
class SermonAnalytics {
  final String sermonId;
  final int viewCount; // Nombre de fois ouvert
  final int totalReadingTimeSeconds; // Temps total de lecture en secondes
  final int lastViewTimestamp; // Timestamp dernière ouverture
  final double progressPercent; // Progression de lecture (0-100)
  final int lastPageRead; // Dernière page lue
  final int totalPages; // Nombre total de pages
  final List<ReadingSession> sessions; // Historique des sessions

  const SermonAnalytics({
    required this.sermonId,
    this.viewCount = 0,
    this.totalReadingTimeSeconds = 0,
    required this.lastViewTimestamp,
    this.progressPercent = 0.0,
    this.lastPageRead = 1,
    this.totalPages = 1,
    this.sessions = const [],
  });

  factory SermonAnalytics.fromJson(Map<String, dynamic> json) {
    return SermonAnalytics(
      sermonId: json['sermonId'] as String,
      viewCount: json['viewCount'] as int? ?? 0,
      totalReadingTimeSeconds: json['totalReadingTimeSeconds'] as int? ?? 0,
      lastViewTimestamp: json['lastViewTimestamp'] as int,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      lastPageRead: json['lastPageRead'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => ReadingSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sermonId': sermonId,
      'viewCount': viewCount,
      'totalReadingTimeSeconds': totalReadingTimeSeconds,
      'lastViewTimestamp': lastViewTimestamp,
      'progressPercent': progressPercent,
      'lastPageRead': lastPageRead,
      'totalPages': totalPages,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  SermonAnalytics copyWith({
    String? sermonId,
    int? viewCount,
    int? totalReadingTimeSeconds,
    int? lastViewTimestamp,
    double? progressPercent,
    int? lastPageRead,
    int? totalPages,
    List<ReadingSession>? sessions,
  }) {
    return SermonAnalytics(
      sermonId: sermonId ?? this.sermonId,
      viewCount: viewCount ?? this.viewCount,
      totalReadingTimeSeconds: totalReadingTimeSeconds ?? this.totalReadingTimeSeconds,
      lastViewTimestamp: lastViewTimestamp ?? this.lastViewTimestamp,
      progressPercent: progressPercent ?? this.progressPercent,
      lastPageRead: lastPageRead ?? this.lastPageRead,
      totalPages: totalPages ?? this.totalPages,
      sessions: sessions ?? this.sessions,
    );
  }

  /// Temps de lecture formaté
  String get formattedReadingTime {
    final duration = Duration(seconds: totalReadingTimeSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Temps moyen par session
  String get averageSessionTime {
    if (sessions.isEmpty) return '0s';
    
    final avgSeconds = totalReadingTimeSeconds ~/ sessions.length;
    final duration = Duration(seconds: avgSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Date de dernière lecture
  DateTime get lastViewDate => DateTime.fromMillisecondsSinceEpoch(lastViewTimestamp);

  /// Est-ce que le sermon a été lu récemment (dans les 7 derniers jours)
  bool get isRecentlyRead {
    final now = DateTime.now();
    final diff = now.difference(lastViewDate);
    return diff.inDays <= 7;
  }

  /// Est-ce que le sermon est complété
  bool get isCompleted => progressPercent >= 100.0;

  /// Sessions des 30 derniers jours
  List<ReadingSession> get recentSessions {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    return sessions.where((session) {
      return session.startDate.isAfter(thirtyDaysAgo);
    }).toList();
  }
}

/// Modèle représentant une session de lecture
class ReadingSession {
  final int startTimestamp;
  final int endTimestamp;
  final int durationSeconds;
  final int pagesRead;
  final int startPage;
  final int endPage;

  const ReadingSession({
    required this.startTimestamp,
    required this.endTimestamp,
    required this.durationSeconds,
    this.pagesRead = 0,
    this.startPage = 1,
    this.endPage = 1,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      startTimestamp: json['startTimestamp'] as int,
      endTimestamp: json['endTimestamp'] as int,
      durationSeconds: json['durationSeconds'] as int,
      pagesRead: json['pagesRead'] as int? ?? 0,
      startPage: json['startPage'] as int? ?? 1,
      endPage: json['endPage'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTimestamp': startTimestamp,
      'endTimestamp': endTimestamp,
      'durationSeconds': durationSeconds,
      'pagesRead': pagesRead,
      'startPage': startPage,
      'endPage': endPage,
    };
  }

  DateTime get startDate => DateTime.fromMillisecondsSinceEpoch(startTimestamp);
  DateTime get endDate => DateTime.fromMillisecondsSinceEpoch(endTimestamp);

  String get formattedDuration {
    final duration = Duration(seconds: durationSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

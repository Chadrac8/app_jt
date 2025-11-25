import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_analytics.dart';

/// Service pour gérer les statistiques de lecture des sermons
class SermonAnalyticsService {
  static const String _analyticsKey = 'wb_sermon_analytics';

  // Cache mémoire
  static Map<String, SermonAnalytics>? _cachedAnalytics;

  /// Récupère toutes les statistiques
  static Future<Map<String, SermonAnalytics>> getAllAnalytics({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAnalytics != null) {
      return _cachedAnalytics!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString(_analyticsKey);

      if (analyticsJson != null) {
        final Map<String, dynamic> jsonMap = json.decode(analyticsJson);
        _cachedAnalytics = jsonMap.map(
          (key, value) => MapEntry(
            key,
            SermonAnalytics.fromJson(value as Map<String, dynamic>),
          ),
        );
        return _cachedAnalytics!;
      }
    } catch (e) {
      debugPrint('Erreur lecture analytics: $e');
    }

    _cachedAnalytics = {};
    return {};
  }

  /// Récupère les statistiques d'un sermon
  static Future<SermonAnalytics?> getAnalytics(String sermonId) async {
    final allAnalytics = await getAllAnalytics();
    return allAnalytics[sermonId];
  }

  /// Crée une nouvelle session de lecture
  static Future<void> startReadingSession(
    String sermonId, {
    int? totalPages,
    int? startPage,
  }) async {
    final allAnalytics = await getAllAnalytics();
    final existing = allAnalytics[sermonId];
    final now = DateTime.now().millisecondsSinceEpoch;

    final updated = (existing ?? SermonAnalytics(
      sermonId: sermonId,
      lastViewTimestamp: now,
      totalPages: totalPages ?? 1,
    )).copyWith(
      viewCount: (existing?.viewCount ?? 0) + 1,
      lastViewTimestamp: now,
      totalPages: totalPages ?? existing?.totalPages,
      lastPageRead: startPage ?? existing?.lastPageRead ?? 1,
    );

    allAnalytics[sermonId] = updated;
    await _saveAnalytics(allAnalytics);
  }

  /// Met à jour la progression de lecture
  static Future<void> updateProgress(
    String sermonId, {
    required int currentPage,
    required int totalPages,
  }) async {
    final allAnalytics = await getAllAnalytics();
    final existing = allAnalytics[sermonId];
    
    if (existing == null) return;

    final progress = (currentPage / totalPages * 100).clamp(0.0, 100.0);

    final updated = existing.copyWith(
      lastPageRead: currentPage,
      totalPages: totalPages,
      progressPercent: progress,
      lastViewTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    allAnalytics[sermonId] = updated;
    await _saveAnalytics(allAnalytics);
  }

  /// Termine une session de lecture
  static Future<void> endReadingSession(
    String sermonId, {
    required int durationSeconds,
    int? startPage,
    int? endPage,
  }) async {
    final allAnalytics = await getAllAnalytics();
    final existing = allAnalytics[sermonId];
    
    if (existing == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final startTimestamp = now - (durationSeconds * 1000);

    final session = ReadingSession(
      startTimestamp: startTimestamp,
      endTimestamp: now,
      durationSeconds: durationSeconds,
      pagesRead: ((endPage ?? existing.lastPageRead) - (startPage ?? existing.lastPageRead)).abs(),
      startPage: startPage ?? existing.lastPageRead,
      endPage: endPage ?? existing.lastPageRead,
    );

    final updatedSessions = [...existing.sessions, session];
    // Garder seulement les 100 dernières sessions pour éviter un stockage trop volumineux
    if (updatedSessions.length > 100) {
      updatedSessions.removeRange(0, updatedSessions.length - 100);
    }

    final updated = existing.copyWith(
      totalReadingTimeSeconds: existing.totalReadingTimeSeconds + durationSeconds,
      sessions: updatedSessions,
      lastViewTimestamp: now,
    );

    allAnalytics[sermonId] = updated;
    await _saveAnalytics(allAnalytics);
  }

  /// Sauvegarde les statistiques
  static Future<void> _saveAnalytics(Map<String, SermonAnalytics> analytics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMap = analytics.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_analyticsKey, json.encode(jsonMap));
      _cachedAnalytics = analytics;
    } catch (e) {
      debugPrint('Erreur sauvegarde analytics: $e');
      rethrow;
    }
  }

  /// Récupère les sermons les plus consultés (top N)
  static Future<List<SermonAnalytics>> getMostViewedSermons({int limit = 10}) async {
    final allAnalytics = await getAllAnalytics();
    final list = allAnalytics.values.toList();
    
    list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    
    return list.take(limit).toList();
  }

  /// Récupère les sermons les plus lus (par temps de lecture)
  static Future<List<SermonAnalytics>> getMostReadSermons({int limit = 10}) async {
    final allAnalytics = await getAllAnalytics();
    final list = allAnalytics.values.toList();
    
    list.sort((a, b) => b.totalReadingTimeSeconds.compareTo(a.totalReadingTimeSeconds));
    
    return list.take(limit).toList();
  }

  /// Récupère les sermons récemment consultés
  static Future<List<SermonAnalytics>> getRecentlyViewedSermons({int limit = 10}) async {
    final allAnalytics = await getAllAnalytics();
    final list = allAnalytics.values.toList();
    
    list.sort((a, b) => b.lastViewTimestamp.compareTo(a.lastViewTimestamp));
    
    return list.take(limit).toList();
  }

  /// Récupère les sermons en cours de lecture (non terminés)
  static Future<List<SermonAnalytics>> getInProgressSermons() async {
    final allAnalytics = await getAllAnalytics();
    
    return allAnalytics.values
        .where((analytics) => 
            analytics.progressPercent > 0 && 
            analytics.progressPercent < 100)
        .toList()
      ..sort((a, b) => b.lastViewTimestamp.compareTo(a.lastViewTimestamp));
  }

  /// Récupère les sermons complétés
  static Future<List<SermonAnalytics>> getCompletedSermons() async {
    final allAnalytics = await getAllAnalytics();
    
    return allAnalytics.values
        .where((analytics) => analytics.progressPercent >= 100)
        .toList()
      ..sort((a, b) => b.lastViewTimestamp.compareTo(a.lastViewTimestamp));
  }

  /// Calcule le temps total de lecture (tous sermons)
  static Future<int> getTotalReadingTimeSeconds() async {
    final allAnalytics = await getAllAnalytics();
    
    return allAnalytics.values.fold<int>(
      0,
      (total, analytics) => total + analytics.totalReadingTimeSeconds,
    );
  }

  /// Compte le nombre total de sermons consultés
  static Future<int> getTotalSermonsViewed() async {
    final allAnalytics = await getAllAnalytics();
    return allAnalytics.length;
  }

  /// Calcule le temps moyen de lecture par sermon
  static Future<String> getAverageReadingTime() async {
    final allAnalytics = await getAllAnalytics();
    
    if (allAnalytics.isEmpty) return '0s';
    
    final totalSeconds = allAnalytics.values.fold(
      0,
      (total, analytics) => total + analytics.totalReadingTimeSeconds,
    );
    
    final avgSeconds = totalSeconds ~/ allAnalytics.length;
    final duration = Duration(seconds: avgSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Récupère les statistiques par période (7, 30 jours)
  static Future<Map<String, dynamic>> getStatsByPeriod(int days) async {
    final allAnalytics = await getAllAnalytics();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

    int sermonsRead = 0;
    int totalReadingTime = 0;
    int totalSessions = 0;

    for (final analytics in allAnalytics.values) {
      // Compter seulement les sermons lus durant la période
      if (analytics.lastViewTimestamp >= cutoffTimestamp) {
        sermonsRead++;
      }

      // Compter les sessions et temps de la période
      for (final session in analytics.sessions) {
        if (session.startTimestamp >= cutoffTimestamp) {
          totalReadingTime += session.durationSeconds;
          totalSessions++;
        }
      }
    }

    return {
      'days': days,
      'sermonsRead': sermonsRead,
      'totalReadingTimeSeconds': totalReadingTime,
      'totalSessions': totalSessions,
      'averageSessionTimeSeconds': totalSessions > 0 ? totalReadingTime ~/ totalSessions : 0,
    };
  }

  /// Exporte toutes les données analytics en JSON
  static Future<String> exportData() async {
    final allAnalytics = await getAllAnalytics();
    final data = {
      'analytics': allAnalytics.map((key, value) => MapEntry(key, value.toJson())),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    return json.encode(data);
  }

  /// Importe des données analytics depuis JSON
  static Future<void> importData(String jsonData) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonData);
      final Map<String, dynamic> analyticsJson = data['analytics'] as Map<String, dynamic>;
      
      final analytics = analyticsJson.map(
        (key, value) => MapEntry(
          key,
          SermonAnalytics.fromJson(value as Map<String, dynamic>),
        ),
      );
      
      await _saveAnalytics(analytics);
    } catch (e) {
      debugPrint('Erreur import analytics: $e');
      rethrow;
    }
  }

  /// Vide toutes les statistiques
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_analyticsKey);
    _cachedAnalytics = {};
  }

  /// Supprime les statistiques d'un sermon spécifique
  static Future<void> deleteSermonAnalytics(String sermonId) async {
    final allAnalytics = await getAllAnalytics();
    allAnalytics.remove(sermonId);
    await _saveAnalytics(allAnalytics);
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sermon_analytics.dart';
import '../services/sermon_analytics_service.dart';

/// Provider pour gérer les statistiques de lecture
class SermonAnalyticsProvider with ChangeNotifier {
  Map<String, SermonAnalytics> _analytics = {};
  bool _isLoading = false;
  String? _error;

  // Session en cours
  String? _currentSermonId;
  DateTime? _sessionStartTime;
  int? _sessionStartPage;
  Timer? _sessionTimer;

  Map<String, SermonAnalytics> get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _currentSermonId != null;
  String? get currentSermonId => _currentSermonId;

  SermonAnalyticsProvider() {
    _loadAnalytics();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    if (_currentSermonId != null) {
      _endSession();
    }
    super.dispose();
  }

  /// Charge toutes les statistiques
  Future<void> _loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await SermonAnalyticsService.getAllAnalytics();
    } catch (e) {
      _error = 'Erreur chargement analytics: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les statistiques
  Future<void> refresh() async {
    await _loadAnalytics();
  }

  /// Récupère les stats d'un sermon
  SermonAnalytics? getSermonAnalytics(String sermonId) {
    return _analytics[sermonId];
  }

  /// Démarre une session de lecture
  Future<void> startReadingSession(
    String sermonId, {
    int? totalPages,
    int? startPage,
  }) async {
    // Terminer la session précédente si elle existe
    if (_currentSermonId != null && _currentSermonId != sermonId) {
      await _endSession();
    }

    _currentSermonId = sermonId;
    _sessionStartTime = DateTime.now();
    _sessionStartPage = startPage ?? 1;

    try {
      await SermonAnalyticsService.startReadingSession(
        sermonId,
        totalPages: totalPages,
        startPage: startPage,
      );
      
      // Recharger les analytics
      _analytics = await SermonAnalyticsService.getAllAnalytics();
      notifyListeners();

      // Timer pour sauvegarder périodiquement (toutes les 30 secondes)
      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _saveSessionProgress(),
      );
    } catch (e) {
      _error = 'Erreur démarrage session: $e';
      debugPrint(_error);
    }
  }

  /// Met à jour la progression
  Future<void> updateProgress({
    required String sermonId,
    required int currentPage,
    required int totalPages,
  }) async {
    try {
      await SermonAnalyticsService.updateProgress(
        sermonId,
        currentPage: currentPage,
        totalPages: totalPages,
      );
      
      // Mettre à jour le cache
      _analytics = await SermonAnalyticsService.getAllAnalytics();
      notifyListeners();
    } catch (e) {
      _error = 'Erreur mise à jour progression: $e';
      debugPrint(_error);
    }
  }

  /// Sauvegarde périodique de la progression
  Future<void> _saveSessionProgress() async {
    if (_currentSermonId == null || _sessionStartTime == null) return;

    final duration = DateTime.now().difference(_sessionStartTime!);
    
    try {
      await SermonAnalyticsService.endReadingSession(
        _currentSermonId!,
        durationSeconds: duration.inSeconds,
        startPage: _sessionStartPage,
        endPage: _analytics[_currentSermonId]?.lastPageRead,
      );
      
      // Redémarrer le timer pour la prochaine période
      _sessionStartTime = DateTime.now();
      
      // Recharger les analytics
      _analytics = await SermonAnalyticsService.getAllAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur sauvegarde session progress: $e');
    }
  }

  /// Termine la session de lecture
  Future<void> endReadingSession({
    int? endPage,
  }) async {
    await _endSession(endPage: endPage);
  }

  Future<void> _endSession({int? endPage}) async {
    if (_currentSermonId == null || _sessionStartTime == null) return;

    _sessionTimer?.cancel();
    _sessionTimer = null;

    final duration = DateTime.now().difference(_sessionStartTime!);

    try {
      await SermonAnalyticsService.endReadingSession(
        _currentSermonId!,
        durationSeconds: duration.inSeconds,
        startPage: _sessionStartPage,
        endPage: endPage ?? _analytics[_currentSermonId]?.lastPageRead,
      );
      
      // Recharger les analytics
      _analytics = await SermonAnalyticsService.getAllAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur fin session: $e');
    } finally {
      _currentSermonId = null;
      _sessionStartTime = null;
      _sessionStartPage = null;
    }
  }

  /// Récupère les sermons les plus consultés
  Future<List<SermonAnalytics>> getMostViewedSermons({int limit = 10}) async {
    return await SermonAnalyticsService.getMostViewedSermons(limit: limit);
  }

  /// Récupère les sermons les plus lus
  Future<List<SermonAnalytics>> getMostReadSermons({int limit = 10}) async {
    return await SermonAnalyticsService.getMostReadSermons(limit: limit);
  }

  /// Récupère les sermons récemment consultés
  Future<List<SermonAnalytics>> getRecentlyViewedSermons({int limit = 10}) async {
    return await SermonAnalyticsService.getRecentlyViewedSermons(limit: limit);
  }

  /// Récupère les sermons en cours
  Future<List<SermonAnalytics>> getInProgressSermons() async {
    return await SermonAnalyticsService.getInProgressSermons();
  }

  /// Récupère les sermons complétés
  Future<List<SermonAnalytics>> getCompletedSermons() async {
    return await SermonAnalyticsService.getCompletedSermons();
  }

  /// Récupère les statistiques globales
  Future<Map<String, dynamic>> getGlobalStats() async {
    final totalTime = await SermonAnalyticsService.getTotalReadingTimeSeconds();
    final totalSermons = await SermonAnalyticsService.getTotalSermonsViewed();
    final avgTime = await SermonAnalyticsService.getAverageReadingTime();
    final stats7Days = await SermonAnalyticsService.getStatsByPeriod(7);
    final stats30Days = await SermonAnalyticsService.getStatsByPeriod(30);

    return {
      'totalReadingTimeSeconds': totalTime,
      'totalSermonsViewed': totalSermons,
      'averageReadingTime': avgTime,
      'last7Days': stats7Days,
      'last30Days': stats30Days,
    };
  }

  /// Exporte les données
  Future<String> exportData() async {
    return await SermonAnalyticsService.exportData();
  }

  /// Importe les données
  Future<void> importData(String jsonData) async {
    await SermonAnalyticsService.importData(jsonData);
    await _loadAnalytics();
  }

  /// Vide toutes les statistiques
  Future<void> clearAll() async {
    await SermonAnalyticsService.clearAll();
    _analytics = {};
    notifyListeners();
  }

  /// Supprime les stats d'un sermon
  Future<void> deleteSermonAnalytics(String sermonId) async {
    await SermonAnalyticsService.deleteSermonAnalytics(sermonId);
    _analytics.remove(sermonId);
    notifyListeners();
  }
}

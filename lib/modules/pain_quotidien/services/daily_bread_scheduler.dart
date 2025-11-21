import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'branham_scraping_service.dart';

/// Service de planification automatique pour le pain quotidien
/// Se déclenche tous les jours à 6h00 pour mettre à jour le contenu
class DailyBreadScheduler {
  static const String _lastUpdateKey = 'daily_bread_last_update';
  static const String _schedulerActiveKey = 'daily_bread_scheduler_active';
  
  static Timer? _dailyTimer;
  static Timer? _minuteCheckTimer;
  static bool _isInitialized = false;

  /// Démarrer le service de planification automatique
  static Future<void> startScheduler() async {
    if (_isInitialized) return;
    
    print('🕰️ Démarrage du planificateur pain quotidien...');
    
    // Vérifier si le scheduler était actif avant
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_schedulerActiveKey, true);
    
    // Vérifier si nous devons faire une mise à jour immédiatement
    await _checkForDailyUpdate();
    
    // Programmer le prochain déclenchement à 6h00
    _scheduleNext6AMUpdate();
    
    // Timer de vérification minutielle pour s'assurer qu'on ne rate pas 6h00
    _startMinuteChecker();
    
    _isInitialized = true;
    print('✅ Planificateur pain quotidien démarré - prochaine mise à jour à 6h00');
  }

  /// Arrêter le service de planification
  static Future<void> stopScheduler() async {
    _dailyTimer?.cancel();
    _minuteCheckTimer?.cancel();
    _dailyTimer = null;
    _minuteCheckTimer = null;
    _isInitialized = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_schedulerActiveKey, false);
    
    print('⏹️ Planificateur pain quotidien arrêté');
  }

  /// Vérifier si le scheduler est actif
  static Future<bool> isSchedulerActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_schedulerActiveKey) ?? false;
  }

  /// Forcer une mise à jour manuelle du pain quotidien
  static Future<void> forceUpdate() async {
    print('🔄 Mise à jour forcée du pain quotidien...');
    await _updateDailyBread();
  }

  /// Calculer le temps jusqu'à 6h00 le lendemain
  static Duration _timeUntil6AM() {
    final now = DateTime.now();
    var next6AM = DateTime(now.year, now.month, now.day, 6, 0, 0);
    
    // Si nous sommes déjà passé 6h00 aujourd'hui, prendre 6h00 demain
    if (now.isAfter(next6AM)) {
      next6AM = next6AM.add(const Duration(days: 1));
    }
    
    final duration = next6AM.difference(now);
    print('⏰ Prochaine mise à jour dans: ${_formatDuration(duration)}');
    return duration;
  }

  /// Programmer le prochain déclenchement à 6h00
  static void _scheduleNext6AMUpdate() {
    _dailyTimer?.cancel();
    
    final timeUntil6AM = _timeUntil6AM();
    
    _dailyTimer = Timer(timeUntil6AM, () async {
      await _updateDailyBread();
      // Programmer la prochaine mise à jour (24h plus tard)
      _scheduleNext6AMUpdate();
    });
  }

  /// Timer de vérification minutielle pour s'assurer qu'on ne rate pas 6h00
  static void _startMinuteChecker() {
    _minuteCheckTimer?.cancel();
    
    _minuteCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final now = DateTime.now();
      
      // Vérifier si nous sommes à 6h00 (±1 minute pour être sûr)
      if (now.hour == 6 && now.minute <= 1) {
        final lastUpdate = await _getLastUpdateDate();
        final today = DateTime.now();
        
        // Vérifier si nous n'avons pas déjà fait la mise à jour aujourd'hui
        if (lastUpdate == null || 
            lastUpdate.day != today.day || 
            lastUpdate.month != today.month || 
            lastUpdate.year != today.year) {
          
          print('🕕 Déclenchement automatique à 6h00 - Mise à jour du pain quotidien');
          await _updateDailyBread();
        }
      }
    });
  }

  /// Vérifier si nous devons faire une mise à jour aujourd'hui
  static Future<void> _checkForDailyUpdate() async {
    final lastUpdate = await _getLastUpdateDate();
    final now = DateTime.now();
    
    if (lastUpdate == null) {
      print('🆕 Première exécution - Mise à jour du pain quotidien');
      await _updateDailyBread();
      return;
    }
    
    // Vérifier si c'est un nouveau jour
    final daysDifference = _daysBetween(lastUpdate, now);
    
    if (daysDifference >= 1) {
      print('📅 Nouveau jour détecté - Mise à jour du pain quotidien');
      await _updateDailyBread();
    } else {
      print('✅ Pain quotidien déjà à jour pour aujourd\'hui');
    }
  }

  /// Effectuer la mise à jour du pain quotidien
  static Future<void> _updateDailyBread() async {
    try {
      print('🍞 Mise à jour du pain quotidien en cours...');
      
      // Récupérer le nouveau contenu depuis branham.org
      final quote = await BranhamScrapingService.instance.getQuoteOfTheDay();
      
      if (quote != null) {
        // Sauvegarder la date de dernière mise à jour
        await _saveLastUpdateDate();
        
        print('✅ Pain quotidien mis à jour avec succès');
        print('📖 Contenu: ${quote.dailyBread.isNotEmpty ? quote.dailyBread.substring(0, min(50, quote.dailyBread.length)) : 'Vide'}...');
        print('📚 Citation: ${quote.text.isNotEmpty ? quote.text.substring(0, min(50, quote.text.length)) : 'Vide'}...');
      } else {
        print('⚠️ Échec de la mise à jour du pain quotidien');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du pain quotidien: $e');
    }
  }

  /// Sauvegarder la date de dernière mise à jour
  static Future<void> _saveLastUpdateDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Récupérer la date de dernière mise à jour
  static Future<DateTime?> _getLastUpdateDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastUpdateKey);
    
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print('⚠️ Erreur parsing date: $e');
        return null;
      }
    }
    
    return null;
  }

  /// Calculer le nombre de jours entre deux dates
  static int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  /// Formater une durée pour l'affichage
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Obtenir les informations de statut du scheduler
  static Future<Map<String, dynamic>> getSchedulerStatus() async {
    final lastUpdate = await _getLastUpdateDate();
    final isActive = await isSchedulerActive();
    final timeUntilNext = _timeUntil6AM();
    
    return {
      'isActive': isActive,
      'isInitialized': _isInitialized,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'timeUntilNext6AM': _formatDuration(timeUntilNext),
      'nextUpdate': DateTime.now().add(timeUntilNext).toIso8601String(),
    };
  }

  /// Méthode de debug pour tester le scheduler
  static Future<void> debugTriggerUpdate() async {
    print('🔧 DEBUG: Déclenchement manuel de la mise à jour');
    await _updateDailyBread();
  }
}
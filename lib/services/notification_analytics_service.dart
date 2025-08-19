import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Modèle pour les analytics de notifications
class NotificationAnalytics {
  final String id;
  final String notificationId;
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? deviceInfo;
  final String? platform;

  NotificationAnalytics({
    String? id,
    required this.notificationId,
    required this.userId,
    required this.action,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    this.deviceInfo,
    this.platform,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now(),
    metadata = metadata ?? {};

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) {
    return NotificationAnalytics(
      id: json['id'],
      notificationId: json['notificationId'],
      userId: json['userId'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      deviceInfo: json['deviceInfo'],
      platform: json['platform'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notificationId': notificationId,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'deviceInfo': deviceInfo,
      'platform': platform,
    };
  }
}

/// Types d'actions trackées
class NotificationActionTypes {
  static const String sent = 'sent';
  static const String delivered = 'delivered';
  static const String opened = 'opened';
  static const String clicked = 'clicked';
  static const String dismissed = 'dismissed';
  static const String actionClicked = 'action_clicked';
  static const String failed = 'failed';
  static const String expired = 'expired';
}

/// Statistiques d'une notification
class NotificationStats {
  final String notificationId;
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalClicked;
  final int totalDismissed;
  final int totalFailed;
  final DateTime firstSentAt;
  final DateTime? lastOpenedAt;
  final Map<String, int> actionCounts;
  final Map<String, int> platformStats;
  final Map<String, int> timeSlotStats;

  const NotificationStats({
    required this.notificationId,
    required this.totalSent,
    required this.totalDelivered,
    required this.totalOpened,
    required this.totalClicked,
    required this.totalDismissed,
    required this.totalFailed,
    required this.firstSentAt,
    this.lastOpenedAt,
    required this.actionCounts,
    required this.platformStats,
    required this.timeSlotStats,
  });

  double get deliveryRate => totalSent > 0 ? (totalDelivered / totalSent) * 100 : 0;
  double get openRate => totalDelivered > 0 ? (totalOpened / totalDelivered) * 100 : 0;
  double get clickRate => totalOpened > 0 ? (totalClicked / totalOpened) * 100 : 0;
  double get engagementRate => totalDelivered > 0 ? ((totalOpened + totalClicked) / totalDelivered) * 100 : 0;

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      notificationId: json['notificationId'],
      totalSent: json['totalSent'],
      totalDelivered: json['totalDelivered'],
      totalOpened: json['totalOpened'],
      totalClicked: json['totalClicked'],
      totalDismissed: json['totalDismissed'],
      totalFailed: json['totalFailed'],
      firstSentAt: DateTime.parse(json['firstSentAt']),
      lastOpenedAt: json['lastOpenedAt'] != null ? DateTime.parse(json['lastOpenedAt']) : null,
      actionCounts: Map<String, int>.from(json['actionCounts']),
      platformStats: Map<String, int>.from(json['platformStats']),
      timeSlotStats: Map<String, int>.from(json['timeSlotStats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'totalSent': totalSent,
      'totalDelivered': totalDelivered,
      'totalOpened': totalOpened,
      'totalClicked': totalClicked,
      'totalDismissed': totalDismissed,
      'totalFailed': totalFailed,
      'firstSentAt': firstSentAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'actionCounts': actionCounts,
      'platformStats': platformStats,
      'timeSlotStats': timeSlotStats,
    };
  }
}

/// Service d'analytics pour les notifications
class NotificationAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enregistrer une action sur une notification
  Future<void> trackAction({
    required String notificationId,
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
    String? deviceInfo,
    String? platform,
  }) async {
    final analytics = NotificationAnalytics(
      notificationId: notificationId,
      userId: userId,
      action: action,
      metadata: metadata,
      deviceInfo: deviceInfo,
      platform: platform,
    );

    // Enregistrer l'événement
    await _firestore
        .collection('notificationAnalytics')
        .doc(analytics.id)
        .set(analytics.toJson());

    // Mettre à jour les statistiques en temps réel
    await _updateNotificationStats(notificationId, action, platform);
  }

  /// Mettre à jour les statistiques d'une notification
  Future<void> _updateNotificationStats(String notificationId, String action, String? platform) async {
    final statsRef = _firestore.collection('notificationStats').doc(notificationId);
    
    await _firestore.runTransaction((transaction) async {
      final statsDoc = await transaction.get(statsRef);
      
      if (statsDoc.exists) {
        final currentStats = statsDoc.data()!;
        final updates = <String, dynamic>{};
        
        // Incrementer le compteur d'action
        switch (action) {
          case NotificationActionTypes.sent:
            updates['totalSent'] = (currentStats['totalSent'] ?? 0) + 1;
            if (currentStats['firstSentAt'] == null) {
              updates['firstSentAt'] = DateTime.now().toIso8601String();
            }
            break;
          case NotificationActionTypes.delivered:
            updates['totalDelivered'] = (currentStats['totalDelivered'] ?? 0) + 1;
            break;
          case NotificationActionTypes.opened:
            updates['totalOpened'] = (currentStats['totalOpened'] ?? 0) + 1;
            updates['lastOpenedAt'] = DateTime.now().toIso8601String();
            break;
          case NotificationActionTypes.clicked:
            updates['totalClicked'] = (currentStats['totalClicked'] ?? 0) + 1;
            break;
          case NotificationActionTypes.dismissed:
            updates['totalDismissed'] = (currentStats['totalDismissed'] ?? 0) + 1;
            break;
          case NotificationActionTypes.failed:
            updates['totalFailed'] = (currentStats['totalFailed'] ?? 0) + 1;
            break;
        }

        // Mettre à jour les stats par plateforme
        if (platform != null) {
          final platformStats = Map<String, int>.from(currentStats['platformStats'] ?? {});
          platformStats[platform] = (platformStats[platform] ?? 0) + 1;
          updates['platformStats'] = platformStats;
        }

        // Mettre à jour les stats par créneaux horaires
        final hour = DateTime.now().hour;
        final timeSlot = _getTimeSlot(hour);
        final timeSlotStats = Map<String, int>.from(currentStats['timeSlotStats'] ?? {});
        timeSlotStats[timeSlot] = (timeSlotStats[timeSlot] ?? 0) + 1;
        updates['timeSlotStats'] = timeSlotStats;

        transaction.update(statsRef, updates);
      } else {
        // Créer de nouvelles statistiques
        final newStats = {
          'notificationId': notificationId,
          'totalSent': action == NotificationActionTypes.sent ? 1 : 0,
          'totalDelivered': action == NotificationActionTypes.delivered ? 1 : 0,
          'totalOpened': action == NotificationActionTypes.opened ? 1 : 0,
          'totalClicked': action == NotificationActionTypes.clicked ? 1 : 0,
          'totalDismissed': action == NotificationActionTypes.dismissed ? 1 : 0,
          'totalFailed': action == NotificationActionTypes.failed ? 1 : 0,
          'firstSentAt': DateTime.now().toIso8601String(),
          'lastOpenedAt': action == NotificationActionTypes.opened ? DateTime.now().toIso8601String() : null,
          'actionCounts': <String, int>{},
          'platformStats': platform != null ? {platform: 1} : <String, int>{},
          'timeSlotStats': {_getTimeSlot(DateTime.now().hour): 1},
        };
        
        transaction.set(statsRef, newStats);
      }
    });
  }

  /// Récupérer les statistiques d'une notification
  Future<NotificationStats?> getNotificationStats(String notificationId) async {
    final doc = await _firestore
        .collection('notificationStats')
        .doc(notificationId)
        .get();
    
    if (doc.exists) {
      return NotificationStats.fromJson(doc.data()!);
    }
    return null;
  }

  /// Récupérer les analytiques globales sur une période
  Future<Map<String, dynamic>> getGlobalAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final query = _firestore
        .collection('notificationAnalytics')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate);

    final snapshot = await query.get();
    final analytics = snapshot.docs
        .map((doc) => NotificationAnalytics.fromJson(doc.data()))
        .toList();

    return _calculateGlobalStats(analytics);
  }

  /// Récupérer les top notifications par engagement
  Future<List<Map<String, dynamic>>> getTopNotificationsByEngagement({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final statsSnapshot = await _firestore
        .collection('notificationStats')
        .where('firstSentAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('firstSentAt', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    final statsWithEngagement = statsSnapshot.docs
        .map((doc) {
          final stats = NotificationStats.fromJson(doc.data());
          return {
            'stats': stats,
            'engagementRate': stats.engagementRate,
          };
        })
        .toList();

    statsWithEngagement.sort((a, b) => 
        (b['engagementRate'] as double).compareTo(a['engagementRate'] as double));

    return statsWithEngagement.take(limit).toList();
  }

  /// Récupérer les analytics par utilisateur
  Future<Map<String, dynamic>> getUserAnalytics(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final snapshot = await _firestore
        .collection('notificationAnalytics')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .get();

    final userAnalytics = snapshot.docs
        .map((doc) => NotificationAnalytics.fromJson(doc.data()))
        .toList();

    return _calculateUserStats(userAnalytics);
  }

  /// Calculer les statistiques globales
  Map<String, dynamic> _calculateGlobalStats(List<NotificationAnalytics> analytics) {
    final stats = <String, int>{};
    final platformStats = <String, int>{};
    final timeSlotStats = <String, int>{};
    final dailyStats = <String, int>{};

    for (final analytic in analytics) {
      // Compter les actions
      stats[analytic.action] = (stats[analytic.action] ?? 0) + 1;

      // Compter par plateforme
      if (analytic.platform != null) {
        platformStats[analytic.platform!] = (platformStats[analytic.platform!] ?? 0) + 1;
      }

      // Compter par créneaux horaires
      final timeSlot = _getTimeSlot(analytic.timestamp.hour);
      timeSlotStats[timeSlot] = (timeSlotStats[timeSlot] ?? 0) + 1;

      // Compter par jour
      final day = analytic.timestamp.toIso8601String().split('T')[0];
      dailyStats[day] = (dailyStats[day] ?? 0) + 1;
    }

    final totalSent = stats[NotificationActionTypes.sent] ?? 0;
    final totalDelivered = stats[NotificationActionTypes.delivered] ?? 0;
    final totalOpened = stats[NotificationActionTypes.opened] ?? 0;
    final totalClicked = stats[NotificationActionTypes.clicked] ?? 0;

    return {
      'totalNotifications': analytics.length,
      'actionStats': stats,
      'platformStats': platformStats,
      'timeSlotStats': timeSlotStats,
      'dailyStats': dailyStats,
      'deliveryRate': totalSent > 0 ? (totalDelivered / totalSent) * 100 : 0,
      'openRate': totalDelivered > 0 ? (totalOpened / totalDelivered) * 100 : 0,
      'clickRate': totalOpened > 0 ? (totalClicked / totalOpened) * 100 : 0,
      'engagementRate': totalDelivered > 0 ? ((totalOpened + totalClicked) / totalDelivered) * 100 : 0,
    };
  }

  /// Calculer les statistiques utilisateur
  Map<String, dynamic> _calculateUserStats(List<NotificationAnalytics> analytics) {
    final actionCounts = <String, int>{};
    final lastActions = <String, DateTime>{};

    for (final analytic in analytics) {
      actionCounts[analytic.action] = (actionCounts[analytic.action] ?? 0) + 1;
      
      if (lastActions[analytic.action] == null || 
          analytic.timestamp.isAfter(lastActions[analytic.action]!)) {
        lastActions[analytic.action] = analytic.timestamp;
      }
    }

    return {
      'totalInteractions': analytics.length,
      'actionCounts': actionCounts,
      'lastActions': lastActions.map((key, value) => MapEntry(key, value.toIso8601String())),
      'mostActiveHour': _getMostActiveHour(analytics),
      'engagementScore': _calculateEngagementScore(actionCounts),
    };
  }

  /// Déterminer le créneau horaire
  String _getTimeSlot(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  /// Trouver l'heure la plus active
  int _getMostActiveHour(List<NotificationAnalytics> analytics) {
    final hourCounts = <int, int>{};
    
    for (final analytic in analytics) {
      final hour = analytic.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return 12;

    return hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculer le score d'engagement
  double _calculateEngagementScore(Map<String, int> actionCounts) {
    final opened = actionCounts[NotificationActionTypes.opened] ?? 0;
    final clicked = actionCounts[NotificationActionTypes.clicked] ?? 0;
    final dismissed = actionCounts[NotificationActionTypes.dismissed] ?? 0;
    
    // Score basé sur les interactions positives vs négatives
    final positiveActions = opened + (clicked * 2); // Cliquer vaut 2x plus qu'ouvrir
    final negativeActions = dismissed;
    
    if (positiveActions + negativeActions == 0) return 0;
    
    return (positiveActions / (positiveActions + negativeActions)) * 100;
  }

  /// Exporter les analytics en CSV
  Future<String> exportAnalyticsToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final snapshot = await _firestore
        .collection('notificationAnalytics')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .orderBy('timestamp', descending: true)
        .get();

    final analytics = snapshot.docs
        .map((doc) => NotificationAnalytics.fromJson(doc.data()))
        .toList();

    // Générer le CSV
    final csvLines = <String>[];
    csvLines.add('ID,NotificationID,UserID,Action,Timestamp,Platform,DeviceInfo');

    for (final analytic in analytics) {
      csvLines.add([
        analytic.id,
        analytic.notificationId,
        analytic.userId,
        analytic.action,
        analytic.timestamp.toIso8601String(),
        analytic.platform ?? '',
        analytic.deviceInfo ?? '',
      ].join(','));
    }

    return csvLines.join('\n');
  }
}

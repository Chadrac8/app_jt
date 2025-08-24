import 'package:cloud_firestore/cloud_firestore.dart';

class LiveReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Vérifier s'il y a un live programmé
  static Future<Map<String, dynamic>?> checkUpcomingLive() async {
    try {
      final homeConfigDoc = await _firestore
          .collection('home_config')
          .doc('main_config')
          .get();

      if (homeConfigDoc.exists) {
        final data = homeConfigDoc.data()!;
        final liveDateTime = data['liveDateTime'] as Timestamp?;
        final isLiveActive = data['isLiveActive'] as bool? ?? false;
        final liveUrl = data['liveUrl'] as String?;

        if (isLiveActive && liveDateTime != null) {
          final liveDate = liveDateTime.toDate();
          final now = DateTime.now();
          
          return {
            'isUpcoming': now.isBefore(liveDate),
            'isLive': now.isAfter(liveDate) && now.difference(liveDate).inHours < 3,
            'liveDateTime': liveDate,
            'liveUrl': liveUrl,
            'timeDifference': liveDate.difference(now),
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Erreur lors de la vérification du live: $e');
      return null;
    }
  }

  /// Stream pour surveiller les changements de live
  static Stream<Map<String, dynamic>?> getLiveStatusStream() {
    return _firestore
        .collection('home_config')
        .doc('main_config')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final liveDateTime = data['liveDateTime'] as Timestamp?;
        final isLiveActive = data['isLiveActive'] as bool? ?? false;
        final liveUrl = data['liveUrl'] as String?;

        if (isLiveActive && liveDateTime != null) {
          final liveDate = liveDateTime.toDate();
          final now = DateTime.now();
          
          return {
            'isUpcoming': now.isBefore(liveDate),
            'isLive': now.isAfter(liveDate) && now.difference(liveDate).inHours < 3,
            'liveDateTime': liveDate,
            'liveUrl': liveUrl,
            'timeDifference': liveDate.difference(now),
          };
        }
      }
      
      return null;
    });
  }

  /// Formater le temps restant avant le live
  static String formatTimeUntilLive(Duration duration) {
    if (duration.isNegative) return 'En cours';
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}j ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Vérifier si c'est l'heure du live (à 1 minute près)
  static bool isLiveTime(DateTime liveDateTime) {
    final now = DateTime.now();
    final difference = now.difference(liveDateTime).abs();
    return difference.inMinutes <= 1;
  }

  /// Obtenir la couleur selon le statut du live
  static String getLiveStatusColor(Map<String, dynamic> liveStatus) {
    if (liveStatus['isLive'] == true) {
      return '#FF4444'; // Rouge pour live en cours
    } else if (liveStatus['isUpcoming'] == true) {
      final duration = liveStatus['timeDifference'] as Duration;
      if (duration.inMinutes <= 30) {
        return '#FF8800'; // Orange pour bientôt
      } else {
        return '#4CAF50'; // Vert pour programmé
      }
    }
    return '#757575'; // Gris par défaut
  }
}

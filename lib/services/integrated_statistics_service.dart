import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

/// Service de statistiques intégrées Services + Événements
class IntegratedStatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les statistiques combinées services + événements
  static Future<Map<String, dynamic>> getCombinedStatistics() async {
    try {
      print('📊 Récupération statistiques intégrées...');
      
      // Récupérer statistiques des services
      final serviceStats = await _getServiceStatistics();
      
      // Récupérer statistiques des événements-services uniquement
      final serviceEvents = await _getServiceEvents();
      final eventStats = await _calculateEventStatistics(serviceEvents);
      
      final combined = {
        // Statistiques services
        'totalServices': serviceStats['total'] ?? 0,
        'upcomingServices': serviceStats['upcoming'] ?? 0,
        'pastServices': serviceStats['past'] ?? 0,
        'publishedServices': serviceStats['published'] ?? 0,
        'draftServices': serviceStats['draft'] ?? 0,
        'cancelledServices': serviceStats['cancelled'] ?? 0,
        
        // Statistiques événements-services
        'totalParticipants': eventStats['totalRegistrations'] ?? 0,
        'averageAttendance': eventStats['averageAttendance'] ?? 0.0,
        'totalConfirmed': eventStats['totalConfirmed'] ?? 0,
        'totalWaiting': eventStats['totalWaiting'] ?? 0,
        
        // Types de services
        'servicesByType': serviceStats['byType'] ?? {},
        'mostPopularServiceType': serviceStats['mostPopularType'] ?? 'Culte',
        
        // Récurrence
        'recurringServicesCount': serviceStats['recurring'] ?? 0,
        'oneTimeServicesCount': serviceStats['oneTime'] ?? 0,
        
        // Taux de participation
        'participationRate': _calculateParticipationRate(
          serviceStats['upcoming'] ?? 0,
          eventStats['totalConfirmed'] ?? 0,
        ),
        
        // Tendances
        'thisMonthServices': serviceStats['thisMonth'] ?? 0,
        'lastMonthServices': serviceStats['lastMonth'] ?? 0,
        'growthRate': _calculateGrowthRate(
          serviceStats['lastMonth'] ?? 0,
          serviceStats['thisMonth'] ?? 0,
        ),
      };
      
      print('✅ Statistiques calculées: ${combined['totalServices']} services, ${combined['totalParticipants']} participants');
      return combined;
    } catch (e) {
      print('❌ Erreur statistiques intégrées: $e');
      return {};
    }
  }
  
  /// Récupère les statistiques des services
  static Future<Map<String, dynamic>> _getServiceStatistics() async {
    try {
      final now = DateTime.now();
      final firstDayThisMonth = DateTime(now.year, now.month, 1);
      final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
      final lastDayLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
      
      // Récupérer tous les services
      final allServices = await _firestore.collection('services').get();
      
      int total = allServices.docs.length;
      int upcoming = 0;
      int past = 0;
      int published = 0;
      int draft = 0;
      int cancelled = 0;
      int recurring = 0;
      int oneTime = 0;
      int thisMonth = 0;
      int lastMonth = 0;
      
      Map<String, int> byType = {};
      
      for (final doc in allServices.docs) {
        final data = doc.data();
        final dateTime = (data['dateTime'] as Timestamp).toDate();
        final status = data['status'] as String?;
        final type = data['type'] as String?;
        final isRecurring = data['isRecurring'] as bool? ?? false;
        
        // Compter par date
        if (dateTime.isAfter(now)) {
          upcoming++;
        } else {
          past++;
        }
        
        // Compter par statut
        if (status == 'publie') published++;
        if (status == 'brouillon') draft++;
        if (status == 'annule') cancelled++;
        
        // Compter par récurrence
        if (isRecurring) {
          recurring++;
        } else {
          oneTime++;
        }
        
        // Compter par type
        if (type != null) {
          byType[type] = (byType[type] ?? 0) + 1;
        }
        
        // Compter par mois
        if (dateTime.isAfter(firstDayThisMonth)) {
          thisMonth++;
        } else if (dateTime.isAfter(firstDayLastMonth) && dateTime.isBefore(lastDayLastMonth)) {
          lastMonth++;
        }
      }
      
      // Trouver le type le plus populaire
      String? mostPopularType;
      int maxCount = 0;
      byType.forEach((type, count) {
        if (count > maxCount) {
          maxCount = count;
          mostPopularType = type;
        }
      });
      
      return {
        'total': total,
        'upcoming': upcoming,
        'past': past,
        'published': published,
        'draft': draft,
        'cancelled': cancelled,
        'recurring': recurring,
        'oneTime': oneTime,
        'byType': byType,
        'mostPopularType': mostPopularType ?? 'culte',
        'thisMonth': thisMonth,
        'lastMonth': lastMonth,
      };
    } catch (e) {
      print('❌ Erreur statistiques services: $e');
      return {};
    }
  }
  
  /// Récupère tous les événements liés à des services
  static Future<List<EventModel>> _getServiceEvents() async {
    try {
      final query = await _firestore
          .collection('events')
          .where('isServiceEvent', isEqualTo: true)
          .get();
      
      return query.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération événements-services: $e');
      return [];
    }
  }
  
  /// Calcule les statistiques des événements-services
  static Future<Map<String, dynamic>> _calculateEventStatistics(List<EventModel> events) async {
    try {
      int totalRegistrations = 0;
      int totalConfirmed = 0;
      int totalWaiting = 0;
      int eventsWithRegistrations = 0;
      
      for (final event in events) {
        // Récupérer les inscriptions pour cet événement
        final registrations = await _firestore
            .collection('event_registrations')
            .where('eventId', isEqualTo: event.id)
            .get();
        
        if (registrations.docs.isNotEmpty) {
          eventsWithRegistrations++;
          
          for (final reg in registrations.docs) {
            final status = reg.data()['status'] as String?;
            totalRegistrations++;
            
            if (status == 'confirmed') {
              totalConfirmed++;
            } else if (status == 'waiting') {
              totalWaiting++;
            }
          }
        }
      }
      
      // Calculer la moyenne de participation
      double averageAttendance = eventsWithRegistrations > 0
          ? totalConfirmed / eventsWithRegistrations
          : 0.0;
      
      return {
        'totalRegistrations': totalRegistrations,
        'totalConfirmed': totalConfirmed,
        'totalWaiting': totalWaiting,
        'averageAttendance': averageAttendance,
        'eventsWithRegistrations': eventsWithRegistrations,
      };
    } catch (e) {
      print('❌ Erreur calcul statistiques événements: $e');
      return {
        'totalRegistrations': 0,
        'totalConfirmed': 0,
        'totalWaiting': 0,
        'averageAttendance': 0.0,
      };
    }
  }
  
  /// Calcule le taux de participation
  static double _calculateParticipationRate(int upcomingServices, int totalConfirmed) {
    if (upcomingServices == 0) return 0.0;
    return (totalConfirmed / upcomingServices) * 100;
  }
  
  /// Calcule le taux de croissance
  static double _calculateGrowthRate(int lastMonth, int thisMonth) {
    if (lastMonth == 0) return thisMonth > 0 ? 100.0 : 0.0;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }
  
  /// Récupère les statistiques par période
  static Future<Map<String, dynamic>> getStatisticsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('📊 Statistiques période: ${startDate.toIso8601String()} → ${endDate.toIso8601String()}');
      
      final servicesQuery = await _firestore
          .collection('services')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      final totalServices = servicesQuery.docs.length;
      
      // Récupérer les événements-services de cette période
      final eventsQuery = await _firestore
          .collection('events')
          .where('isServiceEvent', isEqualTo: true)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      int totalParticipants = 0;
      for (final eventDoc in eventsQuery.docs) {
        final registrations = await _firestore
            .collection('event_registrations')
            .where('eventId', isEqualTo: eventDoc.id)
            .where('status', isEqualTo: 'confirmed')
            .get();
        
        totalParticipants += registrations.docs.length;
      }
      
      return {
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'totalServices': totalServices,
        'totalParticipants': totalParticipants,
        'averageParticipantsPerService': totalServices > 0 
            ? totalParticipants / totalServices 
            : 0.0,
      };
    } catch (e) {
      print('❌ Erreur statistiques par période: $e');
      return {};
    }
  }
}

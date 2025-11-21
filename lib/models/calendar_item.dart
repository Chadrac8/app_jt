// Modèle unifié pour les éléments du calendrier (Services + Événements)
import '../models/service_model.dart';
import '../models/event_model.dart';

class CalendarItem {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final String location;
  final String type; // 'service', 'event', 'occurrence'
  final String status;
  final String? color;
  final String? icon;
  
  // Source des données
  final ServiceModel? sourceService;
  final EventModel? sourceEvent;
  EventModel? linkedEvent; // Événement lié au service
  
  // Indicateurs spéciaux
  final bool isRecurring;
  final bool isOccurrence;
  final bool isModified;
  final String? seriesId;
  final int? occurrenceIndex;

  CalendarItem({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.endDateTime,
    required this.location,
    required this.type,
    required this.status,
    this.color,
    this.icon,
    this.sourceService,
    this.sourceEvent,
    this.linkedEvent,
    this.isRecurring = false,
    this.isOccurrence = false,
    this.isModified = false,
    this.seriesId,
    this.occurrenceIndex,
  });

  // Factory depuis ServiceModel
  factory CalendarItem.fromService(ServiceModel service) {
    return CalendarItem(
      id: service.id,
      title: service.name,
      description: service.description,
      dateTime: service.dateTime,
      endDateTime: service.dateTime.add(Duration(minutes: service.durationMinutes)),
      location: service.location,
      type: 'service',
      status: service.status,
      color: _getServiceColor(service.status),
      icon: _getServiceIcon(service.type),
      sourceService: service,
      isRecurring: service.isRecurring,
      isOccurrence: !service.isSeriesMaster && service.seriesId != null,
      isModified: service.isModifiedOccurrence,
      seriesId: service.seriesId,
      occurrenceIndex: service.occurrenceIndex,
    );
  }

  // Factory depuis EventModel
  factory CalendarItem.fromEvent(EventModel event) {
    return CalendarItem(
      id: event.id,
      title: event.title,
      description: event.description,
      dateTime: event.startDate,
      endDateTime: event.endDate,
      location: event.location,
      type: 'event',
      status: event.status,
      color: _getEventColor(event.type),
      icon: _getEventIcon(event.type),
      sourceEvent: event,
      isRecurring: event.isRecurring,
      isOccurrence: !event.isSeriesMaster && event.seriesId != null,
      isModified: event.isModifiedOccurrence,
      seriesId: event.seriesId,
      occurrenceIndex: event.occurrenceIndex,
    );
  }

  // Méthodes utilitaires pour les couleurs et icônes
  static String _getServiceColor(String status) {
    switch (status) {
      case 'publie': return '#10B981'; // Vert
      case 'brouillon': return '#F59E0B'; // Orange
      case 'archive': return '#6B7280'; // Gris
      case 'annule': return '#EF4444'; // Rouge
      default: return '#3B82F6'; // Bleu
    }
  }

  static String _getEventColor(String type) {
    switch (type) {
      case 'celebration': return '#A855F7'; // Violet
      case 'formation': return '#3B82F6'; // Bleu
      case 'reunion': return '#F59E0B'; // Orange
      case 'sortie': return '#10B981'; // Vert
      case 'bapteme': return '#06B6D4'; // Cyan
      case 'conference': return '#6366F1'; // Indigo
      default: return '#6B7280'; // Gris
    }
  }

  static String _getServiceIcon(String type) {
    switch (type) {
      case 'culte': return 'church';
      case 'repetition': return 'music_note';
      case 'evenement_special': return 'celebration';
      case 'reunion': return 'meeting_room';
      default: return 'event';
    }
  }

  static String _getEventIcon(String type) {
    switch (type) {
      case 'celebration': return 'celebration';
      case 'formation': return 'school';
      case 'reunion': return 'meeting_room';
      case 'sortie': return 'directions_walk';
      case 'bapteme': return 'water_drop';
      case 'conference': return 'record_voice_over';
      default: return 'event';
    }
  }

  // Méthodes utilitaires
  bool get hasLinkedEvent => linkedEvent != null;
  
  String get displayType {
    if (isOccurrence) return 'Occurrence ${occurrenceIndex! + 1}';
    if (isRecurring) return 'Série récurrente';
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }

  String get statusDisplayText {
    switch (status) {
      case 'publie': return 'Publié';
      case 'brouillon': return 'Brouillon';
      case 'archive': return 'Archivé';
      case 'annule': return 'Annulé';
      case 'active': return 'Actif';
      default: return status;
    }
  }

  Duration get duration {
    if (endDateTime != null) {
      return endDateTime!.difference(dateTime);
    }
    // Durée par défaut selon le type
    switch (type) {
      case 'service': return const Duration(minutes: 90);
      case 'event': return const Duration(hours: 2);
      default: return const Duration(hours: 1);
    }
  }

  // Méthodes de comparaison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CalendarItem(id: $id, title: $title, type: $type, dateTime: $dateTime)';
  }
}
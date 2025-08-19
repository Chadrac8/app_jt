import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final String type; // 'music', 'tech', 'welcome', 'children', 'youth', etc.
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final List<String> requiredRoles;
  final List<String> assignedVolunteers;
  final int maxVolunteers;
  final bool isRecurring;
  final String? recurrencePattern; // 'weekly', 'monthly', etc.
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'draft', 'published', 'completed', 'cancelled'
  final String? notes;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.location,
    required this.requiredRoles,
    required this.assignedVolunteers,
    required this.maxVolunteers,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'draft',
    this.notes,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      location: data['location'] ?? '',
      requiredRoles: List<String>.from(data['requiredRoles'] ?? []),
      assignedVolunteers: List<String>.from(data['assignedVolunteers'] ?? []),
      maxVolunteers: data['maxVolunteers'] ?? 0,
      isRecurring: data['isRecurring'] ?? false,
      recurrencePattern: data['recurrencePattern'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'draft',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'requiredRoles': requiredRoles,
      'assignedVolunteers': assignedVolunteers,
      'maxVolunteers': maxVolunteers,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
      'notes': notes,
    };
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    List<String>? requiredRoles,
    List<String>? assignedVolunteers,
    int? maxVolunteers,
    bool? isRecurring,
    String? recurrencePattern,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? notes,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      requiredRoles: requiredRoles ?? this.requiredRoles,
      assignedVolunteers: assignedVolunteers ?? this.assignedVolunteers,
      maxVolunteers: maxVolunteers ?? this.maxVolunteers,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  bool get hasAvailableSlots {
    return assignedVolunteers.length < maxVolunteers;
  }

  int get availableSlots {
    return maxVolunteers - assignedVolunteers.length;
  }

  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
           startDate.month == now.month &&
           startDate.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return startDate.isAfter(weekStart) && startDate.isBefore(weekEnd);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'completed'
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String> assigneeIds;
  final List<String> tags;
  final String? category;
  final bool isPublic;
  final int? estimatedHours;
  final String? location;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.assigneeIds,
    required this.tags,
    this.category,
    this.isPublic = true,
    this.estimatedHours,
    this.location,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'todo',
      priority: data['priority'] ?? 'medium',
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      assigneeIds: List<String>.from(data['assigneeIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'],
      isPublic: data['isPublic'] ?? true,
      estimatedHours: data['estimatedHours'],
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'assigneeIds': assigneeIds,
      'tags': tags,
      'category': category,
      'isPublic': isPublic,
      'estimatedHours': estimatedHours,
      'location': location,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? assigneeIds,
    List<String>? tags,
    String? category,
    bool? isPublic,
    int? estimatedHours,
    String? location,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      location: location ?? this.location,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == 'completed') return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isUrgent {
    if (dueDate == null || status == 'completed') return false;
    final now = DateTime.now();
    return dueDate!.isBefore(now.add(const Duration(days: 3)));
  }

  double get progressPercentage {
    switch (status) {
      case 'completed':
        return 100.0;
      case 'in_progress':
        return 50.0;
      case 'todo':
        return 0.0;
      default:
        return 0.0;
    }
  }
}

import 'package:uuid/uuid.dart';

/// Modèle pour les notifications enrichies avec images et actions
class RichNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final String senderId;
  final String senderName;
  final List<String> recipients;
  final String? imageUrl;
  final List<NotificationAction> actions;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final bool isRead;
  final String? categoryId;
  final DateTime? expiresAt;

  RichNotificationModel({
    String? id,
    required this.title,
    required this.body,
    required this.type,
    DateTime? timestamp,
    required this.senderId,
    required this.senderName,
    required this.recipients,
    this.imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.categoryId,
    this.expiresAt,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now(),
    actions = actions ?? [],
    data = data ?? {};

  factory RichNotificationModel.fromJson(Map<String, dynamic> json) {
    return RichNotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'],
      senderName: json['senderName'],
      recipients: List<String>.from(json['recipients']),
      imageUrl: json['imageUrl'],
      actions: (json['actions'] as List<dynamic>?)
          ?.map((action) => NotificationAction.fromJson(action))
          .toList() ?? [],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      priority: NotificationPriority.values[json['priority'] ?? 1],
      isRead: json['isRead'] ?? false,
      categoryId: json['categoryId'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'senderName': senderName,
      'recipients': recipients,
      'imageUrl': imageUrl,
      'actions': actions.map((action) => action.toJson()).toList(),
      'data': data,
      'priority': priority.index,
      'isRead': isRead,
      'categoryId': categoryId,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  RichNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    String? senderId,
    String? senderName,
    List<String>? recipients,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    bool? isRead,
    String? categoryId,
    DateTime? expiresAt,
  }) {
    return RichNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipients: recipients ?? this.recipients,
      imageUrl: imageUrl ?? this.imageUrl,
      actions: actions ?? this.actions,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      categoryId: categoryId ?? this.categoryId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Actions disponibles sur une notification
class NotificationAction {
  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> data;
  final String? icon;
  final bool isDestructive;

  const NotificationAction({
    required this.id,
    required this.title,
    required this.type,
    this.data = const {},
    this.icon,
    this.isDestructive = false,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      icon: json['icon'],
      isDestructive: json['isDestructive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'data': data,
      'icon': icon,
      'isDestructive': isDestructive,
    };
  }
}

/// Priorités des notifications
enum NotificationPriority {
  low,
  normal,
  high,
  urgent
}

/// Extensions utiles
extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Faible';
      case NotificationPriority.normal:
        return 'Normale';
      case NotificationPriority.high:
        return 'Haute';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }

  int get androidPriority {
    switch (this) {
      case NotificationPriority.low:
        return -1;
      case NotificationPriority.normal:
        return 0;
      case NotificationPriority.high:
        return 1;
      case NotificationPriority.urgent:
        return 2;
    }
  }
}

/// Types d'actions prédéfinies
class NotificationActionTypes {
  static const String view = 'view';
  static const String reply = 'reply';
  static const String accept = 'accept';
  static const String decline = 'decline';
  static const String remind = 'remind';
  static const String share = 'share';
  static const String download = 'download';
  static const String navigate = 'navigate';
}

/// Factory pour créer des actions communes
class NotificationActionFactory {
  static NotificationAction viewAction({
    required String targetUrl,
    String title = 'Voir',
  }) {
    return NotificationAction(
      id: 'view_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: NotificationActionTypes.view,
      data: {'url': targetUrl},
      icon: 'visibility',
    );
  }

  static NotificationAction replyAction({
    required String conversationId,
    String title = 'Répondre',
  }) {
    return NotificationAction(
      id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: NotificationActionTypes.reply,
      data: {'conversationId': conversationId},
      icon: 'reply',
    );
  }

  static NotificationAction acceptAction({
    required String itemId,
    String title = 'Accepter',
  }) {
    return NotificationAction(
      id: 'accept_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: NotificationActionTypes.accept,
      data: {'itemId': itemId},
      icon: 'check',
    );
  }

  static NotificationAction declineAction({
    required String itemId,
    String title = 'Refuser',
  }) {
    return NotificationAction(
      id: 'decline_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: NotificationActionTypes.decline,
      data: {'itemId': itemId},
      icon: 'close',
      isDestructive: true,
    );
  }
}

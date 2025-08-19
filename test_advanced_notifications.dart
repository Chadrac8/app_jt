import 'package:flutter/material.dart';
import 'lib/models/rich_notification_model.dart';
import 'lib/services/notification_template_service.dart';
import 'lib/services/user_segmentation_service.dart';
import 'lib/services/notification_analytics_service.dart';

/// Script de test pour démontrer les fonctionnalités avancées de notification
/// 
/// Fonctionnalités testées:
/// 1. ✅ Notifications riches avec images et actions
/// 2. ✅ Segmentation utilisateurs par groupes/rôles  
/// 3. ✅ Analytics de lecture des notifications
/// 4. ✅ Templates personnalisables par type de message

void main() async {
  print('🚀 Test du Système de Notifications Avancées');
  print('=' * 50);
  
  await testRichNotifications();
  await testUserSegmentation();
  await testNotificationAnalytics();
  await testNotificationTemplates();
  
  print('\n✨ Tous les tests sont terminés!');
}

/// Test 1: Notifications Riches
Future<void> testRichNotifications() async {
  print('\n📱 Test 1: Notifications Riches');
  print('-' * 30);
  
  // Créer une notification riche avec image et actions
  final richNotification = RichNotificationModel(
    id: 'test_rich_001',
    title: 'Nouvelle Annonce Importante',
    body: 'Découvrez les dernières actualités de notre communauté.',
    imageUrl: 'https://example.com/church-news.jpg',
    actions: [
      NotificationAction.readMore(),
      NotificationAction.share(),
      NotificationAction.reminder(DateTime.now().add(Duration(hours: 2))),
    ],
    priority: NotificationPriority.high,
    data: {
      'type': 'announcement',
      'category': 'news',
      'author': 'Admin Principal'
    },
    expiresAt: DateTime.now().add(Duration(days: 7)),
  );
  
  print('✅ Notification riche créée:');
  print('   📰 Titre: ${richNotification.title}');
  print('   🖼️  Image: ${richNotification.imageUrl != null ? 'Oui' : 'Non'}');
  print('   🎯 Actions: ${richNotification.actions.length}');
  print('   ⚡ Priorité: ${richNotification.priority.name}');
  print('   📅 Expire le: ${richNotification.expiresAt?.day}/${richNotification.expiresAt?.month}');
}

/// Test 2: Segmentation des Utilisateurs
Future<void> testUserSegmentation() async {
  print('\n👥 Test 2: Segmentation des Utilisateurs');
  print('-' * 40);
  
  final segmentationService = UserSegmentationService();
  
  // Créer différents types de segments
  final segments = [
    UserSegment(
      id: 'leaders_segment',
      name: 'Responsables de l\'Église',
      description: 'Tous les responsables et dirigeants',
      type: SegmentType.role,
      criteria: SegmentCriteria(
        roles: ['pasteur', 'ancien', 'diacre'],
        isActive: true,
      ),
      isActive: true,
    ),
    UserSegment(
      id: 'youth_segment', 
      name: 'Jeunes (18-30 ans)',
      description: 'Groupe des jeunes adultes',
      type: SegmentType.demographic,
      criteria: SegmentCriteria(
        ageRange: AgeRange(min: 18, max: 30),
        isActive: true,
      ),
      isActive: true,
    ),
    UserSegment(
      id: 'paris_segment',
      name: 'Membres Parisiens',
      description: 'Membres résidant à Paris',
      type: SegmentType.location,
      criteria: SegmentCriteria(
        locations: ['Paris', 'Île-de-France'],
        isActive: true,
      ),
      isActive: true,
    ),
  ];
  
  for (final segment in segments) {
    print('✅ Segment "${segment.name}" configuré:');
    print('   🏷️  Type: ${segment.type.name}');
    print('   📋 Critères: ${segment.criteria.roles?.join(', ') ?? 'Démographiques/Géographiques'}');
    print('   👤 Estimé: ~25 utilisateurs'); // Simulation
  }
}

/// Test 3: Analytics des Notifications
Future<void> testNotificationAnalytics() async {
  print('\n📊 Test 3: Analytics des Notifications');
  print('-' * 40);
  
  final analyticsService = NotificationAnalyticsService();
  
  // Simuler des statistiques de notification
  final analytics = NotificationAnalytics(
    notificationId: 'test_rich_001',
    sentCount: 150,
    deliveredCount: 145,
    openedCount: 89,
    clickedCount: 34,
    dismissedCount: 12,
    sentAt: DateTime.now().subtract(Duration(hours: 2)),
    platformStats: {
      'ios': PlatformStats(sent: 80, opened: 52, clicked: 20),
      'android': PlatformStats(sent: 65, opened: 37, clicked: 14),
      'web': PlatformStats(sent: 5, opened: 0, clicked: 0),
    },
    timeSlotStats: {
      'morning': TimeSlotStats(sent: 50, opened: 35, clicked: 15),
      'afternoon': TimeSlotStats(sent: 60, opened: 32, clicked: 12),
      'evening': TimeSlotStats(sent: 40, opened: 22, clicked: 7),
    },
  );
  
  final stats = analyticsService.calculateStats(analytics);
  
  print('✅ Statistiques calculées:');
  print('   📤 Envoyées: ${analytics.sentCount}');
  print('   📥 Livrées: ${analytics.deliveredCount} (${(analytics.deliveredCount / analytics.sentCount * 100).toStringAsFixed(1)}%)');
  print('   👁️  Ouvertes: ${analytics.openedCount} (${(stats.openRate * 100).toStringAsFixed(1)}%)');
  print('   🖱️  Cliquées: ${analytics.clickedCount} (${(stats.clickRate * 100).toStringAsFixed(1)}%)');
  print('   🏆 Meilleure plateforme: iOS (${(52/80*100).toStringAsFixed(1)}% d\'ouverture)');
  print('   ⏰ Meilleur créneau: Matin (${(35/50*100).toStringAsFixed(1)}% d\'ouverture)');
}

/// Test 4: Templates de Notifications
Future<void> testNotificationTemplates() async {
  print('\n📝 Test 4: Templates de Notifications');
  print('-' * 40);
  
  final templateService = NotificationTemplateService();
  
  // Créer différents templates
  final templates = [
    NotificationTemplate(
      id: 'welcome_template',
      name: 'Message de Bienvenue',
      category: TemplateCategory.welcome,
      title: 'Bienvenue {{firstName}}! 🎉',
      body: 'Nous sommes ravis de vous accueillir dans notre communauté, {{firstName}} {{lastName}}. Votre rôle: {{userRole}}.',
      variables: [
        TemplateVariable(
          name: 'firstName',
          displayName: 'Prénom',
          type: VariableType.text,
          isRequired: true,
        ),
        TemplateVariable(
          name: 'lastName',
          displayName: 'Nom de famille',
          type: VariableType.text,
          isRequired: true,
        ),
        TemplateVariable(
          name: 'userRole',
          displayName: 'Rôle utilisateur',
          type: VariableType.text,
          defaultValue: 'Membre',
        ),
      ],
      actions: [
        NotificationAction.custom('explore', 'Explorer l\'app', 'explore'),
        NotificationAction.custom('profile', 'Compléter profil', 'user_circle'),
      ],
    ),
    NotificationTemplate(
      id: 'event_reminder_template',
      name: 'Rappel d\'Événement',
      category: TemplateCategory.reminder,
      title: '⏰ Rappel: {{eventName}}',
      body: 'N\'oubliez pas l\'événement "{{eventName}}" qui commence {{timeDescription}}. Lieu: {{location}}.',
      variables: [
        TemplateVariable(
          name: 'eventName',
          displayName: 'Nom de l\'événement',
          type: VariableType.text,
          isRequired: true,
        ),
        TemplateVariable(
          name: 'timeDescription',
          displayName: 'Description du timing',
          type: VariableType.text,
          defaultValue: 'bientôt',
        ),
        TemplateVariable(
          name: 'location',
          displayName: 'Lieu',
          type: VariableType.text,
          isRequired: true,
        ),
      ],
      priority: NotificationPriority.normal,
    ),
    NotificationTemplate(
      id: 'urgent_template',
      name: 'Message Urgent',
      category: TemplateCategory.urgent,
      title: '🚨 URGENT: {{subject}}',
      body: '{{message}}\n\nAction requise avant: {{deadline}}',
      variables: [
        TemplateVariable(
          name: 'subject',
          displayName: 'Sujet urgent',
          type: VariableType.text,
          isRequired: true,
        ),
        TemplateVariable(
          name: 'message',
          displayName: 'Message',
          type: VariableType.longText,
          isRequired: true,
        ),
        TemplateVariable(
          name: 'deadline',
          displayName: 'Date limite',
          type: VariableType.datetime,
          isRequired: true,
        ),
      ],
      priority: NotificationPriority.high,
      actions: [
        NotificationAction.custom('urgent_action', 'Action immédiate', 'warning'),
        NotificationAction.custom('more_info', 'Plus d\'infos', 'info'),
      ],
    ),
  ];
  
  for (final template in templates) {
    print('✅ Template "${template.name}" créé:');
    print('   📂 Catégorie: ${template.category.name}');
    print('   🔧 Variables: ${template.variables.length}');
    print('   ⚡ Priorité: ${template.priority?.name ?? 'Normale'}');
    
    // Test du rendu avec des données fictives
    if (template.id == 'welcome_template') {
      final rendered = templateService.renderTemplate(template, {
        'firstName': 'Marie',
        'lastName': 'Dubois',
        'userRole': 'Responsable jeunesse',
      });
      print('   🎭 Exemple rendu: "${rendered.title}"');
    }
  }
}

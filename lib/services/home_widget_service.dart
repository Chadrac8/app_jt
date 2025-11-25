import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_widget_model.dart';
import '../auth/auth_service.dart';

class HomeWidgetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'home_config_extended';

  /// Récupérer la configuration étendue de l'accueil
  static Future<ExtendedHomeConfigModel> getExtendedHomeConfig() async {
    try {
      final doc = await _firestore.collection(_collectionName).doc('main').get();
      
      if (doc.exists) {
        return ExtendedHomeConfigModel.fromMap(doc.data()!);
      } else {
        // Créer une configuration par défaut
        final defaultConfig = ExtendedHomeConfigModel(
          id: 'main',
          welcomeTitle: 'Jubilé Tabernacle France',
          welcomeSubtitle: 'Votre communauté spirituelle',
          showGreeting: true,
          widgets: _getDefaultWidgets(),
          lastUpdated: DateTime.now());
        
        await updateExtendedHomeConfig(defaultConfig);
        return defaultConfig;
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la configuration: $e');
    }
  }

  /// Stream de la configuration étendue
  static Stream<ExtendedHomeConfigModel> getExtendedHomeConfigStream() {
    return _firestore
        .collection(_collectionName)
        .doc('main')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ExtendedHomeConfigModel.fromMap(doc.data()!);
      } else {
        return ExtendedHomeConfigModel(
          id: 'main',
          lastUpdated: DateTime.now(),
          widgets: _getDefaultWidgets());
      }
    });
  }

  /// Mettre à jour la configuration étendue
  static Future<void> updateExtendedHomeConfig(ExtendedHomeConfigModel config) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final updatedConfig = config.copyWith(
        lastUpdated: DateTime.now(),
        lastUpdatedBy: currentUser.uid);

      await _firestore
          .collection(_collectionName)
          .doc('main')
          .set(updatedConfig.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Ajouter un widget
  static Future<String> addWidget(HomeWidgetModel widget) async {
    try {
      final config = await getExtendedHomeConfig();
      final newWidget = widget.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        order: config.widgets.length);

      final updatedWidgets = [...config.widgets, newWidget];
      await updateExtendedHomeConfig(config.copyWith(widgets: updatedWidgets));
      
      return newWidget.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du widget: $e');
    }
  }

  /// Mettre à jour un widget
  static Future<void> updateWidget(String widgetId, HomeWidgetModel updatedWidget) async {
    try {
      final config = await getExtendedHomeConfig();
      final widgetIndex = config.widgets.indexWhere((w) => w.id == widgetId);
      
      if (widgetIndex == -1) {
        throw Exception('Widget non trouvé');
      }

      final updatedWidgets = [...config.widgets];
      updatedWidgets[widgetIndex] = updatedWidget.copyWith(
        id: widgetId,
        updatedAt: DateTime.now());

      await updateExtendedHomeConfig(config.copyWith(widgets: updatedWidgets));
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du widget: $e');
    }
  }

  /// Supprimer un widget
  static Future<void> deleteWidget(String widgetId) async {
    try {
      final config = await getExtendedHomeConfig();
      final updatedWidgets = config.widgets.where((w) => w.id != widgetId).toList();
      
      // Réorganiser les ordres
      for (int i = 0; i < updatedWidgets.length; i++) {
        updatedWidgets[i] = updatedWidgets[i].copyWith(order: i);
      }

      await updateExtendedHomeConfig(config.copyWith(widgets: updatedWidgets));
    } catch (e) {
      throw Exception('Erreur lors de la suppression du widget: $e');
    }
  }

  /// Réorganiser les widgets
  static Future<void> reorderWidgets(List<String> widgetIds) async {
    try {
      final config = await getExtendedHomeConfig();
      final reorderedWidgets = <HomeWidgetModel>[];

      for (int i = 0; i < widgetIds.length; i++) {
        final widget = config.widgets.firstWhere((w) => w.id == widgetIds[i]);
        reorderedWidgets.add(widget.copyWith(order: i));
      }

      await updateExtendedHomeConfig(config.copyWith(widgets: reorderedWidgets));
    } catch (e) {
      throw Exception('Erreur lors de la réorganisation: $e');
    }
  }

  /// Activer/Désactiver un widget
  static Future<void> toggleWidgetVisibility(String widgetId) async {
    try {
      final config = await getExtendedHomeConfig();
      final widgetIndex = config.widgets.indexWhere((w) => w.id == widgetId);
      
      if (widgetIndex == -1) {
        throw Exception('Widget non trouvé');
      }

      final updatedWidgets = [...config.widgets];
      updatedWidgets[widgetIndex] = updatedWidgets[widgetIndex].copyWith(
        isVisible: !updatedWidgets[widgetIndex].isVisible,
        updatedAt: DateTime.now());

      await updateExtendedHomeConfig(config.copyWith(widgets: updatedWidgets));
    } catch (e) {
      throw Exception('Erreur lors du changement de visibilité: $e');
    }
  }

  /// Widgets par défaut
  static List<HomeWidgetModel> _getDefaultWidgets() {
    return [
      HomeWidgetModel(
        id: 'verse_card_default',
        type: HomeWidgetType.verseCard.value,
        title: 'Verset du jour',
        description: 'Verset quotidien inspirant',
        configuration: {
          'showIcon': true,
          'style': 'modern',
        },
        order: 0,
        createdAt: DateTime.now()),
      HomeWidgetModel(
        id: 'quick_actions_default',
        type: HomeWidgetType.quickAction.value,
        title: 'Actions rapides',
        description: 'Accès rapide aux fonctionnalités',
        configuration: {
          'actions': [
            {
              'title': 'Nous visiter',
              'subtitle': 'Adresse & horaires',
              'icon': 'location_on',
              'color': '#2196F3',
              'action': {
                'type': 'internal',
                'route': '/church-info',
              },
            },
            {
              'title': 'Demande de prière',
              'subtitle': 'Partager vos besoins',
              'icon': 'favorite',
              'color': '#F44336',
              'action': {
                'type': 'internal',
                'route': '/prayer-wall',
              },
            },
          ],
        },
        order: 1,
        createdAt: DateTime.now()),
      HomeWidgetModel(
        id: 'sermon_card_default',
        type: HomeWidgetType.sermonCard.value,
        title: 'Dernière prédication',
        description: 'Prédication la plus récente',
        configuration: {
          'showVideo': true,
          'showDescription': true,
        },
        order: 2,
        createdAt: DateTime.now()),
      HomeWidgetModel(
        id: 'donation_card_default',
        type: HomeWidgetType.donationCard.value,
        title: 'Soutenir l\'œuvre',
        description: 'Widget de don',
        configuration: {
          'showProgress': false,
          'style': 'modern',
        },
        order: 3,
        createdAt: DateTime.now()),
    ];
  }

  /// Récupérer les modules disponibles pour les redirections
  static Future<List<Map<String, dynamic>>> getAvailableModules() async {
    // Cette méthode devrait récupérer les modules depuis la configuration
    return [
      {'id': 'songs', 'name': 'Cantiques', 'route': '/member/songs'},
      {'id': 'search', 'name': 'Sermons WB', 'route': '/member/search'},
      {'id': 'groups', 'name': 'Groupes', 'route': '/member/groups'},
      {'id': 'events', 'name': 'Événements', 'route': '/member/events'},
      {'id': 'services', 'name': 'Services', 'route': '/member/services'},
      {'id': 'forms', 'name': 'Formulaires', 'route': '/member/forms'},
      {'id': 'tasks', 'name': 'Tâches', 'route': '/member/tasks'},
      {'id': 'appointments', 'name': 'Rendez-vous', 'route': '/member/appointments'},
      {'id': 'prayers', 'name': 'Mur de prière', 'route': '/member/prayers'},
      {'id': 'calendar', 'name': 'Calendrier', 'route': '/member/calendar'},
      {'id': 'profile', 'name': 'Profil', 'route': '/member/profile'},
      {'id': 'notifications', 'name': 'Notifications', 'route': '/member/notifications'},
    ];
  }

  /// Récupérer les pages personnalisées disponibles
  static Future<List<Map<String, dynamic>>> getAvailablePages() async {
    try {
      final pagesSnapshot = await _firestore
          .collection('custom_pages')
          .where('status', isEqualTo: 'published')
          .where('isVisible', isEqualTo: true)
          .get();

      return pagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Page sans titre',
          'slug': data['slug'] ?? '',
          'route': '/pages/${data['slug']}',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Dupliquer un widget
  static Future<String> duplicateWidget(String widgetId) async {
    try {
      final config = await getExtendedHomeConfig();
      final originalWidget = config.widgets.firstWhere((w) => w.id == widgetId);
      
      final duplicatedWidget = originalWidget.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${originalWidget.title} (Copie)',
        createdAt: DateTime.now(),
        updatedAt: null,
        order: config.widgets.length);

      final updatedWidgets = [...config.widgets, duplicatedWidget];
      await updateExtendedHomeConfig(config.copyWith(widgets: updatedWidgets));
      
      return duplicatedWidget.id;
    } catch (e) {
      throw Exception('Erreur lors de la duplication: $e');
    }
  }
}

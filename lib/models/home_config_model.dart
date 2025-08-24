import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de configuration pour la page d'accueil membre
class HomeConfigModel {
  final String id;
  final String coverImageUrl;
  final List<String> coverImageUrls; // Pour le carrousel
  final String? coverVideoUrl; // URL de la vidéo de couverture
  final bool useVideo; // Utiliser la vidéo au lieu des images
  final String? coverTitle;
  final String? coverSubtitle;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  
  // Configuration du live/culte
  final DateTime? liveDateTime;
  final String? liveUrl;
  final bool isLiveActive;
  final String? liveDescription;
  
  // Configuration du pain quotidien
  final String? dailyBreadTitle;
  final String? dailyBreadVerse;
  final String? dailyBreadReference;
  final bool isDailyBreadActive;
  
  // Configuration de la dernière prédication
  final String? lastSermonTitle;
  final String? lastSermonPreacher;
  final String? lastSermonDuration;
  final String? lastSermonThumbnailUrl;
  final String? lastSermonUrl;
  final bool isLastSermonActive;
  
  // Perfect 13 compatibility - pour le widget sermon
  final String? sermonYouTubeUrl;
  final String sermonTitle;
  final DateTime lastUpdated;
  
  // Configuration des événements
  final List<Map<String, dynamic>> upcomingEvents;
  final bool areEventsActive;
  
  // Configuration des actions rapides
  final bool areQuickActionsActive;
  final List<Map<String, dynamic>> quickActions;
  
  // Configuration des informations de contact
  final String? contactEmail;
  final String? contactPhone;
  final String? contactWhatsApp;
  final String? contactAddress;
  final bool isContactActive;

  HomeConfigModel({
    required this.id,
    required this.coverImageUrl,
    this.coverImageUrls = const [],
    this.coverVideoUrl,
    this.useVideo = false,
    this.coverTitle,
    this.coverSubtitle,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.liveDateTime,
    this.liveUrl,
    this.isLiveActive = false,
    this.liveDescription,
    this.dailyBreadTitle,
    this.dailyBreadVerse,
    this.dailyBreadReference,
    this.isDailyBreadActive = true,
    this.lastSermonTitle,
    this.lastSermonPreacher,
    this.lastSermonDuration,
    this.lastSermonThumbnailUrl,
    this.lastSermonUrl,
    this.isLastSermonActive = true,
    this.upcomingEvents = const [],
    this.areEventsActive = true,
    this.areQuickActionsActive = true,
    this.quickActions = const [],
    this.contactEmail,
    this.contactPhone,
    this.contactWhatsApp,
    this.contactAddress,
    this.isContactActive = true,
    // Perfect 13 compatibility
    this.sermonYouTubeUrl,
    this.sermonTitle = 'Dernière prédication',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? updatedAt;

  /// Constructeur pour créer une nouvelle configuration
  factory HomeConfigModel.create({
    required String coverImageUrl,
    List<String> coverImageUrls = const [],
    String? coverVideoUrl,
    bool useVideo = false,
    String? coverTitle,
    String? coverSubtitle,
    String? createdBy,
    DateTime? liveDateTime,
    String? liveUrl,
    bool isLiveActive = false,
    String? liveDescription,
    String? dailyBreadTitle,
    String? dailyBreadVerse,
    String? dailyBreadReference,
    bool isDailyBreadActive = true,
    String? lastSermonTitle,
    String? lastSermonPreacher,
    String? lastSermonDuration,
    String? lastSermonThumbnailUrl,
    String? lastSermonUrl,
    bool isLastSermonActive = true,
    List<Map<String, dynamic>> upcomingEvents = const [],
    bool areEventsActive = true,
    bool areQuickActionsActive = true,
    List<Map<String, dynamic>> quickActions = const [],
    String? contactEmail,
    String? contactPhone,
    String? contactWhatsApp,
    String? contactAddress,
    bool isContactActive = true,
  }) {
    final now = DateTime.now();
    return HomeConfigModel(
      id: '',
      coverImageUrl: coverImageUrl,
      coverImageUrls: coverImageUrls,
      coverVideoUrl: coverVideoUrl,
      useVideo: useVideo,
      coverTitle: coverTitle,
      coverSubtitle: coverSubtitle,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      lastModifiedBy: createdBy,
      liveDateTime: liveDateTime,
      liveUrl: liveUrl,
      isLiveActive: isLiveActive,
      liveDescription: liveDescription,
      dailyBreadTitle: dailyBreadTitle,
      dailyBreadVerse: dailyBreadVerse,
      dailyBreadReference: dailyBreadReference,
      isDailyBreadActive: isDailyBreadActive,
      lastSermonTitle: lastSermonTitle,
      lastSermonPreacher: lastSermonPreacher,
      lastSermonDuration: lastSermonDuration,
      lastSermonThumbnailUrl: lastSermonThumbnailUrl,
      lastSermonUrl: lastSermonUrl,
      isLastSermonActive: isLastSermonActive,
      upcomingEvents: upcomingEvents,
      areEventsActive: areEventsActive,
      areQuickActionsActive: areQuickActionsActive,
      quickActions: quickActions,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactWhatsApp: contactWhatsApp,
      contactAddress: contactAddress,
      isContactActive: isContactActive,
    );
  }

  /// Créer à partir des données Firestore
  factory HomeConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeConfigModel(
      id: doc.id,
      coverImageUrl: data['coverImageUrl'] ?? '',
      coverImageUrls: List<String>.from(data['coverImageUrls'] ?? []),
      coverVideoUrl: data['coverVideoUrl'],
      useVideo: data['useVideo'] ?? false,
      coverTitle: data['coverTitle'],
      coverSubtitle: data['coverSubtitle'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      liveDateTime: (data['liveDateTime'] as Timestamp?)?.toDate(),
      liveUrl: data['liveUrl'],
      isLiveActive: data['isLiveActive'] ?? false,
      liveDescription: data['liveDescription'],
      dailyBreadTitle: data['dailyBreadTitle'],
      dailyBreadVerse: data['dailyBreadVerse'],
      dailyBreadReference: data['dailyBreadReference'],
      isDailyBreadActive: data['isDailyBreadActive'] ?? true,
      lastSermonTitle: data['lastSermonTitle'],
      lastSermonPreacher: data['lastSermonPreacher'],
      lastSermonDuration: data['lastSermonDuration'],
      lastSermonThumbnailUrl: data['lastSermonThumbnailUrl'],
      lastSermonUrl: data['lastSermonUrl'],
      isLastSermonActive: data['isLastSermonActive'] ?? true,
      upcomingEvents: List<Map<String, dynamic>>.from(data['upcomingEvents'] ?? []),
      areEventsActive: data['areEventsActive'] ?? true,
      areQuickActionsActive: data['areQuickActionsActive'] ?? true,
      quickActions: List<Map<String, dynamic>>.from(data['quickActions'] ?? []),
      contactEmail: data['contactEmail'],
      contactPhone: data['contactPhone'],
      contactWhatsApp: data['contactWhatsApp'],
      contactAddress: data['contactAddress'],
      isContactActive: data['isContactActive'] ?? true,
      // Perfect 13 compatibility
      sermonYouTubeUrl: data['sermonYouTubeUrl'] ?? data['lastSermonUrl'],
      sermonTitle: data['sermonTitle'] ?? data['lastSermonTitle'] ?? 'Dernière prédication',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'coverImageUrl': coverImageUrl,
      'coverImageUrls': coverImageUrls,
      'coverVideoUrl': coverVideoUrl,
      'useVideo': useVideo,
      'coverTitle': coverTitle,
      'coverSubtitle': coverSubtitle,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'liveDateTime': liveDateTime != null ? Timestamp.fromDate(liveDateTime!) : null,
      'liveUrl': liveUrl,
      'isLiveActive': isLiveActive,
      'liveDescription': liveDescription,
      'dailyBreadTitle': dailyBreadTitle,
      'dailyBreadVerse': dailyBreadVerse,
      'dailyBreadReference': dailyBreadReference,
      'isDailyBreadActive': isDailyBreadActive,
      'lastSermonTitle': lastSermonTitle,
      'lastSermonPreacher': lastSermonPreacher,
      'lastSermonDuration': lastSermonDuration,
      'lastSermonThumbnailUrl': lastSermonThumbnailUrl,
      'lastSermonUrl': lastSermonUrl,
      'isLastSermonActive': isLastSermonActive,
      'upcomingEvents': upcomingEvents,
      'areEventsActive': areEventsActive,
      'areQuickActionsActive': areQuickActionsActive,
      'quickActions': quickActions,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactWhatsApp': contactWhatsApp,
      'contactAddress': contactAddress,
      'isContactActive': isContactActive,
      // Perfect 13 compatibility
      'sermonYouTubeUrl': sermonYouTubeUrl,
      'sermonTitle': sermonTitle,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Créer une copie avec des modifications
  HomeConfigModel copyWith({
    String? id,
    String? coverImageUrl,
    List<String>? coverImageUrls,
    String? coverVideoUrl,
    bool? useVideo,
    String? coverTitle,
    String? coverSubtitle,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    DateTime? liveDateTime,
    String? liveUrl,
    bool? isLiveActive,
    String? liveDescription,
    String? dailyBreadTitle,
    String? dailyBreadVerse,
    String? dailyBreadReference,
    bool? isDailyBreadActive,
    String? lastSermonTitle,
    String? lastSermonPreacher,
    String? lastSermonDuration,
    String? lastSermonThumbnailUrl,
    String? lastSermonUrl,
    bool? isLastSermonActive,
    List<Map<String, dynamic>>? upcomingEvents,
    bool? areEventsActive,
    bool? areQuickActionsActive,
    List<Map<String, dynamic>>? quickActions,
    String? contactEmail,
    String? contactPhone,
    String? contactWhatsApp,
    String? contactAddress,
    bool? isContactActive,
  }) {
    return HomeConfigModel(
      id: id ?? this.id,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageUrls: coverImageUrls ?? this.coverImageUrls,
      coverVideoUrl: coverVideoUrl ?? this.coverVideoUrl,
      useVideo: useVideo ?? this.useVideo,
      coverTitle: coverTitle ?? this.coverTitle,
      coverSubtitle: coverSubtitle ?? this.coverSubtitle,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      liveDateTime: liveDateTime ?? this.liveDateTime,
      liveUrl: liveUrl ?? this.liveUrl,
      isLiveActive: isLiveActive ?? this.isLiveActive,
      liveDescription: liveDescription ?? this.liveDescription,
      dailyBreadTitle: dailyBreadTitle ?? this.dailyBreadTitle,
      dailyBreadVerse: dailyBreadVerse ?? this.dailyBreadVerse,
      dailyBreadReference: dailyBreadReference ?? this.dailyBreadReference,
      isDailyBreadActive: isDailyBreadActive ?? this.isDailyBreadActive,
      lastSermonTitle: lastSermonTitle ?? this.lastSermonTitle,
      lastSermonPreacher: lastSermonPreacher ?? this.lastSermonPreacher,
      lastSermonDuration: lastSermonDuration ?? this.lastSermonDuration,
      lastSermonThumbnailUrl: lastSermonThumbnailUrl ?? this.lastSermonThumbnailUrl,
      lastSermonUrl: lastSermonUrl ?? this.lastSermonUrl,
      isLastSermonActive: isLastSermonActive ?? this.isLastSermonActive,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      areEventsActive: areEventsActive ?? this.areEventsActive,
      areQuickActionsActive: areQuickActionsActive ?? this.areQuickActionsActive,
      quickActions: quickActions ?? this.quickActions,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactWhatsApp: contactWhatsApp ?? this.contactWhatsApp,
      contactAddress: contactAddress ?? this.contactAddress,
      isContactActive: isContactActive ?? this.isContactActive,
    );
  }

  /// Configuration par défaut
  static HomeConfigModel get defaultConfig {
    final now = DateTime.now();
    return HomeConfigModel(
      id: 'default',
      coverImageUrl: '',
      coverImageUrls: [],
      useVideo: false,
      coverTitle: 'Jubilé Tabernacle',
      coverSubtitle: 'Bienvenue dans la maison de Dieu',
      isActive: true,
      createdAt: now,
      updatedAt: now,
      isLiveActive: false,
      liveDescription: 'Culte dominical',
      dailyBreadTitle: 'Pain quotidien',
      dailyBreadVerse: '"Car l\'Éternel, ton Dieu, t\'a béni dans tout le travail de tes mains"',
      dailyBreadReference: 'Deutéronome 2:7',
      isDailyBreadActive: true,
      lastSermonTitle: 'La grâce de Dieu',
      lastSermonPreacher: 'Pasteur Jean-Baptiste',
      lastSermonDuration: '45 min',
      isLastSermonActive: true,
      upcomingEvents: [
        {
          'day': '25',
          'month': 'Déc',
          'title': 'Culte de Noël',
          'description': 'Célébration spéciale de Noël',
          'time': '10:00'
        },
        {
          'day': '31',
          'month': 'Déc',
          'title': 'Veillée du Nouvel An',
          'description': 'Prière et louange',
          'time': '22:00'
        }
      ],
      areEventsActive: true,
      areQuickActionsActive: true,
      quickActions: [
        {
          'title': 'Donner sa vie à Jésus',
          'description': 'Accepter Christ comme Sauveur',
          'icon': 'favorite_rounded',
          'color': 0xFFE57373
        },
        {
          'title': 'Étudier la Parole',
          'description': 'Lecture et méditation biblique',
          'icon': 'menu_book_rounded',
          'color': 0xFF81C784
        },
        {
          'title': 'Requêtes de prière',
          'description': 'Déposer une demande de prière',
          'icon': 'volunteer_activism_rounded',
          'color': 0xFFBA68C8
        },
        {
          'title': 'Faire un don',
          'description': 'Soutenir l\'œuvre de Dieu',
          'icon': 'card_giftcard_rounded',
          'color': 0xFFFFB74D
        }
      ],
      contactEmail: 'contact@jubiletabernacle.org',
      contactPhone: '+33 6 77 45 72 78',
      contactWhatsApp: '+33 6 77 45 72 78',
      contactAddress: 'Jubilé Tabernacle\n124 bis rue de l\'Épidème\n59200 Tourcoing',
      isContactActive: true,
      // Perfect 13 compatibility
      sermonYouTubeUrl: null,
      sermonTitle: 'La grâce de Dieu',
      lastUpdated: now,
    );
  }

  /// Vérifier si le live est maintenant
  bool get isLiveNow {
    if (!isLiveActive || liveDateTime == null) return false;
    final now = DateTime.now();
    final liveTime = liveDateTime!;
    // Considérer comme "live" si c'est dans les 2 heures suivant l'heure programmée
    return now.isAfter(liveTime) && 
           now.isBefore(liveTime.add(const Duration(hours: 2)));
  }

  /// Vérifier si le live est à venir
  bool get isLiveUpcoming {
    if (!isLiveActive || liveDateTime == null) return false;
    final now = DateTime.now();
    return now.isBefore(liveDateTime!);
  }
}

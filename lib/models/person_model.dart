import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_model.dart';

/// Fonction utilitaire pour parser les dates qui peuvent être Timestamp ou String
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      print('Erreur parsing date: $value - $e');
      return null;
    }
  }
  return null;
}

/// Classe pour représenter un contact d'urgence
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String relationship;
  final bool isPrimary;
  final String? notes;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.relationship,
    this.isPrimary = false,
    this.notes,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      relationship: map['relationship'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'notes': notes,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    bool? isPrimary,
    String? notes,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
    );
  }
}

/// Classe pour représenter une note de famille
class FamilyNote {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String? category;
  final bool isPrivate;

  FamilyNote({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.category,
    this.isPrivate = false,
  });

  factory FamilyNote.fromMap(Map<String, dynamic> map) {
    return FamilyNote(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      category: map['category'],
      isPrivate: map['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'isPrivate': isPrivate,
    };
  }
}

/// Classe pour représenter un événement de famille
class FamilyEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String type; // 'birthday', 'anniversary', 'milestone', 'custom'
  final bool isRecurring;
  final String? recurringPattern;
  final List<String> attendees;

  FamilyEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    required this.type,
    this.isRecurring = false,
    this.recurringPattern,
    this.attendees = const [],
  });

  factory FamilyEvent.fromMap(Map<String, dynamic> map) {
    return FamilyEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      eventDate: _parseDateTime(map['eventDate']) ?? DateTime.now(),
      type: map['type'] ?? 'custom',
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      attendees: List<String>.from(map['attendees'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'type': type,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'attendees': attendees,
    };
  }
}

class PersonModel {
  final String id;
  final String? uid; // Firebase Auth UID - null pour les personnes créées manuellement
  final String firstName;
  final String lastName;
  final String? email; // Nullable pour import/export
  final String? phone;
  final String? country;
  final DateTime? birthDate;
  final String? address;
  final String? additionalAddress;
  final String? zipCode;
  final String? city;
  final String? gender;
  final String? maritalStatus;
  final List<String> children;
  final String? profileImageUrl;
  final String? privateNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? familyId;
  final FamilyRole familyRole;
  final List<String> roles;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? lastModifiedBy;

  PersonModel({
    required this.id,
    this.uid,
    required this.firstName,
    required this.lastName,
    this.email, // Nullable pour import/export
    this.phone,
    this.country,
    this.birthDate,
    this.address,
    this.additionalAddress,
    this.zipCode,
    this.city,
    this.gender,
    this.maritalStatus,
    this.children = const [],
    this.profileImageUrl,
    this.privateNotes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.familyId,
    this.familyRole = FamilyRole.other,
    this.roles = const [],
    this.tags = const [],
    this.customFields = const {},
    this.lastModifiedBy,
  });

  String get fullName => '$firstName $lastName';

  String get displayInitials {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String? get formattedBirthDate {
    if (birthDate == null) return null;
    return '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';
  }

  // Méthode pour vérifier si la personne a une permission spécifique
  bool hasPermission(String permission, List<RoleModel> allRoles) {
    // Admin système a toutes les permissions
    for (String roleId in roles) {
      try {
        final role = allRoles.firstWhere((r) => r.id == roleId);
        if (role.isActive && (role.permissions.contains(permission) || role.permissions.contains('system_admin'))) {
          return true;
        }
      } catch (e) {
        // Role not found, continue to next role
        continue;
      }
    }
    return false;
  }

  // Méthode pour obtenir toutes les permissions de la personne
  List<String> getAllPermissions(List<RoleModel> allRoles) {
    final Set<String> permissions = {};
    for (String roleId in roles) {
      try {
        final role = allRoles.firstWhere((r) => r.id == roleId);
        if (role.isActive) {
          permissions.addAll(role.permissions);
        }
      } catch (e) {
        // Role not found, continue to next role
        continue;
      }
    }
    return permissions.toList();
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  factory PersonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonModel(
      id: doc.id,
      uid: data['uid'],
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      country: data['country'],
      birthDate: _parseDateTime(data['birthDate']),
      address: data['address'],
      additionalAddress: data['additionalAddress'],
      zipCode: data['zipCode'],
      city: data['city'],
      gender: data['gender'],
      maritalStatus: data['maritalStatus'],
      children: List<String>.from(data['children'] ?? []),
      profileImageUrl: data['profileImageUrl'],
      privateNotes: data['privateNotes'],
      isActive: data['isActive'] ?? true,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      familyId: data['familyId'],
      familyRole: FamilyRole.values.firstWhere(
        (r) => r.toString().split('.').last == (data['familyRole'] ?? 'other'),
        orElse: () => FamilyRole.other,
      ),
      roles: List<String>.from(data['roles'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'country': country,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'address': address,
      'additionalAddress': additionalAddress,
      'zipCode': zipCode,
      'city': city,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'children': children,
      'profileImageUrl': profileImageUrl,
      'privateNotes': privateNotes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'familyId': familyId,
      'familyRole': familyRole.toString().split('.').last,
      'roles': roles,
      'tags': tags,
      'customFields': customFields,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  PersonModel copyWith({
    String? id,
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? country,
    DateTime? birthDate,
    String? address,
    String? additionalAddress,
    String? zipCode,
    String? city,
    String? gender,
    String? maritalStatus,
    List<String>? children,
    String? profileImageUrl,
    String? privateNotes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? familyId,
    FamilyRole? familyRole,
    List<String>? roles,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? lastModifiedBy,
  }) {
    return PersonModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      additionalAddress: additionalAddress ?? this.additionalAddress,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      children: children ?? this.children,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      privateNotes: privateNotes ?? this.privateNotes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      familyId: familyId ?? this.familyId,
      familyRole: familyRole ?? this.familyRole,
      roles: roles ?? this.roles,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  /// Constructeur factory pour l'import depuis un format simple (CSV/JSON)
  factory PersonModel.fromImport({
    String? id,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? country,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? address,
    String? additionalAddress,
    String? zipCode,
    String? city,
    String? profileImageUrl,
    List<String>? roles,
    Map<String, dynamic>? customFields,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return PersonModel(
      id: id ?? '',
      uid: null, // Pas d'UID pour les imports
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      country: country,
      birthDate: birthDate,
      address: address,
      additionalAddress: additionalAddress,
      zipCode: zipCode,
      city: city,
      gender: gender,
      maritalStatus: maritalStatus,
      children: const [],
      profileImageUrl: profileImageUrl,
      privateNotes: null,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
      familyId: null,
      familyRole: FamilyRole.other,
      roles: roles ?? const [],
      tags: const [],
      customFields: customFields ?? const {},
      lastModifiedBy: null,
    );
  }

  /// Convertir vers un format simple pour l'export
  Map<String, dynamic> toImportExportFormat() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'country': country,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'maritalStatus': maritalStatus,
      'address': address,
      'additionalAddress': additionalAddress,
      'zipCode': zipCode,
      'city': city,
      'profileImageUrl': profileImageUrl,
      'roles': roles,
      'customFields': customFields,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Vérifier si la personne a un rôle spécifique (compatible avec Person)
  bool hasRole(String role) {
    return roles.contains(role);
  }
}

class FamilyModel {
  final String id;
  final String name;
  final String? headOfFamilyId;
  final List<String> memberIds;
  
  // Adresse principale
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  
  // Contacts
  final String? homePhone;
  final String? mobilePhone;
  final String? email;
  final String? website;
  
  // Contacts d'urgence multiples
  final List<EmergencyContact> emergencyContacts;
  
  // Statut et métadonnées
  final FamilyStatus status;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? photoUrl;
  final String? notes;
  final bool isActive;
  
  // Dates et traçabilité
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  
  // Informations étendues
  final String? preferredLanguage;
  final String? timezone;
  final Map<String, String> socialMedia;
  final String? anniversary;
  final String? churchMembershipDate;
  final String? familyType; // 'nuclear', 'extended', 'single_parent', 'blended'
  final int? numberOfChildren;
  final List<String> allergies;
  final List<String> interests;
  final String? primaryIncome;
  final String? secondaryIncome;
  
  // Préférences de communication
  final bool allowSMS;
  final bool allowEmail;
  final bool allowPhone;
  final bool allowPushNotifications;
  final List<String> communicationPreferences;
  
  // Historique et notes
  final List<FamilyNote> familyNotes;
  final List<FamilyEvent> familyEvents;
  final Map<String, dynamic> membershipHistory;

  FamilyModel({
    required this.id,
    required this.name,
    this.headOfFamilyId,
    this.memberIds = const [],
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.homePhone,
    this.mobilePhone,
    this.email,
    this.website,
    this.emergencyContacts = const [],
    this.status = FamilyStatus.active,
    this.tags = const [],
    this.customFields = const {},
    this.photoUrl,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.preferredLanguage,
    this.timezone,
    this.socialMedia = const {},
    this.anniversary,
    this.churchMembershipDate,
    this.familyType,
    this.numberOfChildren,
    this.allergies = const [],
    this.interests = const [],
    this.primaryIncome,
    this.secondaryIncome,
    this.allowSMS = true,
    this.allowEmail = true,
    this.allowPhone = true,
    this.allowPushNotifications = true,
    this.communicationPreferences = const [],
    this.familyNotes = const [],
    this.familyEvents = const [],
    this.membershipHistory = const {},
  });

  /// Retourne l'adresse complète formatée
  String get fullAddress {
    final addressParts = [
      address,
      city,
      state,
      zipCode,
      country,
    ].where((part) => part != null && part.isNotEmpty);
    return addressParts.join(', ');
  }

  /// Retourne le contact d'urgence principal
  EmergencyContact? get primaryEmergencyContact {
    try {
      return emergencyContacts.firstWhere((contact) => contact.isPrimary);
    } catch (e) {
      return emergencyContacts.isNotEmpty ? emergencyContacts.first : null;
    }
  }

  /// Getters de compatibilité pour l'ancien format
  String? get emergencyContact {
    final primary = primaryEmergencyContact;
    return primary?.name;
  }

  String? get emergencyPhone {
    final primary = primaryEmergencyContact;
    return primary?.phone;
  }

  /// Retourne tous les contacts d'urgence actifs
  List<EmergencyContact> get activeEmergencyContacts {
    return emergencyContacts.where((contact) => contact.phone.isNotEmpty).toList();
  }

  /// Filtre les membres par rôle familial
  List<PersonModel> getParents(List<PersonModel> allMembers) {
    return allMembers.where((member) {
      return member.familyRole == FamilyRole.parent || 
             member.familyRole == FamilyRole.head ||
             member.id == headOfFamilyId;
    }).toList();
  }

  List<PersonModel> getChildren(List<PersonModel> allMembers) {
    return allMembers.where((member) {
      return member.familyRole == FamilyRole.child;
    }).toList();
  }

  List<PersonModel> getOtherMembers(List<PersonModel> allMembers) {
    return allMembers.where((member) {
      return member.familyRole == FamilyRole.other;
    }).toList();
  }

  /// Retourne le chef de famille
  PersonModel? getHeadOfFamily(List<PersonModel> allMembers) {
    if (headOfFamilyId == null) return null;
    try {
      return allMembers.firstWhere((member) => member.id == headOfFamilyId);
    } catch (e) {
      return null;
    }
  }

  /// Méthodes de validation
  bool get isValid {
    return name.isNotEmpty && memberIds.isNotEmpty;
  }

  bool get hasValidAddress {
    return address != null && address!.isNotEmpty && 
           city != null && city!.isNotEmpty;
  }

  bool get hasEmergencyContact {
    return emergencyContacts.isNotEmpty;
  }

  /// Statistiques de la famille
  int get memberCount => memberIds.length;
  
  int get childrenCount => numberOfChildren ?? 0;
  
  int get adultsCount => memberCount - childrenCount;

  /// Méthodes utilitaires pour les communications
  bool get canReceiveSMS => allowSMS && (homePhone != null || mobilePhone != null);
  
  bool get canReceiveEmail => allowEmail && email != null;
  
  bool get canReceivePhoneCalls => allowPhone && (homePhone != null || mobilePhone != null);

  /// Méthodes pour les événements
  List<FamilyEvent> getUpcomingEvents({int daysAhead = 30}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));
    
    return familyEvents.where((event) {
      return event.eventDate.isAfter(now) && event.eventDate.isBefore(futureDate);
    }).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  List<FamilyEvent> getBirthdaysThisMonth() {
    final now = DateTime.now();
    return familyEvents.where((event) {
      return event.type == 'birthday' && 
             event.eventDate.month == now.month;
    }).toList();
  }

  /// Méthodes pour les notes
  List<FamilyNote> getRecentNotes({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return familyNotes.where((note) {
      return note.createdAt.isAfter(cutoffDate);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<FamilyNote> getNotesByCategory(String category) {
    return familyNotes.where((note) {
      return note.category == category;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Méthodes pour les préférences
  bool hasPreference(String preference) {
    return communicationPreferences.contains(preference);
  }

  String get preferredContactMethod {
    if (communicationPreferences.isEmpty) return 'email';
    return communicationPreferences.first;
  }

  /// Méthodes de comparaison et recherche
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    return name.toLowerCase().contains(searchQuery) ||
           (address?.toLowerCase().contains(searchQuery) ?? false) ||
           (city?.toLowerCase().contains(searchQuery) ?? false) ||
           tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
           (homePhone?.contains(searchQuery) ?? false) ||
           (email?.toLowerCase().contains(searchQuery) ?? false);
  }

  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  bool hasAnyTag(List<String> tagList) {
    return tagList.any((tag) => tags.contains(tag));
  }

  /// Méthodes pour l'historique
  Map<String, dynamic> generateSnapshot() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'name': name,
      'status': status.toString(),
      'memberCount': memberCount,
      'address': fullAddress,
      'headOfFamily': headOfFamilyId,
    };
  }

  /// Méthodes de formatage
  String get statusDisplayName {
    switch (status) {
      case FamilyStatus.active:
        return 'Actif';
      case FamilyStatus.inactive:
        return 'Inactif';
      case FamilyStatus.visitor:
        return 'Visiteur';
      case FamilyStatus.member:
        return 'Membre';
      case FamilyStatus.inactive_member:
        return 'Ancien membre';
      case FamilyStatus.attendee:
        return 'Participant';
    }
  }

  String get familyTypeDisplayName {
    switch (familyType) {
      case 'nuclear':
        return 'Famille nucléaire';
      case 'extended':
        return 'Famille élargie';
      case 'single_parent':
        return 'Famille monoparentale';
      case 'blended':
        return 'Famille recomposée';
      default:
        return familyType ?? 'Non spécifié';
    }
  }

  /// Création depuis Firestore
  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FamilyModel(
      id: doc.id,
      name: data['name'] ?? '',
      headOfFamilyId: data['headOfFamilyId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      country: data['country'],
      homePhone: data['homePhone'],
      mobilePhone: data['mobilePhone'],
      email: data['email'],
      website: data['website'],
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
          ?.map((contact) => EmergencyContact.fromMap(contact as Map<String, dynamic>))
          .toList() ?? [],
      status: FamilyStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (data['status'] ?? 'active'),
        orElse: () => FamilyStatus.active,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
      photoUrl: data['photoUrl'],
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      preferredLanguage: data['preferredLanguage'],
      timezone: data['timezone'],
      socialMedia: Map<String, String>.from(data['socialMedia'] ?? {}),
      anniversary: data['anniversary'],
      churchMembershipDate: data['churchMembershipDate'],
      familyType: data['familyType'],
      numberOfChildren: data['numberOfChildren'],
      allergies: List<String>.from(data['allergies'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      primaryIncome: data['primaryIncome'],
      secondaryIncome: data['secondaryIncome'],
      allowSMS: data['allowSMS'] ?? true,
      allowEmail: data['allowEmail'] ?? true,
      allowPhone: data['allowPhone'] ?? true,
      allowPushNotifications: data['allowPushNotifications'] ?? true,
      communicationPreferences: List<String>.from(data['communicationPreferences'] ?? []),
      familyNotes: (data['familyNotes'] as List<dynamic>?)
          ?.map((note) => FamilyNote.fromMap(note as Map<String, dynamic>))
          .toList() ?? [],
      familyEvents: (data['familyEvents'] as List<dynamic>?)
          ?.map((event) => FamilyEvent.fromMap(event as Map<String, dynamic>))
          .toList() ?? [],
      membershipHistory: Map<String, dynamic>.from(data['membershipHistory'] ?? {}),
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'headOfFamilyId': headOfFamilyId,
      'memberIds': memberIds,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'email': email,
      'website': website,
      'emergencyContacts': emergencyContacts.map((contact) => contact.toMap()).toList(),
      'status': status.toString().split('.').last,
      'tags': tags,
      'customFields': customFields,
      'photoUrl': photoUrl,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'preferredLanguage': preferredLanguage,
      'timezone': timezone,
      'socialMedia': socialMedia,
      'anniversary': anniversary,
      'churchMembershipDate': churchMembershipDate,
      'familyType': familyType,
      'numberOfChildren': numberOfChildren,
      'allergies': allergies,
      'interests': interests,
      'primaryIncome': primaryIncome,
      'secondaryIncome': secondaryIncome,
      'allowSMS': allowSMS,
      'allowEmail': allowEmail,
      'allowPhone': allowPhone,
      'allowPushNotifications': allowPushNotifications,
      'communicationPreferences': communicationPreferences,
      'familyNotes': familyNotes.map((note) => note.toMap()).toList(),
      'familyEvents': familyEvents.map((event) => event.toMap()).toList(),
      'membershipHistory': membershipHistory,
    };
  }

  /// Méthode copyWith complète
  FamilyModel copyWith({
    String? id,
    String? name,
    String? headOfFamilyId,
    List<String>? memberIds,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? homePhone,
    String? mobilePhone,
    String? email,
    String? website,
    List<EmergencyContact>? emergencyContacts,
    FamilyStatus? status,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? photoUrl,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    String? preferredLanguage,
    String? timezone,
    Map<String, String>? socialMedia,
    String? anniversary,
    String? churchMembershipDate,
    String? familyType,
    int? numberOfChildren,
    List<String>? allergies,
    List<String>? interests,
    String? primaryIncome,
    String? secondaryIncome,
    bool? allowSMS,
    bool? allowEmail,
    bool? allowPhone,
    bool? allowPushNotifications,
    List<String>? communicationPreferences,
    List<FamilyNote>? familyNotes,
    List<FamilyEvent>? familyEvents,
    Map<String, dynamic>? membershipHistory,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      headOfFamilyId: headOfFamilyId ?? this.headOfFamilyId,
      memberIds: memberIds ?? this.memberIds,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      homePhone: homePhone ?? this.homePhone,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      email: email ?? this.email,
      website: website ?? this.website,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      socialMedia: socialMedia ?? this.socialMedia,
      anniversary: anniversary ?? this.anniversary,
      churchMembershipDate: churchMembershipDate ?? this.churchMembershipDate,
      familyType: familyType ?? this.familyType,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      allergies: allergies ?? this.allergies,
      interests: interests ?? this.interests,
      primaryIncome: primaryIncome ?? this.primaryIncome,
      secondaryIncome: secondaryIncome ?? this.secondaryIncome,
      allowSMS: allowSMS ?? this.allowSMS,
      allowEmail: allowEmail ?? this.allowEmail,
      allowPhone: allowPhone ?? this.allowPhone,
      allowPushNotifications: allowPushNotifications ?? this.allowPushNotifications,
      communicationPreferences: communicationPreferences ?? this.communicationPreferences,
      familyNotes: familyNotes ?? this.familyNotes,
      familyEvents: familyEvents ?? this.familyEvents,
      membershipHistory: membershipHistory ?? this.membershipHistory,
    );
  }
}

enum FamilyStatus {
  active,
  inactive,
  visitor,
  member,
  inactive_member,
  attendee,
}

enum FamilyRole {
  head,
  parent,
  child,
  other,
}


class WorkflowModel {
  final String id;
  final String name;
  final String description;
  final List<WorkflowStep> steps;
  final Map<String, dynamic> triggerConditions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String category;
  final String color;
  final String icon;

  WorkflowModel({
    required this.id,
    required this.name,
    required this.description,
    this.steps = const [],
    this.triggerConditions = const {},
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
    this.createdBy = '',
    this.category = 'Général',
    this.color = '#2196F3',
    this.icon = 'track_changes',
  }) : updatedAt = updatedAt ?? createdAt;

  factory WorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkflowModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      steps: (data['steps'] as List<dynamic>?)
          ?.map((step) => WorkflowStep.fromMap(step))
          .toList() ?? [],
      triggerConditions: Map<String, dynamic>.from(data['triggerConditions'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      category: data['category'] ?? 'Général',
      color: data['color'] ?? '#2196F3',
      icon: data['icon'] ?? 'track_changes',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'steps': steps.map((step) => step.toMap()).toList(),
      'triggerConditions': triggerConditions,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'category': category,
      'color': color,
      'icon': icon,
    };
  }

  WorkflowModel copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkflowStep>? steps,
    Map<String, dynamic>? triggerConditions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? category,
    String? color,
    String? icon,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      triggerConditions: triggerConditions ?? this.triggerConditions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

class WorkflowStep {
  final String id;
  final String name;
  final String description;
  final int order;
  final bool isRequired;
  final int estimatedDuration; // En minutes
  final String? assignedTo; // ID de la personne responsable
  final String? assignedToName; // Nom de la personne responsable pour affichage

  WorkflowStep({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    this.isRequired = false,
    this.estimatedDuration = 30,
    this.assignedTo,
    this.assignedToName,
  });

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      isRequired: map['isRequired'] ?? false,
      estimatedDuration: map['estimatedDuration'] ?? 30,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'isRequired': isRequired,
      'estimatedDuration': estimatedDuration,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
    };
  }

  WorkflowStep copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? isRequired,
    int? estimatedDuration,
    String? assignedTo,
    String? assignedToName,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      isRequired: isRequired ?? this.isRequired,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
    );
  }
}

class PersonWorkflowModel {
  final String id;
  final String personId;
  final String workflowId;
  final int currentStep;
  final List<String> completedSteps;
  final String notes;
  final DateTime startDate;
  final DateTime lastUpdated;
  final String status; // 'pending', 'in_progress', 'completed', 'paused'
  final DateTime? completedDate;

  PersonWorkflowModel({
    required this.id,
    required this.personId,
    required this.workflowId,
    this.currentStep = 0,
    this.completedSteps = const [],
    this.notes = '',
    required this.startDate,
    required this.lastUpdated,
    this.status = 'pending',
    this.completedDate,
  });

  factory PersonWorkflowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonWorkflowModel(
      id: doc.id,
      personId: data['personId'] ?? '',
      workflowId: data['workflowId'] ?? '',
      currentStep: data['currentStep'] ?? 0,
      completedSteps: List<String>.from(data['completedSteps'] ?? []),
      notes: data['notes'] ?? '',
      startDate: _parseDateTime(data['startDate']) ?? DateTime.now(),
      lastUpdated: _parseDateTime(data['lastUpdated']) ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      completedDate: _parseDateTime(data['completedDate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personId': personId,
      'workflowId': workflowId,
      'currentStep': currentStep,
      'completedSteps': completedSteps,
      'notes': notes,
      'startDate': startDate,
      'lastUpdated': lastUpdated,
      'status': status,
      'completedDate': completedDate,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';
  bool get isPaused => status == 'paused';

  PersonWorkflowModel copyWith({
    String? id,
    String? personId,
    String? workflowId,
    int? currentStep,
    List<String>? completedSteps,
    String? notes,
    DateTime? startDate,
    DateTime? lastUpdated,
    String? status,
    DateTime? completedDate,
  }) {
    return PersonWorkflowModel(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      workflowId: workflowId ?? this.workflowId,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}
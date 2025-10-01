import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour représenter une personne
class Person {
  final String? id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? country;
  final DateTime? birthDate;
  final String? gender;
  final String? maritalStatus;
  final String? address;
  final String? additionalAddress;
  final String? zipCode;
  final String? city;
  final String? profileImageUrl;
  final List<String> roles;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Person({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.country,
    this.birthDate,
    this.gender,
    this.maritalStatus,
    this.address,
    this.additionalAddress,
    this.zipCode,
    this.city,
    this.profileImageUrl,
    this.roles = const [],
    this.customFields = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Nom complet de la personne
  String get fullName => '$firstName $lastName';

  /// Âge calculé à partir de la date de naissance
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      return age - 1;
    }
    return age;
  }

  /// Vérifier si la personne a un rôle spécifique
  bool hasRole(String role) {
    return roles.contains(role);
  }

  /// Obtenir la valeur d'un champ personnalisé
  T? getCustomField<T>(String fieldName) {
    return customFields[fieldName] as T?;
  }

  /// Créer une copie avec des modifications
  Person copyWith({
    String? id,
    String? firstName,
    String? lastName,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Person(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      address: address ?? this.address,
      additionalAddress: additionalAddress ?? this.additionalAddress,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      roles: roles ?? this.roles,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Créer depuis Map de Firestore avec gestion des Timestamps
  factory Person.fromMap(Map<String, dynamic> map, String id) {
    return Person(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'],
      phone: map['phone'],
      country: map['country'],
      birthDate: _parseDateTime(map['birthDate']),
      gender: map['gender'],
      maritalStatus: map['maritalStatus'],
      address: map['address'],
      additionalAddress: map['additionalAddress'],
      zipCode: map['zipCode'],
      city: map['city'],
      profileImageUrl: map['profileImageUrl'],
      roles: List<String>.from(map['roles'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convertir de manière sécurisée un champ en DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Erreur lors du parsing de la date: $value - $e');
        return null;
      }
    }
    
    return null;
  }

  @override
  String toString() {
    return 'Person(id: $id, fullName: $fullName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
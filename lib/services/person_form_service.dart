import '../models/person_model.dart';

/// Service pour gérer la logique métier du formulaire de personne
/// Sépare la logique de validation et de transformation des données de l'UI
class PersonFormService {
  
  /// Valide et nettoie les données du formulaire
  static PersonFormData validateAndSanitizeFormData({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    List<String>? children,
    List<String>? tags,
    List<String>? roles,
    Map<String, dynamic>? customFields,
    String? profileImageUrl,
    String? privateNotes,
    bool isActive = true,
  }) {
    // Nettoyer et valider les données
    final cleanFirstName = _sanitizeString(firstName);
    final cleanLastName = _sanitizeString(lastName);
    final cleanEmail = _sanitizeEmail(email);
    
    // Validation des champs obligatoires
    final errors = <String>[];
    
    if (cleanFirstName.isEmpty) {
      errors.add('Le prénom est obligatoire');
    }
    
    if (cleanLastName.isEmpty) {
      errors.add('Le nom est obligatoire');
    }
    
    if (cleanEmail.isEmpty) {
      errors.add('L\'email est obligatoire');
    } else if (!_isValidEmail(cleanEmail)) {
      errors.add('L\'email n\'est pas valide');
    }
    
    if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
      errors.add('Le numéro de téléphone n\'est pas valide');
    }
    
    return PersonFormData(
      firstName: cleanFirstName,
      lastName: cleanLastName,
      email: cleanEmail,
      phone: phone,
      address: address,
      birthDate: birthDate,
      gender: gender,
      maritalStatus: maritalStatus,
      children: children ?? [],
      tags: tags ?? [],
      roles: roles ?? [],
      customFields: customFields ?? {},
      profileImageUrl: profileImageUrl,
      privateNotes: _sanitizeString(privateNotes),
      isActive: isActive,
      errors: errors,
    );
  }
  
  /// Construit l'adresse complète à partir des composants
  static String? buildFullAddress({
    String? address,
    String? addressComplement,
    String? postalCode,
    String? city,
  }) {
    final parts = <String>[];
    
    if (address?.trim().isNotEmpty == true) {
      parts.add(address!.trim());
    }
    
    if (addressComplement?.trim().isNotEmpty == true) {
      parts.add(addressComplement!.trim());
    }
    
    final cityParts = <String>[];
    if (postalCode?.trim().isNotEmpty == true) {
      cityParts.add(postalCode!.trim());
    }
    if (city?.trim().isNotEmpty == true) {
      cityParts.add(city!.trim());
    }
    
    if (cityParts.isNotEmpty) {
      parts.add(cityParts.join(' '));
    }
    
    return parts.isEmpty ? null : parts.join(', ');
  }
  
  /// Construit le numéro de téléphone complet
  static String? buildFullPhone(String? countryCode, String? phone) {
    if (phone?.trim().isNotEmpty == true && countryCode?.isNotEmpty == true) {
      return '$countryCode ${phone!.trim()}';
    }
    return phone?.trim().isNotEmpty == true ? phone!.trim() : null;
  }
  
  /// Parse un numéro de téléphone existant
  static PhoneData parseExistingPhone(String? phone, Map<String, String> countryCodes) {
    if (phone == null || phone.isEmpty) {
      return PhoneData(
        countryCode: '+33',
        country: 'France',
        number: '',
      );
    }

    // Rechercher un code de pays dans le numéro de téléphone
    for (var entry in countryCodes.entries) {
      if (phone.startsWith(entry.key)) {
        return PhoneData(
          countryCode: entry.key,
          country: entry.value,
          number: phone.substring(entry.key.length).trim(),
        );
      }
    }

    // Si aucun code pays trouvé, utiliser France par défaut
    return PhoneData(
      countryCode: '+33',
      country: 'France',
      number: phone,
    );
  }
  
  /// Parse une adresse existante
  static AddressData parseExistingAddress(String? address) {
    if (address == null || address.isEmpty) {
      return AddressData(
        address: '',
        addressComplement: '',
        postalCode: '',
        city: '',
      );
    }
    
    // Logique simple de parsing - peut être améliorée
    final parts = address.split(', ');
    
    if (parts.length >= 3) {
      final lastPart = parts.last.split(' ');
      return AddressData(
        address: parts.first,
        addressComplement: parts.length > 3 ? parts[1] : '',
        postalCode: lastPart.length > 1 ? lastPart.first : '',
        city: lastPart.length > 1 ? lastPart.skip(1).join(' ') : lastPart.first,
      );
    } else if (parts.length == 2) {
      return AddressData(
        address: parts.first,
        addressComplement: '',
        postalCode: '',
        city: parts.last,
      );
    } else {
      return AddressData(
        address: address,
        addressComplement: '',
        postalCode: '',
        city: '',
      );
    }
  }
  
  // Méthodes privées de validation et nettoyage
  static String _sanitizeString(String? input) {
    return input?.trim() ?? '';
  }
  
  static String _sanitizeEmail(String? email) {
    return email?.trim().toLowerCase() ?? '';
  }
  
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
  
  static bool _isValidPhone(String phone) {
    // Validation basique - peut être améliorée
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanPhone.length >= 10 && cleanPhone.length <= 15;
  }
}

/// Modèle pour les données du formulaire validées
class PersonFormData {
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final DateTime? birthDate;
  final String? gender;
  final String? maritalStatus;
  final List<String> children;
  final List<String> tags;
  final List<String> roles;
  final Map<String, dynamic> customFields;
  final String? profileImageUrl;
  final String? privateNotes;
  final bool isActive;
  final List<String> errors;
  
  const PersonFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.birthDate,
    this.gender,
    this.maritalStatus,
    required this.children,
    required this.tags,
    required this.roles,
    required this.customFields,
    this.profileImageUrl,
    this.privateNotes,
    required this.isActive,
    required this.errors,
  });
  
  bool get isValid => errors.isEmpty;
  
  /// Convertit en PersonModel pour la sauvegarde
  PersonModel toPersonModel({
    String? id,
    DateTime? createdAt,
    String? lastModifiedBy,
  }) {
    final now = DateTime.now();
    
    return PersonModel(
      id: id ?? '',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      birthDate: birthDate,
      address: address,
      gender: gender,
      maritalStatus: maritalStatus,
      children: children,
      profileImageUrl: profileImageUrl,
      privateNotes: privateNotes?.isEmpty == true ? null : privateNotes,
      isActive: isActive,
      createdAt: createdAt ?? now,
      updatedAt: now,
      tags: tags,
      roles: roles,
      customFields: customFields,
      lastModifiedBy: lastModifiedBy,
    );
  }
}

/// Modèle pour les données de téléphone
class PhoneData {
  final String countryCode;
  final String country;
  final String number;
  
  const PhoneData({
    required this.countryCode,
    required this.country,
    required this.number,
  });
}

/// Modèle pour les données d'adresse
class AddressData {
  final String address;
  final String addressComplement;
  final String postalCode;
  final String city;
  
  const AddressData({
    required this.address,
    required this.addressComplement,
    required this.postalCode,
    required this.city,
  });
}
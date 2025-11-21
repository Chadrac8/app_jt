import 'package:flutter/material.dart';

/// Classe utilitaire pour les validations de formulaire
/// Centralise toutes les validations et les rend réutilisables
class FormValidators {
  
  /// Validateur pour les champs obligatoires
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est obligatoire';
    }
    return null;
  }
  
  /// Validateur pour le prénom
  static String? firstName(String? value) {
    final requiredError = required(value, fieldName: 'Le prénom');
    if (requiredError != null) return requiredError;
    
    if (value!.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    
    if (value.trim().length > 50) {
      return 'Le prénom ne peut pas dépasser 50 caractères';
    }
    
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-\u0027]+$').hasMatch(value.trim())) {
      return 'Le prénom contient des caractères non autorisés';
    }
    
    return null;
  }
  
  /// Validateur pour le nom de famille
  static String? lastName(String? value) {
    final requiredError = required(value, fieldName: 'Le nom');
    if (requiredError != null) return requiredError;
    
    if (value!.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    
    if (value.trim().length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }
    
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-\u0027]+$').hasMatch(value.trim())) {
      return 'Le nom contient des caractères non autorisés';
    }
    
    return null;
  }
  
  /// Validateur pour l'email
  static String? email(String? value) {
    final requiredError = required(value, fieldName: 'L\'email');
    if (requiredError != null) return requiredError;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Veuillez saisir un email valide';
    }
    
    if (value.trim().length > 100) {
      return 'L\'email ne peut pas dépasser 100 caractères';
    }
    
    return null;
  }
  
  /// Validateur pour le téléphone (optionnel)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Le téléphone est optionnel
    }
    
    // Nettoyer le numéro (garder seulement les chiffres, espaces, +, -, ())
    final cleanValue = value.replaceAll(RegExp(r'[^\d\s\+\-\(\)]'), '');
    
    if (cleanValue.length < 10) {
      return 'Le numéro de téléphone doit contenir au moins 10 chiffres';
    }
    
    if (cleanValue.length > 20) {
      return 'Le numéro de téléphone ne peut pas dépasser 20 caractères';
    }
    
    return null;
  }
  
  /// Validateur pour l'adresse (optionnel)
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // L'adresse est optionnelle
    }
    
    if (value.trim().length < 5) {
      return 'L\'adresse doit contenir au moins 5 caractères';
    }
    
    if (value.trim().length > 200) {
      return 'L\'adresse ne peut pas dépasser 200 caractères';
    }
    
    return null;
  }
  
  /// Validateur pour le code postal
  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Le code postal est optionnel
    }
    
    // Validation pour code postal français (5 chiffres)
    if (!RegExp(r'^\d{5}$').hasMatch(value.trim())) {
      return 'Le code postal doit contenir exactement 5 chiffres';
    }
    
    return null;
  }
  
  /// Validateur pour la ville
  static String? city(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // La ville est optionnelle
    }
    
    if (value.trim().length < 2) {
      return 'Le nom de la ville doit contenir au moins 2 caractères';
    }
    
    if (value.trim().length > 50) {
      return 'Le nom de la ville ne peut pas dépasser 50 caractères';
    }
    
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-\u0027]+$').hasMatch(value.trim())) {
      return 'Le nom de la ville contient des caractères non autorisés';
    }
    
    return null;
  }
  
  /// Validateur pour les notes privées
  static String? privateNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Les notes sont optionnelles
    }
    
    if (value.trim().length > 1000) {
      return 'Les notes ne peuvent pas dépasser 1000 caractères';
    }
    
    return null;
  }
  
  /// Validateur pour la date de naissance
  static String? birthDate(DateTime? value) {
    if (value == null) {
      return null; // La date de naissance est optionnelle
    }
    
    final now = DateTime.now();
    final minDate = DateTime(now.year - 120, now.month, now.day);
    final maxDate = DateTime(now.year - 1, now.month, now.day);
    
    if (value.isBefore(minDate)) {
      return 'La date de naissance ne peut pas être antérieure à ${minDate.year}';
    }
    
    if (value.isAfter(maxDate)) {
      return 'La personne doit avoir au moins 1 an';
    }
    
    if (value.isAfter(now)) {
      return 'La date de naissance ne peut pas être dans le futur';
    }
    
    return null;
  }
  
  /// Combinateur de validateurs
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
  
  /// Validateur conditionnel
  static String? Function(String?) conditional(
    bool condition,
    String? Function(String?) validator,
  ) {
    return (String? value) {
      if (condition) {
        return validator(value);
      }
      return null;
    };
  }
}

/// Extension pour faciliter l'utilisation des validateurs sur TextFormField
extension TextFormFieldValidation on TextFormField {
  /// Crée un TextFormField avec validation pré-configurée pour le prénom
  static TextFormField firstName({
    required TextEditingController controller,
    String? hintText,
    Widget? prefixIcon,
    bool enabled = true,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Prénom *',
        hintText: hintText ?? 'Entrez le prénom',
        prefixIcon: prefixIcon ?? const Icon(Icons.person),
        border: const OutlineInputBorder(),
      ),
      validator: FormValidators.firstName,
    );
  }
  
  /// Crée un TextFormField avec validation pré-configurée pour le nom
  static TextFormField lastName({
    required TextEditingController controller,
    String? hintText,
    Widget? prefixIcon,
    bool enabled = true,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Nom *',
        hintText: hintText ?? 'Entrez le nom de famille',
        prefixIcon: prefixIcon ?? const Icon(Icons.person),
        border: const OutlineInputBorder(),
      ),
      validator: FormValidators.lastName,
    );
  }
  
  /// Crée un TextFormField avec validation pré-configurée pour l'email
  static TextFormField email({
    required TextEditingController controller,
    String? hintText,
    Widget? prefixIcon,
    bool enabled = true,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Email *',
        hintText: hintText ?? 'exemple@domaine.com',
        prefixIcon: prefixIcon ?? const Icon(Icons.email),
        border: const OutlineInputBorder(),
      ),
      validator: FormValidators.email,
    );
  }
  
  /// Crée un TextFormField avec validation pré-configurée pour le téléphone
  static TextFormField phone({
    required TextEditingController controller,
    String? hintText,
    Widget? prefixIcon,
    bool enabled = true,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Téléphone',
        hintText: hintText ?? '01 23 45 67 89',
        prefixIcon: prefixIcon ?? const Icon(Icons.phone),
        border: const OutlineInputBorder(),
      ),
      validator: FormValidators.phone,
    );
  }
}

/// Widget personnalisé pour les validations en temps réel
class ValidatedTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final bool validateOnChange;
  
  const ValidatedTextFormField({
    super.key,
    required this.controller,
    required this.validator,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.validateOnChange = true,
  });

  @override
  State<ValidatedTextFormField> createState() => _ValidatedTextFormFieldState();
}

class _ValidatedTextFormFieldState extends State<ValidatedTextFormField> {
  String? _errorText;
  bool _hasBeenTouched = false;

  @override
  void initState() {
    super.initState();
    if (widget.validateOnChange) {
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    if (widget.validateOnChange) {
      widget.controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasBeenTouched) {
      setState(() {
        _errorText = widget.validator(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: () {
        setState(() {
          _hasBeenTouched = true;
        });
      },
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        border: const OutlineInputBorder(),
        errorText: _errorText,
        errorMaxLines: 2,
      ),
      validator: (value) {
        _hasBeenTouched = true;
        final error = widget.validator(value);
        if (mounted) {
          setState(() {
            _errorText = error;
          });
        }
        return error;
      },
    );
  }
}
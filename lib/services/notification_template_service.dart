import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Modèle pour les templates de notifications
class NotificationTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String titleTemplate;
  final String bodyTemplate;
  final String? imageUrlTemplate;
  final List<NotificationActionTemplate> actionTemplates;
  final Map<String, TemplateVariable> variables;
  final Map<String, dynamic> defaultValues;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String> tags;
  final TemplateType type;

  NotificationTemplate({
    String? id,
    required this.name,
    required this.description,
    required this.category,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.imageUrlTemplate,
    List<NotificationActionTemplate>? actionTemplates,
    Map<String, TemplateVariable>? variables,
    Map<String, dynamic>? defaultValues,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdBy,
    List<String>? tags,
    this.type = TemplateType.standard,
  }) : 
    id = id ?? const Uuid().v4(),
    actionTemplates = actionTemplates ?? [],
    variables = variables ?? {},
    defaultValues = defaultValues ?? {},
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    tags = tags ?? [];

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      titleTemplate: json['titleTemplate'],
      bodyTemplate: json['bodyTemplate'],
      imageUrlTemplate: json['imageUrlTemplate'],
      actionTemplates: (json['actionTemplates'] as List<dynamic>?)
          ?.map((action) => NotificationActionTemplate.fromJson(action))
          .toList() ?? [],
      variables: (json['variables'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, TemplateVariable.fromJson(value)))
          ?? {},
      defaultValues: Map<String, dynamic>.from(json['defaultValues'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      tags: List<String>.from(json['tags'] ?? []),
      type: TemplateType.values[json['type'] ?? 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'titleTemplate': titleTemplate,
      'bodyTemplate': bodyTemplate,
      'imageUrlTemplate': imageUrlTemplate,
      'actionTemplates': actionTemplates.map((action) => action.toJson()).toList(),
      'variables': variables.map((key, value) => MapEntry(key, value.toJson())),
      'defaultValues': defaultValues,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'tags': tags,
      'type': type.index,
    };
  }
}

/// Template pour les actions
class NotificationActionTemplate {
  final String id;
  final String titleTemplate;
  final String type;
  final Map<String, String> dataTemplates;
  final String? iconTemplate;
  final bool isDestructive;

  const NotificationActionTemplate({
    required this.id,
    required this.titleTemplate,
    required this.type,
    this.dataTemplates = const {},
    this.iconTemplate,
    this.isDestructive = false,
  });

  factory NotificationActionTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationActionTemplate(
      id: json['id'],
      titleTemplate: json['titleTemplate'],
      type: json['type'],
      dataTemplates: Map<String, String>.from(json['dataTemplates'] ?? {}),
      iconTemplate: json['iconTemplate'],
      isDestructive: json['isDestructive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleTemplate': titleTemplate,
      'type': type,
      'dataTemplates': dataTemplates,
      'iconTemplate': iconTemplate,
      'isDestructive': isDestructive,
    };
  }
}

/// Variable de template
class TemplateVariable {
  final String name;
  final String description;
  final VariableType type;
  final bool isRequired;
  final dynamic defaultValue;
  final List<String>? allowedValues;
  final String? validationPattern;

  const TemplateVariable({
    required this.name,
    required this.description,
    required this.type,
    this.isRequired = false,
    this.defaultValue,
    this.allowedValues,
    this.validationPattern,
  });

  factory TemplateVariable.fromJson(Map<String, dynamic> json) {
    return TemplateVariable(
      name: json['name'],
      description: json['description'],
      type: VariableType.values[json['type']],
      isRequired: json['isRequired'] ?? false,
      defaultValue: json['defaultValue'],
      allowedValues: json['allowedValues']?.cast<String>(),
      validationPattern: json['validationPattern'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type.index,
      'isRequired': isRequired,
      'defaultValue': defaultValue,
      'allowedValues': allowedValues,
      'validationPattern': validationPattern,
    };
  }
}

/// Types de templates
enum TemplateType {
  standard,
  rich,
  interactive,
  scheduled
}

/// Types de variables
enum VariableType {
  text,
  number,
  date,
  time,
  datetime,
  email,
  url,
  phone,
  select,
  boolean
}

/// Service de gestion des templates
class NotificationTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un nouveau template
  Future<NotificationTemplate> createTemplate(NotificationTemplate template) async {
    await _firestore
        .collection('notificationTemplates')
        .doc(template.id)
        .set(template.toJson());
    return template;
  }

  /// Récupérer tous les templates
  Future<List<NotificationTemplate>> getAllTemplates() async {
    final snapshot = await _firestore
        .collection('notificationTemplates')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => NotificationTemplate.fromJson(doc.data()))
        .toList();
  }

  /// Récupérer les templates par catégorie
  Future<List<NotificationTemplate>> getTemplatesByCategory(String category) async {
    final snapshot = await _firestore
        .collection('notificationTemplates')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => NotificationTemplate.fromJson(doc.data()))
        .toList();
  }

  /// Récupérer un template par ID
  Future<NotificationTemplate?> getTemplateById(String templateId) async {
    final doc = await _firestore
        .collection('notificationTemplates')
        .doc(templateId)
        .get();
    
    if (doc.exists) {
      return NotificationTemplate.fromJson(doc.data()!);
    }
    return null;
  }

  /// Mettre à jour un template
  Future<void> updateTemplate(NotificationTemplate template) async {
    final updatedTemplate = template.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('notificationTemplates')
        .doc(template.id)
        .update(updatedTemplate.toJson());
  }

  /// Supprimer un template
  Future<void> deleteTemplate(String templateId) async {
    await _firestore
        .collection('notificationTemplates')
        .doc(templateId)
        .update({'isActive': false});
  }

  /// Rendre un template à partir de variables
  Map<String, dynamic> renderTemplate(
    NotificationTemplate template,
    Map<String, dynamic> variables,
  ) {
    // Fusionner avec les valeurs par défaut
    final allVariables = Map<String, dynamic>.from(template.defaultValues);
    allVariables.addAll(variables);

    // Valider les variables requises
    for (final variable in template.variables.values) {
      if (variable.isRequired && !allVariables.containsKey(variable.name)) {
        throw Exception('Variable requise manquante: ${variable.name}');
      }
    }

    return {
      'title': _renderString(template.titleTemplate, allVariables),
      'body': _renderString(template.bodyTemplate, allVariables),
      'imageUrl': template.imageUrlTemplate != null 
          ? _renderString(template.imageUrlTemplate!, allVariables)
          : null,
      'actions': template.actionTemplates.map((actionTemplate) {
        return {
          'id': actionTemplate.id,
          'title': _renderString(actionTemplate.titleTemplate, allVariables),
          'type': actionTemplate.type,
          'data': actionTemplate.dataTemplates.map((key, value) => 
              MapEntry(key, _renderString(value, allVariables))),
          'icon': actionTemplate.iconTemplate != null
              ? _renderString(actionTemplate.iconTemplate!, allVariables)
              : null,
          'isDestructive': actionTemplate.isDestructive,
        };
      }).toList(),
    };
  }

  /// Rechercher des templates
  Future<List<NotificationTemplate>> searchTemplates({
    String? query,
    String? category,
    List<String>? tags,
  }) async {
    Query<Map<String, dynamic>> queryRef = _firestore
        .collection('notificationTemplates')
        .where('isActive', isEqualTo: true);

    if (category != null) {
      queryRef = queryRef.where('category', isEqualTo: category);
    }

    final snapshot = await queryRef.get();
    List<NotificationTemplate> templates = snapshot.docs
        .map((doc) => NotificationTemplate.fromJson(doc.data()))
        .toList();

    // Filtrer par requête de recherche
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      templates = templates.where((template) =>
          template.name.toLowerCase().contains(lowerQuery) ||
          template.description.toLowerCase().contains(lowerQuery) ||
          template.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
      ).toList();
    }

    // Filtrer par tags
    if (tags != null && tags.isNotEmpty) {
      templates = templates.where((template) =>
          tags.any((tag) => template.tags.contains(tag))
      ).toList();
    }

    return templates;
  }

  /// Dupliquer un template
  Future<NotificationTemplate> duplicateTemplate(String templateId, String newName) async {
    final original = await getTemplateById(templateId);
    if (original == null) {
      throw Exception('Template introuvable');
    }

    final duplicate = original.copyWith(
      id: const Uuid().v4(),
      name: newName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await createTemplate(duplicate);
  }

  /// Valider un template
  List<String> validateTemplate(NotificationTemplate template) {
    final errors = <String>[];

    // Vérifier que le titre n'est pas vide
    if (template.titleTemplate.trim().isEmpty) {
      errors.add('Le titre du template ne peut pas être vide');
    }

    // Vérifier que le body n'est pas vide
    if (template.bodyTemplate.trim().isEmpty) {
      errors.add('Le corps du template ne peut pas être vide');
    }

    // Vérifier les variables utilisées dans les templates
    final usedVariables = <String>{};
    usedVariables.addAll(_extractVariables(template.titleTemplate));
    usedVariables.addAll(_extractVariables(template.bodyTemplate));
    
    if (template.imageUrlTemplate != null) {
      usedVariables.addAll(_extractVariables(template.imageUrlTemplate!));
    }

    for (final actionTemplate in template.actionTemplates) {
      usedVariables.addAll(_extractVariables(actionTemplate.titleTemplate));
      for (final dataTemplate in actionTemplate.dataTemplates.values) {
        usedVariables.addAll(_extractVariables(dataTemplate));
      }
    }

    // Vérifier que toutes les variables utilisées sont définies
    for (final usedVar in usedVariables) {
      if (!template.variables.containsKey(usedVar)) {
        errors.add('Variable non définie utilisée: $usedVar');
      }
    }

    return errors;
  }

  /// Rendre une chaîne avec des variables
  String _renderString(String template, Map<String, dynamic> variables) {
    String result = template;
    
    // Remplacer les variables {{variable}}
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(template);
    
    for (final match in matches) {
      final variableName = match.group(1)!.trim();
      if (variables.containsKey(variableName)) {
        result = result.replaceAll(match.group(0)!, variables[variableName].toString());
      }
    }
    
    return result;
  }

  /// Extraire les variables d'un template
  Set<String> _extractVariables(String template) {
    final variables = <String>{};
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(template);
    
    for (final match in matches) {
      variables.add(match.group(1)!.trim());
    }
    
    return variables;
  }
}

/// Extension pour NotificationTemplate
extension NotificationTemplateExtension on NotificationTemplate {
  NotificationTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? titleTemplate,
    String? bodyTemplate,
    String? imageUrlTemplate,
    List<NotificationActionTemplate>? actionTemplates,
    Map<String, TemplateVariable>? variables,
    Map<String, dynamic>? defaultValues,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? tags,
    TemplateType? type,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      titleTemplate: titleTemplate ?? this.titleTemplate,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      imageUrlTemplate: imageUrlTemplate ?? this.imageUrlTemplate,
      actionTemplates: actionTemplates ?? this.actionTemplates,
      variables: variables ?? this.variables,
      defaultValues: defaultValues ?? this.defaultValues,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      type: type ?? this.type,
    );
  }
}

/// Templates prédéfinis pour une église
class ChurchTemplatePresets {
  static NotificationTemplate welcomeTemplate(String createdBy) {
    return NotificationTemplate(
      name: 'Bienvenue nouveau membre',
      description: 'Template de bienvenue pour les nouveaux membres',
      category: 'Accueil',
      titleTemplate: 'Bienvenue {{firstName}} !',
      bodyTemplate: 'Nous sommes ravis de vous accueillir dans notre communauté. Votre première réunion est prévue le {{meetingDate}}.',
      variables: {
        'firstName': const TemplateVariable(
          name: 'firstName',
          description: 'Prénom du nouveau membre',
          type: VariableType.text,
          isRequired: true,
        ),
        'meetingDate': const TemplateVariable(
          name: 'meetingDate',
          description: 'Date de la première réunion',
          type: VariableType.date,
          isRequired: true,
        ),
      },
      actionTemplates: [
        const NotificationActionTemplate(
          id: 'view_welcome_guide',
          titleTemplate: 'Guide d\'accueil',
          type: 'view',
          dataTemplates: {'url': '/welcome-guide'},
        ),
      ],
      tags: ['accueil', 'nouveau', 'membre'],
      createdBy: createdBy,
    );
  }

  static NotificationTemplate eventReminderTemplate(String createdBy) {
    return NotificationTemplate(
      name: 'Rappel d\'événement',
      description: 'Template pour rappeler un événement',
      category: 'Événements',
      titleTemplate: 'Rappel: {{eventName}}',
      bodyTemplate: 'N\'oubliez pas: {{eventName}} commence dans {{timeUntil}} à {{location}}.',
      variables: {
        'eventName': const TemplateVariable(
          name: 'eventName',
          description: 'Nom de l\'événement',
          type: VariableType.text,
          isRequired: true,
        ),
        'timeUntil': const TemplateVariable(
          name: 'timeUntil',
          description: 'Temps avant l\'événement',
          type: VariableType.text,
          isRequired: true,
        ),
        'location': const TemplateVariable(
          name: 'location',
          description: 'Lieu de l\'événement',
          type: VariableType.text,
          isRequired: true,
        ),
      },
      actionTemplates: [
        const NotificationActionTemplate(
          id: 'view_event',
          titleTemplate: 'Voir l\'événement',
          type: 'view',
          dataTemplates: {'url': '/events/{{eventId}}'},
        ),
        const NotificationActionTemplate(
          id: 'set_reminder',
          titleTemplate: 'Programmer rappel',
          type: 'remind',
          dataTemplates: {'eventId': '{{eventId}}'},
        ),
      ],
      tags: ['événement', 'rappel'],
      createdBy: createdBy,
    );
  }

  static NotificationTemplate prayerRequestTemplate(String createdBy) {
    return NotificationTemplate(
      name: 'Demande de prière',
      description: 'Template pour les demandes de prière',
      category: 'Prière',
      titleTemplate: 'Nouvelle demande de prière',
      bodyTemplate: '{{requesterName}} demande vos prières pour: {{request}}',
      variables: {
        'requesterName': const TemplateVariable(
          name: 'requesterName',
          description: 'Nom de la personne qui demande',
          type: VariableType.text,
          isRequired: true,
        ),
        'request': const TemplateVariable(
          name: 'request',
          description: 'Demande de prière',
          type: VariableType.text,
          isRequired: true,
        ),
      },
      actionTemplates: [
        const NotificationActionTemplate(
          id: 'pray_now',
          titleTemplate: 'Prier maintenant',
          type: 'action',
          dataTemplates: {'action': 'pray'},
        ),
        const NotificationActionTemplate(
          id: 'view_request',
          titleTemplate: 'Voir la demande',
          type: 'view',
          dataTemplates: {'url': '/prayer-requests/{{requestId}}'},
        ),
      ],
      tags: ['prière', 'demande'],
      createdBy: createdBy,
    );
  }
}

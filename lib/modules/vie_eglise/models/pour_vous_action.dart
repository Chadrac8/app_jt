import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Wrapper pour distinguer "paramètre non fourni" de "paramètre = null"
class Optional<T> {
  final T? value;
  final bool isSet;
  
  const Optional.value(this.value) : isSet = true;
  const Optional.unset() : value = null, isSet = false;
}

/// Modèle pour les actions "Pour vous" dans le module Vie de l'église
class PourVousAction {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String iconCodePoint; // Pour stocker l'icône en Firestore
  final String actionType; // 'navigation', 'form', 'external'
  final String? targetModule; // Module de destination pour la navigation
  final String? targetRoute; // Route spécifique
  final Map<String, dynamic>? actionData; // Données supplémentaires pour l'action
  final bool isActive;
  final int order; // Ordre d'affichage
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? color; // Couleur hexadécimale optionnelle
  final String? groupId; // ID du groupe auquel appartient l'action
  final String? backgroundImageUrl; // URL de l'image de fond
  final String? category; // Catégorie pour le groupement
  
  // Nouveaux champs pour personnalisation avancée
  final String? iconColor; // Couleur de l'icône (null = auto)
  final String? backgroundColor; // Couleur d'arrière-plan (prioritaire sur color si défini)
  final String? textColor; // Couleur du texte (null = auto basé sur contraste)
  final bool showIcon; // Afficher ou masquer l'icône

  PourVousAction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconCodePoint,
    this.actionType = 'navigation',
    this.targetModule,
    this.targetRoute,
    this.actionData,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.color,
    this.groupId,
    this.backgroundImageUrl,
    this.category,
    this.iconColor,
    this.backgroundColor,
    this.textColor,
    this.showIcon = true,
  });

  factory PourVousAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PourVousAction(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: _iconFromData(data),
      iconCodePoint: data['iconCodePoint']?.toString() ?? Icons.help_outline.codePoint.toString(),
      actionType: data['actionType'] ?? 'navigation',
      targetModule: data['targetModule'],
      targetRoute: data['targetRoute'],
      actionData: data['actionData'],
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      color: data['color'],
      groupId: data['groupId'],
      backgroundImageUrl: data['backgroundImageUrl'],
      category: data['category'],
      iconColor: data['iconColor'],
      backgroundColor: data['backgroundColor'],
      textColor: data['textColor'],
      showIcon: data['showIcon'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'iconCodePoint': int.parse(iconCodePoint),
      'actionType': actionType,
      'targetModule': targetModule,
      'targetRoute': targetRoute,
      'actionData': actionData,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'color': color,
      'groupId': groupId,
      'backgroundImageUrl': backgroundImageUrl,
      'category': category,
      'iconColor': iconColor,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'showIcon': showIcon,
    };
  }

  PourVousAction copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    String? iconCodePoint,
    String? actionType,
    String? targetModule,
    String? targetRoute,
    Map<String, dynamic>? actionData,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? color,
    String? groupId,
    Optional<String>? backgroundImageUrl,
    String? category,
    Optional<String>? iconColor,
    Optional<String>? backgroundColor,
    Optional<String>? textColor,
    bool? showIcon,
  }) {
    return PourVousAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      actionType: actionType ?? this.actionType,
      targetModule: targetModule ?? this.targetModule,
      targetRoute: targetRoute ?? this.targetRoute,
      actionData: actionData ?? this.actionData,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      color: color ?? this.color,
      groupId: groupId ?? this.groupId,
      backgroundImageUrl: backgroundImageUrl != null && backgroundImageUrl.isSet 
          ? backgroundImageUrl.value 
          : this.backgroundImageUrl,
      category: category ?? this.category,
      iconColor: iconColor != null && iconColor.isSet 
          ? iconColor.value 
          : this.iconColor,
      backgroundColor: backgroundColor != null && backgroundColor.isSet 
          ? backgroundColor.value 
          : this.backgroundColor,
      textColor: textColor != null && textColor.isSet 
          ? textColor.value 
          : this.textColor,
      showIcon: showIcon ?? this.showIcon,
    );
  }

  /// Actions prédéfinies par défaut
  static List<PourVousAction> getDefaultActions() {
    final now = DateTime.now();
    
    return [
      PourVousAction(
        id: 'bapteme',
        title: 'Prendre le baptême',
        description: 'Faire une demande de baptême',
        icon: Icons.water_drop,
        iconCodePoint: Icons.water_drop.codePoint.toString(),
        actionType: 'form',
        order: 1,
        createdAt: now,
        updatedAt: now,
        color: '#2196F3',
      ),
      PourVousAction(
        id: 'rdv_pasteur',
        title: 'Rendez-vous avec le pasteur',
        description: 'Prendre un rendez-vous personnel',
        icon: Icons.person_add,
        iconCodePoint: Icons.person_add.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'rendez_vous',
        order: 2,
        createdAt: now,
        updatedAt: now,
        color: '#4CAF50',
      ),
      PourVousAction(
        id: 'rejoindre_equipe',
        title: 'Rejoindre une équipe',
        description: 'Intégrer un groupe ou une équipe',
        icon: Icons.group_add,
        iconCodePoint: Icons.group_add.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'groupes',
        order: 3,
        createdAt: now,
        updatedAt: now,
        color: '#FF9800',
      ),
      PourVousAction(
        id: 'requetes_priere',
        title: 'Requêtes de prière',
        description: 'Demander une prière ou prier pour d\'autres',
        icon: Icons.favorite,
        iconCodePoint: Icons.favorite.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'mur_priere',
        order: 4,
        createdAt: now,
        updatedAt: now,
        color: '#E91E63',
      ),
      PourVousAction(
        id: 'question_pasteur',
        title: 'Poser une question au pasteur',
        description: 'Envoyer une question personnelle',
        icon: Icons.help_outline,
        iconCodePoint: Icons.help_outline.codePoint.toString(),
        actionType: 'form',
        order: 5,
        createdAt: now,
        updatedAt: now,
        color: '#9C27B0',
      ),
      PourVousAction(
        id: 'proposer_idee',
        title: 'Proposer une idée',
        description: 'Partager une suggestion ou idée',
        icon: Icons.lightbulb_outline,
        iconCodePoint: Icons.lightbulb_outline.codePoint.toString(),
        actionType: 'form',
        order: 6,
        createdAt: now,
        updatedAt: now,
        color: '#FFC107',
      ),
      PourVousAction(
        id: 'chant_special',
        title: 'Chanter un chant spécial',
        description: 'Proposer un chant pour le service',
        icon: Icons.music_note,
        iconCodePoint: Icons.music_note.codePoint.toString(),
        actionType: 'form',
        order: 7,
        createdAt: now,
        updatedAt: now,
        color: '#673AB7',
      ),
      PourVousAction(
        id: 'infos_eglise',
        title: 'Informations sur l\'église',
        description: 'En savoir plus sur notre église',
        icon: Icons.info_outline,
        iconCodePoint: Icons.info_outline.codePoint.toString(),
        actionType: 'form',
        order: 8,
        createdAt: now,
        updatedAt: now,
        color: '#607D8B',
      ),
    ];
  }

  static IconData _iconFromData(Map<String, dynamic> data) {
    try {
      final codePointString = data['iconCodePoint'];
      if (codePointString != null) {
        final codePoint = int.tryParse(codePointString.toString());
        if (codePoint != null) {
          // Utilisation d'une constante pour permettre le tree shaking
          return const IconData(0xe88a, fontFamily: 'MaterialIcons'); // favorite icon par défaut
        }
      }
    } catch (e) {
      print('Erreur lors de la conversion de l\'icône: $e');
    }
    
    // Icône par défaut en cas d'erreur
    return Icons.help_outline;
  }
}

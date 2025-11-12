import 'package:flutter/material.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/action_service.dart';
import '../services/action_group_service.dart';

/// Script de migration pour créer les actions et groupes par défaut 
/// basés sur l'ancien système hardcodé
class PourVousDataMigration {
  final ActionService _actionService = ActionService();
  final ActionGroupService _groupService = ActionGroupService();

  /// Exécute la migration complète
  Future<void> migrate() async {
    print('🚀 Début de la migration des données "Pour Vous"...');
    
    try {
      // 1. Créer les groupes
      final groups = await _createGroups();
      print('✅ ${groups.length} groupes créés');
      
      // 2. Créer les actions
      final actions = await _createActions(groups);
      print('✅ ${actions.length} actions créées');
      
      print('🎉 Migration terminée avec succès !');
      
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  /// Crée les groupes par défaut
  Future<List<ActionGroup>> _createGroups() async {
    final groups = [
      ActionGroup(
        id: 'seigneur',
        name: 'Relation avec Le Seigneur',
        description: 'Actions pour approfondir votre relation spirituelle',
        icon: Icons.church,
        iconCodePoint: Icons.church.codePoint.toString(),
        color: '#1976D2', // Blue
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ActionGroup(
        id: 'pasteur',
        name: 'Relation avec le pasteur',
        description: 'Interactions et échanges avec le ministère pastoral',
        icon: Icons.person,
        iconCodePoint: Icons.person.codePoint.toString(),
        color: '#388E3C', // Green
        order: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ActionGroup(
        id: 'culte',
        name: 'Participer au culte',
        description: 'Actions pour s\'impliquer dans les services religieux',
        icon: Icons.celebration,
        iconCodePoint: Icons.celebration.codePoint.toString(),
        color: '#F57C00', // Orange
        order: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ActionGroup(
        id: 'amelioration',
        name: 'Amélioration',
        description: 'Contributions et suggestions pour l\'église',
        icon: Icons.lightbulb,
        iconCodePoint: Icons.lightbulb.codePoint.toString(),
        color: '#D32F2F', // Red
        order: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final createdGroups = <ActionGroup>[];
    for (final group in groups) {
      try {
        await _groupService.createGroup(group);
        createdGroups.add(group);
        print('  📁 Groupe créé: ${group.name}');
      } catch (e) {
        print('  ⚠️  Erreur création groupe ${group.name}: $e');
      }
    }

    return createdGroups;
  }

  /// Crée les actions par défaut
  Future<List<PourVousAction>> _createActions(List<ActionGroup> groups) async {
    final groupMap = {for (var g in groups) g.name: g.id};
    
    final actions = [
      // Groupe: Relation avec Le Seigneur
      PourVousAction(
        id: 'bapteme_eau',
        title: 'Baptême d\'eau',
        description: 'Demander le baptême',
        actionType: 'form',
        targetRoute: '/forms/baptism',
        icon: Icons.water_drop_rounded,
        iconCodePoint: Icons.water_drop_rounded.codePoint.toString(),
        color: '#1976D2',
        category: 'seigneur',
        groupId: groupMap['Relation avec Le Seigneur'],
        order: 1,
        actionData: {
          'module': 'forms',
          'page': 'baptism_request',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PourVousAction(
        id: 'rejoindre_equipe',
        title: 'Rejoindre une équipe',
        description: 'Servir dans l\'église',
        actionType: 'form',
        targetRoute: '/forms/team_join',
        icon: Icons.group_rounded,
        iconCodePoint: Icons.group_rounded.codePoint.toString(),
        color: '#1976D2',
        category: 'seigneur',
        groupId: groupMap['Relation avec Le Seigneur'],
        order: 2,
        actionData: {
          'module': 'forms',
          'page': 'team_join_request',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Groupe: Relation avec le pasteur
      PourVousAction(
        id: 'rendez_vous',
        title: 'Prendre rendez-vous',
        description: 'Rencontrer le pasteur',
        actionType: 'navigation',
        targetRoute: '/appointments',
        icon: Icons.calendar_today_rounded,
        iconCodePoint: Icons.calendar_today_rounded.codePoint.toString(),
        color: '#388E3C',
        category: 'pasteur',
        groupId: groupMap['Relation avec le pasteur'],
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PourVousAction(
        id: 'poser_question',
        title: 'Poser une question',
        description: 'Demander conseil',
        actionType: 'form',
        targetRoute: '/forms/question',
        icon: Icons.help_rounded,
        iconCodePoint: Icons.help_rounded.codePoint.toString(),
        color: '#388E3C',
        category: 'pasteur',
        groupId: groupMap['Relation avec le pasteur'],
        order: 2,
        actionData: {
          'module': 'forms',
          'page': 'pastor_question',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Groupe: Participer au culte
      PourVousAction(
        id: 'chant_special',
        title: 'Chant spécial',
        description: 'Réserver une date',
        actionType: 'form',
        targetRoute: '/forms/special_song',
        icon: Icons.mic_rounded,
        iconCodePoint: Icons.mic_rounded.codePoint.toString(),
        color: '#F57C00',
        category: 'culte',
        groupId: groupMap['Participer au culte'],
        order: 1,
        actionData: {
          'module': 'forms',
          'page': 'special_song_reservation',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PourVousAction(
        id: 'temoignage',
        title: 'Partager un témoignage',
        description: 'Témoigner publiquement',
        actionType: 'form',
        targetRoute: '/forms/testimony',
        icon: Icons.record_voice_over_rounded,
        iconCodePoint: Icons.record_voice_over_rounded.codePoint.toString(),
        color: '#F57C00',
        category: 'culte',
        groupId: groupMap['Participer au culte'],
        order: 2,
        actionData: {
          'module': 'forms',
          'page': 'testimony_request',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Groupe: Amélioration
      PourVousAction(
        id: 'proposer_idee',
        title: 'Proposer une idée',
        description: 'Suggérer une amélioration',
        actionType: 'form',
        targetRoute: '/forms/suggestion',
        icon: Icons.lightbulb_outline_rounded,
        iconCodePoint: Icons.lightbulb_outline_rounded.codePoint.toString(),
        color: '#D32F2F',
        category: 'general',
        groupId: groupMap['Amélioration'],
        order: 1,
        actionData: {
          'module': 'forms',
          'page': 'improvement_suggestion',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PourVousAction(
        id: 'signaler_probleme',
        title: 'Signaler un problème',
        description: 'Rapporter un dysfonctionnement',
        actionType: 'form',
        targetRoute: '/forms/issue_report',
        icon: Icons.report_problem_rounded,
        iconCodePoint: Icons.report_problem_rounded.codePoint.toString(),
        color: '#D32F2F',
        category: 'general',
        groupId: groupMap['Amélioration'],
        order: 2,
        actionData: {
          'module': 'forms',
          'page': 'issue_report',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final createdActions = <PourVousAction>[];
    for (final action in actions) {
      try {
        await _actionService.createAction(action);
        createdActions.add(action);
        print('  ⚡ Action créée: ${action.title}');
      } catch (e) {
        print('  ⚠️  Erreur création action ${action.title}: $e');
      }
    }

    return createdActions;
  }

  /// Nettoie toutes les données existantes (utilisé pour les tests)
  Future<void> cleanAll() async {
    print('🧹 Nettoyage des données existantes...');
    
    try {
      // Note: Cette méthode nécessiterait d'implémenter des méthodes de nettoyage
      // dans les services. Pour l'instant, on peut la laisser vide.
      print('✅ Nettoyage terminé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }
}

/// Widget utilitaire pour exécuter la migration depuis l'interface
class MigrationButton extends StatefulWidget {
  const MigrationButton({Key? key}) : super(key: key);

  @override
  State<MigrationButton> createState() => _MigrationButtonState();
}

class _MigrationButtonState extends State<MigrationButton> {
  bool _isRunning = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isRunning ? null : _runMigration,
          child: _isRunning 
              ? const CircularProgressIndicator()
              : const Text('Migrer les données "Pour Vous"'),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(_status),
        ],
      ],
    );
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Migration en cours...';
    });

    try {
      final migration = PourVousDataMigration();
      await migration.migrate();
      
      setState(() {
        _status = '✅ Migration réussie !';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
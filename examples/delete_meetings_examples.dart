// 🗑️ Exemples d'Utilisation : Suppression de Réunions de Groupes
//
// Ce fichier contient des exemples d'utilisation des nouvelles méthodes
// de suppression de réunions dans GroupsFirebaseService.
//
// Fichier: examples/delete_meetings_examples.dart

import 'package:flutter/material.dart';
import '../services/groups_firebase_service.dart';
import '../models/group_model.dart';
import '../utils/theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// EXEMPLE 1 : Supprimer une Réunion Simple
/// ═══════════════════════════════════════════════════════════════

class DeleteSingleMeetingExample extends StatelessWidget {
  final String meetingId;
  final String meetingTitle;

  const DeleteSingleMeetingExample({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
  });

  Future<void> _deleteMeeting(BuildContext context) async {
    // 1. Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la réunion ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer "$meetingTitle" ?'),
            const SizedBox(height: 16),
            const Text(
              'Cette action est irréversible.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2. Supprimer la réunion
    try {
      await GroupsFirebaseService.deleteMeeting(meetingId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Réunion supprimée avec succès'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
        Navigator.pop(context, true); // Retour avec succès
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _deleteMeeting(context),
      icon: const Icon(Icons.delete),
      label: const Text('Supprimer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// EXEMPLE 2 : Supprimer Réunion + Événement Lié
/// ═══════════════════════════════════════════════════════════════

class DeleteMeetingWithEventExample extends StatelessWidget {
  final GroupMeetingModel meeting;

  const DeleteMeetingWithEventExample({
    super.key,
    required this.meeting,
  });

  Future<void> _deleteMeetingWithEvent(BuildContext context) async {
    final hasLinkedEvent = meeting.linkedEventId != null;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la réunion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Réunion : "${meeting.title}"'),
            const SizedBox(height: 8),
            if (hasLinkedEvent) ...[
              const Divider(),
              const Row(
                children: [
                  Icon(Icons.event, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Événement lié détecté',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'L\'événement du calendrier sera aussi supprimé.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Cette action est irréversible.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(hasLinkedEvent 
                ? 'Supprimer les 2' 
                : 'Supprimer'
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Supprime réunion + événement si lié
      await GroupsFirebaseService.deleteMeetingWithEvent(meeting.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasLinkedEvent 
                ? '✅ Réunion et événement supprimés' 
                : '✅ Réunion supprimée'
            ),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          _deleteMeetingWithEvent(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Supprimer'),
            ],
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// EXEMPLE 3 : Supprimer Toutes les Réunions d'un Groupe
/// ═══════════════════════════════════════════════════════════════

class DeleteAllGroupMeetingsExample extends StatefulWidget {
  final String groupId;
  final String groupName;

  const DeleteAllGroupMeetingsExample({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<DeleteAllGroupMeetingsExample> createState() => _DeleteAllGroupMeetingsExampleState();
}

class _DeleteAllGroupMeetingsExampleState extends State<DeleteAllGroupMeetingsExample> {
  bool _isDeleting = false;

  Future<void> _deleteAllMeetings(BuildContext context, {required bool includeEvents}) async {
    // 1. Confirmation avec avertissement fort
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('ATTENTION'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supprimer TOUTES les réunions du groupe "${widget.groupName}" ?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ ATTENTION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Action irréversible'),
                  const Text('• Toutes les présences seront perdues'),
                  const Text('• Tous les rapports seront perdus'),
                  if (includeEvents) const Text('• Tous les événements liés seront supprimés'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2. Suppression avec indicateur de progression
    setState(() => _isDeleting = true);

    try {
      final count = await GroupsFirebaseService.deleteAllGroupMeetings(
        widget.groupId,
        includeEvents: includeEvents,
      );
      
      setState(() => _isDeleting = false);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $count réunions supprimées avec succès'),
            backgroundColor: AppTheme.greenStandard,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Option 1 : Supprimer réunions seulement
        ElevatedButton.icon(
          onPressed: _isDeleting 
              ? null 
              : () => _deleteAllMeetings(context, includeEvents: false),
          icon: _isDeleting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_sweep),
          label: const Text('Supprimer toutes les réunions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        // Option 2 : Supprimer réunions + événements
        ElevatedButton.icon(
          onPressed: _isDeleting 
              ? null 
              : () => _deleteAllMeetings(context, includeEvents: true),
          icon: _isDeleting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever),
          label: const Text('Supprimer réunions + événements'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// EXEMPLE 4 : Supprimer Réunions Passées (avec Date)
/// ═══════════════════════════════════════════════════════════════

class DeleteOldMeetingsExample {
  /// Supprime les réunions passées d'un groupe (plus anciennes que [daysAgo] jours)
  static Future<int> deleteOldMeetings(
    String groupId, {
    int daysAgo = 90,
    bool includeEvents = false,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysAgo));
      
      print('🗑️ Suppression réunions > $daysAgo jours (avant ${cutoffDate.toIso8601String()})');
      
      // Récupérer les réunions passées
      final snapshot = await GroupsFirebaseService.getGroupMeetingsStream(groupId).first;
      final oldMeetings = snapshot.where((m) => m.date.isBefore(cutoffDate)).toList();
      
      print('   📊 ${oldMeetings.length} réunions trouvées');
      
      if (oldMeetings.isEmpty) {
        print('   ⚠️ Aucune réunion à supprimer');
        return 0;
      }
      
      // Supprimer chaque réunion
      int deletedCount = 0;
      for (final meeting in oldMeetings) {
        if (includeEvents && meeting.linkedEventId != null) {
          await GroupsFirebaseService.deleteMeetingWithEvent(meeting.id);
        } else {
          await GroupsFirebaseService.deleteMeeting(meeting.id);
        }
        deletedCount++;
      }
      
      print('✅ $deletedCount réunions passées supprimées');
      return deletedCount;
    } catch (e) {
      print('❌ Erreur: $e');
      throw Exception('Erreur lors de la suppression des réunions passées: $e');
    }
  }
}

/// ═══════════════════════════════════════════════════════════════
/// EXEMPLE 5 : Widget Complet avec Menu de Suppression
/// ═══════════════════════════════════════════════════════════════

class MeetingCardWithDeleteMenu extends StatelessWidget {
  final GroupMeetingModel meeting;
  final VoidCallback? onDeleted;

  const MeetingCardWithDeleteMenu({
    super.key,
    required this.meeting,
    this.onDeleted,
  });

  Future<void> _showDeleteOptions(BuildContext context) async {
    final hasEvent = meeting.linkedEventId != null;
    
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Supprimer la réunion uniquement'),
              subtitle: hasEvent 
                  ? const Text('L\'événement sera conservé')
                  : null,
              onTap: () => Navigator.pop(context, 'meeting_only'),
            ),
            if (hasEvent)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Supprimer réunion + événement'),
                subtitle: const Text('Supprime aussi l\'événement du calendrier'),
                onTap: () => Navigator.pop(context, 'with_event'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    try {
      if (choice == 'meeting_only') {
        await GroupsFirebaseService.deleteMeeting(meeting.id);
      } else if (choice == 'with_event') {
        await GroupsFirebaseService.deleteMeetingWithEvent(meeting.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Suppression réussie'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
        onDeleted?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(meeting.title),
        subtitle: Text(meeting.date.toString()),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showDeleteOptions(context),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// USAGE RAPIDE DANS VOTRE CODE
/// ═══════════════════════════════════════════════════════════════

/*

// 1️⃣ Supprimer une réunion simple
await GroupsFirebaseService.deleteMeeting('meeting_abc123');

// 2️⃣ Supprimer réunion + événement lié
await GroupsFirebaseService.deleteMeetingWithEvent('meeting_abc123');

// 3️⃣ Supprimer toutes les réunions d'un groupe
final count = await GroupsFirebaseService.deleteAllGroupMeetings(
  'group_xyz',
  includeEvents: false, // ou true pour inclure les événements
);
print('$count réunions supprimées');

// 4️⃣ Supprimer réunions passées (>90 jours)
final count = await DeleteOldMeetingsExample.deleteOldMeetings(
  'group_xyz',
  daysAgo: 90,
  includeEvents: true,
);

*/

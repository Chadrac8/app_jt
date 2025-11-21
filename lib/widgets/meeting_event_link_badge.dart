import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

/// 🔗 Badge lien réunion ↔ événement
/// 
/// Affiche badge cliquable indiquant qu'une réunion est liée à un événement calendrier.
/// Permet navigation rapide vers événement.
/// 
/// Usage dans GroupDetailPage:
/// ```dart
/// MeetingEventLinkBadge(
///   linkedEventId: meeting.linkedEventId!,
///   onTap: () {
///     Navigator.push(context, MaterialPageRoute(
///       builder: (_) => EventDetailPage(eventId: meeting.linkedEventId!),
///     ));
///   },
/// )
/// ```
class MeetingEventLinkBadge extends StatelessWidget {
  final String linkedEventId;
  final VoidCallback? onTap;
  final bool showLabel;

  const MeetingEventLinkBadge({
    Key? key,
    required this.linkedEventId,
    this.onTap,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(linkedEventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingBadge(context);
        }

        final event = EventModel.fromFirestore(snapshot.data!);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 6),
          Text(
            'Chargement...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// 🔗 Badge lien événement → groupe
/// 
/// Affiche badge cliquable dans EventDetailPage indiquant que l'événement
/// est lié à une réunion de groupe.
/// 
/// Usage dans EventDetailPage:
/// ```dart
/// EventGroupLinkBadge(
///   linkedGroupId: event.linkedGroupId!,
///   onTap: () {
///     Navigator.push(context, MaterialPageRoute(
///       builder: (_) => GroupDetailPage(groupId: event.linkedGroupId!),
///     ));
///   },
/// )
/// ```
class EventGroupLinkBadge extends StatelessWidget {
  final String linkedGroupId;
  final VoidCallback? onTap;
  final bool showFullInfo;

  const EventGroupLinkBadge({
    Key? key,
    required this.linkedGroupId,
    this.onTap,
    this.showFullInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(linkedGroupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingBadge(context);
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>?;
        final groupName = groupData?['name'] ?? 'Groupe sans nom';

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.group,
                  size: 18,
                  color: Colors.green,
                ),
                if (showFullInfo) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Réunion de groupe',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Chargement...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

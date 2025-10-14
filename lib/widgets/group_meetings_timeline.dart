import 'package:flutter/material.dart';
import '../models/group_model.dart';
import 'meeting_event_link_badge.dart';

/// 📅 Timeline des réunions de groupe
/// 
/// Affiche liste verticale avec indicateur visuel passé/futur.
/// Intégration badges événements liés.
/// 
/// Usage dans GroupDetailPage:
/// ```dart
/// GroupMeetingsTimeline(
///   meetings: groupMeetings,
///   onMeetingTap: (meeting) {
///     // Navigation ou détails
///   },
///   onEventTap: (eventId) {
///     Navigator.push(context, MaterialPageRoute(
///       builder: (_) => EventDetailPage(eventId: eventId),
///     ));
///   },
/// )
/// ```
class GroupMeetingsTimeline extends StatelessWidget {
  final List<GroupMeetingModel> meetings;
  final Function(GroupMeetingModel)? onMeetingTap;
  final Function(String)? onEventTap;
  final bool showPastMeetings;

  const GroupMeetingsTimeline({
    Key? key,
    required this.meetings,
    this.onMeetingTap,
    this.onEventTap,
    this.showPastMeetings = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sortedMeetings = List<GroupMeetingModel>.from(meetings)
      ..sort((a, b) => a.date.compareTo(b.date));

    final futureMeetings = sortedMeetings.where((m) => m.date.isAfter(now)).toList();
    final pastMeetings = showPastMeetings
        ? sortedMeetings.where((m) => m.date.isBefore(now)).toList()
        : <GroupMeetingModel>[];

    if (sortedMeetings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Réunions à venir
        if (futureMeetings.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'À venir',
            Icons.upcoming,
            Colors.blue,
            futureMeetings.length,
          ),
          const SizedBox(height: 8),
          ...futureMeetings.map((meeting) => _buildMeetingItem(
                context,
                meeting,
                isPast: false,
              )),
        ],

        // Séparateur
        if (futureMeetings.isNotEmpty && pastMeetings.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Réunions passées
        if (pastMeetings.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Passées',
            Icons.history,
            Colors.grey,
            pastMeetings.length,
          ),
          const SizedBox(height: 8),
          ...pastMeetings.reversed.map((meeting) => _buildMeetingItem(
                context,
                meeting,
                isPast: true,
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingItem(
    BuildContext context,
    GroupMeetingModel meeting, {
    required bool isPast,
  }) {
    final opacity = isPast ? 0.6 : 1.0;
    final now = DateTime.now();
    final isToday = meeting.date.year == now.year &&
        meeting.date.month == now.month &&
        meeting.date.day == now.day;

    return InkWell(
      onTap: onMeetingTap != null ? () => onMeetingTap!(meeting) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.green
                        : (isPast
                            ? Colors.grey.withOpacity(0.5)
                            : Theme.of(context).primaryColor),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
                if (meetings.indexOf(meeting) < meetings.length - 1)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Meeting content
            Expanded(
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.green.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date et heure
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isToday ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(meeting.date),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.green : Colors.grey[700],
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AUJOURD\'HUI',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Notes (si présentes)
                      if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          meeting.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Badge événement lié
                      if (meeting.linkedEventId != null) ...[
                        const SizedBox(height: 8),
                        MeetingEventLinkBadge(
                          linkedEventId: meeting.linkedEventId!,
                          onTap: onEventTap != null
                              ? () => onEventTap!(meeting.linkedEventId!)
                              : null,
                        ),
                      ],

                      // Indicateur récurrence
                      if (meeting.isRecurring) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Récurrente',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Indicateur modification
                      if (meeting.isModified) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Modifiée',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune réunion planifiée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activez les réunions récurrentes pour générer automatiquement les dates',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    const days = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];
    
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$dayName ${date.day} $monthName ${date.year} à $hour:$minute';
  }
}

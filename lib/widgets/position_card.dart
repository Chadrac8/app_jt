import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../../theme.dart';

class PositionCard extends StatelessWidget {
  final PositionModel position;
  final Color teamColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const PositionCard({
    super.key,
    required this.position,
    required this.teamColor,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: ValueKey('position_${position.id}'),
      child: Card(
        elevation: isSelected ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Position icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: teamColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      position.isLeaderPosition 
                          ? Icons.supervisor_account
                          : Icons.assignment_ind,
                      color: teamColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  
                  // Position info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                position.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (position.isLeaderPosition) ...[
                              const SizedBox(width: AppTheme.spaceSmall),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: teamColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: Text(
                                  'Leader',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: teamColor,
                                    fontWeight: AppTheme.fontSemiBold,
                                  ),
                                ),
                              ),
                            ],
                            if (!position.isActive) ...[
                              const SizedBox(width: AppTheme.spaceSmall),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: Text(
                                  'Inactif',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: AppTheme.fontMedium,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Text(
                          position.description.isNotEmpty 
                              ? position.description 
                              : 'Aucune description',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection indicator or max assignments
                  if (isSelectionMode) ...[
                    const SizedBox(width: AppTheme.spaceSmall),
                    Checkbox(
                      value: isSelected,
                      onChanged: onSelectionChanged != null 
                          ? (bool? value) => onSelectionChanged!(value ?? false)
                          : null,
                      activeColor: teamColor,
                    ),
                  ] else ...[
                    const SizedBox(width: AppTheme.spaceSmall),
                    Column(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          position.maxAssignments.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Required skills
              if (position.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: position.requiredSkills.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        skill,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(position.requiredSkills.length > 3 ? [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          '+${position.requiredSkills.length - 3}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ),
                    ] : []),
                ),
              ],

              // Bottom info
              const SizedBox(height: AppTheme.spaceSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        _formatDate(position.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  if (position.isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: teamColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes}min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
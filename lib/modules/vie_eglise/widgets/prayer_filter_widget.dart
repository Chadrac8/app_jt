import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../models/prayer_model.dart';

/// Widget de filtre pour le mur de prière - Material Design 3
/// Respecte les guidelines MD3 et le thème de l'application
class PrayerFilterWidget extends StatelessWidget {
  final PrayerType? selectedType;
  final ValueChanged<PrayerType?> onFilterChanged;

  const PrayerFilterWidget({
    super.key,
    required this.selectedType,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: _buildFilterChips(),
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    final filters = [
      _FilterItem(
        type: null,
        label: 'Toutes',
        icon: Icons.all_inclusive,
        color: AppTheme.onSurfaceVariant,
      ),
      _FilterItem(
        type: PrayerType.request,
        label: 'Demandes',
        icon: Icons.volunteer_activism,
        color: AppTheme.primaryColor,
      ),
      _FilterItem(
        type: PrayerType.thanksgiving,
        label: 'Actions de grâce',
        icon: Icons.celebration,
        color: AppTheme.secondaryColor,
      ),
      _FilterItem(
        type: PrayerType.testimony,
        label: 'Témoignages',
        icon: Icons.auto_awesome,
        color: AppTheme.tertiaryColor,
      ),
    ];

    return filters.map((filter) {
      final isSelected = selectedType == filter.type;
      
      return Padding(
        padding: const EdgeInsets.only(right: AppTheme.spaceSmall),
        child: FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                size: 18,
                color: isSelected 
                    ? AppTheme.onSecondaryContainer
                    : filter.color,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                filter.label,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  color: isSelected 
                      ? AppTheme.onSecondaryContainer
                      : AppTheme.onSurface,
                ),
              ),
            ],
          ),
          onSelected: (selected) {
            onFilterChanged(selected ? filter.type : null);
          },
          backgroundColor: AppTheme.surface,
          selectedColor: AppTheme.secondaryContainer,
          checkmarkColor: AppTheme.onSecondaryContainer,
          side: BorderSide(
            color: isSelected 
                ? AppTheme.secondaryContainer
                : AppTheme.outline.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
        ),
      );
    }).toList();
  }
}

class _FilterItem {
  final PrayerType? type;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
}

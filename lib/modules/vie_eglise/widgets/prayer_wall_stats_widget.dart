import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../models/prayer_model.dart';

/// Widget d'affichage des statistiques du mur de prière - Material Design 3
/// Respecte les guidelines MD3 et le thème de l'application
class PrayerWallStatsWidget extends StatelessWidget {
  final List<PrayerModel> prayers;

  const PrayerWallStatsWidget({
    super.key,
    required this.prayers,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.volunteer_activism,
              label: 'Demandes',
              value: stats.requests.toString(),
              color: AppTheme.primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.outline.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.celebration,
              label: 'Actions de grâce',
              value: stats.thanksgiving.toString(),
              color: AppTheme.secondaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.outline.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.auto_awesome,
              label: 'Témoignages',
              value: stats.testimonies.toString(),
              color: AppTheme.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize20,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize12,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  _PrayerStats _calculateStats() {
    int requests = 0;
    int thanksgiving = 0;
    int testimonies = 0;

    for (final prayer in prayers) {
      switch (prayer.type) {
        case PrayerType.request:
          requests++;
          break;
        case PrayerType.thanksgiving:
          thanksgiving++;
          break;
        case PrayerType.testimony:
          testimonies++;
          break;
      }
    }

    return _PrayerStats(
      requests: requests,
      thanksgiving: thanksgiving,
      testimonies: testimonies,
    );
  }
}

class _PrayerStats {
  final int requests;
  final int thanksgiving;
  final int testimonies;

  const _PrayerStats({
    required this.requests,
    required this.thanksgiving,
    required this.testimonies,
  });
}

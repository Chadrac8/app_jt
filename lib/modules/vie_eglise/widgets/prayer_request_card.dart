import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme.dart';
import '../../../models/prayer_model.dart';

/// Carte de demande de prière - Material Design 3
/// Respecte les guidelines MD3 et le thème de l'application
class PrayerRequestCard extends StatelessWidget {
  final PrayerModel prayer;
  final VoidCallback? onTap;
  final VoidCallback? onPrayFor;
  final bool showActions;

  const PrayerRequestCard({
    super.key,
    required this.prayer,
    this.onTap,
    this.onPrayFor,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return Card(
      elevation: isIOS ? 0 : AppTheme.elevation2,
      shadowColor: isIOS ? null : Colors.black.withOpacity(0.15),
      color: _getCardBackgroundColor(isIOS),
      surfaceTintColor: isIOS ? null : AppTheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isIOS ? 12 : AppTheme.radiusLarge),
        side: BorderSide(
          color: isIOS 
              ? AppTheme.outline.withOpacity(0.2)
              : AppTheme.outline.withOpacity(0.12),
          width: isIOS ? 1 : 0.5,
        ),
      ),
      margin: EdgeInsets.zero, // Important pour contrôler l'espacement depuis le parent
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isIOS ? 12 : AppTheme.radiusLarge),
          // Border gauche coloré pour distinction visuelle selon le type
          border: isIOS ? Border(
            left: BorderSide(
              color: _getTypeColor(),
              width: 3,
            ),
          ) : Border(
            left: BorderSide(
              color: _getTypeColor(),
              width: 4,
            ),
          ),
          // Ombres pour iOS
          boxShadow: isIOS ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 1),
              blurRadius: 3,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 0),
              blurRadius: 1,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isIOS ? 12 : AppTheme.radiusLarge),
          child: Padding(
            padding: EdgeInsets.all(isIOS ? 16 : AppTheme.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: isIOS ? 12 : AppTheme.spaceMedium),
                _buildContent(),
                if (showActions) ...[
                  SizedBox(height: isIOS ? 16 : AppTheme.spaceLarge),
                  _buildActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) {
        final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
        
        return Row(
          children: [
            // Avatar ou icône de type
            Container(
              width: isIOS ? 36 : 40,
              height: isIOS ? 36 : 40,
              decoration: BoxDecoration(
                color: _getTypeColor().withOpacity(isIOS ? 0.15 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(),
                color: _getTypeColor(),
                size: isIOS ? 18 : 20,
              ),
            ),
            SizedBox(width: isIOS ? 12 : AppTheme.spaceMedium),
            
            // Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.authorName,
                    style: GoogleFonts.inter(
                      fontSize: isIOS ? 15 : AppTheme.fontSize14,
                      fontWeight: isIOS ? FontWeight.w600 : AppTheme.fontSemiBold,
                      color: AppTheme.onSurface,
                      letterSpacing: isIOS ? -0.3 : 0,
                    ),
                  ),
                  SizedBox(height: isIOS ? 3 : 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isIOS ? 6 : AppTheme.spaceSmall,
                          vertical: isIOS ? 3 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withOpacity(isIOS ? 0.15 : 0.12),
                          borderRadius: BorderRadius.circular(isIOS ? 6 : AppTheme.radiusSmall),
                        ),
                        child: Text(
                          _getTypeLabel(),
                          style: GoogleFonts.inter(
                            fontSize: isIOS ? 11 : AppTheme.fontSize12,
                            fontWeight: isIOS ? FontWeight.w600 : AppTheme.fontMedium,
                            color: _getTypeColor(),
                            letterSpacing: isIOS ? -0.2 : 0,
                          ),
                        ),
                      ),
                      SizedBox(width: isIOS ? 6 : AppTheme.spaceSmall),
                      Text(
                        _formatDate(prayer.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: isIOS ? 11 : AppTheme.fontSize12,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: isIOS ? -0.2 : 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menu contextuel
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppTheme.onSurfaceVariant,
                size: 20,
              ),
              color: AppTheme.surface,
              surfaceTintColor: AppTheme.surfaceTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: AppTheme.onSurface,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Signaler',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prayer.title.isNotEmpty) ...[
          Text(
            prayer.title,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
        ],
        Text(
          prayer.content,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            color: AppTheme.onSurface,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    // Adapter les actions selon le type de prière
    final bool showPrayButton = prayer.type == PrayerType.request;
    final bool showSupport = prayer.type == PrayerType.testimony || prayer.type == PrayerType.thanksgiving;
    
    return Row(
      children: [
        // Bouton "Prier pour" (seulement pour les demandes)
        if (showPrayButton)
          TextButton.icon(
            onPressed: onPrayFor,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            icon: Icon(
              prayer.prayedByUsers.isNotEmpty ? Icons.favorite : Icons.favorite_border,
              size: 18,
            ),
            label: Text(
              prayer.prayedByUsers.isNotEmpty ? 'Vous priez' : 'Prier pour',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
          ),
        
        // Bouton "Soutenir" (pour témoignages et actions de grâce)
        if (showSupport)
          TextButton.icon(
            onPressed: onPrayFor, // Même action mais sémantique différente
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            icon: Icon(
              prayer.prayedByUsers.isNotEmpty ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
            ),
            label: Text(
              prayer.prayedByUsers.isNotEmpty ? 'Vous soutenez' : 'Soutenir',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
          ),
        
        const SizedBox(width: AppTheme.spaceSmall),
        
        // Compteur adapté selon le type
        if (prayer.prayerCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showPrayButton ? Icons.people : Icons.thumb_up,
                  size: 14,
                  color: AppTheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  '${prayer.prayerCount}',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        
        const Spacer(),
        
        // Bouton "Voir plus"
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.spaceSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voir plus',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTypeColor() {
    switch (prayer.type) {
      case PrayerType.request:
        return AppTheme.primaryColor;
      case PrayerType.thanksgiving:
        return AppTheme.secondaryColor;
      case PrayerType.testimony:
        return AppTheme.tertiaryColor;
    }
  }

  /// Couleur de fond de la carte selon le type et la plateforme
  Color _getCardBackgroundColor(bool isIOS) {
    if (isIOS) {
      // iOS : fond très subtil pour distinction
      switch (prayer.type) {
        case PrayerType.request:
          return AppTheme.surface;
        case PrayerType.thanksgiving:
          return AppTheme.secondaryContainer.withOpacity(0.02);
        case PrayerType.testimony:
          return AppTheme.tertiaryContainer.withOpacity(0.02);
      }
    } else {
      // Android : fond légèrement teinté pour MD3
      switch (prayer.type) {
        case PrayerType.request:
          return AppTheme.surface;
        case PrayerType.thanksgiving:
          return AppTheme.secondaryContainer.withOpacity(0.05);
        case PrayerType.testimony:
          return AppTheme.tertiaryContainer.withOpacity(0.05);
      }
    }
  }

  IconData _getTypeIcon() {
    switch (prayer.type) {
      case PrayerType.request:
        return Icons.volunteer_activism;
      case PrayerType.thanksgiving:
        return Icons.celebration;
      case PrayerType.testimony:
        return Icons.auto_awesome;
    }
  }

  String _getTypeLabel() {
    switch (prayer.type) {
      case PrayerType.request:
        return 'Demande';
      case PrayerType.thanksgiving:
        return 'Action de grâce';
      case PrayerType.testimony:
        return 'Témoignage';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}

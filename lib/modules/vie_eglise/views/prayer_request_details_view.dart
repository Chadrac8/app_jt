import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme.dart';
import '../../../models/prayer_model.dart';

/// Vue de détails d'une demande de prière - Material Design 3
/// Respecte les guidelines MD3 et le thème de l'application
class PrayerRequestDetailsView extends StatefulWidget {
  final PrayerModel prayer;

  const PrayerRequestDetailsView({
    super.key,
    required this.prayer,
  });

  @override
  State<PrayerRequestDetailsView> createState() => _PrayerRequestDetailsViewState();
}

class _PrayerRequestDetailsViewState extends State<PrayerRequestDetailsView> {
  late PrayerModel _prayer;
  bool _isLoading = false;
  bool _hasPrayed = false;

  @override
  void initState() {
    super.initState();
    _prayer = widget.prayer;
    // Initialiser l'état de prière de l'utilisateur
    // _hasPrayed = widget.prayer.userHasPrayed;
  }

  Future<void> _togglePrayer() async {
    setState(() => _isLoading = true);

    try {
      // Logique pour ajouter/retirer une prière
      // await PrayersFirebaseService.togglePrayer(_prayer.id);
      
      setState(() {
        _hasPrayed = !_hasPrayed;
        if (_hasPrayed) {
          _prayer = _prayer.copyWith(prayerCount: _prayer.prayerCount + 1);
        } else {
          _prayer = _prayer.copyWith(prayerCount: _prayer.prayerCount - 1);
        }
      });

      _showSuccessSnackBar(_hasPrayed ? 'Vous priez maintenant pour cette demande' : 'Prière retirée');
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppTheme.onSuccess,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppTheme.onSuccess,
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.onError,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppTheme.onError,
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Détails de la prière',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize20,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.onPrimaryColor,
            ),
            color: AppTheme.surface,
            surfaceTintColor: AppTheme.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(
                      Icons.share,
                      size: 18,
                      color: AppTheme.onSurface,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Partager',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildContent(),
            _buildStats(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _prayer.authorName,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize18,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            _getTypeLabel(),
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontMedium,
                              color: _getTypeColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(
                          _formatDate(_prayer.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_prayer.title.isNotEmpty) ...[
            Text(
              _prayer.title,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize24,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              _prayer.content,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceLarge),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            color: AppTheme.onPrimaryContainer,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            '${_prayer.prayerCount} personne${_prayer.prayerCount > 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            _prayer.prayerCount > 1 ? 'prient' : 'prie',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            'pour cette demande',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _togglePrayer,
            style: FilledButton.styleFrom(
              backgroundColor: _hasPrayed ? AppTheme.secondaryColor : AppTheme.primaryColor,
              foregroundColor: _hasPrayed ? AppTheme.onSecondaryColor : AppTheme.onPrimaryColor,
              disabledBackgroundColor: AppTheme.onSurface.withOpacity(0.12),
              disabledForegroundColor: AppTheme.onSurface.withOpacity(0.38),
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              elevation: 0,
            ),
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (_hasPrayed ? AppTheme.onSecondaryColor : AppTheme.onPrimaryColor)
                            .withOpacity(0.7),
                      ),
                    ),
                  )
                : Icon(
                    _hasPrayed ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                  ),
            label: Text(
              _hasPrayed ? 'Vous priez pour cette demande' : 'Prier pour cette demande',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (_prayer.type) {
      case PrayerType.request:
        return AppTheme.primaryColor;
      case PrayerType.thanksgiving:
        return AppTheme.secondaryColor;
      case PrayerType.testimony:
        return AppTheme.tertiaryColor;
    }
  }

  IconData _getTypeIcon() {
    switch (_prayer.type) {
      case PrayerType.request:
        return Icons.volunteer_activism;
      case PrayerType.thanksgiving:
        return Icons.celebration;
      case PrayerType.testimony:
        return Icons.auto_awesome;
    }
  }

  String _getTypeLabel() {
    switch (_prayer.type) {
      case PrayerType.request:
        return 'Demande de prière';
      case PrayerType.thanksgiving:
        return 'Action de grâce';
      case PrayerType.testimony:
        return 'Témoignage';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);
  }
}

extension PrayerModelExtension on PrayerModel {
  PrayerModel copyWith({
    String? id,
    String? title,
    String? content,
    PrayerType? type,
    String? category,
    String? authorName,
    String? authorId,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    bool? isArchived,
    int? prayerCount,
  }) {
    return PrayerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      category: category ?? this.category,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      isArchived: isArchived ?? this.isArchived,
      prayerCount: prayerCount ?? this.prayerCount,
    );
  }
}
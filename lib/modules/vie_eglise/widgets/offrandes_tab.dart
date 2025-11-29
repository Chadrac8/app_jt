import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../pages/helloasso_iframe_page.dart';
import '../../../theme.dart';
import '../../../auth/auth_service.dart';
import '../../../models/person_model.dart';

class OffrandesTab extends StatefulWidget {
  const OffrandesTab({Key? key}) : super(key: key);

  @override
  State<OffrandesTab> createState() => _OffrandesTabState();
}

class _OffrandesTabState extends State<OffrandesTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PersonModel? _currentUser;
  bool _isLoadingUser = true;

  final List<DonationType> _donationTypes = [
    DonationType(
      title: 'Offrande',
      description: 'Offrande libre pour soutenir l\'œuvre de Dieu',
      icon: Icons.favorite,
      color: AppTheme.pinkStandard,
    ),
    DonationType(
      title: 'Loyer de l\'église',
      description: 'Participation aux frais de location du lieu de culte',
      icon: Icons.home_filled,
      color: AppTheme.blueStandard,
    ),
    DonationType(
      title: 'Achat du local',
      description: 'Contribution pour l\'acquisition de notre propre lieu',
      icon: Icons.business,
      color: AppTheme.greenStandard,
    ),
    DonationType(
      title: 'Dîme',
      description: 'Dîme selon les enseignements bibliques (10%)',
      icon: Icons.percent,
      color: AppTheme.orangeStandard,
    ),
  ];

  // URLs HelloAsso pour chaque type de don
  final Map<int, String> _donationUrls = {
    0: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/1', // Offrande
    1: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/6', // Loyer de l'église
    2: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/5', // Achat du local
    3: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/4', // Dîme
  };

  // Informations bancaires
  final String _iban = 'FR76 1670 6054 2853 9993 2537 436';
  final String _bic = 'AGRIFRPP867';
  final String _titulaire = 'Jubilé Tabernacle';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoadingUser = true);

      final user = AuthService.currentUser;
      if (user != null) {
        final person = await AuthService.getCurrentUserProfile();
        if (person != null && mounted) {
          setState(() {
            _currentUser = person;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBiblicalVerse(colorScheme, textTheme),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildDonationTypes(colorScheme, textTheme),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildPaymentMethods(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildBiblicalVerse(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: AppTheme.isApplePlatform ? 0 : 3,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.secondary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.isApplePlatform
                        ? []
                        : [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Text(
                    'Parole de Dieu',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Text(
                '"Que chacun donne comme il l\'a résolu en son cœur, sans tristesse ni contrainte ; car Dieu aime celui qui donne avec joie."',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                Icon(
                  Icons.bookmark,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.space6),
                Text(
                  '2 Corinthiens 9:7',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationTypes(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                'Payer par carte bancaire',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Choisissez le type de don et payez en ligne de manière sécurisée',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ...List.generate(_donationTypes.length, (index) {
          final donation = _donationTypes[index];

          final cardContent = Card(
            elevation: AppTheme.isApplePlatform ? 0 : 2,
            shadowColor: donation.color.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
              side: BorderSide(
                color: donation.color.withOpacity(0.15),
                width: AppTheme.actionCardBorderWidth,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(AppTheme.actionCardPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    donation.color.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: donation.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.isApplePlatform
                          ? []
                          : [
                              BoxShadow(
                                color: donation.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(donation.icon, color: donation.color, size: 26),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Text(
                          donation.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space6),
                    decoration: BoxDecoration(
                      color: donation.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppTheme.isApplePlatform
                          ? Icons.chevron_right
                          : Icons.arrow_forward_ios,
                      color: donation.color,
                      size: AppTheme.isApplePlatform ? 22 : 16,
                    ),
                  ),
                ],
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppTheme.isApplePlatform
                ? GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final baseUrl = _donationUrls[index];
                      if (baseUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelloAssoIframePage(
                              donationType: donation.title,
                              icon: donation.icon,
                              color: donation.color,
                              donationUrl: baseUrl,
                            ),
                          ),
                        );
                      }
                    },
                    child: cardContent,
                  )
                : InkWell(
                    borderRadius: BorderRadius.circular(
                      AppTheme.actionCardRadius,
                    ),
                    splashColor: donation.color.withValues(
                      alpha: AppTheme.interactionOpacity,
                    ),
                    onTap: () {
                      final baseUrl = _donationUrls[index];
                      if (baseUrl != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelloAssoIframePage(
                              donationType: donation.title,
                              icon: donation.icon,
                              color: donation.color,
                              donationUrl: baseUrl,
                            ),
                          ),
                        );
                      }
                    },
                    child: cardContent,
                  ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethods(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                'Moyens de paiement',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildPaymentMethodCard(
          icon: Icons.account_balance,
          title: 'Virement bancaire',
          description: 'Virement SEPA gratuit',
          onTap: _showRIBBottomSheet,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppTheme.space12),
        _buildPaymentMethodCard(
          icon: Icons.receipt_long,
          title: 'Chèque',
          description: 'À l\'ordre de l\'association',
          onTap: _showCheckInstructions,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final cardContent = Card(
      elevation: AppTheme.isApplePlatform ? 0 : 2,
      shadowColor: colorScheme.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.15),
          width: AppTheme.actionCardBorderWidth,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(AppTheme.actionCardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.isApplePlatform
                    ? []
                    : [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(icon, color: colorScheme.primary, size: 26),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.space6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppTheme.isApplePlatform
                    ? Icons.chevron_right
                    : Icons.arrow_forward_ios,
                color: colorScheme.primary,
                size: AppTheme.isApplePlatform ? 22 : 16,
              ),
            ),
          ],
        ),
      ),
    );

    return AppTheme.isApplePlatform
        ? GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: cardContent,
          )
        : InkWell(
            borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
            splashColor: colorScheme.primary.withValues(
              alpha: AppTheme.interactionOpacity,
            ),
            onTap: onTap,
            child: cardContent,
          );
  }

  Widget _buildRIBField(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.space12,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: AppTheme.isApplePlatform
                  ? []
                  : [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontFamily: 'RobotoMono',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        // Plus de padding sur Android pour éviter les textes coupés
        padding: EdgeInsets.symmetric(
          vertical: 14,
          horizontal: AppTheme.isApplePlatform ? 18 : 22,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: AppTheme.isApplePlatform ? 0 : 3,
        shadowColor: colorScheme.primary.withOpacity(0.4),
        textStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: AppTheme.isApplePlatform ? 1.2 : 1.3,
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.greenStandard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareRIB() {
    final ribInfo =
        '''
Informations bancaires - Jubilé Tabernacle

Titulaire: $_titulaire
IBAN: $_iban
BIC/SWIFT: $_bic

Pour vos dons et offrandes.
Merci pour votre générosité !
''';
    Share.share(ribInfo, subject: 'Informations bancaires - Jubilé Tabernacle');
  }

  void _showRIBBottomSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.isApplePlatform
                        ? []
                        : [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Informations bancaires',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // RIB fields
            _buildRIBField(
              'Titulaire du compte',
              _titulaire,
              colorScheme,
              textTheme,
            ),
            _buildRIBField('IBAN', _iban, colorScheme, textTheme),
            _buildRIBField('BIC/SWIFT', _bic, colorScheme, textTheme),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Copier IBAN',
                    Icons.copy,
                    () => _copyToClipboard(_iban, 'IBAN copié'),
                    colorScheme,
                    textTheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Partager',
                    Icons.share,
                    _shareRIB,
                    colorScheme,
                    textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.secondaryContainer.withOpacity(0.5),
                    colorScheme.tertiaryContainer.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.secondary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: AppTheme.isApplePlatform
                    ? []
                    : [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Précisez le type de don en commentaire du virement',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckInstructions() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.isApplePlatform
                        ? []
                        : [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Paiement par chèque',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions :',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Libeller votre chèque à l\'ordre de :',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"Jubilé Tabernacle"',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '2. Envoyer le chèque à l\'adresse :\n124 Bis rue de l\'\u00c9pidème\n59200 Tourcoing, France',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '3. Préciser le type de don au dos du chèque',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Compris',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DonationType {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  DonationType({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

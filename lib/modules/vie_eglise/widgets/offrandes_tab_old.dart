import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../pages/donation_webview_page.dart';
import '../../../pages/simple_donation_webview_page.dart';
import '../../../theme.dart';

class OffrandesTab extends StatefulWidget {
  const OffrandesTab({Key? key}) : super(key: key);

  @override
  State<OffrandesTab> createState() => _OffrandesTabState();
}

class _OffrandesTabState extends State<OffrandesTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _showRIB = false;

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

  // Informations bancaires (à remplacer par les vraies données)
  final String _iban = 'FR76 1234 5678 9012 3456 7890 123';
  final String _bic = 'TESTFRPP';
  final String _titulaire = 'Association Jubilé Tabernacle France';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
            const SizedBox(height: AppTheme.spaceLarge),
            if (_showRIB) _buildRIBSection(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }



  Widget _buildBiblicalVerse(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer.withValues(alpha: 0.6),
            colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: colorScheme.onTertiaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Text(
                  'Parole de Dieu',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Que chacun donne comme il l\'a résolu en son cœur, sans tristesse ni contrainte ; car Dieu aime celui qui donne avec joie."',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Text(
                    '2 Corinthiens 9:7',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationTypes(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_giftcard_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Types de dons',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize22,
                fontWeight: AppTheme.fontBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space20),
        ...List.generate(_donationTypes.length, (index) {
          final donation = _donationTypes[index];
          final isSelected = _selectedDonationType == index;
          
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutQuart,
              ),
            )),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0,
                end: 1,
              ).animate(CurvedAnimation(
                parent: _cardAnimationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOut,
                ),
              )),
              child: _buildDonationCard(donation, index, isSelected, colorScheme),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDonationCard(DonationType donation, int index, bool isSelected, ColorScheme colorScheme) {
    final cardColor = _getColorFromName(donation.colorName, colorScheme);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
        color: isSelected 
            ? cardColor.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLow,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
          onTap: () => _handleDonationTap(donation, index),
          onLongPress: () => _showDonationOptions(donation, index),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
              border: Border.all(
                color: isSelected 
                    ? cardColor
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? cardColor.withValues(alpha: 0.15)
                      : colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: isSelected ? 12 : 8,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      ),
                      child: Icon(
                        donation.icon,
                        color: cardColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.title,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: AppTheme.fontSemiBold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space6),
                          Text(
                            donation.description,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: colorScheme.surface,
                          size: 16,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                  ],
                ),
                if (donation.biblicalText.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: cardColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: cardColor,
                          size: 18,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Text(
                            donation.biblicalText,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize13,
                              fontStyle: FontStyle.italic,
                              color: cardColor,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceMedium),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _navigateToDonation(donation, index),
                    icon: Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(
                      'Donner maintenant',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
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

  Widget _buildPaymentMethods(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.payment_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Moyens de paiement',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize22,
                fontWeight: AppTheme.fontBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space20),
        _buildPaymentMethodCard(
          icon: Icons.credit_card_rounded,
          title: 'HelloAsso (Recommandé)',
          description: 'Paiement sécurisé par carte bancaire',
          colorScheme: colorScheme,
          isPrimary: true,
          onTap: () {
            // Navigation vers HelloAsso pour le type sélectionné
            if (_selectedDonationType >= 0) {
              _navigateToDonation(_donationTypes[_selectedDonationType], _selectedDonationType);
            } else {
              _showSelectDonationTypeFirst();
            }
          },
        ),
        const SizedBox(height: AppTheme.space12),
        _buildPaymentMethodCard(
          icon: Icons.account_balance_rounded,
          title: 'Virement bancaire',
          description: 'Virement SEPA vers notre compte',
          colorScheme: colorScheme,
          onTap: () {
            setState(() => _showRIB = !_showRIB);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      color: isPrimary 
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(
              color: isPrimary 
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: isPrimary 
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRIBSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                'Informations bancaires',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showRIB = false),
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          _buildBankInfoRow('Titulaire', _titulaire, colorScheme),
          _buildBankInfoRow('IBAN', _iban, colorScheme),
          _buildBankInfoRow('BIC', _bic, colorScheme),
          const SizedBox(height: AppTheme.space20),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _copyAllBankInfo,
                  icon: Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copier tout',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _shareBankInfo,
                  icon: Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    'Partager',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontSemiBold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                IconButton(
                  onPressed: () => _copyToClipboard(value, label),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: const EdgeInsets.all(AppTheme.space6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  Color _getColorFromName(String colorName, ColorScheme colorScheme) {
    switch (colorName) {
      case 'pink':
        return AppTheme.pinkStandard;
      case 'blue':
        return AppTheme.infoColor;
      case 'green':
        return AppTheme.successColor;
      case 'orange':
        return AppTheme.warning;
      default:
        return colorScheme.primary;
    }
  }

  void _handleDonationTap(DonationType donation, int index) {
    setState(() {
      _selectedDonationType = _selectedDonationType == index ? -1 : index;
    });
  }

  void _showDonationOptions(DonationType donation, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppTheme.radius2),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: _getColorFromName(donation.colorName, colorScheme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Icon(
                    donation.icon,
                    color: _getColorFromName(donation.colorName, colorScheme),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.title,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        donation.description,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToDonation(donation, index);
                },
                icon: Icon(Icons.open_in_new_rounded),
                label: Text('Ouvrir HelloAsso'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDonationType = index;
                    _showRIB = true;
                  });
                },
                icon: Icon(Icons.account_balance_rounded),
                label: Text('Voir le RIB'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDonation(DonationType donation, int index) {
    final url = _donationUrls[index];
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonationWebViewPage(
            donationType: donation.title,
            url: url,
            icon: donation.icon,
            color: _getColorFromName(donation.colorName, Theme.of(context).colorScheme),
          ),
        ),
      );
    }
  }

  void _showSelectDonationTypeFirst() {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Veuillez d\'abord sélectionner un type de don',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copié',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  void _copyAllBankInfo() {
    final allInfo = '''
Informations bancaires - Jubilé Tabernacle France

Titulaire: $_titulaire
IBAN: $_iban
BIC: $_bic

Merci pour votre générosité !
''';
    Clipboard.setData(ClipboardData(text: allInfo));
    _copyToClipboard(allInfo, 'Informations bancaires');
  }

  void _shareBankInfo() {
    final allInfo = '''
Informations bancaires - Jubilé Tabernacle France

Titulaire: $_titulaire
IBAN: $_iban
BIC: $_bic

Pour vos dons et offrandes.
Merci pour votre générosité !
''';
    Share.share(allInfo, subject: 'Informations bancaires - Jubilé Tabernacle');
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

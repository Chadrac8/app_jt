import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import 'donation_webview_page.dart';
import 'simple_donation_webview_page.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({Key? key}) : super(key: key);

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  int _selectedDonationType = 0;
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

  // Informations bancaires (à remplacer par les vraies données)
  final String _iban = 'FR76 1234 5678 9012 3456 7890 123';
  final String _bic = 'TESTFRPP';
  final String _titulaire = 'Association Jubilé Tabernacle France';

  // URLs HelloAsso pour chaque type de don
  final Map<int, String> _donationUrls = {
    0: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/1', // Offrande
    1: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/6', // Loyer de l'église
    2: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/5', // Achat du local
    3: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/4', // Dîme
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Faire un don', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.primary,
      ),
      body: SingleChildScrollView(
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

  Widget _buildBiblicalVerse(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
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
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.auto_stories,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Text(
                  'Parole de Dieu',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          Text(
            '"Que chacun donne comme il l\'a résolu en son cœur, sans tristesse ni contrainte ; car Dieu aime celui qui donne avec joie."',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            '2 Corinthiens 9:7',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationTypes(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types de dons',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ...List.generate(_donationTypes.length, (index) {
          final donation = _donationTypes[index];
          final isSelected = _selectedDonationType == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              splashColor: donation.color.withOpacity(0.15),
              onTap: () {
                final url = _donationUrls[index];
                if (url != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationWebViewPage(
                        donationType: donation.title,
                        url: url,
                        icon: donation.icon,
                        color: donation.color,
                      ),
                    ),
                  );
                } else {
                  setState(() {
                    _selectedDonationType = index;
                  });
                }
              },
              onLongPress: () {
                final url = _donationUrls[index];
                if (url != null) {
                  _showLoadingOptions(context, donation, url);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: isSelected ? donation.color.withOpacity(0.12) : colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: isSelected ? donation.color : colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: donation.color.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: donation.color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(
                        donation.icon,
                        color: donation.color,
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
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
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
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: donation.color,
                        size: 24,
                      ),
                  ],
                ),
              ),
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
        Text(
          'Moyens de paiement',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildPaymentMethodCard(
          icon: Icons.account_balance,
          title: 'Virement bancaire',
          description: 'Virement SEPA gratuit',
          onTap: () {
            setState(() {
              _showRIB = !_showRIB;
            });
          },
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
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      splashColor: colorScheme.primary.withOpacity(0.12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
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
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRIBSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                'Informations bancaires',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          _buildRIBField('Titulaire du compte', _titulaire, colorScheme, textTheme),
          _buildRIBField('IBAN', _iban, colorScheme, textTheme),
          _buildRIBField('BIC/SWIFT', _bic, colorScheme, textTheme),
          const SizedBox(height: AppTheme.space20),
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
              const SizedBox(width: AppTheme.space12),
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
          const SizedBox(height: AppTheme.spaceMedium),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    'Précisez le type de don en commentaire du virement',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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

  Widget _buildRIBField(String label, String value, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontFamily: 'RobotoMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, ColorScheme colorScheme, TextTheme textTheme) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        textStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
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
      ),
    );
  }

  void _shareRIB() {
    final selectedDonation = _donationTypes[_selectedDonationType];
    final text = '''
🏛️ Don pour: ${selectedDonation.title}
Jubilé Tabernacle France

💳 Informations bancaires:
Titulaire: $_titulaire
IBAN: $_iban
BIC: $_bic

📖 "${_getBiblicalVerse()}"
2 Corinthiens 9:7

Merci pour votre générosité ! 🙏
''';
    
    Share.share(text, subject: 'Informations de don - Jubilé Tabernacle France');
  }

  void _showCheckInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: const BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Paiement par chèque',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),
            _buildCheckInstruction('À l\'ordre de', _titulaire),
            _buildCheckInstruction('Préciser au dos', _donationTypes[_selectedDonationType].title),
            _buildCheckInstruction('Envoyer à', 'Adresse de l\'église\n[À compléter avec l\'adresse réelle]'),
            const SizedBox(height: AppTheme.space20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  'Compris',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInstruction(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize13,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXSmall),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBiblicalVerse() {
    return 'Que chacun donne comme il l\'a résolu en son cœur, sans tristesse ni contrainte ; car Dieu aime celui qui donne avec joie.';
  }

  void _showLoadingOptions(BuildContext context, DonationType donation, String url) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: const BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: donation.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    donation.icon,
                    color: donation.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Text(
                    'Options de chargement',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),
            _buildLoadingOption(
              context,
              'Chargement normal',
              'Version complète avec toutes les fonctionnalités',
              Icons.web,
              AppTheme.blueStandard,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonationWebViewPage(
                      donationType: donation.title,
                      url: url,
                      icon: donation.icon,
                      color: donation.color,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.space12),
            _buildLoadingOption(
              context,
              'Chargement simplifié',
              'Version basique si problème de paiement',
              Icons.speed,
              AppTheme.greenStandard,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleDonationWebViewPage(
                      donationType: donation.title,
                      url: url,
                      icon: donation.icon,
                      color: donation.color,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.grey500.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
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
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.grey500,
              size: 16,
            ),
          ],
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

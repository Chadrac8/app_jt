import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import 'helloasso_iframe_page.dart';
import '../auth/auth_service.dart';
import '../models/person_model.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({Key? key}) : super(key: key);

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
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

  // Informations bancaires
  final String _iban = 'FR76 1670 6054 2853 9993 2537 436';
  final String _bic = 'AGRIFRPP867';
  final String _titulaire = 'Jubilé Tabernacle';

  // URLs HelloAsso pour chaque type de don
  final Map<int, String> _donationUrls = {
    0: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/1', // Offrande
    1: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/6', // Loyer de l'église
    2: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/5', // Achat du local
    3: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/4', // Dîme
  };

  @override
  void initState() {
    super.initState();
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
          'Payer par carte bancaire',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          'Choisissez le type de don et payez en ligne de manière sécurisée',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ...List.generate(_donationTypes.length, (index) {
          final donation = _donationTypes[index];
          
          final cardContent = Container(
            padding: EdgeInsets.all(AppTheme.actionCardPadding), // Adaptatif: 16dp mobile, 20dp desktop
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.actionCardRadius), // Adaptatif: 12dp iOS, 16dp Android
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: AppTheme.actionCardBorderWidth, // Adaptatif: 0.5px iOS, 1px Android
              ),
              boxShadow: AppTheme.isApplePlatform
                  ? [] // iOS: pas de shadow
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
                Icon(
                  AppTheme.isApplePlatform ? Icons.chevron_right : Icons.arrow_forward_ios,
                  color: donation.color,
                  size: AppTheme.isApplePlatform ? 24 : 16,
                ),
              ],
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
                    borderRadius: BorderRadius.circular(AppTheme.actionCardRadius),
                    splashColor: donation.color.withValues(alpha: AppTheme.interactionOpacity),
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
    final cardContent = Container(
      padding: EdgeInsets.all(AppTheme.actionCardPadding), // Adaptatif
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.actionCardRadius), // Adaptatif
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.18),
          width: AppTheme.actionCardBorderWidth, // Adaptatif
        ),
        boxShadow: AppTheme.isApplePlatform
            ? [] // iOS: pas de shadow
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
            AppTheme.isApplePlatform ? Icons.chevron_right : Icons.arrow_forward_ios,
            color: colorScheme.onSurfaceVariant,
            size: AppTheme.isApplePlatform ? 24 : 16,
          ),
        ],
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
            splashColor: colorScheme.primary.withValues(alpha: AppTheme.interactionOpacity),
            onTap: onTap,
            child: cardContent,
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
    final text = '''
🏛️ Informations bancaires
Jubilé Tabernacle France

💳 Coordonnées bancaires:
Titulaire: $_titulaire
IBAN: $_iban
BIC: $_bic

💡 Précisez le type de don dans le libellé de votre virement

📖 "${_getBiblicalVerse()}"
2 Corinthiens 9:7

Merci pour votre générosité ! 🙏
''';
    
    Share.share(text, subject: 'Informations bancaires - Jubilé Tabernacle France');
  }

  Widget _buildRIBFieldBottomSheet(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white100.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.textSecondaryColor.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonBottomSheet(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
        textStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontMedium,
        ),
      ),
    );
  }

  void _showRIBBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: AppTheme.spaceLarge,
              right: AppTheme.spaceLarge,
              top: AppTheme.spaceLarge,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLarge,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.white100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: AppTheme.textSecondaryColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Informations bancaires',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // RIB fields
            _buildRIBFieldBottomSheet('Titulaire du compte', _titulaire),
            _buildRIBFieldBottomSheet('IBAN', _iban),
            _buildRIBFieldBottomSheet('BIC/SWIFT', _bic),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButtonBottomSheet(
                    'Copier IBAN',
                    Icons.copy,
                    () => _copyToClipboard(_iban, 'IBAN copié'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButtonBottomSheet(
                    'Partager',
                    Icons.share,
                    _shareRIB,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Info notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryColor.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Précisez le type de don en commentaire du virement',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.textSecondaryColor,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: AppTheme.spaceLarge,
              right: AppTheme.spaceLarge,
              top: AppTheme.spaceLarge,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLarge,
            ),
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
            _buildCheckInstruction('Préciser au dos', 'Le type de don (Offrande, Dîme, etc.)'),
            _buildCheckInstruction('Envoyer à', '124 Bis rue de l\'\u00c9pidème\n59200 Tourcoing\nFrance'),
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

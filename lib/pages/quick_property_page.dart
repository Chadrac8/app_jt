import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'donation_webview_page.dart';

class QuickPropertyPage extends StatelessWidget {
  const QuickPropertyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white100,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.greenStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.greenStandard,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Achat du local',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildVision(),
            const SizedBox(height: 24),
            _buildContributionLevels(),
            const SizedBox(height: 32),
            _buildWebViewOption(context),
            const SizedBox(height: 24),
            _buildProjectInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.greenStandard.withOpacity(0.1),
            Colors.lightGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business,
            color: AppTheme.greenStandard,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Achat du local',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Investir dans l\'avenir de l\'église',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVision() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.blueStandard.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.blueStandard.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                color: AppTheme.blueStandard,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Notre vision',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.blueStandard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Acquérir un lieu de culte permanent pour Jubilé Tabernacle France, permettant à notre communauté de se rassembler librement et de développer les ministères avec stabilité.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveaux de contribution',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildContributionCard(
          '🌱 Contributeur',
          '50€ - 200€',
          'Participation à l\'effort collectif',
          AppTheme.grey100,
          AppTheme.greenStandard,
        ),
        const SizedBox(height: 12),
        _buildContributionCard(
          '🌿 Partenaire',
          '200€ - 500€',
          'Soutien significatif au projet',
          AppTheme.grey100,
          AppTheme.blueStandard,
        ),
        const SizedBox(height: 12),
        _buildContributionCard(
          '🌳 Bâtisseur',
          '500€ - 1000€',
          'Engagement fort pour l\'avenir',
          AppTheme.grey100,
          AppTheme.orangeStandard,
        ),
        const SizedBox(height: 12),
        _buildContributionCard(
          '🏛️ Fondateur',
          '1000€ et plus',
          'Vision à long terme de l\'église',
          Colors.purple[100]!,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildContributionCard(String level, String amount, String description, Color bgColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: textColor!.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: AppTheme.fontSemiBold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: AppTheme.fontBold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebViewOption(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.grey500.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.greenStandard.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.web,
                  color: AppTheme.greenStandard,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plateforme HelloAsso',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contribuer à l\'achat du local',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DonationWebViewPage(
                      donationType: 'Achat du local',
                      url: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/5',
                      icon: Icons.business,
                      color: AppTheme.greenStandard,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Contribuer au projet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.greenStandard,
                foregroundColor: AppTheme.white100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.greenStandard.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.greenStandard.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: AppTheme.greenStandard,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Avantages du projet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.greenStandard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('🏠', 'Lieu de culte permanent'),
          _buildInfoItem('💰', 'Investissement à long terme'),
          _buildInfoItem('📈', 'Croissance des ministères'),
          _buildInfoItem('👥', 'Stabilité pour la communauté'),
          _buildInfoItem('🧾', 'Reçu fiscal (déduction 66%)'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Projet à long terme nécessitant l\'engagement de toute la communauté',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.amber[800],
                      fontWeight: AppTheme.fontMedium,
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

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

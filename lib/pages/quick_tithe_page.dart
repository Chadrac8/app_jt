import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'donation_webview_page.dart';

class QuickTithePage extends StatelessWidget {
  const QuickTithePage({Key? key}) : super(key: key);

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
              color: AppTheme.orangeStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.orangeStandard,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dîme',
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
            _buildBiblicalVerse(),
            const SizedBox(height: 24),
            _buildTitheCalculator(),
            const SizedBox(height: 32),
            _buildWebViewOption(context),
            const SizedBox(height: 24),
            _buildTitheInfo(),
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
            AppTheme.orangeStandard.withOpacity(0.1),
            Colors.deepOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Column(
        children: [
          Icon(
            Icons.percent,
            color: AppTheme.orangeStandard,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Dîme',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fidélité selon les Écritures',
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

  Widget _buildBiblicalVerse() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: Colors.amber[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Parole de Dieu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"Apportez toutes les dîmes à la maison du trésor, afin qu\'il y ait de la nourriture dans ma maison; mettez-moi de la sorte à l\'épreuve, dit l\'Éternel des armées. Et vous verrez si je n\'ouvre pas pour vous les écluses des cieux, si je ne répands pas sur vous la bénédiction en abondance."',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Malachie 3:10',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: AppTheme.fontSemiBold,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitheCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculateur de dîme (10%)',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.grey500.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildCalculatorRow('Salaire mensuel de 1 500€', '150€'),
              const SizedBox(height: 8),
              _buildCalculatorRow('Salaire mensuel de 2 000€', '200€'),
              const SizedBox(height: 8),
              _buildCalculatorRow('Salaire mensuel de 2 500€', '250€'),
              const SizedBox(height: 8),
              _buildCalculatorRow('Salaire mensuel de 3 000€', '300€'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorRow(String income, String tithe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          income,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.orangeStandard.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text(
            tithe,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.orangeStandard,
            ),
          ),
        ),
      ],
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
                  color: AppTheme.orangeStandard.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.web,
                  color: AppTheme.orangeStandard,
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
                      'Interface complète pour votre dîme',
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
                      donationType: 'Dîme',
                      url: 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/4',
                      icon: Icons.percent,
                      color: AppTheme.orangeStandard,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Donner ma dîme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeStandard,
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

  Widget _buildTitheInfo() {
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
                Icons.favorite,
                color: AppTheme.greenStandard,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Bénédictions de la dîme',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.greenStandard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('🙏', 'Obéissance à la Parole de Dieu'),
          _buildInfoItem('💰', 'Bénédictions financières promises'),
          _buildInfoItem('🏛️', 'Soutien à l\'œuvre de Dieu'),
          _buildInfoItem('❤️', 'Expression de reconnaissance'),
          _buildInfoItem('🧾', 'Reçu fiscal (déduction 66%)'),
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

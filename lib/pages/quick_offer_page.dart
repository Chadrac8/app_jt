import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'offer_webview_page.dart';

class QuickOfferPage extends StatelessWidget {
  const QuickOfferPage({Key? key}) : super(key: key);

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
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Offrande rapide',
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
            _buildQuickAmounts(),
            const SizedBox(height: 32),
            _buildWebViewOption(context),
            const SizedBox(height: 24),
            _buildSecurityInfo(),
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
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.pinkStandard.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            color: AppTheme.primaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Faire une offrande',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soutenez l\'œuvre de Dieu avec joie',
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

  Widget _buildQuickAmounts() {
    final amounts = [10, 25, 50, 100, 200];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montants suggérés',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: amounts.map((amount) => _buildAmountChip(amount)).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountChip(int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Text(
        '${amount}€',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: AppTheme.fontSemiBold,
          color: AppTheme.primaryColor,
        ),
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
                  color: AppTheme.blueStandard.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.web,
                  color: AppTheme.blueStandard,
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
                      'Interface complète avec toutes les options',
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
                    builder: (context) => const OfferWebViewPage(),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Accéder à HelloAsso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blueStandard,
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

  Widget _buildSecurityInfo() {
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
        children: [
          Row(
            children: [
              const Icon(
                Icons.security,
                color: AppTheme.greenStandard,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Paiement 100% sécurisé',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.greenStandard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSecurityItem('🏛️', 'Plateforme régulée par l\'ACPR'),
          _buildSecurityItem('🔒', 'Chiffrement SSL 256 bits'),
          _buildSecurityItem('🧾', 'Reçu fiscal automatique'),
          _buildSecurityItem('💰', 'Déduction fiscale de 66%'),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String emoji, String text) {
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

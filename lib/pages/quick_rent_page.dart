import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'donation_webview_page.dart';
import '../auth/auth_service.dart';
import '../models/person_model.dart';
import '../utils/donation_url_helper.dart';

class QuickRentPage extends StatefulWidget {
  const QuickRentPage({Key? key}) : super(key: key);

  @override
  State<QuickRentPage> createState() => _QuickRentPageState();
}

class _QuickRentPageState extends State<QuickRentPage> {
  PersonModel? _currentUser;
  bool _isLoadingUser = true;

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
    return Scaffold(
      backgroundColor: AppTheme.white100,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: AppTheme.blueStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.blueStandard,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Loyer de l\'église',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimaryColor,
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildQuickAmounts(),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildWebViewOption(context),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildRentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.blueStandard.withOpacity(0.1),
            AppTheme.blueStandard.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Column(
        children: [
          Icon(
            Icons.home_filled,
            color: AppTheme.blueStandard,
            size: 48,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Loyer de l\'église',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Soutenez notre lieu de culte',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    final amounts = [50, 100, 150, 200, 300];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participation suggérée',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
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
        color: AppTheme.blueStandard.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.blueStandard.withOpacity(0.2),
        ),
      ),
      child: Text(
        '${amount}€',
        style: GoogleFonts.poppins(
          fontSize: AppTheme.fontSize16,
          fontWeight: AppTheme.fontSemiBold,
          color: AppTheme.blueStandard,
        ),
      ),
    );
  }

  Widget _buildWebViewOption(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
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
                padding: const EdgeInsets.all(AppTheme.space12),
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
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plateforme HelloAsso',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      'Interface complète pour la participation au loyer',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final baseUrl = 'https://www.helloasso.com/associations/jubile-tabernacle/formulaires/6';
                final prefilledUrl = DonationUrlHelper.buildDonationTypeUrl(baseUrl, _currentUser, 'Loyer de l\'église');
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonationWebViewPage(
                      donationType: 'Loyer de l\'église',
                      url: prefilledUrl,
                      icon: Icons.home_filled,
                      color: AppTheme.blueStandard,
                      user: _currentUser,
                    ),
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

  Widget _buildRentInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
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
              const Icon(
                Icons.info_outline,
                color: AppTheme.blueStandard,
                size: 24,
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                'À propos du loyer',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.blueStandard,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          _buildInfoItem('🏛️', 'Lieu de culte partagé'),
          _buildInfoItem('📅', 'Frais mensuels de location'),
          _buildInfoItem('👥', 'Soutien communautaire'),
          _buildInfoItem('🧾', 'Reçu fiscal automatique'),
          const SizedBox(height: AppTheme.spaceMedium),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.greenStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.greenStandard.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: AppTheme.greenStandard,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    'Paiement 100% sécurisé avec déduction fiscale de 66%',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.greenStandard,
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
          Text(emoji, style: const TextStyle(fontSize: AppTheme.fontSize16)),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

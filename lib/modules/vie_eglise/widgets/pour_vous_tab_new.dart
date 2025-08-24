import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';

class PourVousTab extends StatefulWidget {
  const PourVousTab({Key? key}) : super(key: key);

  @override
  State<PourVousTab> createState() => _PourVousTabState();
}

class _PourVousTabState extends State<PourVousTab> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeActions();
  }

  Future<void> _initializeActions() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    // Simulation du chargement
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textTertiaryColor.withOpacity(0.05),
      body: _isLoading
          ? _buildLoadingWidget()
          : _buildContent());
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)));
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _initializeActions();
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: _buildWelcomeContent()));
  }

  Widget _buildWelcomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWelcomeCard(),
        const SizedBox(height: 24),
        _buildFeatureCards(),
        const SizedBox(height: 24),
        _buildSuggestedActions(),
        const SizedBox(height: 20),
      ]);
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: AppTheme.surfaceColor,
                size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bonjour !',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.surfaceColor))),
            ]),
          const SizedBox(height: 16),
          Text(
            'Bienvenue dans votre espace personnel. Découvrez les actions et ressources préparées spécialement pour vous par votre église.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.surfaceColor.withOpacity(0.9),
              height: 1.5)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.surfaceColor,
                  size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les actions personnalisées seront configurées par votre église',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.surfaceColor.withOpacity(0.9)))),
              ])),
        ]));
  }

  Widget _buildFeatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités disponibles',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Sermons',
                'Écoutez les prédications',
                Icons.play_circle,
                AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                'Bénévolat',
                'Servez dans l\'église',
                Icons.volunteer_activism,
                Colors.orange)),
          ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Prières',
                'Demandes & témoignages',
                Icons.pan_tool,
                Colors.green)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                'Ressources',
                'Outils spirituels',
                Icons.library_books,
                Colors.purple)),
          ]),
      ]);
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor)),
        ]));
  }

  Widget _buildSuggestedActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 24),
              const SizedBox(width: 8),
              Text(
                'Actions suggérées',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor)),
            ]),
          const SizedBox(height: 16),
          _buildActionItem(
            'Explorez les sermons audio',
            'Découvrez la richesse des prédications disponibles',
            Icons.headphones,
            AppTheme.primaryColor),
          const SizedBox(height: 12),
          _buildActionItem(
            'Rejoignez le bénévolat',
            'Trouvez des opportunités de service dans l\'église',
            Icons.volunteer_activism,
            Colors.orange),
          const SizedBox(height: 12),
          _buildActionItem(
            'Partagez vos prières',
            'Demandez des prières ou partagez vos témoignages',
            Icons.pan_tool,
            Colors.green),
        ]));
  }

  Widget _buildActionItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor)),
              ])),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: color.withOpacity(0.6)),
        ]));
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

class AdminSermonsTab extends StatefulWidget {
  const AdminSermonsTab({Key? key}) : super(key: key);

  @override
  State<AdminSermonsTab> createState() => _AdminSermonsTabState();
}

class _AdminSermonsTabState extends State<AdminSermonsTab> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSermonDialog,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: AppTheme.surfaceColor),
        tooltip: 'Ajouter un sermon'));
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)));
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildSermonsList()),
      ]);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textTertiaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                color: AppTheme.primaryColor,
                size: 24),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Administration - Sermons locaux',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor)),
            ]),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Gérez les sermons et prédications de votre église locale',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor)),
        ]));
  }

  Widget _buildSermonsList() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: AppTheme.space20),
          Expanded(
            child: _buildEmptyState()),
        ]));
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Sermons publiés',
            '0',
            Icons.public,
            AppTheme.greenStandard)),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            'Brouillons',
            '0',
            Icons.edit,
            AppTheme.orangeStandard)),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            'Total d\'écoutes',
            '0',
            Icons.headphones,
            AppTheme.primaryColor)),
      ]);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: color)),
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.textSecondaryColor)),
        ]));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 64,
            color: AppTheme.textTertiaryColor),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucun sermon ajouté',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Ajoutez des sermons de votre église\npour enrichir l\'expérience des membres',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor)),
          const SizedBox(height: AppTheme.spaceLarge),
          ElevatedButton.icon(
            onPressed: _showAddSermonDialog,
            icon: Icon(Icons.add, color: AppTheme.surfaceColor),
            label: Text(
              'Ajouter un sermon',
              style: GoogleFonts.poppins(
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.surfaceColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium)))),
        ]));
  }

  void _showAddSermonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: Text(
          'Ajouter un sermon',
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor)),
        content: Text(
          'Cette fonctionnalité sera disponible prochainement.\n\nElle permettra d\'ajouter et de gérer les sermons de votre église locale.',
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: AppTheme.fontSemiBold))),
        ]));
  }
}

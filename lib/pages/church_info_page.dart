import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';

class ChurchInfoPage extends StatefulWidget {
  const ChurchInfoPage({super.key});

  @override
  State<ChurchInfoPage> createState() => _ChurchInfoPageState();
}

class _ChurchInfoPageState extends State<ChurchInfoPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nous visiter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildContactInfo(),
                  const SizedBox(height: 24),
                  _buildServiceHours(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                ])));
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ])),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceColor, width: 3),
                color: AppTheme.surfaceColor.withOpacity(0.2)),
              child: const Icon(
                Icons.church,
                color: AppTheme.surfaceColor,
                size: 40)),
            const SizedBox(height: 16),
            Text(
              'Jubilé Tabernacle France',
              style: TextStyle(
                fontSize: 24,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.surfaceColor)),
            const SizedBox(height: 8),
            Text(
              'Votre communauté spirituelle',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.surfaceColor.withOpacity(0.9))),
          ])));
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.location_on,
              title: 'Adresse',
              value: '123 Rue de l\'Église\n75001 Paris, France',
              onTap: () => _launchMaps()),
            const Divider(),
            _buildContactItem(
              icon: Icons.phone,
              title: 'Téléphone',
              value: '+33 1 23 45 67 89',
              onTap: () => _launchPhone('+33123456789')),
            const Divider(),
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              value: 'contact@jubile-tabernacle.fr',
              onTap: () => _launchEmail('contact@jubile-tabernacle.fr')),
          ])));
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(icon, color: AppTheme.primaryColor)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.textSecondaryColor)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor)),
                ])),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiaryColor),
          ])));
  }

  Widget _buildServiceHours() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horaires des services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            _buildServiceHour('Dimanche', 'Culte principal', '10h00 - 12h00'),
            _buildServiceHour('Mercredi', 'Prière & Étude biblique', '19h30 - 21h00'),
            _buildServiceHour('Samedi', 'Réunion des jeunes', '18h00 - 20h00'),
          ])));
  }

  Widget _buildServiceHour(String day, String service, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day - $service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor)),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor)),
              ])),
        ]));
  }

  Widget _buildDescription() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À propos de nous',
              style: TextStyle(
                fontSize: 20,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            Text(
              'Jubilé Tabernacle France est une communauté chrétienne dynamique qui accueille tous ceux qui cherchent à grandir dans leur relation avec Dieu. Nous sommes une famille unie par la foi, l\'amour et le service.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            Text(
              'Notre mission est de partager l\'amour du Christ, d\'édifier les croyants et de servir notre communauté avec compassion et excellence.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.textPrimaryColor)),
          ])));
  }

  Future<void> _launchMaps() async {
    const url = 'https://maps.google.com/?q=123+Rue+de+l\'Église,+75001+Paris,+France';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

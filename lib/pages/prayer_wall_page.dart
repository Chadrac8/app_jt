import 'package:flutter/material.dart';
import '../../theme.dart';

class PrayerWallPage extends StatefulWidget {
  const PrayerWallPage({super.key});

  @override
  State<PrayerWallPage> createState() => _PrayerWallPageState();
}

class _PrayerWallPageState extends State<PrayerWallPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _requestController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mur de prière'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.surfaceColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildForm(),
            const SizedBox(height: 24),
            _buildRecentPrayers(),
          ])));
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
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
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ])),
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              size: 48,
              color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Partagez vos demandes de prière',
              style: TextStyle(
                fontSize: 20,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 8),
            Text(
              'Notre communauté prie pour vous. Partagez vos besoins et soyez béni.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor)),
          ])));
  }

  Widget _buildForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle demande de prière',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 20),
              
              // Case anonyme
              CheckboxListTile(
                title: Text(
                  'Demande anonyme',
                  style: TextStyle(color: AppTheme.textPrimaryColor)),
                subtitle: Text(
                  'Votre nom ne sera pas affiché',
                  style: TextStyle(color: AppTheme.textSecondaryColor)),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor),
              
              const SizedBox(height: 16),
              
              // Nom (si pas anonyme)
              if (!_isAnonymous) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Votre prénom',
                    hintText: 'Comment vous appelez-vous ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                    prefixIcon: const Icon(Icons.person)),
                  validator: (value) {
                    if (!_isAnonymous && (value == null || value.trim().isEmpty)) {
                      return 'Veuillez saisir votre prénom';
                    }
                    return null;
                  }),
                const SizedBox(height: 16),
              ],
              
              // Demande de prière
              TextFormField(
                controller: _requestController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Votre demande de prière',
                  hintText: 'Partagez ce pour quoi vous aimeriez que nous priions...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  prefixIcon: const Icon(Icons.message)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre demande de prière';
                  }
                  return null;
                }),
              
              const SizedBox(height: 24),
              
              // Bouton d'envoi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPrayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.surfaceColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium))),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100)))
                      : const Text(
                          'Partager ma demande',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: AppTheme.fontSemiBold)))),
            ])),
      ),
    );
  }

  Widget _buildRecentPrayers() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prières récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 16),
            
            // Exemple de prières (normalement chargées depuis Firestore)
            _buildPrayerItem(
              name: 'Marie',
              request: 'Merci de prier pour ma guérison et celle de ma famille.',
              time: 'Il y a 2 heures',
              prayerCount: 12),
            const Divider(),
            _buildPrayerItem(
              name: 'Anonyme',
              request: 'Demande de prière pour un nouveau travail.',
              time: 'Il y a 5 heures',
              prayerCount: 8),
            const Divider(),
            _buildPrayerItem(
              name: 'Jean',
              request: 'Prière pour les examens de mes enfants.',
              time: 'Hier',
              prayerCount: 15),
          ])));
  }

  Widget _buildPrayerItem({
    required String name,
    required String request,
    required String time,
    required int prayerCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: AppTheme.fontBold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.textPrimaryColor)),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor)),
                  ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '$prayerCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.primaryColor)),
                  ])),
            ]),
          const SizedBox(height: 8),
          Text(
            request,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor)),
        ]));
  }

  Future<void> _submitPrayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Ici, vous ajouteriez l'envoi vers Firestore
      // await FirestoreService.addPrayerRequest(...)

      await Future.delayed(const Duration(seconds: 2)); // Simulation

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Votre demande de prière a été partagée'),
            backgroundColor: AppTheme.greenStandard,
            behavior: SnackBarBehavior.floating));

        // Réinitialiser le formulaire
        _nameController.clear();
        _requestController.clear();
        setState(() {
          _isAnonymous = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.redStandard,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

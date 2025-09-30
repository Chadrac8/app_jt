import 'package:flutter/material.dart';
import '../../theme.dart';

class NewMemberFormPage extends StatefulWidget {
  const NewMemberFormPage({super.key});

  @override
  State<NewMemberFormPage> createState() => _NewMemberFormPageState();
}

class _NewMemberFormPageState extends State<NewMemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau membre'),
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
              Icons.person_add,
              size: 48,
              color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Rejoignez notre communauté',
              style: TextStyle(
                fontSize: 20,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 8),
            Text(
              'Remplissez ce formulaire pour devenir membre de Jubilé Tabernacle France',
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
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 20),
              
              // Prénom
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Prénom *',
                  hintText: 'Votre prénom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  prefixIcon: const Icon(Icons.person)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre prénom';
                  }
                  return null;
                }),
              const SizedBox(height: 16),
              
              // Nom
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Nom *',
                  hintText: 'Votre nom de famille',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  prefixIcon: const Icon(Icons.person_outline)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre nom';
                  }
                  return null;
                }),
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  hintText: 'votre.email@exemple.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  prefixIcon: const Icon(Icons.email)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Veuillez saisir un email valide';
                  }
                  return null;
                }),
              const SizedBox(height: 16),
              
              // Téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  hintText: '+33 6 12 34 56 78',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  prefixIcon: const Icon(Icons.phone))),
              const SizedBox(height: 16),
              
              // Adresse
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Votre adresse complète',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  prefixIcon: const Icon(Icons.home))),
              
              const SizedBox(height: 24),
              
              // Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.blueStandard.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.blueStandard.withOpacity(0.3))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: AppTheme.blueStandard, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Un responsable vous contactera dans les prochains jours pour finaliser votre adhésion.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.blueStandard))),
                  ])),
              
              const SizedBox(height: 24),
              
              // Bouton d'envoi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
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
                          'Envoyer ma demande',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: AppTheme.fontSemiBold)))),
            ])),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Ici, vous ajouteriez l'envoi vers Firestore
      // await FirestoreService.addNewMemberRequest(...)

      await Future.delayed(const Duration(seconds: 2)); // Simulation

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Votre demande a été envoyée avec succès'),
            backgroundColor: AppTheme.greenStandard,
            behavior: SnackBarBehavior.floating));

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _addressController.clear();
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

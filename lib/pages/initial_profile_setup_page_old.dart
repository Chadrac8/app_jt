import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;

class InitialProfileSetupPage extends StatefulWidget {
  const InitialProfileSetupPage({super.key});

  @override
  State<InitialProfileSetupPage> createState() => _InitialProfileSetupPageState();
}

class _InitialProfileSetupPageState extends State<InitialProfileSetupPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  
  // Form values
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;
  String? _churchStatus;
  String? _profileImageUrl;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Homme', 'Femme'];
  final List<String> _maritalStatusOptions = ['Célibataire', 'Marié', 'Veuf/veuve'];
  final List<String> _churchStatusOptions = ['Membre', 'Visiteur'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _prefillFromAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressComplementController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationController.forward();
  }

  void _prefillFromAuth() {
    final user = AuthService.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.trim().split(' ');
        _firstNameController.text = nameParts.first;
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.skip(1).join(' ');
        }
      }
      
      if (user.photoURL != null) {
        _profileImageUrl = user.photoURL;
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes != null) {
        // Sauvegarder l'ancienne URL pour la supprimer après upload réussi
        final oldImageUrl = _profileImageUrl;
        
        // Upload to Firebase Storage instead of storing as base64
        final imageUrl = await ImageStorage.ImageStorageService.uploadImage(
          imageBytes,
          customPath: 'profiles/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        if (imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
          
          // Supprimer l'ancienne image si elle existe et est stockée sur Firebase
          if (oldImageUrl != null && 
              oldImageUrl.isNotEmpty && 
              ImageStorage.ImageStorageService.isFirebaseStorageUrl(oldImageUrl)) {
            ImageStorage.ImageStorageService.deleteImageByUrl(oldImageUrl);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image de profil mise à jour avec succès'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } else {
          throw Exception('Échec de l\'upload de l\'image vers Firebase Storage');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String? _buildFullAddress() {
    final parts = <String>[];
    
    if (_addressController.text.trim().isNotEmpty) {
      parts.add(_addressController.text.trim());
    }
    
    if (_addressComplementController.text.trim().isNotEmpty) {
      parts.add(_addressComplementController.text.trim());
    }
    
    final cityParts = <String>[];
    if (_postalCodeController.text.trim().isNotEmpty) {
      cityParts.add(_postalCodeController.text.trim());
    }
    if (_cityController.text.trim().isNotEmpty) {
      cityParts.add(_cityController.text.trim());
    }
    
    if (cityParts.isNotEmpty) {
      parts.add(cityParts.join(' '));
    }
    
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Get current profile
      final currentProfile = await AuthService.getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('Profil utilisateur non trouvé');
      }

      // Update profile with additional info
      final updatedProfile = currentProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _buildFullAddress(),
        birthDate: _birthDate,
        gender: _gender,
        maritalStatus: _maritalStatus,
        profileImageUrl: _profileImageUrl,
        updatedAt: DateTime.now(),
      );

      // Add church status as a role
      List<String> newRoles = List<String>.from(currentProfile.roles);
      if (_churchStatus != null) {
        // Remove existing church status roles
        newRoles.removeWhere((role) => role == 'Membre' || role == 'Visiteur');
        // Add new church status role
        newRoles.add(_churchStatus!);
      }

      final finalProfile = updatedProfile.copyWith(roles: newRoles);

      await AuthService.updateCurrentUserProfile(finalProfile);

      if (mounted) {
        // Navigate to main app
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la configuration: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildProgressIndicator(),
                      const SizedBox(height: 32),
                      _buildProfileForm(),
                      const SizedBox(height: 40),
                      _buildModernActionButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Configuration du profil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complétez votre profil pour accéder à l\'application',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Informations',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667EEA),
              ),
            ),
            Text(
              'Adresse',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Validation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildProfileImageSection(),
          const SizedBox(height: 32),
          _buildPersonalInfoSection(),
          const SizedBox(height: 24),
          _buildContactSection(),
          const SizedBox(height: 24),
          _buildAddressSection(),
          const SizedBox(height: 24),
          _buildStatusSection(),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Informations personnelles',
      icon: Icons.person_outline,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _firstNameController,
                label: 'Prénom *',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _lastNameController,
                label: 'Nom *',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderDropdown(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contact',
      icon: Icons.phone_outlined,
      children: [
        _buildModernTextField(
          controller: _phoneController,
          label: 'Téléphone *',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Le téléphone est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _buildSection(
      title: 'Adresse',
      icon: Icons.location_on_outlined,
      children: [
        _buildModernTextField(
          controller: _addressController,
          label: 'Adresse',
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _addressComplementController,
          label: 'Complément d\'adresse',
          icon: Icons.add_home_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildModernTextField(
                controller: _postalCodeController,
                label: 'Code postal',
                icon: Icons.local_post_office_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildModernTextField(
                controller: _cityController,
                label: 'Ville',
                icon: Icons.location_city_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _buildSection(
      title: 'Statut',
      icon: Icons.info_outline,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMaritalStatusDropdown(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChurchStatusDropdown(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectBirthDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF667EEA)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Date de naissance *',
                style: TextStyle(
                  fontSize: 16,
                  color: _birthDate != null 
                      ? const Color(0xFF1F2937) 
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Genre *',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF667EEA)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _genderOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _gender = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le genre est requis';
        }
        return null;
      },
    );
  }

  Widget _buildMaritalStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _maritalStatus,
      decoration: InputDecoration(
        labelText: 'Statut marital',
        prefixIcon: const Icon(Icons.favorite_outline, color: Color(0xFF667EEA)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _maritalStatusOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _maritalStatus = newValue;
        });
      },
    );
  }

  Widget _buildChurchStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _churchStatus,
      decoration: InputDecoration(
        labelText: 'Statut église',
        prefixIcon: const Icon(Icons.church_outlined, color: Color(0xFF667EEA)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _churchStatusOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _churchStatus = newValue;
        });
      },
    );
  }

  Widget _buildModernActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _completeSetup,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Finaliser la configuration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImageSection(),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone *',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le téléphone est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Adresse',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _gender,
                label: 'Genre *',
                icon: Icons.person_2,
                items: _genderOptions,
                onChanged: (value) => setState(() => _gender = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le genre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _maritalStatus,
                label: 'Statut marital',
                icon: Icons.favorite,
                items: _maritalStatusOptions,
                onChanged: (value) => setState(() => _maritalStatus = value),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _churchStatus,
                label: 'Statut par rapport à Jubilé Tabernacle',
                icon: Icons.church,
                items: _churchStatusOptions,
                onChanged: (value) => setState(() => _churchStatus = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImageUrl != null
                    ? (_profileImageUrl!.startsWith('data:')
                        ? Image.memory(
                            base64Decode(_profileImageUrl!.split(',')[1]),
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: _profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => _buildFallbackAvatar(),
                          ))
                    : _buildFallbackAvatar(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Changer la photo'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 60,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDateField() {
    return FormField<DateTime>(
      validator: (value) {
        if (_birthDate == null) {
          return 'La date de naissance est requise';
        }
        return null;
      },
      builder: (FormFieldState<DateTime> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError ? Colors.red : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _birthDate != null
                            ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                            : 'Date de naissance *',
                        style: TextStyle(
                          color: _birthDate != null
                              ? AppTheme.textPrimaryColor
                              : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: validator,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

}
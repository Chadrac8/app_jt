import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/user_profile_service.dart';
import '../services/roles_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../widgets/custom_page_app_bar.dart';
import '../widgets/admin_navigation_wrapper.dart';
import '../widgets/user_avatar.dart';
import '../extensions/datetime_extensions.dart';

import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;

class MemberProfilePage extends StatefulWidget {
  final PersonModel? person;

  const MemberProfilePage({super.key, this.person});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  PersonModel? _currentPerson;
  FamilyModel? _family;
  List<PersonModel> _familyMembers = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;
  String? _profileImageUrl;
  bool _hasImageChanged = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPersonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadPersonData() async {
    try {
      setState(() => _isLoading = true);
      
      // Charger le profil de l'utilisateur connecté
      PersonModel? person = await AuthService.getCurrentUserProfile();

      if (person == null) {
        // Fallback: essayer de créer le profil depuis Firebase Auth
        final user = AuthService.currentUser;
        if (user != null) {
          print('Tentative de création du profil pour ${user.uid}');
          await UserProfileService.ensureUserProfile(user);
          person = await AuthService.getCurrentUserProfile();
        }
      }

      if (person != null) {
        setState(() {
          _currentPerson = person;
          _initializeForm();
        });

        // Charger la famille si elle existe
        if (person.familyId != null) {
          try {
            final family = await FirebaseService.getFamily(person.familyId!);
            if (family != null) {
              setState(() {
                _family = family;
              });
              await _loadFamilyMembers();
            }
          } catch (e) {
            print('Erreur chargement famille: $e');
          }
        }

        // Charger les rôles
        await _loadRoles();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de charger votre profil'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement profil: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _initializeForm() {
    if (_currentPerson != null) {
      _firstNameController.text = _currentPerson!.firstName;
      _lastNameController.text = _currentPerson!.lastName;
      _emailController.text = _currentPerson!.email;
      _phoneController.text = _currentPerson!.phone ?? '';
      _addressController.text = _currentPerson!.address ?? '';
      _birthDate = _currentPerson!.birthDate;
      _gender = _currentPerson!.gender;
      _maritalStatus = _currentPerson!.maritalStatus;
      _profileImageUrl = _currentPerson!.profileImageUrl;
    }
  }

  Future<void> _loadFamilyMembers() async {
    if (_family == null) return;

    try {
      final members = <PersonModel>[];
      for (final memberId in _family!.memberIds) {
        final member = await FirebaseService.getPerson(memberId);
        if (member != null) {
          members.add(member);
        }
      }
      setState(() {
        _familyMembers = members;
      });
    } catch (e) {
      print('Erreur chargement famille: $e');
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RolesFirebaseService.getRolesStream(activeOnly: true).first;
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      print('Erreur chargement rôles: $e');
    }
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      
      if (imageBytes != null) {
        // Sauvegarder l'ancienne URL pour la supprimer après upload réussi
        final oldImageUrl = _profileImageUrl;
        
        // Obtenir l'ID de l'utilisateur actuel pour respecter les règles de sécurité Firebase
        final userId = _currentPerson?.id ?? 'unknown';
        
        // Upload to Firebase Storage avec le bon chemin selon les règles de sécurité
        final imageUrl = await ImageStorage.ImageStorageService.uploadImage(
          imageBytes,
          customPath: 'profiles/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        if (imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
            _hasImageChanged = true;
          });
          
          // Sauvegarder automatiquement l'image de profil mise à jour
          if (_currentPerson != null) {
            try {
              final updatedPerson = _currentPerson!.copyWith(
                profileImageUrl: imageUrl,
                updatedAt: DateTime.now(),
              );
              
              await AuthService.updateCurrentUserProfile(updatedPerson);
              
              setState(() {
                _currentPerson = updatedPerson;
                _hasImageChanged = false;
              });
            } catch (e) {
              print('Erreur lors de la sauvegarde: $e');
            }
          }
          
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
                backgroundColor: AppTheme.successColor,
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
            content: Text('Erreur lors de la sélection de l\'image : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showFamilyManagementDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Gestion de famille'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Que souhaitez-vous faire ?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer\nune famille'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'join'),
                      icon: const Icon(Icons.group_add),
                      label: const Text('Rejoindre\nune famille'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (choice == 'create') {
      await _createFamily();
    } else if (choice == 'join') {
      await _joinFamily();
    }
  }

  Future<void> _createFamily() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Créer une famille'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom de famille',
                      hintText: 'ex: Famille Martin',
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom de famille est requis';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse familiale (optionnel)',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone familial (optionnel)',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );

    if (result == true && _currentPerson != null) {
      try {
        final newFamily = FamilyModel(
          id: '',
          name: nameController.text.trim(),
          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
          homePhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          headOfFamilyId: _currentPerson!.id,
          memberIds: [_currentPerson!.id],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final familyId = await FirebaseService.createFamily(newFamily);
        
        // Mettre à jour la personne avec l'ID de famille
        final updatedPerson = _currentPerson!.copyWith(
          familyId: familyId,
          updatedAt: DateTime.now(),
        );
        
        await AuthService.updateCurrentUserProfile(updatedPerson);
        
        // Recharger les données
        await _loadPersonData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Famille "${nameController.text.trim()}" créée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la création de la famille : $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _joinFamily() async {
    try {
      final families = await FirebaseService.getFamiliesStream().first;
      
      if (!mounted) return;

      final selectedFamily = await showDialog<FamilyModel>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text('Rejoindre une famille'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: families.isEmpty
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucune famille disponible'),
                        SizedBox(height: 8),
                        Text(
                          'Demandez à un membre de votre famille de créer une famille d\'abord.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: families.length,
                      itemBuilder: (context, index) {
                        final family = families[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.home,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(
                              family.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${family.memberIds.length} membre(s)'),
                                if (family.address != null)
                                  Text(
                                    family.address!,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                            onTap: () => Navigator.pop(context, family),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (selectedFamily != null && _currentPerson != null) {
        await FirebaseService.addPersonToFamily(_currentPerson!.id, selectedFamily.id);
        
        // Recharger les données
        await _loadPersonData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous avez rejoint la famille "${selectedFamily.name}"'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la tentative de rejoindre la famille : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_currentPerson == null) return;

    try {
      final updatedPerson = _currentPerson!.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        birthDate: _birthDate,
        gender: _gender,
        maritalStatus: _maritalStatus,
        profileImageUrl: _profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await AuthService.updateCurrentUserProfile(updatedPerson);

      setState(() {
        _currentPerson = updatedPerson;
        _isEditing = false;
        _hasImageChanged = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildSliverAppBar(),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Informations'),
                            Tab(text: 'Famille'),
                            Tab(text: 'Rôles'),
                            Tab(text: 'Historique'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildInformationTab(),
                    _buildFamilyTab(),
                    _buildRolesTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              _buildProfileImage(),
              const SizedBox(height: 20),
              if (_currentPerson != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _currentPerson!.fullName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentPerson!.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_currentPerson!.roles.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _currentPerson!.roles.map((role) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      actions: [
        // Toggle to admin view
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNavigationWrapper(),
                ),
              );
            },
            tooltip: 'Vue Administrateur',
            iconSize: 20,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: Icon(_isEditing ? Icons.save : Icons.edit),
          onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return ProfileUserAvatar(
      person: _currentPerson,
      isEditable: true,
      onTap: _pickProfileImage,
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Adresse',
                icon: Icons.location_on_outlined,
                enabled: _isEditing,
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informations personnelles',
            icon: Icons.info_outline,
            children: [
              _buildDateField(),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _gender,
                label: 'Genre',
                icon: Icons.wc,
                items: _genderOptions,
                onChanged: _isEditing ? (value) => setState(() => _gender = value) : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _maritalStatus,
                label: 'Statut marital',
                icon: Icons.favorite_outline,
                items: _maritalStatusOptions,
                onChanged: _isEditing ? (value) => setState(() => _maritalStatus = value) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_family != null) ...[
            _buildInfoCard(
              title: 'Famille : ${_family!.name}',
              icon: Icons.family_restroom,
              children: [
                if (_family!.address != null)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse familiale',
                    value: _family!.address!,
                  ),
                if (_family!.homePhone != null)
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Téléphone familial',
                    value: _family!.homePhone!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Membres de la famille',
              icon: Icons.people,
              children: _familyMembers
                  .map((member) => _buildFamilyMemberItem(member))
                  .toList(),
            ),
          ] else
            _buildInfoCard(
              title: 'Famille',
              icon: Icons.family_restroom,
              children: [
                const Text(
                  'Aucune famille associée',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showFamilyManagementDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer ou rejoindre une famille'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Mes rôles',
            icon: Icons.badge,
            children: _currentPerson?.roles.isNotEmpty == true
                ? _currentPerson!.roles.map((roleId) {
                    try {
                      final role = _roles.firstWhere((r) => r.id == roleId);
                      return _buildRoleItem(role);
                    } catch (e) {
                      return _buildRoleItem(RoleModel(
                        id: roleId,
                        name: roleId,
                        description: '',
                        color: '#6F61EF',
                        permissions: [],
                        icon: 'star',
                        isActive: true,
                        createdAt: DateTime.now(),
                      ));
                    }
                  }).toList()
                : [
                    const Text(
                      'Aucun rôle assigné',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Historique des interactions',
            icon: Icons.history,
            children: [
              _buildHistoryItem(
                'Inscription à l\'église',
                _currentPerson?.createdAt ?? DateTime.now(),
                Icons.church,
                AppTheme.primaryColor,
              ),
              _buildHistoryItem(
                'Dernière mise à jour du profil',
                _currentPerson?.updatedAt ?? DateTime.now(),
                Icons.edit,
                AppTheme.secondaryColor,
              ),
              // TODO: Ajouter plus d'historique depuis les logs d'activité
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    bool enabled = true,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: onChanged == null,
        fillColor: onChanged == null ? Colors.grey[100] : null,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _isEditing ? _selectBirthDate : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: _isEditing ? null : Colors.grey[100],
        ),
        child: Text(
          _birthDate != null
              ? _birthDate!.shortDate
              : 'Non renseignée',
          style: TextStyle(
            color: _birthDate != null
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberItem(PersonModel member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(member.displayInitials)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (_family?.headOfFamilyId == member.id)
                  const Text(
                    'Chef de famille',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(RoleModel role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(int.parse(role.color.replaceFirst('#', '0xFF')))
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(int.parse(role.color.replaceFirst('#', '0xFF')))
                .withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconFromString(role.icon),
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (role.description.isNotEmpty)
                    Text(
                      role.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, DateTime date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  date.mediumDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'church':
        return Icons.church;
      case 'groups':
        return Icons.groups;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
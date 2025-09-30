import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/person_model.dart';
import '../services/family_service.dart';
import '../../theme.dart';

// Mutable version of EmergencyContact for form editing
class MutableEmergencyContact {
  String id;
  String name;
  String phone;
  String? email;
  String relationship;
  bool isPrimary;
  String? notes;

  MutableEmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.relationship,
    this.isPrimary = false,
    this.notes,
  });

  factory MutableEmergencyContact.fromEmergencyContact(EmergencyContact contact) {
    return MutableEmergencyContact(
      id: contact.id,
      name: contact.name,
      phone: contact.phone,
      email: contact.email,
      relationship: contact.relationship,
      isPrimary: contact.isPrimary,
      notes: contact.notes,
    );
  }

  EmergencyContact toEmergencyContact() {
    return EmergencyContact(
      id: id,
      name: name,
      phone: phone,
      email: email,
      relationship: relationship,
      isPrimary: isPrimary,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'notes': notes,
    };
  }
}

class FamilyFormEnhancedPage extends StatefulWidget {
  final Map<String, dynamic>? familyData;
  
  const FamilyFormEnhancedPage({Key? key, this.familyData}) : super(key: key);

  @override
  State<FamilyFormEnhancedPage> createState() => _FamilyFormEnhancedPageState();
}

class _FamilyFormEnhancedPageState extends State<FamilyFormEnhancedPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Basic info controllers
  final _familyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Address controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  
  // Family details
  String _selectedFamilyType = 'Nuclear';
  String _selectedLanguage = 'French';
  List<String> _selectedInterests = [];
  List<String> _allergies = [];
  
  // Communication preferences
  bool _allowEmails = true;
  bool _allowSMS = true;
  bool _allowCalls = true;
  bool _allowWhatsApp = false;
  bool _allowNewsletter = true;
  String _preferredContactMethod = 'email';
  List<String> _contactTimes = [];
  
  // Social media
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  // Emergency contacts
  List<MutableEmergencyContact> _emergencyContacts = [];
  
  // Family members
  List<String> _selectedMemberIds = [];
  List<Map<String, dynamic>> _availablePersons = [];
  String? _familyHeadId;
  
  // Form state
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isEdit = false;
  
  // Available options
  final List<String> _familyTypes = [
    'Nuclear', 'Extended', 'Single', 'Blended', 'Adoptive', 'Foster', 'Childless', 'Other'
  ];
  
  final List<String> _languages = [
    'French', 'English', 'Spanish', 'Portuguese', 'German', 'Italian', 'Other'
  ];
  
  final List<String> _interestOptions = [
    'Musique', 'Sport', 'Lecture', 'Cuisine', 'Jardinage', 'Voyage', 'Art', 
    'Technologie', 'Bénévolat', 'Éducation', 'Santé', 'Nature'
  ];
  
  final List<String> _contactMethods = [
    'email', 'phone', 'sms', 'whatsapp', 'post'
  ];
  
  final List<String> _timeSlots = [
    'Matin (8h-12h)', 'Après-midi (12h-17h)', 'Soirée (17h-20h)', 'Weekend'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadAvailablePersons();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.familyData != null) {
      _isEdit = true;
      final family = widget.familyData!;
      
      _familyNameController.text = family['familyName'] ?? '';
      _phoneController.text = family['phone'] ?? '';
      _emailController.text = family['email'] ?? '';
      _notesController.text = family['notes'] ?? '';
      
      // Address
      final address = family['address'] as Map<String, dynamic>?;
      if (address != null) {
        _streetController.text = address['street'] ?? '';
        _cityController.text = address['city'] ?? '';
        _regionController.text = address['region'] ?? '';
        _postalCodeController.text = address['postalCode'] ?? '';
        _countryController.text = address['country'] ?? '';
      }
      
      // Family details
      _selectedFamilyType = family['familyType'] ?? 'Nuclear';
      _selectedLanguage = family['primaryLanguage'] ?? 'French';
      _selectedInterests = List<String>.from(family['interests'] ?? []);
      _allergies = List<String>.from(family['allergies'] ?? []);
      
      // Communication preferences
      final commPrefs = family['communicationPreferences'] as Map<String, dynamic>?;
      if (commPrefs != null) {
        _allowEmails = commPrefs['allowEmails'] ?? true;
        _allowSMS = commPrefs['allowSMS'] ?? true;
        _allowCalls = commPrefs['allowCalls'] ?? true;
        _allowWhatsApp = commPrefs['allowWhatsApp'] ?? false;
        _allowNewsletter = commPrefs['allowNewsletter'] ?? true;
        _preferredContactMethod = commPrefs['preferredMethod'] ?? 'email';
        _contactTimes = List<String>.from(commPrefs['preferredTimes'] ?? []);
      }
      
      // Social media
      final socialMedia = family['socialMedia'] as Map<String, dynamic>?;
      if (socialMedia != null) {
        _facebookController.text = socialMedia['facebook'] ?? '';
        _instagramController.text = socialMedia['instagram'] ?? '';
        _twitterController.text = socialMedia['twitter'] ?? '';
        _linkedinController.text = socialMedia['linkedin'] ?? '';
      }
      
      // Emergency contacts
      final emergencyContacts = family['emergencyContacts'] as List<dynamic>?;
      if (emergencyContacts != null) {
        _emergencyContacts = emergencyContacts.map((contact) => 
          MutableEmergencyContact.fromEmergencyContact(EmergencyContact.fromMap(contact))
        ).toList();
      }
      
      // Members
      _selectedMemberIds = List<String>.from(family['memberIds'] ?? []);
      _familyHeadId = family['familyHeadId'];
    } else {
      // Default values for new family
      _countryController.text = 'France';
      _emergencyContacts.add(MutableEmergencyContact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        phone: '',
        relationship: '',
        email: '',
      ));
    }
  }

  Future<void> _loadAvailablePersons() async {
    try {
      // This would need to be implemented in FirebaseService
      // For now, we'll use a placeholder
      setState(() {
        _availablePersons = [];
      });
    } catch (e) {
      print('Error loading persons: $e');
    }
  }

  Future<void> _validateAndSave() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Veuillez corriger les erreurs dans le formulaire');
      return;
    }
    
    // Additional validations
    if (_selectedMemberIds.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner au moins un membre de famille');
      return;
    }
    
    if (_familyHeadId == null) {
      _showErrorSnackBar('Veuillez désigner un chef de famille');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Build family data
      Map<String, dynamic> familyData = {
        'familyName': _familyNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'notes': _notesController.text.trim(),
        'familyType': _selectedFamilyType,
        'primaryLanguage': _selectedLanguage,
        'interests': _selectedInterests,
        'allergies': _allergies,
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'region': _regionController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
        'communicationPreferences': {
          'allowEmails': _allowEmails,
          'allowSMS': _allowSMS,
          'allowCalls': _allowCalls,
          'allowWhatsApp': _allowWhatsApp,
          'allowNewsletter': _allowNewsletter,
          'preferredMethod': _preferredContactMethod,
          'preferredTimes': _contactTimes,
        },
        'socialMedia': {
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'twitter': _twitterController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
        },
        'emergencyContacts': _emergencyContacts.map((contact) => contact.toMap()).toList(),
        'memberIds': _selectedMemberIds,
        'familyHeadId': _familyHeadId,
        'memberCount': _selectedMemberIds.length,
      };
      
      // Validate data
      Map<String, dynamic> validation = await FamilyService.validateFamilyData(familyData);
      
      if (!validation['isValid']) {
        List<String> errors = List<String>.from(validation['errors']);
        _showErrorSnackBar('Erreurs de validation: ${errors.join(', ')}');
        setState(() => _isLoading = false);
        return;
      }
      
      // Show warnings if any
      List<String> warnings = List<String>.from(validation['warnings']);
      if (warnings.isNotEmpty) {
        bool? proceed = await _showWarningDialog(
          'Avertissements',
          'Les avertissements suivants ont été détectés:\n${warnings.join('\n')}\n\nContinuer quand même ?',
        );
        if (proceed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      // Save family
      String? familyId;
      if (_isEdit) {
        bool success = await FamilyService.updateFamilyFromMap(widget.familyData!['id'], familyData);
        if (success) {
          familyId = widget.familyData!['id'];
        }
      } else {
        familyId = await FamilyService.createFamilyFromMap(familyData);
      }
      
      if (familyId != null) {
        _showSuccessSnackBar(_isEdit ? 'Famille mise à jour' : 'Famille créée avec succès');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Erreur lors de la sauvegarde');
      }
      
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addEmergencyContact() {
    setState(() {
      _emergencyContacts.add(MutableEmergencyContact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        phone: '',
        relationship: '',
        email: '',
      ));
    });
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  void _addAllergy() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter une allergie'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Allergie',
              hintText: 'Ex: Arachides, Lactose...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _allergies.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showWarningDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.redStandard,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.greenStandard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la famille' : 'Nouvelle famille'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Step labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepLabel('Info', 0),
                  _buildStepLabel('Adresse', 1),
                  _buildStepLabel('Contact', 2),
                  _buildStepLabel('Urgence', 3),
                  _buildStepLabel('Membres', 4),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildBasicInfoStep(),
                  _buildAddressStep(),
                  _buildContactStep(),
                  _buildEmergencyStep(),
                  _buildMembersStep(),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _currentStep < 4
                              ? _nextStep
                              : _validateAndSave,
                      child: Text(_currentStep < 4 ? 'Suivant' : 'Enregistrer'),
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

  Widget _buildStepLabel(String label, int step) {
    bool isActive = step == _currentStep;
    bool isCompleted = step < _currentStep;
    
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? AppTheme.fontBold : FontWeight.normal,
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : isCompleted
                ? AppTheme.greenStandard
                : AppTheme.grey500,
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de base',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _familyNameController,
            decoration: const InputDecoration(
              labelText: 'Nom de famille *',
              prefixIcon: Icon(Icons.family_restroom),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom de famille est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedFamilyType,
            decoration: const InputDecoration(
              labelText: 'Type de famille',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: _familyTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) => setState(() => _selectedFamilyType = value!),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Langue principale',
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
            items: _languages.map((lang) => DropdownMenuItem(
              value: lang,
              child: Text(lang),
            )).toList(),
            onChanged: (value) => setState(() => _selectedLanguage = value!),
          ),
          const SizedBox(height: 16),
          
          // Interests
          Text(
            'Centres d\'intérêt',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestOptions.map((interest) {
              bool isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Allergies
          Row(
            children: [
              Text(
                'Allergies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: _addAllergy,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies.map((allergy) => Chip(
              label: Text(allergy),
              onDeleted: () {
                setState(() => _allergies.remove(allergy));
              },
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adresse',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Rue',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Code postal',
                    prefixIcon: Icon(Icons.local_post_office),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _regionController,
            decoration: const InputDecoration(
              labelText: 'Région/État',
              prefixIcon: Icon(Icons.map),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _countryController,
            decoration: const InputDecoration(
              labelText: 'Pays',
              prefixIcon: Icon(Icons.public),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de contact',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                  return 'Format d\'email invalide';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          Text(
            'Préférences de communication',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Emails'),
            subtitle: const Text('Recevoir des emails'),
            value: _allowEmails,
            onChanged: (value) => setState(() => _allowEmails = value),
          ),
          
          SwitchListTile(
            title: const Text('SMS'),
            subtitle: const Text('Recevoir des SMS'),
            value: _allowSMS,
            onChanged: (value) => setState(() => _allowSMS = value),
          ),
          
          SwitchListTile(
            title: const Text('Appels téléphoniques'),
            subtitle: const Text('Recevoir des appels'),
            value: _allowCalls,
            onChanged: (value) => setState(() => _allowCalls = value),
          ),
          
          SwitchListTile(
            title: const Text('WhatsApp'),
            subtitle: const Text('Recevoir des messages WhatsApp'),
            value: _allowWhatsApp,
            onChanged: (value) => setState(() => _allowWhatsApp = value),
          ),
          
          SwitchListTile(
            title: const Text('Newsletter'),
            subtitle: const Text('Recevoir la newsletter'),
            value: _allowNewsletter,
            onChanged: (value) => setState(() => _allowNewsletter = value),
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _preferredContactMethod,
            decoration: const InputDecoration(
              labelText: 'Méthode de contact préférée',
              border: OutlineInputBorder(),
            ),
            items: _contactMethods.map((method) => DropdownMenuItem(
              value: method,
              child: Text(method),
            )).toList(),
            onChanged: (value) => setState(() => _preferredContactMethod = value!),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Créneaux de contact préférés',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((timeSlot) {
              bool isSelected = _contactTimes.contains(timeSlot);
              return FilterChip(
                label: Text(timeSlot),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _contactTimes.add(timeSlot);
                    } else {
                      _contactTimes.remove(timeSlot);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Réseaux sociaux',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _facebookController,
            decoration: const InputDecoration(
              labelText: 'Facebook',
              prefixIcon: Icon(Icons.facebook),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _instagramController,
            decoration: const InputDecoration(
              labelText: 'Instagram',
              prefixIcon: Icon(Icons.camera_alt),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _twitterController,
            decoration: const InputDecoration(
              labelText: 'Twitter',
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _linkedinController,
            decoration: const InputDecoration(
              labelText: 'LinkedIn',
              prefixIcon: Icon(Icons.work),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contacts d\'urgence',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                onPressed: _addEmergencyContact,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_emergencyContacts.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.contact_emergency,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun contact d\'urgence',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addEmergencyContact,
                    child: const Text('Ajouter un contact'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _emergencyContacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Contact ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _removeEmergencyContact(index),
                              icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          initialValue: contact.name,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet *',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => contact.name = value,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          initialValue: contact.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) => contact.phone = value,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le téléphone est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          initialValue: contact.relationship,
                          decoration: const InputDecoration(
                            labelText: 'Relation *',
                            hintText: 'Ex: Frère, Ami, Voisin...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => contact.relationship = value,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La relation est requise';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          initialValue: contact.email,
                          decoration: const InputDecoration(
                            labelText: 'Email (optionnel)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => contact.email = value,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                                return 'Format d\'email invalide';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMembersStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membres de la famille',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          if (_availablePersons.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune personne disponible',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez d\'abord des personnes dans le système',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Selected members count
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedMemberIds.length} membre(s) sélectionné(s)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Family head selection
                if (_selectedMemberIds.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _familyHeadId,
                    decoration: const InputDecoration(
                      labelText: 'Chef de famille *',
                      border: OutlineInputBorder(),
                    ),
                    items: _selectedMemberIds.map((id) {
                      final person = _availablePersons.firstWhere((p) => p['id'] == id);
                      return DropdownMenuItem(
                        value: id,
                        child: Text('${person['firstName']} ${person['lastName']}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _familyHeadId = value),
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez désigner un chef de famille';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Available persons list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availablePersons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final person = _availablePersons[index];
                    final personId = person['id'] as String;
                    final isSelected = _selectedMemberIds.contains(personId);
                    
                    return Card(
                      child: CheckboxListTile(
                        title: Text('${person['firstName']} ${person['lastName']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (person['dateOfBirth'] != null)
                              Text('Né(e) le: ${person['dateOfBirth']}'),
                            if (person['phone'] != null)
                              Text('Tel: ${person['phone']}'),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedMemberIds.add(personId);
                            } else {
                              _selectedMemberIds.remove(personId);
                              if (_familyHeadId == personId) {
                                _familyHeadId = null;
                              }
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
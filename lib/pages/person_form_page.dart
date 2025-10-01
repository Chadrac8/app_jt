import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/roles_firebase_service.dart';
import '../widgets/custom_fields_widget.dart';
import '../widgets/family_info_widget.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;
import 'firebase_storage_diagnostic_page.dart';
import '../utils/performance_utils.dart';
import '../../theme.dart';

class PersonFormPage extends StatefulWidget {
  final PersonModel? person;

  const PersonFormPage({super.key, this.person});

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _privateNotesController = TextEditingController();
  
  // Form values
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;
  List<String> _children = [];
  List<String> _tags = [];
  List<String> _roles = [];
  Map<String, dynamic> _customFields = {};
  bool _isActive = true;
  bool _isLoading = false;
  
  // Image handling
  String? _profileImageUrl;
  String? _countryCode;
  String? _country;
  
  // Performance controller
  late PersonFormController _formController;
  
  void _markAsChanged() {
    _formController.markAsChanged();
  }

  final List<String> _genderOptions = ['Homme', 'Femme'];
  final List<String> _maritalStatusOptions = [
    'Célibataire',
    'Marié(e)',
    'Veuf/Veuve'
  ];

  // Indicatifs de pays (version courte pour person_form_page)
  final Map<String, String> _countryCodes = {
    '+33': 'France',
    '+1': 'États-Unis/Canada',
    '+32': 'Belgique',
    '+41': 'Suisse',
    '+49': 'Allemagne',
    '+39': 'Italie',
    '+34': 'Espagne',
    '+44': 'Royaume-Uni',
    '+351': 'Portugal',
    '+31': 'Pays-Bas',
    '+43': 'Autriche',
    '+212': 'Maroc',
    '+213': 'Algérie',
    '+216': 'Tunisie',
    '+221': 'Sénégal',
    '+225': 'Côte d\'Ivoire',
    '+237': 'Cameroun',
    '+242': 'République du Congo',
    '+243': 'République démocratique du Congo',
    '+262': 'La Réunion',
    '+590': 'Guadeloupe',
    '+594': 'Guyane française',
    '+596': 'Martinique',
  };

  // Liste des pays principaux
  final List<String> _countries = [
    'France',
    'Belgique',
    'Suisse',
    'Canada',
    'États-Unis',
    'Allemagne',
    'Italie',
    'Espagne',
    'Royaume-Uni',
    'Portugal',
    'Pays-Bas',
    'Autriche',
    'Maroc',
    'Algérie',
    'Tunisie',
    'Sénégal',
    'Côte d\'Ivoire',
    'Cameroun',
    'République du Congo',
    'République démocratique du Congo',
    'La Réunion',
    'Guadeloupe',
    'Guyane française',
    'Martinique',
  ];

  // Mapping des pays vers leurs indicatifs principaux
  final Map<String, String> _countryToCountryCode = {
    'France': '+33',
    'Belgique': '+32',
    'Suisse': '+41',
    'Canada': '+1',
    'États-Unis': '+1',
    'Allemagne': '+49',
    'Italie': '+39',
    'Espagne': '+34',
    'Royaume-Uni': '+44',
    'Portugal': '+351',
    'Pays-Bas': '+31',
    'Autriche': '+43',
    'Maroc': '+212',
    'Algérie': '+213',
    'Tunisie': '+216',
    'Sénégal': '+221',
    'Côte d\'Ivoire': '+225',
    'Cameroun': '+237',
    'République du Congo': '+242',
    'République démocratique du Congo': '+243',
    'La Réunion': '+262',
    'Guadeloupe': '+590',
    'Guyane française': '+594',
    'Martinique': '+596',
  };

  @override
  void initState() {
    super.initState();
    
    // Initialiser le contrôleur de performance
    _formController = PersonFormController();
    
    // Valeurs par défaut
    _countryCode = '+33'; // France par défaut
    _country = 'France'; // France par défaut
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _initializeForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressComplementController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _privateNotesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.person != null) {
      final person = widget.person!;
      _firstNameController.text = person.firstName;
      _lastNameController.text = person.lastName;
      _emailController.text = person.email;
      _parseExistingPhone(person.phone);
      _parseExistingAddress(person.address);
      _privateNotesController.text = person.privateNotes ?? '';
      _birthDate = person.birthDate;
      _gender = person.gender;
      _maritalStatus = person.maritalStatus;
      _children = List.from(person.children);
      _tags = List.from(person.tags);
      _roles = List.from(person.roles);
      _customFields = Map.from(person.customFields);
      _isActive = person.isActive;
      _profileImageUrl = person.profileImageUrl;
    }
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _birthDate = date;
      });
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

  String? _buildFullPhone() {
    if (_phoneController.text.trim().isNotEmpty && _countryCode != null) {
      return '$_countryCode ${_phoneController.text.trim()}';
    }
    return _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
  }

  void _parseExistingPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      _phoneController.clear();
      _countryCode = '+33';
      _country = 'France';
      return;
    }

    // Rechercher un code de pays dans le numéro de téléphone
    for (var entry in _countryCodes.entries) {
      if (phone.startsWith(entry.value)) {
        _countryCode = entry.value;
        _country = entry.key;
        // Extraire le numéro sans le code pays
        _phoneController.text = phone.substring(entry.value.length).trim();
        return;
      }
    }

    // Si aucun code pays trouvé, utiliser France par défaut
    _phoneController.text = phone;
    _countryCode = '+33';
    _country = 'France';
  }

  void _parseExistingAddress(String? address) {
    if (address == null || address.isEmpty) {
      _addressController.clear();
      _addressComplementController.clear();
      _postalCodeController.clear();
      _cityController.clear();
      return;
    }

    // Tentative de parsing intelligent de l'adresse
    final parts = address.split(', ');
    
    if (parts.length >= 3) {
      // Format attendu: "Adresse, Complément, Code Ville"
      _addressController.text = parts[0].trim();
      _addressComplementController.text = parts[1].trim();
      
      // Essayer de séparer code postal et ville du dernier élément
      final lastPart = parts.last.trim();
      final codeVilleMatch = RegExp(r'^(\d{5})\s+(.+)$').firstMatch(lastPart);
      
      if (codeVilleMatch != null) {
        _postalCodeController.text = codeVilleMatch.group(1) ?? '';
        _cityController.text = codeVilleMatch.group(2) ?? '';
      } else {
        _postalCodeController.clear();
        _cityController.text = lastPart;
      }
    } else if (parts.length == 2) {
      // Format: "Adresse, Code Ville"
      _addressController.text = parts[0].trim();
      _addressComplementController.clear();
      
      final lastPart = parts[1].trim();
      final codeVilleMatch = RegExp(r'^(\d{5})\s+(.+)$').firstMatch(lastPart);
      
      if (codeVilleMatch != null) {
        _postalCodeController.text = codeVilleMatch.group(1) ?? '';
        _cityController.text = codeVilleMatch.group(2) ?? '';
      } else {
        _postalCodeController.clear();
        _cityController.text = lastPart;
      }
    } else {
      // Fallback: tout dans l'adresse principale
      _addressController.text = address;
      _addressComplementController.clear();
      _postalCodeController.clear();
      _cityController.clear();
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      setState(() => _isLoading = true);
      
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
            content: Text('Erreur lors de la sélection d\'image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Diagnostic',
              textColor: AppTheme.white100,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FirebaseStorageDiagnosticPage(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addChild() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un enfant'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nom de l\'enfant',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _children.add(controller.text);
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

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nom du tag',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _tags.add(controller.text);
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

  void _selectRoles() {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<RoleModel>>(
          stream: RolesFirebaseService.getRolesStream(activeOnly: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Erreur'),
                content: Text('Impossible de charger les rôles: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              );
            }

            final roles = snapshot.data ?? [];
            final selectedRoleIds = Set<String>.from(_roles);

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Sélectionner les rôles'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: roles.isEmpty
                        ? const Center(
                            child: Text('Aucun rôle disponible'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: roles.length,
                            itemBuilder: (context, index) {
                              final role = roles[index];
                              final isSelected = selectedRoleIds.contains(role.id);
                              
                              return CheckboxListTile(
                                title: Text(role.name),
                                subtitle: role.description.isNotEmpty 
                                    ? Text(role.shortDescription)
                                    : null,
                                value: isSelected,
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedRoleIds.add(role.id);
                                    } else {
                                      selectedRoleIds.remove(role.id);
                                    }
                                  });
                                },
                                secondary: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  ),
                                  child: Icon(
                                    _getIconData(role.icon),
                                    color: AppTheme.white100,
                                    size: 20,
                                  ),
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
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _roles = selectedRoleIds.toList();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Confirmer'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'security': return Icons.security;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'church': return Icons.church;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'person': return Icons.person;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'groups': return Icons.groups;
      case 'event': return Icons.event;
      case 'assignment': return Icons.assignment;
      case 'description': return Icons.description;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'manage_accounts': return Icons.manage_accounts;
      case 'psychology': return Icons.psychology;
      case 'music_note': return Icons.music_note;
      case 'mic': return Icons.mic;
      case 'campaign': return Icons.campaign;
      case 'handshake': return Icons.handshake;
      default: return Icons.security;
    }
  }

  Widget _buildCountryCodeDropdown() {
    return DropdownSearch<String>(
      selectedItem: _countryCode,
      items: _countryCodes.values.toList(),
      itemAsString: (code) => code,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Indicatif',
          prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF667EEA)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.grey500),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.grey500),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Rechercher un indicatif...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
        itemBuilder: (context, item, isSelected) {
          // Trouver le pays correspondant à ce code
          String country = '';
          for (var entry in _countryCodes.entries) {
            if (entry.value == item) {
              country = entry.key;
              break;
            }
          }
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  item,
                  style: const TextStyle(fontWeight: AppTheme.fontBold),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    country,
                    style: TextStyle(
                      color: AppTheme.grey600,
                      fontSize: AppTheme.fontSize13,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        fit: FlexFit.loose,
      ),
      filterFn: (item, filter) {
        // Recherche par code ou par nom de pays
        String country = '';
        for (var entry in _countryCodes.entries) {
          if (entry.value == item) {
            country = entry.key;
            break;
          }
        }
        return item.toLowerCase().contains(filter.toLowerCase()) ||
            country.toLowerCase().contains(filter.toLowerCase());
      },
      onChanged: (String? newValue) {
        setState(() {
          _countryCode = newValue;
        });
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownSearch<String>(
      selectedItem: _country,
      items: _countries,
      itemAsString: (country) => country,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Pays',
          prefixIcon: const Icon(Icons.public_outlined, color: Color(0xFF667EEA)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.grey500),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.grey500),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Rechercher un pays...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
        fit: FlexFit.loose,
      ),
      filterFn: (item, filter) {
        return item.toLowerCase().contains(filter.toLowerCase());
      },
      onChanged: (String? newValue) {
        setState(() {
          _country = newValue;
          // Remplissage automatique de l'indicatif basé sur le pays choisi
          if (newValue != null && _countryToCountryCode.containsKey(newValue)) {
            _countryCode = _countryToCountryCode[newValue];
          }
        });
      },
    );
  }

  Future<List<Widget>> _buildRoleChips() async {
    final List<Widget> chips = [];
    
    for (int i = 0; i < _roles.length; i++) {
      final roleId = _roles[i];
      try {
        final role = await RolesFirebaseService.getRole(roleId);
        if (role != null) {
          chips.add(
            Chip(
              avatar: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  _getIconData(role.icon),
                  color: AppTheme.white100,
                  size: 12,
                ),
              ),
              label: Text(role.name),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _roles.removeAt(i);
                });
              },
              backgroundColor: Color(int.parse(role.color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
              side: BorderSide(
                color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
              ),
            ),
          );
        }
      } catch (e) {
        // Si le rôle ne peut pas être chargé, on affiche quand même quelque chose
        chips.add(
          Chip(
            label: const Text('Rôle inconnu'),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                _roles.removeAt(i);
              });
            },
            backgroundColor: AppTheme.grey500.withOpacity(0.1),
            side: BorderSide(
              color: AppTheme.grey500.withOpacity(0.3),
            ),
          ),
        );
      }
    }
    
    return chips;
  }

  Future<void> _savePerson() async {
    print('=== DÉBUT SAUVEGARDE ===');
    print('Bouton "Sauvegarder" cliqué');
    print('_isLoading: $_isLoading');
    
    // Vérifier si déjà en cours de sauvegarde
    if (_isLoading) {
      print('Sauvegarde déjà en cours, arrêt de l\'exécution');
      return;
    }
    
    // Marquer les changements avec le contrôleur
    _formController.markAsChanged();
    
    // Vérifier la validité du formulaire
    if (_formKey.currentState == null) {
      print('ERREUR: _formKey.currentState est null!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: Formulaire non initialisé'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    
    print('Vérification de la validation du formulaire...');
    if (!_formKey.currentState!.validate()) {
      print('ERREUR: Validation du formulaire échouée');
      
      // Afficher un message d'erreur plus informatif
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez corriger les erreurs dans le formulaire'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    print('Validation du formulaire réussie');
    print('Nom: ${_firstNameController.text.trim()}');
    print('Prenom: ${_lastNameController.text.trim()}');
    print('Email: ${_emailController.text.trim()}');
    
    setState(() {
      _isLoading = true;
    });
    _formController.setLoading(true);

    try {
      final now = DateTime.now();
      
      if (widget.person == null) {
        print('Mode: Création d\'une nouvelle personne');
        // Create new person
        final newPerson = PersonModel(
          id: '',
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _buildFullPhone(),
          birthDate: _birthDate,
          address: _buildFullAddress(),
          gender: _gender,
          maritalStatus: _maritalStatus,
          children: _children,
          profileImageUrl: _profileImageUrl,
          privateNotes: _privateNotesController.text.trim().isEmpty 
              ? null 
              : _privateNotesController.text.trim(),
          isActive: _isActive,
          createdAt: now,
          updatedAt: now,
          tags: _tags,
          roles: _roles,
          customFields: _customFields,
        );
        
        print('Appel FirebaseService.createPerson...');
        await FirebaseService.createPerson(newPerson);
        print('Création réussie!');
      } else {
        print('Mode: Modification de la personne ID: ${widget.person!.id}');
        
        // Vérifier que l'ID n'est pas vide
        if (widget.person!.id.isEmpty) {
          throw Exception('ID de la personne vide - impossible de mettre à jour');
        }
        
        // Update existing person
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        print('Utilisateur actuel: $currentUserId');
        
        final updatedPerson = widget.person!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _buildFullPhone(),
          birthDate: _birthDate,
          address: _buildFullAddress(),
          gender: _gender,
          maritalStatus: _maritalStatus,
          children: _children,
          profileImageUrl: _profileImageUrl,
          privateNotes: _privateNotesController.text.trim().isEmpty 
              ? null 
              : _privateNotesController.text.trim(),
          isActive: _isActive,
          updatedAt: now,
          tags: _tags,
          roles: _roles,
          customFields: _customFields,
          lastModifiedBy: currentUserId,
        );
        
        print('Données à sauvegarder: ${updatedPerson.firstName} ${updatedPerson.lastName}');
        print('ID de la personne: ${updatedPerson.id}');
        print('Email: ${updatedPerson.email}');

        print('Date de naissance: ${updatedPerson.birthDate}');
        print('Vérification toFirestore...');
        try {
          final firestoreData = updatedPerson.toFirestore();
          print('toFirestore() réussi, clés: ${firestoreData.keys}');
        } catch (e) {
          throw Exception('Erreur lors de la conversion des données: $e');
        }

        
        await FirebaseService.updatePerson(updatedPerson);
      }
      

      if (mounted) {
        print('Affichage du message de succès');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personne sauvegardée avec succès'),
            backgroundColor: AppTheme.greenStandard,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Attendre un peu avant de fermer la page
        await Future.delayed(const Duration(milliseconds: 500));
        
        print('Navigation vers la page précédente...');
        _formController.markAsSaved();
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('ERREUR lors de la sauvegarde: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () => _savePerson(),
            ),
          ),
        );
      }
    } finally {
      print('=== FIN SAUVEGARDE ===');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _formController.setLoading(false);
      }
    }
  }


  
  // NavigationGuard buildContent implementation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: Text(
            widget.person == null ? 'Nouvelle Personne' : 'Modifier Personne',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          actions: [
            if (_formController.isLoading)
              const Padding(
                padding: EdgeInsets.all(AppTheme.spaceMedium),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _savePerson,
                child: Text(
                  'Sauvegarder',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
          ],
        ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideAnimation.value)),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image Section
                      _buildProfileImageSection(),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Basic Information
                      _buildSection(
                        title: 'Informations de base',
                        icon: Icons.person,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _firstNameController,
                                  label: 'Prénom *',
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Le prénom est requis';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              Expanded(
                                child: _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Nom *',
                                  icon: Icons.badge,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Le nom est requis';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email *',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'L\'email est requis';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Format d\'email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          // Section téléphone avec code pays et pays
                          Row(
                            children: [
                              // Dropdown pour l'indicatif de pays
                              Container(
                                width: 120,
                                child: _buildCountryCodeDropdown(),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              // Champ téléphone
                              Expanded(
                                child: _buildTextField(
                                  controller: _phoneController,
                                  label: 'Téléphone',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          // Dropdown pour le pays
                          _buildCountryDropdown(),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Personal Information
                      _buildSection(
                        title: 'Informations personnelles',
                        icon: Icons.info,
                        children: [
                          // Birth Date
                          InkWell(
                            onTap: _selectBirthDate,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spaceMedium),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cake,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppTheme.spaceMedium),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date de naissance',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                        Text(
                                          _birthDate != null
                                              ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                                              : 'Sélectionner une date',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: _birthDate != null
                                                ? Theme.of(context).colorScheme.onSurface
                                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          
                          // Gender and Marital Status
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(context,
                                  value: _gender,
                                  label: 'Genre',
                                  icon: Icons.wc,
                                  items: _genderOptions,
                                  onChanged: (value) => setState(() => _gender = value),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              Expanded(
                                child: _buildDropdown(context,
                                  value: _maritalStatus,
                                  label: 'Statut marital',
                                  icon: Icons.favorite,
                                  items: _maritalStatusOptions,
                                  onChanged: (value) => setState(() => _maritalStatus = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          
                          _buildTextField(
                            controller: _addressController,
                            label: 'Adresse',
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          _buildTextField(
                            controller: _addressComplementController,
                            label: 'Complément d\'adresse',
                            icon: Icons.add_home_outlined,
                          ),
                          const SizedBox(height: AppTheme.spaceMedium),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  controller: _postalCodeController,
                                  label: 'Code postal',
                                  icon: Icons.local_post_office_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMedium),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _cityController,
                                  label: 'Ville',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Children Section
                      _buildSection(
                        title: 'Enfants',
                        icon: Icons.child_friendly,
                        children: [
                          ..._children.asMap().entries.map((entry) {
                            final index = entry.key;
                            final child = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.child_care,
                                    color: Theme.of(context).colorScheme.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Expanded(
                                    child: Text(
                                      child,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: AppTheme.fontMedium,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _children.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          ElevatedButton.icon(
                            onPressed: _addChild,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un enfant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Tags Section
                      _buildSection(
                        title: 'Tags',
                        icon: Icons.local_offer,
                        children: [
                          if (_tags.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _tags.asMap().entries.map((entry) {
                                final index = entry.key;
                                final tag = entry.value;
                                return Chip(
                                  label: Text(tag),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setState(() {
                                      _tags.removeAt(index);
                                    });
                                  },
                                  backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppTheme.space12),
                          ],
                          ElevatedButton.icon(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un tag'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.tertiary,
                              foregroundColor: Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Roles Section
                      _buildSection(
                        title: 'Rôles',
                        icon: Icons.security,
                        children: [
                          if (_roles.isNotEmpty) ...[
                            FutureBuilder<List<Widget>>(
                              future: _buildRoleChips(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 40,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: snapshot.data ?? [],
                                );
                              },
                            ),
                            const SizedBox(height: AppTheme.space12),
                          ],
                          ElevatedButton.icon(
                            onPressed: _selectRoles,
                            icon: const Icon(Icons.add),
                            label: Text(_roles.isEmpty ? 'Ajouter des rôles' : 'Modifier les rôles'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Custom Fields Section
                      CustomFieldsWidget(
                        initialValues: _customFields,
                        onChanged: (values) {
                          setState(() {
                            _customFields = values;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Private Notes Section
                      _buildSection(
                        title: 'Notes privées',
                        icon: Icons.note,
                        children: [
                          _buildTextField(
                            controller: _privateNotesController,
                            label: 'Notes (visibles uniquement par les administrateurs)',
                            icon: Icons.note_alt,
                            maxLines: 4,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Status Section
                      _buildSection(
                        title: 'Statut',
                        icon: Icons.toggle_on,
                        children: [
                          SwitchListTile(
                            title: const Text('Membre actif'),
                            subtitle: Text(
                              _isActive
                                  ? 'Ce membre est actuellement actif'
                                  : 'Ce membre est inactif',
                            ),
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 80), // Extra space for FAB
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _savePerson,
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImageUrl != null
                    ? (_profileImageUrl!.startsWith('data:image')
                        ? Image.memory(
                            Uri.parse(_profileImageUrl!).data!.contentAsBytes(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                          )
                        : Image.network(
                            _profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                          ))
                    : _buildImagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: Text(_profileImageUrl != null ? 'Changer la photo' : 'Ajouter une photo'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Photo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, {
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
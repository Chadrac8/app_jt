import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/user_profile_service.dart';
import '../services/roles_firebase_service.dart';
import '../services/people_module_service.dart';
import '../auth/auth_service.dart';

import '../../theme.dart';
import '../widgets/user_avatar.dart';
import '../widgets/family_info_widget.dart';
import '../extensions/datetime_extensions.dart';
import '../widgets/admin_view_toggle_button.dart';

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
  PersonModel? _peopleModulePerson; // Données depuis le module Personnes
  FamilyModel? _family;
  List<PersonModel> _familyMembers = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;
  bool _isEditing = false;
  
  final PeopleModuleService _peopleService = PeopleModuleService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;
  String? _profileImageUrl;
  String? _countryCode;
  String? _country;
  bool _hasImageChanged = false;

  final List<String> _genderOptions = ['Masculin', 'Féminin'];
  final List<String> _maritalStatusOptions = [
    'Célibataire',
    'Marié(e)',
    'Veuf/Veuve'
  ];

  // Indicatifs de pays du monde entier
  final Map<String, String> _countryCodes = {
    '+93': 'Afghanistan',
    '+355': 'Albanie',
    '+213': 'Algérie',
    '+376': 'Andorre',
    '+244': 'Angola',
    '+1': 'États-Unis/Canada',
    '+54': 'Argentine',
    '+374': 'Arménie',
    '+61': 'Australie',
    '+43': 'Autriche',
    '+994': 'Azerbaïdjan',
    '+973': 'Bahreïn',
    '+880': 'Bangladesh',
    '+375': 'Biélorussie',
    '+32': 'Belgique',
    '+229': 'Bénin',
    '+975': 'Bhoutan',
    '+591': 'Bolivie',
    '+387': 'Bosnie-Herzégovine',
    '+267': 'Botswana',
    '+55': 'Brésil',
    '+673': 'Brunei',
    '+359': 'Bulgarie',
    '+226': 'Burkina Faso',
    '+257': 'Burundi',
    '+855': 'Cambodge',
    '+237': 'Cameroun',
    '+238': 'Cap-Vert',
    '+236': 'République centrafricaine',
    '+235': 'Tchad',
    '+56': 'Chili',
    '+86': 'Chine',
    '+357': 'Chypre',
    '+57': 'Colombie',
    '+269': 'Comores',
    '+242': 'République du Congo',
    '+243': 'République démocratique du Congo',
    '+506': 'Costa Rica',
    '+225': 'Côte d\'Ivoire',
    '+385': 'Croatie',
    '+53': 'Cuba',
    '+420': 'République tchèque',
    '+45': 'Danemark',
    '+253': 'Djibouti',
    '+593': 'Équateur',
    '+20': 'Égypte',
    '+503': 'Salvador',
    '+240': 'Guinée équatoriale',
    '+291': 'Érythrée',
    '+372': 'Estonie',
    '+251': 'Éthiopie',
    '+679': 'Fidji',
    '+358': 'Finlande',
    '+33': 'France',
    '+241': 'Gabon',
    '+220': 'Gambie',
    '+995': 'Géorgie',
    '+49': 'Allemagne',
    '+233': 'Ghana',
    '+30': 'Grèce',
    '+502': 'Guatemala',
    '+224': 'Guinée',
    '+245': 'Guinée-Bissau',
    '+592': 'Guyana',
    '+509': 'Haïti',
    '+504': 'Honduras',
    '+36': 'Hongrie',
    '+354': 'Islande',
    '+91': 'Inde',
    '+62': 'Indonésie',
    '+98': 'Iran',
    '+964': 'Irak',
    '+353': 'Irlande',
    '+972': 'Israël',
    '+39': 'Italie',
    '+1876': 'Jamaïque',
    '+81': 'Japon',
    '+962': 'Jordanie',
    '+7': 'Kazakhstan',
    '+254': 'Kenya',
    '+996': 'Kirghizistan',
    '+850': 'Corée du Nord',
    '+82': 'Corée du Sud',
    '+965': 'Koweït',
    '+856': 'Laos',
    '+371': 'Lettonie',
    '+961': 'Liban',
    '+266': 'Lesotho',
    '+231': 'Liberia',
    '+218': 'Libye',
    '+423': 'Liechtenstein',
    '+370': 'Lituanie',
    '+352': 'Luxembourg',
    '+261': 'Madagascar',
    '+60': 'Malaisie',
    '+265': 'Malawi',
    '+960': 'Maldives',
    '+223': 'Mali',
    '+356': 'Malte',
    '+230': 'Maurice',
    '+222': 'Mauritanie',
    '+52': 'Mexique',
    '+373': 'Moldavie',
    '+377': 'Monaco',
    '+976': 'Mongolie',
    '+382': 'Monténégro',
    '+212': 'Maroc',
    '+258': 'Mozambique',
    '+95': 'Myanmar',
    '+264': 'Namibie',
    '+977': 'Népal',
    '+31': 'Pays-Bas',
    '+64': 'Nouvelle-Zélande',
    '+505': 'Nicaragua',
    '+227': 'Niger',
    '+234': 'Nigeria',
    '+47': 'Norvège',
    '+968': 'Oman',
    '+92': 'Pakistan',
    '+507': 'Panama',
    '+595': 'Paraguay',
    '+51': 'Pérou',
    '+63': 'Philippines',
    '+48': 'Pologne',
    '+351': 'Portugal',
    '+974': 'Qatar',
    '+40': 'Roumanie',
    '+250': 'Rwanda',
    '+221': 'Sénégal',
    '+381': 'Serbie',
    '+248': 'Seychelles',
    '+232': 'Sierra Leone',
    '+65': 'Singapour',
    '+421': 'Slovaquie',
    '+386': 'Slovénie',
    '+252': 'Somalie',
    '+27': 'Afrique du Sud',
    '+34': 'Espagne',
    '+94': 'Sri Lanka',
    '+249': 'Soudan',
    '+597': 'Suriname',
    '+46': 'Suède',
    '+41': 'Suisse',
    '+963': 'Syrie',
    '+992': 'Tadjikistan',
    '+255': 'Tanzanie',
    '+66': 'Thaïlande',
    '+228': 'Togo',
    '+216': 'Tunisie',
    '+90': 'Turquie',
    '+993': 'Turkménistan',
    '+256': 'Ouganda',
    '+380': 'Ukraine',
    '+971': 'Émirats arabes unis',
    '+44': 'Royaume-Uni',
    '+598': 'Uruguay',
    '+998': 'Ouzbékistan',
    '+58': 'Venezuela',
    '+84': 'Vietnam',
    '+967': 'Yémen',
    '+260': 'Zambie',
    '+263': 'Zimbabwe',
  };

  // Liste de tous les pays du monde
  final List<String> _countries = [
    'Afghanistan',
    'Afrique du Sud',
    'Albanie',
    'Algérie',
    'Allemagne',
    'Andorre',
    'Angola',
    'Argentine',
    'Arménie',
    'Australie',
    'Autriche',
    'Azerbaïdjan',
    'Bahamas',
    'Bahreïn',
    'Bangladesh',
    'Belgique',
    'Bénin',
    'Bhoutan',
    'Biélorussie',
    'Bolivie',
    'Bosnie-Herzégovine',
    'Botswana',
    'Brésil',
    'Brunei',
    'Bulgarie',
    'Burkina Faso',
    'Burundi',
    'Cambodge',
    'Cameroun',
    'Canada',
    'Cap-Vert',
    'Chili',
    'Chine',
    'Chypre',
    'Colombie',
    'Comores',
    'Corée du Nord',
    'Corée du Sud',
    'Costa Rica',
    'Côte d\'Ivoire',
    'Croatie',
    'Cuba',
    'Danemark',
    'Djibouti',
    'Égypte',
    'Émirats arabes unis',
    'Équateur',
    'Érythrée',
    'Espagne',
    'Estonie',
    'États-Unis',
    'Éthiopie',
    'Fidji',
    'Finlande',
    'France',
    'Gabon',
    'Gambie',
    'Géorgie',
    'Ghana',
    'Grèce',
    'Guatemala',
    'Guinée',
    'Guinée équatoriale',
    'Guinée-Bissau',
    'Guyana',
    'Haïti',
    'Honduras',
    'Hongrie',
    'Inde',
    'Indonésie',
    'Irak',
    'Iran',
    'Irlande',
    'Islande',
    'Israël',
    'Italie',
    'Jamaïque',
    'Japon',
    'Jordanie',
    'Kazakhstan',
    'Kenya',
    'Kirghizistan',
    'Koweït',
    'Laos',
    'Lesotho',
    'Lettonie',
    'Liban',
    'Liberia',
    'Libye',
    'Liechtenstein',
    'Lituanie',
    'Luxembourg',
    'Madagascar',
    'Malaisie',
    'Malawi',
    'Maldives',
    'Mali',
    'Malte',
    'Maroc',
    'Maurice',
    'Mauritanie',
    'Mexique',
    'Moldavie',
    'Monaco',
    'Mongolie',
    'Monténégro',
    'Mozambique',
    'Myanmar',
    'Namibie',
    'Népal',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'Norvège',
    'Nouvelle-Zélande',
    'Oman',
    'Ouganda',
    'Ouzbékistan',
    'Pakistan',
    'Panama',
    'Paraguay',
    'Pays-Bas',
    'Pérou',
    'Philippines',
    'Pologne',
    'Portugal',
    'Qatar',
    'République centrafricaine',
    'République démocratique du Congo',
    'République du Congo',
    'République tchèque',
    'Roumanie',
    'Royaume-Uni',
    'Russie',
    'Rwanda',
    'Salvador',
    'Sénégal',
    'Serbie',
    'Seychelles',
    'Sierra Leone',
    'Singapour',
    'Slovaquie',
    'Slovénie',
    'Somalie',
    'Soudan',
    'Sri Lanka',
    'Suède',
    'Suisse',
    'Suriname',
    'Syrie',
    'Tadjikistan',
    'Tanzanie',
    'Tchad',
    'Thaïlande',
    'Togo',
    'Tunisie',
    'Turkménistan',
    'Turquie',
    'Ukraine',
    'Uruguay',
    'Venezuela',
    'Vietnam',
    'Yémen',
    'Zambie',
    'Zimbabwe',
  ];

  // Mapping des pays vers leurs indicatifs principaux
  final Map<String, String> _countryToCountryCode = {
    'Afghanistan': '+93',
    'Afrique du Sud': '+27',
    'Albanie': '+355',
    'Algérie': '+213',
    'Allemagne': '+49',
    'Andorre': '+376',
    'Angola': '+244',
    'Argentine': '+54',
    'Arménie': '+374',
    'Australie': '+61',
    'Autriche': '+43',
    'Azerbaïdjan': '+994',
    'Bahamas': '+1',
    'Bahreïn': '+973',
    'Bangladesh': '+880',
    'Belgique': '+32',
    'Bénin': '+229',
    'Bhoutan': '+975',
    'Biélorussie': '+375',
    'Bolivie': '+591',
    'Bosnie-Herzégovine': '+387',
    'Botswana': '+267',
    'Brésil': '+55',
    'Brunei': '+673',
    'Bulgarie': '+359',
    'Burkina Faso': '+226',
    'Burundi': '+257',
    'Cambodge': '+855',
    'Cameroun': '+237',
    'Canada': '+1',
    'Cap-Vert': '+238',
    'Chili': '+56',
    'Chine': '+86',
    'Chypre': '+357',
    'Colombie': '+57',
    'Comores': '+269',
    'Corée du Nord': '+850',
    'Corée du Sud': '+82',
    'Costa Rica': '+506',
    'Côte d\'Ivoire': '+225',
    'Croatie': '+385',
    'Cuba': '+53',
    'Danemark': '+45',
    'Djibouti': '+253',
    'Égypte': '+20',
    'Émirats arabes unis': '+971',
    'Équateur': '+593',
    'Érythrée': '+291',
    'Espagne': '+34',
    'Estonie': '+372',
    'États-Unis': '+1',
    'Éthiopie': '+251',
    'Fidji': '+679',
    'Finlande': '+358',
    'France': '+33',
    'Gabon': '+241',
    'Gambie': '+220',
    'Géorgie': '+995',
    'Ghana': '+233',
    'Grèce': '+30',
    'Guatemala': '+502',
    'Guinée': '+224',
    'Guinée équatoriale': '+240',
    'Guinée-Bissau': '+245',
    'Guyana': '+592',
    'Haïti': '+509',
    'Honduras': '+504',
    'Hongrie': '+36',
    'Inde': '+91',
    'Indonésie': '+62',
    'Irak': '+964',
    'Iran': '+98',
    'Irlande': '+353',
    'Islande': '+354',
    'Israël': '+972',
    'Italie': '+39',
    'Jamaïque': '+1',
    'Japon': '+81',
    'Jordanie': '+962',
    'Kazakhstan': '+7',
    'Kenya': '+254',
    'Kirghizistan': '+996',
    'Koweït': '+965',
    'Laos': '+856',
    'Lesotho': '+266',
    'Lettonie': '+371',
    'Liban': '+961',
    'Liberia': '+231',
    'Libye': '+218',
    'Liechtenstein': '+423',
    'Lituanie': '+370',
    'Luxembourg': '+352',
    'Madagascar': '+261',
    'Malaisie': '+60',
    'Malawi': '+265',
    'Maldives': '+960',
    'Mali': '+223',
    'Malte': '+356',
    'Maroc': '+212',
    'Maurice': '+230',
    'Mauritanie': '+222',
    'Mexique': '+52',
    'Moldavie': '+373',
    'Monaco': '+377',
    'Mongolie': '+976',
    'Monténégro': '+382',
    'Mozambique': '+258',
    'Myanmar': '+95',
    'Namibie': '+264',
    'Népal': '+977',
    'Nicaragua': '+505',
    'Niger': '+227',
    'Nigeria': '+234',
    'Norvège': '+47',
    'Nouvelle-Zélande': '+64',
    'Oman': '+968',
    'Ouganda': '+256',
    'Ouzbékistan': '+998',
    'Pakistan': '+92',
    'Panama': '+507',
    'Paraguay': '+595',
    'Pays-Bas': '+31',
    'Pérou': '+51',
    'Philippines': '+63',
    'Pologne': '+48',
    'Portugal': '+351',
    'Qatar': '+974',
    'République centrafricaine': '+236',
    'République démocratique du Congo': '+243',
    'République du Congo': '+242',
    'République tchèque': '+420',
    'Roumanie': '+40',
    'Royaume-Uni': '+44',
    'Russie': '+7',
    'Rwanda': '+250',
    'Salvador': '+503',
    'Sénégal': '+221',
    'Serbie': '+381',
    'Seychelles': '+248',
    'Sierra Leone': '+232',
    'Singapour': '+65',
    'Slovaquie': '+421',
    'Slovénie': '+386',
    'Somalie': '+252',
    'Soudan': '+249',
    'Sri Lanka': '+94',
    'Suède': '+46',
    'Suisse': '+41',
    'Suriname': '+597',
    'Syrie': '+963',
    'Tadjikistan': '+992',
    'Tanzanie': '+255',
    'Tchad': '+235',
    'Thaïlande': '+66',
    'Togo': '+228',
    'Tunisie': '+216',
    'Turkménistan': '+993',
    'Turquie': '+90',
    'Ukraine': '+380',
    'Uruguay': '+598',
    'Venezuela': '+58',
    'Vietnam': '+84',
    'Yémen': '+967',
    'Zambie': '+260',
    'Zimbabwe': '+263',
  };

  @override
  void initState() {
    super.initState();
    // Valeurs par défaut
    _countryCode = '+33'; // France par défaut
    _country = 'France'; // France par défaut
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
    _addressComplementController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
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
      print('🔄 MemberProfilePage: Début du chargement du profil...');
      setState(() => _isLoading = true);
      
      // Vérifier l'utilisateur connecté
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        print('❌ Aucun utilisateur connecté');
        setState(() {
          _isLoading = false;
          _currentPerson = null;
        });
        return;
      }
      
      print('✅ Utilisateur connecté: ${currentUser.uid}');
      
      // Charger le profil de l'utilisateur connecté
      PersonModel? person = await AuthService.getCurrentUserProfile();
      print('📊 Résultat getCurrentUserProfile: ${person != null ? "Profil trouvé" : "Null"}');

      if (person == null) {
        print('⚠️  Profil null, tentative de création...');
        // Fallback: essayer de créer le profil depuis Firebase Auth
        final user = AuthService.currentUser;
        if (user != null) {
          print('🔧 Tentative de création du profil pour ${user.uid}');
          try {
            await UserProfileService.ensureUserProfile(user);
            person = await AuthService.getCurrentUserProfile();
            print('📊 Après ensureUserProfile: ${person != null ? "Profil créé" : "Échec création"}');
          } catch (ensureError) {
            print('❌ Erreur lors de ensureUserProfile: $ensureError');
          }
        }
      }

      if (person != null) {
        print('✅ Profil chargé avec succès: ${person.firstName} ${person.lastName}');
        
        // 🎯 NOUVEAU: Synchroniser avec le module Personnes
        await _synchronizeWithPeopleModule(person);
        
        setState(() {
          _currentPerson = person;
          _initializeForm();
        });

        // Charger la famille si elle existe
        if (person.familyId != null) {
          print('👨‍👩‍👧‍👦 Chargement famille: ${person.familyId}');
          try {
            final family = await FirebaseService.getFamily(person.familyId!);
            if (family != null) {
              print('✅ Famille chargée: ${family.name}');
              setState(() {
                _family = family;
              });
              await _loadFamilyMembers();
            } else {
              print('⚠️  Famille non trouvée');
            }
          } catch (e) {
            print('❌ Erreur chargement famille: $e');
          }
        } else {
          print('ℹ️  Aucune famille associée');
        }

        // Charger les rôles
        print('🎭 Chargement des rôles...');
        await _loadRoles();
      } else {
        print('❌ ÉCHEC: Impossible de charger ou créer le profil');
        setState(() {
          _currentPerson = null;
        });
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
      print('✅ Chargement profil terminé');
    } catch (e, stackTrace) {
      print('❌ ERREUR CRITIQUE chargement profil: $e');
      print('📍 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _currentPerson = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Synchronise les données du profil utilisateur avec celles du module Personnes
  /// Les données du module Personnes ont la priorité pour maintenir une source unique de vérité
  Future<void> _synchronizeWithPeopleModule(PersonModel userProfile) async {
    try {
      print('🔄 Synchronisation avec le module Personnes...');
      
      // Rechercher la personne dans le module Personnes par email
      final peopleModulePerson = userProfile.email != null ? await _peopleService.findByEmail(userProfile.email!) : null;
      
      if (peopleModulePerson != null) {
        print('✅ Personne trouvée dans le module Personnes: ${peopleModulePerson.fullName}');
        
        setState(() {
          _peopleModulePerson = peopleModulePerson;
        });
        
        // Synchroniser les données depuis le module Personnes vers le profil utilisateur
        // Les champs du module Personnes ont la priorité
        final updatedProfile = userProfile.copyWith(
          firstName: peopleModulePerson.firstName,
          lastName: peopleModulePerson.lastName,
          phone: peopleModulePerson.phone,
          country: peopleModulePerson.country,
          birthDate: peopleModulePerson.birthDate,
          gender: peopleModulePerson.gender,
          maritalStatus: peopleModulePerson.maritalStatus,
          // Utiliser les champs séparés du module Personnes
          address: peopleModulePerson.address,
          additionalAddress: peopleModulePerson.additionalAddress,
          zipCode: peopleModulePerson.zipCode,
          city: peopleModulePerson.city,
          profileImageUrl: peopleModulePerson.profileImageUrl ?? userProfile.profileImageUrl,
        );
        
        // Mettre à jour le profil utilisateur si des changements sont détectés
        if (_hasChanges(userProfile, updatedProfile)) {
          print('🔄 Mise à jour du profil utilisateur avec les données du module Personnes...');
          await FirebaseService.updatePerson(updatedProfile);
          setState(() {
            _currentPerson = updatedProfile;
          });
          print('✅ Profil utilisateur synchronisé');
        } else {
          print('ℹ️  Aucune synchronisation nécessaire');
        }
      } else {
        print('⚠️  Personne non trouvée dans le module Personnes pour l\'email: ${userProfile.email}');
        print('💡 Suggestion: Créer la personne dans le module Personnes pour activer la synchronisation');
      }
    } catch (e) {
      print('❌ Erreur lors de la synchronisation avec le module Personnes: $e');
      // Ne pas bloquer l'interface en cas d'erreur de synchronisation
    }
  }

  /// Construit l'adresse complète à partir des champs séparés du module Personnes


  /// Vérifie s'il y a des changements entre deux profils
  bool _hasChanges(PersonModel oldProfile, PersonModel newProfile) {
    return oldProfile.firstName != newProfile.firstName ||
           oldProfile.lastName != newProfile.lastName ||
           oldProfile.phone != newProfile.phone ||
           oldProfile.country != newProfile.country ||
           oldProfile.birthDate != newProfile.birthDate ||
           oldProfile.gender != newProfile.gender ||
           oldProfile.maritalStatus != newProfile.maritalStatus ||
           oldProfile.address != newProfile.address ||
           oldProfile.profileImageUrl != newProfile.profileImageUrl;
  }



  void _initializeForm() {
    if (_currentPerson != null) {
      // Utiliser en priorité les données du module Personnes si disponibles
      if (_peopleModulePerson != null) {
        _firstNameController.text = _peopleModulePerson!.firstName;
        _lastNameController.text = _peopleModulePerson!.lastName;
      } else {
        _firstNameController.text = _currentPerson!.firstName;
        _lastNameController.text = _currentPerson!.lastName;
      }
      
      _emailController.text = _currentPerson!.email ?? ''; // L'email vient toujours du profil utilisateur
      
      // Pour le téléphone et l'adresse, utiliser les données du module Personnes si disponibles
      if (_peopleModulePerson != null) {
        _parseExistingPhone(_peopleModulePerson!.phone);
        _parseExistingAddressFromPeopleModule(_peopleModulePerson!);
        _birthDate = _peopleModulePerson!.birthDate;
        _gender = _peopleModulePerson!.gender;
        _maritalStatus = _peopleModulePerson!.maritalStatus;
        _profileImageUrl = _peopleModulePerson!.profileImageUrl ?? _currentPerson!.profileImageUrl;
        _country = _peopleModulePerson!.country;
      } else {
        // Fallback sur les données du profil utilisateur
        _parseExistingPhone(_currentPerson!.phone);
        // Charger les champs d'adresse séparés
        _addressController.text = _currentPerson!.address ?? '';
        _addressComplementController.text = _currentPerson!.additionalAddress ?? '';  
        _postalCodeController.text = _currentPerson!.zipCode ?? '';
        _cityController.text = _currentPerson!.city ?? '';
        _birthDate = _currentPerson!.birthDate;
        _gender = _currentPerson!.gender;
        _maritalStatus = _currentPerson!.maritalStatus;
        _profileImageUrl = _currentPerson!.profileImageUrl;
        _country = _currentPerson!.country ?? 'France';
      }
    }
  }

  /// Parse l'adresse depuis les champs séparés du module Personnes
  void _parseExistingAddressFromPeopleModule(PersonModel person) {
    _addressController.text = person.address ?? '';
    _addressComplementController.text = person.additionalAddress ?? '';
    _postalCodeController.text = person.zipCode ?? '';
    _cityController.text = person.city ?? '';
    _country = person.country ?? 'France';
    
    // Définir l'indicatif pays selon le pays
    if (_country != null && _countryToCountryCode.containsKey(_country)) {
      // Le téléphone du module Personnes peut déjà contenir l'indicatif, on le parse
      _parseExistingPhone(person.phone);
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





  String? _buildFullPhone() {
    if (_phoneController.text.trim().isEmpty) {
      return null;
    }
    
    final countryCode = _countryCode ?? '+33';
    return '$countryCode${_phoneController.text.trim()}';
  }



  void _parseExistingPhone(String? fullPhone) {
    if (fullPhone == null || fullPhone.isEmpty) {
      _phoneController.clear();
      _countryCode = '+33'; // Défaut France
      return;
    }

    // Essayer de détecter un indicatif au début du numéro
    for (String code in _countryCodes.keys) {
      if (fullPhone.startsWith(code)) {
        _countryCode = code;
        _phoneController.text = fullPhone.substring(code.length).trim();
        return;
      }
    }

    // Si aucun indicatif trouvé, considérer que c'est un numéro français
    _countryCode = '+33';
    _phoneController.text = fullPhone;
  }



  Future<void> _pickProfileImage() async {
    try {
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      
      if (imageBytes != null) {
        // Sauvegarder l'ancienne URL pour la supprimer après upload réussi
        final oldImageUrl = _profileImageUrl;
        
        // Obtenir l'UID Firebase Auth (pas l'ID PersonModel) pour respecter les règles de sécurité Firebase
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }
        final userId = user.uid; // UID Firebase Auth, pas PersonModel.id
        
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              const Text('Gestion de famille'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Que souhaitez-vous faire ?',
                style: TextStyle(fontSize: AppTheme.fontSize16),
              ),
              const SizedBox(height: AppTheme.space20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer\nune famille'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white100,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                  const SizedBox(height: AppTheme.spaceMedium),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse familiale (optionnel)',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone familial (optionnel)',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                foregroundColor: AppTheme.white100,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
            title: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                const Text('Rejoindre une famille'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: families.isEmpty
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.family_restroom, size: 64, color: AppTheme.grey500),
                        SizedBox(height: AppTheme.spaceMedium),
                        Text('Aucune famille disponible'),
                        SizedBox(height: AppTheme.spaceSmall),
                        Text(
                          'Demandez à un membre de votre famille de créer une famille d\'abord.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.grey500),
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
                              style: const TextStyle(fontWeight: AppTheme.fontSemiBold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${family.memberIds.length} membre(s)'),
                                if (family.address != null)
                                  Text(
                                    family.address!,
                                    style: const TextStyle(fontSize: AppTheme.fontSize12, color: AppTheme.grey500),
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
      // Mise à jour du profil utilisateur (champs restreints exclus de la modification)
      final updatedPerson = _currentPerson!.copyWith(
        // firstName et lastName ne sont pas modifiés depuis le profil
        email: _emailController.text,
        phone: _buildFullPhone(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        additionalAddress: _addressComplementController.text.trim().isEmpty ? null : _addressComplementController.text.trim(),
        zipCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _country,
        // birthDate et gender ne sont pas modifiés depuis le profil
        maritalStatus: _maritalStatus,
        profileImageUrl: _profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await AuthService.updateCurrentUserProfile(updatedPerson);
      
      // 🔄 Synchronisation inverse : mettre à jour la fiche dans le module Personnes
      if (_peopleModulePerson != null) {
        try {
          print('🔄 Synchronisation des modifications vers le module Personnes...');
          final updatedPeopleModulePerson = _peopleModulePerson!.copyWith(
            // firstName et lastName préservés (non modifiables depuis le profil)
            email: _emailController.text,
            phone: _buildFullPhone(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            additionalAddress: _addressComplementController.text.trim().isEmpty ? null : _addressComplementController.text.trim(),
            zipCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
            city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            country: _country,
            // birthDate et gender préservés (non modifiables depuis le profil)
            maritalStatus: _maritalStatus,
            profileImageUrl: _profileImageUrl,
            updatedAt: DateTime.now(),
          );
          
          await PeopleModuleService().update(_peopleModulePerson!.id, updatedPeopleModulePerson);
          setState(() {
            _peopleModulePerson = updatedPeopleModulePerson;
          });
          print('✅ Synchronisation vers le module Personnes réussie');
        } catch (e) {
          print('⚠️  Erreur lors de la synchronisation vers le module Personnes: $e');
          // On n'interrompt pas le processus si la synchronisation échoue
        }
      }

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
          : _currentPerson == null 
              ? _buildErrorState()
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
                              labelColor: AppTheme.primaryColor,
                              unselectedLabelColor: AppTheme.onSurfaceVariant,
                              indicatorColor: AppTheme.primaryColor,
                              indicatorWeight: 3,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.grey500,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Impossible de charger votre profil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.grey500,
                fontWeight: AppTheme.fontSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Vérifiez votre connexion internet et réessayez',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadPersonData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
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
            color: AppTheme.white100,
            fontWeight: AppTheme.fontBold,
            fontSize: AppTheme.fontSize18,
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
              const SizedBox(height: AppTheme.space20),
              if (_currentPerson != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _currentPerson!.fullName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.white100,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Text(
                    _currentPerson!.email ?? '',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.white100,
                      fontWeight: AppTheme.fontMedium,
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
                            color: AppTheme.white100.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppTheme.white100.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: AppTheme.white100,
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontSemiBold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ),
      actions: [
        // Bouton de bascule vers la vue Admin (visible uniquement pour les admins)
        const AdminViewToggleButton(
          iconColor: AppTheme.white100,
          backgroundColor: Colors.transparent,
        ),
        // Bouton d'édition/sauvegarde
        IconButton(
          icon: Icon(_isEditing ? Icons.save : Icons.edit),
          onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
          color: AppTheme.white100,
          tooltip: _isEditing ? 'Sauvegarder' : 'Modifier le profil',
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
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                enabled: false, // Champ non modifiable
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person_outline,
                enabled: false, // Champ non modifiable
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildCountryCodeDropdown(),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildAddressSection(),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildInfoCard(
            title: 'Informations personnelles',
            icon: Icons.info_outline,
            children: [
              _buildDateField(),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildDropdown(
                value: _gender,
                label: 'Genre',
                icon: Icons.wc,
                items: _genderOptions,
                onChanged: null, // Genre non modifiable
              ),
              const SizedBox(height: AppTheme.spaceMedium),
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
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget famille personnalisé
          if (_currentPerson != null)
            FamilyInfoWidget(
              person: _currentPerson!,
              onFamilyChanged: _loadPersonData,
            ),
          const SizedBox(height: AppTheme.spaceMedium),
          
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
            const SizedBox(height: AppTheme.spaceMedium),
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
                const SizedBox(height: AppTheme.spaceMedium),
                ElevatedButton.icon(
                  onPressed: _showFamilyManagementDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer ou rejoindre une famille'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white100,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
              // Charger plus d'activités depuis activity_logs:
              // StreamBuilder<QuerySnapshot>(
              //   stream: FirebaseFirestore.instance
              //       .collection('activity_logs')
              //       .where('userId', isEqualTo: widget.personId)
              //       .orderBy('timestamp', descending: true)
              //       .limit(10)
              //       .snapshots(),
              //   builder: (context, snapshot) {
              //     if (!snapshot.hasData) return const SizedBox();
              //     return Column(
              //       children: snapshot.data!.docs.map((doc) {
              //         final data = doc.data() as Map<String, dynamic>;
              //         return _buildHistoryItem(
              //           data['action'] ?? '',
              //           (data['timestamp'] as Timestamp).toDate(),
              //           _getActivityIcon(data['type']),
              //           AppTheme.grey600,
              //         );
              //       }).toList(),
              //     );
              //   },
              // ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
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
        fillColor: enabled ? null : AppTheme.grey100,
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
    // Vérifier si la valeur est valide (existe dans les items)
    String? validValue = value;
    if (value != null && !items.contains(value)) {
      print('⚠️  Valeur dropdown invalide: "$value" pour $label. Items disponibles: $items');
      validValue = null; // Réinitialiser à null si la valeur n'est pas dans la liste
    }
    
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: onChanged == null,
        fillColor: onChanged == null ? AppTheme.grey100 : null,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildCountryCodeDropdown() {
    return DropdownSearch<String>(
      selectedItem: _countryCode,
      items: _countryCodes.keys.toList(),
      itemAsString: (code) => code,
      enabled: _isEditing,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Indicatif',
          prefixIcon: const Icon(Icons.flag_outlined),
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: _isEditing ? null : AppTheme.grey100,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Rechercher un indicatif...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        itemBuilder: (context, item, isSelected) {
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
                    _countryCodes[item] ?? '',
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
        return item.toLowerCase().contains(filter.toLowerCase()) ||
            (_countryCodes[item] ?? '').toLowerCase().contains(filter.toLowerCase());
      },
      onChanged: _isEditing ? (String? newValue) {
        setState(() {
          _countryCode = newValue;
        });
      } : null,
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownSearch<String>(
      selectedItem: _country,
      items: _countries,
      itemAsString: (country) => country,
      enabled: _isEditing,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Pays',
          prefixIcon: const Icon(Icons.public_outlined),
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: _isEditing ? null : AppTheme.grey100,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Rechercher un pays...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        fit: FlexFit.loose,
      ),
      filterFn: (item, filter) {
        return item.toLowerCase().contains(filter.toLowerCase());
      },
      onChanged: _isEditing ? (String? newValue) {
        setState(() {
          _country = newValue;
          // Remplissage automatique de l'indicatif basé sur le pays choisi
          if (newValue != null && _countryToCountryCode.containsKey(newValue)) {
            _countryCode = _countryToCountryCode[newValue];
          }
        });
      } : null,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: null, // Date de naissance non modifiable
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: _isEditing ? null : AppTheme.grey100,
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
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
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
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (_family?.headOfFamilyId == member.id)
                  const Text(
                    'Chef de famille',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.primaryColor,
                      fontWeight: AppTheme.fontMedium,
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
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: Color(int.parse(role.color.replaceFirst('#', '0xFF')))
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: Color(int.parse(role.color.replaceFirst('#', '0xFF')))
                .withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconFromString(role.icon),
                size: 16,
                color: AppTheme.white100,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: const TextStyle(
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (role.description.isNotEmpty)
                    Text(
                      role.description,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize12,
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
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
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
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  date.mediumDate,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize12,
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

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _addressController,
          label: 'Adresse',
          icon: Icons.home_outlined,
          enabled: _isEditing,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildTextField(
          controller: _addressComplementController,
          label: 'Complément d\'adresse',
          icon: Icons.add_home_outlined,
          enabled: _isEditing,
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
                enabled: _isEditing,
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
                enabled: _isEditing,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildCountryDropdown(),
      ],
    );
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.outline.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
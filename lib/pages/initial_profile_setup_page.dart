import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  
  // Form values
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;
  String? _profileImageUrl;
  String? _countryCode;
  String? _country;
  bool _isLoading = false;

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
    '+7840': 'Kazakhstan',
    '+254': 'Kenya',
    '+996': 'Kirghizistan',
    '+965': 'Koweït',
    '+371': 'Lettonie',
    '+961': 'Liban',
    '+266': 'Lesotho',
    '+231': 'Liberia',
    '+218': 'Libye',
    '+423': 'Liechtenstein',
    '+370': 'Lituanie',
    '+352': 'Luxembourg',
    '+261': 'Madagascar',
    '+265': 'Malawi',
    '+60': 'Malaisie',
    '+960': 'Maldives',
    '+223': 'Mali',
    '+356': 'Malte',
    '+222': 'Mauritanie',
    '+230': 'Maurice',
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
    '+850': 'Corée du Nord',
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
    '+7': 'Russie',
    '+250': 'Rwanda',
    '+966': 'Arabie saoudite',
    '+221': 'Sénégal',
    '+381': 'Serbie',
    '+248': 'Seychelles',
    '+232': 'Sierra Leone',
    '+65': 'Singapour',
    '+421': 'Slovaquie',
    '+386': 'Slovénie',
    '+252': 'Somalie',
    '+27': 'Afrique du Sud',
    '+82': 'Corée du Sud',
    '+34': 'Espagne',
    '+94': 'Sri Lanka',
    '+249': 'Soudan',
    '+597': 'Suriname',
    '+268': 'Eswatini',
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

  // Tous les pays du monde
  final List<String> _countries = [
    'Afghanistan',
    'Afrique du Sud',
    'Albanie',
    'Algérie',
    'Allemagne',
    'Andorre',
    'Angola',
    'Arabie saoudite',
    'Argentine',
    'Arménie',
    'Australie',
    'Autriche',
    'Azerbaïdjan',
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
    'Eswatini',
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
    _prefillFromExistingProfile();
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
      
      if (user.email != null) {
        _emailController.text = user.email!;
      }
      
      if (user.photoURL != null) {
        _profileImageUrl = user.photoURL;
      }
    }
  }

  Future<void> _prefillFromExistingProfile() async {
    try {
      print('🔄 InitialProfileSetup: Chargement du profil existant...');
      
      // D'abord, préremplir avec les données Firebase Auth
      _prefillFromAuth();
      
      // Ensuite, récupérer et préremplir avec le profil Firestore s'il existe
      final existingProfile = await AuthService.getCurrentUserProfile();
      
      if (existingProfile != null) {
        print('✅ Profil existant trouvé, préremplissage des champs...');
        
        // Ne pas écraser les champs déjà remplis par Firebase Auth, 
        // mais compléter avec les données du profil Firestore
        if (_firstNameController.text.isEmpty) {
          _firstNameController.text = existingProfile.firstName;
        }
        if (_lastNameController.text.isEmpty) {
          _lastNameController.text = existingProfile.lastName;
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = existingProfile.email;
        }
        
        // Préremplir les champs spécifiques au profil
        _parseExistingPhone(existingProfile.phone);
        
        // Préremplir l'adresse en la décomposant
        _parseExistingAddress(existingProfile.address);
        
        // Préremplir les autres champs
        _birthDate = existingProfile.birthDate;
        _gender = existingProfile.gender;
        _maritalStatus = existingProfile.maritalStatus;
        _profileImageUrl = existingProfile.profileImageUrl;
        
        // Mettre à jour l'interface
        if (mounted) {
          setState(() {});
        }
        
        print('✅ Préremplissage terminé avec succès');
      } else {
        print('ℹ️  Aucun profil existant, utilisation des données Firebase Auth uniquement');
      }
    } catch (e) {
      print('⚠️  Erreur lors du préremplissage: $e');
      // En cas d'erreur, on garde au moins les données Firebase Auth
    }
  }

  void _parseExistingAddress(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) {
      return;
    }

    try {
      print('🔄 Parsing de l\'adresse existante: "$fullAddress"');
      
      // Patterns pour identifier les composants de l'adresse
      final postalCodePattern = RegExp(r'\b\d{5}\b');
      final cityPattern = RegExp(r'\b\d{5}\s+([A-ZÀ-Ÿ][a-zà-ÿ\s\-]+)', caseSensitive: false);
      final complementPattern = RegExp(r'(appt?\.?\s*\d+|appartement\s*\d+|bat\.?\s*[a-z0-9]+|bâtiment\s*[a-z0-9]+|étage\s*\d+|porte\s*[a-z0-9]+|bis|ter)', caseSensitive: false);
      
      String remainingAddress = fullAddress;
      
      // 1. Extraire le pays (généralement à la fin)
      final parts = fullAddress.split(', ');
      if (parts.length > 1) {
        final lastPart = parts.last.trim();
        // Vérifier si le dernier élément est un pays connu
        if (_countries.contains(lastPart)) {
          _country = lastPart;
          remainingAddress = parts.take(parts.length - 1).join(', ');
          print('✅ Pays trouvé: $lastPart');
        }
      }
      
      // 2. Extraire le code postal
      final postalMatch = postalCodePattern.firstMatch(remainingAddress);
      if (postalMatch != null) {
        _postalCodeController.text = postalMatch.group(0)!;
        print('✅ Code postal trouvé: ${postalMatch.group(0)}');
      }
      
      // 3. Extraire la ville (après le code postal)
      final cityMatch = cityPattern.firstMatch(remainingAddress);
      if (cityMatch != null) {
        final cityName = cityMatch.group(1)!.trim();
        _cityController.text = cityName;
        print('✅ Ville trouvée: $cityName');
        
        // Supprimer code postal + ville de l'adresse
        remainingAddress = remainingAddress.replaceFirst(cityMatch.group(0)!, '').trim();
      }
      
      // 4. Extraire le complément d'adresse
      final complementMatch = complementPattern.firstMatch(remainingAddress);
      if (complementMatch != null) {
        _addressComplementController.text = complementMatch.group(0)!;
        print('✅ Complément trouvé: ${complementMatch.group(0)}');
        
        // Supprimer le complément de l'adresse
        remainingAddress = remainingAddress.replaceFirst(complementMatch.group(0)!, '').trim();
      }
      
      // 5. Ce qui reste est l'adresse principale
      if (remainingAddress.isNotEmpty) {
        // Nettoyer l'adresse (supprimer les virgules en fin)
        remainingAddress = remainingAddress.replaceAll(RegExp(r',$'), '').trim();
        _addressController.text = remainingAddress.replaceAll(RegExp(r'\s+'), ' ').trim();
        print('✅ Adresse principale: ${_addressController.text}');
      }
      
      print('✅ Parsing terminé - Adresse: "${_addressController.text}", Complément: "${_addressComplementController.text}", CP: "${_postalCodeController.text}", Ville: "${_cityController.text}", Pays: "$_country"');
      
    } catch (e) {
      print('⚠️  Erreur lors du parsing de l\'adresse: $e');
      // En cas d'erreur, on met l'adresse complète dans le champ principal
      _addressController.text = fullAddress;
    }
  }

  void _parseExistingPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return;
    }

    try {
      print('🔄 Parsing du téléphone existant: "$phone"');
      
      // Chercher un indicatif de pays au début
      for (final code in _countryCodes.keys) {
        if (phone.startsWith(code)) {
          _countryCode = code;
          _phoneController.text = phone.substring(code.length).trim();
          print('✅ Indicatif trouvé: $code, Numéro: ${_phoneController.text}');
          return;
        }
      }
      
      // Si aucun indicatif trouvé, garder le numéro tel quel
      _phoneController.text = phone;
      print('✅ Numéro sans indicatif: $phone');
      
    } catch (e) {
      print('⚠️  Erreur lors du parsing du téléphone: $e');
      _phoneController.text = phone;
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
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
    
    // Ajouter le pays à la fin
    if (_country != null && _country!.isNotEmpty) {
      parts.add(_country!);
    }
    
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? _buildFullPhone() {
    if (_phoneController.text.trim().isNotEmpty && _countryCode != null) {
      return '$_countryCode ${_phoneController.text.trim()}';
    }
    return _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
  }

  Future<void> _completeSetup() async {
    print('🔄 Début de _completeSetup()');
    print('📋 Validation du formulaire...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Validation du formulaire échouée');
      return;
    }
    
    print('✅ Validation du formulaire réussie');
    print('📋 Validation des champs supplémentaires...');

      // Validation supplémentaire pour les champs requis non-textuels
      if (_birthDate == null) {
        print('❌ Date de naissance manquante');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner votre date de naissance'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
        return;
      }

      if (_gender == null || _gender!.isEmpty) {
        print('❌ Genre manquant');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner votre genre'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
        return;
      }

      if (_country == null || _country!.isEmpty) {
        print('❌ Pays manquant');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner votre pays'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
        return;
      }
      
    print('✅ Validation des champs supplémentaires réussie');
    print('📊 Valeurs actuelles des champs:');
    print('  - Prénom: "${_firstNameController.text.trim()}"');
    print('  - Nom: "${_lastNameController.text.trim()}"');
    print('  - Email: "${_emailController.text.trim()}"');
    print('  - Téléphone: "${_phoneController.text.trim()}"');
    print('  - Code pays: "$_countryCode"');
    print('  - Adresse: "${_addressController.text.trim()}"');
    print('  - Complément: "${_addressComplementController.text.trim()}"');
    print('  - Code postal: "${_postalCodeController.text.trim()}"');
    print('  - Ville: "${_cityController.text.trim()}"');
    print('  - Pays: "$_country"');
    print('  - Date de naissance: $_birthDate');
    print('  - Genre: "$_gender"');
    print('  - État matrimonial: "$_maritalStatus"');
    
    print('🔄 Construction du téléphone complet: ${_buildFullPhone()}');
    print('🔄 Construction de l\'adresse complète: ${_buildFullAddress()}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      print('🔄 Sauvegarde du profil complété...');
      
      // Get current profile
      final currentProfile = await AuthService.getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('Profil utilisateur non trouvé');
      }

      print('📊 Profil existant trouvé, mise à jour intelligente...');

      // Valider que tous les champs requis sont remplis
      if (_firstNameController.text.trim().isEmpty) {
        throw Exception('Le prénom est requis');
      }
      if (_lastNameController.text.trim().isEmpty) {
        throw Exception('Le nom de famille est requis');
      }
      if (_phoneController.text.trim().isEmpty) {
        throw Exception('Le numéro de téléphone est requis');
      }
      if (_countryCode == null || _countryCode!.isEmpty) {
        throw Exception('L\'indicatif de pays est requis');
      }
      if (_addressController.text.trim().isEmpty) {
        throw Exception('L\'adresse est requise');
      }
      if (_postalCodeController.text.trim().isEmpty) {
        throw Exception('Le code postal est requis');
      }
      if (_cityController.text.trim().isEmpty) {
        throw Exception('La ville est requise');
      }
      if (_country == null || _country!.isEmpty) {
        throw Exception('Le pays est requis');
      }
      if (_birthDate == null) {
        throw Exception('La date de naissance est requise');
      }
      if (_gender == null || _gender!.isEmpty) {
        throw Exception('Le genre est requis');
      }

      // Update profile with smart preservation of existing data
      final updatedProfile = currentProfile.copyWith(
        // Toujours mettre à jour les champs principaux
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        
        // Construire les champs complexes
        phone: _buildFullPhone(),
        address: _buildFullAddress(),
        
        birthDate: _birthDate,
        gender: _gender,
        maritalStatus: _maritalStatus,
        
        profileImageUrl: _profileImageUrl ?? currentProfile.profileImageUrl,
        
        updatedAt: DateTime.now(),
      );

      await AuthService.updateCurrentUserProfile(updatedProfile);
      
      print('✅ Profil sauvegardé avec succès');
      print('📊 Vérification finale du profil:');
      print('  - Prénom: "${updatedProfile.firstName}"');
      print('  - Nom: "${updatedProfile.lastName}"');
      print('  - Email: "${updatedProfile.email}"');
      print('  - Téléphone: "${updatedProfile.phone}"');
      print('  - Adresse: "${updatedProfile.address}"');
      print('  - Date de naissance: ${updatedProfile.birthDate}');
      print('  - Genre: "${updatedProfile.gender}"');
      print('  - État matrimonial: "${updatedProfile.maritalStatus}"');

      // Vérification en relisant le profil pour s'assurer qu'il est bien sauvegardé
      print('🔄 Vérification post-sauvegarde...');
      await Future.delayed(const Duration(milliseconds: 2000));
      
      final verifiedProfile = await AuthService.getCurrentUserProfile();
      if (verifiedProfile != null) {
        print('✅ Profil vérifié après sauvegarde:');
        print('  - Téléphone vérifié: "${verifiedProfile.phone}"');
        print('  - Adresse vérifiée: "${verifiedProfile.address}"');
        print('  - Genre vérifié: "${verifiedProfile.gender}"');
      } else {
        print('❌ Impossible de vérifier le profil après sauvegarde');
      }

      if (mounted) {
        // Attendre un délai plus long pour s'assurer que la sauvegarde est complète
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Naviguer vers l'interface utilisateur appropriée
        // Au lieu de naviguer vers '/', on va forcer une reconstruction de l'AuthWrapper
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
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
                      const SizedBox(height: AppTheme.spaceXLarge),
                      _buildProgressIndicator(),
                      const SizedBox(height: AppTheme.spaceXLarge),
                      _buildProfileForm(),
                      const SizedBox(height: AppTheme.space40),
                      _buildModernActionButton(),
                      const SizedBox(height: AppTheme.spaceXLarge),
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
          const SizedBox(height: AppTheme.space40),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.white100.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              size: 48,
              color: AppTheme.white100,
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          const Text(
            'Configuration du profil',
            style: TextStyle(
              fontSize: AppTheme.fontSize28,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.white100,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Complétez votre profil pour accéder à l\'application',
            style: TextStyle(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.white100.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space40),
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
                  borderRadius: BorderRadius.circular(AppTheme.radius2),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey500,
                  borderRadius: BorderRadius.circular(AppTheme.radius2),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey500,
                  borderRadius: BorderRadius.circular(AppTheme.radius2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Informations',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                fontWeight: AppTheme.fontSemiBold,
                color: const Color(0xFF667EEA),
              ),
            ),
            Text(
              'Adresse',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey500,
              ),
            ),
            Text(
              'Validation',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey500,
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
          const SizedBox(height: AppTheme.spaceXLarge),
          _buildPersonalInfoSection(),
          const SizedBox(height: AppTheme.spaceLarge),
          _buildAddressSection(),
          const SizedBox(height: AppTheme.spaceLarge),
          _buildContactSection(),
          const SizedBox(height: AppTheme.spaceLarge),
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
                  color: AppTheme.black100.withOpacity(0.1),
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
                        color: AppTheme.grey500,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.grey500,
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: AppTheme.grey500,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.grey500,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.grey500,
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
                    color: AppTheme.white100,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black100.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.white100,
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
            const SizedBox(width: AppTheme.spaceMedium),
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
        const SizedBox(height: AppTheme.spaceMedium),
        _buildModernTextField(
          controller: _emailController,
          label: 'Email *',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'L\'email est requis';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Format d\'email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: _buildDateField(),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
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
              child: _buildModernTextField(
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
            ),
          ],
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
          label: 'Adresse *',
          icon: Icons.home_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildModernTextField(
          controller: _addressComplementController,
          label: 'Complément d\'adresse',
          icon: Icons.add_home_outlined,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildModernTextField(
                controller: _postalCodeController,
                label: 'Code postal *',
                icon: Icons.local_post_office_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le code postal est requis';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              flex: 2,
              child: _buildModernTextField(
                controller: _cityController,
                label: 'Ville *',
                icon: Icons.location_city_outlined,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'La ville est requise';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildCountryDropdown(),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _buildSection(
      title: 'Statut',
      icon: Icons.info_outline,
      children: [
        _buildMaritalStatusDropdown(),
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
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
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
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),
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
        fontSize: AppTheme.fontSize16,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        labelStyle: TextStyle(
          color: AppTheme.grey500,
          fontSize: AppTheme.fontSize14,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.redStandard, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.redStandard, width: 2),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.grey500),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF667EEA)),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Date de naissance *',
                style: TextStyle(
                  fontSize: AppTheme.fontSize16,
                  color: _birthDate != null 
                      ? const Color(0xFF1F2937) 
                      : AppTheme.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownSearch<String>(
      selectedItem: _gender,
      items: _genderOptions,
      itemAsString: (gender) => gender,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Genre *',
          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF667EEA)),
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
        fit: FlexFit.loose,
      ),
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
    return DropdownSearch<String>(
      selectedItem: _maritalStatus,
      items: _maritalStatusOptions,
      itemAsString: (status) => status,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Statut marital',
          prefixIcon: const Icon(Icons.favorite_outline, color: Color(0xFF667EEA)),
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
        fit: FlexFit.loose,
      ),
      onChanged: (String? newValue) {
        setState(() {
          _maritalStatus = newValue;
        });
      },
    );
  }

  Widget _buildCountryCodeDropdown() {
    return DropdownSearch<String>(
      selectedItem: _countryCode,
      items: _countryCodes.keys.toList(),
      itemAsString: (code) => code,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'L\'indicatif de pays est requis';
        }
        return null;
      },
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
          labelText: 'Pays *',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le pays est requis';
        }
        return null;
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: _isLoading ? null : _completeSetup,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.white100,
                        size: 24,
                      ),
                      SizedBox(width: AppTheme.space12),
                      Text(
                        'Finaliser la configuration',
                        style: TextStyle(
                          color: AppTheme.white100,
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
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

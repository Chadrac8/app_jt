import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/special_song_reservation_model.dart';
import '../models/person_model.dart';
import '../services/special_song_reservation_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../widgets/sunday_calendar_widget.dart';
import '../../theme.dart';

class SpecialSongReservationPage extends StatefulWidget {
  const SpecialSongReservationPage({super.key});

  @override
  State<SpecialSongReservationPage> createState() => _SpecialSongReservationPageState();
}

class _SpecialSongReservationPageState extends State<SpecialSongReservationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late AnimationController _pulseController; // Nouveau contrôleur pour l'animation de pulsation
  late AnimationController _instructionsController; // Contrôleur pour l'animation des instructions
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation; // Animation de pulsation pour le message d'alerte
  late Animation<double> _instructionsHeightAnimation;
  late Animation<double> _instructionsOpacityAnimation;
  
  // État pour contrôler l'affichage des instructions
  bool _showInstructions = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _songTitleController = TextEditingController();
  final _musicianLinkController = TextEditingController();
  
  // State variables
  DateTime? _selectedSunday;
  PersonModel? _currentUser;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _canUserReserve = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _instructionsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _instructionsHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _instructionsController,
      curve: Curves.easeInOut,
    ));
    
    _instructionsOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _instructionsController,
      curve: Curves.easeIn,
    ));
    
    _loadUserData();
    _animationController.forward();
    
    // Démarrer l'animation de pulsation en boucle
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose(); // Nettoyer le contrôleur de pulsation
    _instructionsController.dispose(); // Nettoyer le contrôleur d'instructions
    _nameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _songTitleController.dispose();
    _musicianLinkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = AuthService.currentUser;
      if (user != null) {
        final person = await FirebaseService.getPerson(user.uid);
        if (person != null) {
          setState(() {
            _currentUser = person;
            _nameController.text = person.lastName;
            _firstNameController.text = person.firstName;
            _emailController.text = person.email;
            _phoneController.text = person.phone ?? '';
          });
          
          // Vérifier si l'utilisateur peut réserver
          final canReserve = await SpecialSongReservationService.canPersonReserve(person.id);
          setState(() => _canUserReserve = canReserve);
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des données utilisateur: $e';
      });
    }
  }

  void _onSundaySelected(DateTime sunday) {
    // Vérifier si l'utilisateur a atteint sa limite
    if (!_canUserReserve) {
      _showLimitReachedDialog();
      return;
    }
    
    setState(() {
      _selectedSunday = sunday;
      _errorMessage = null;
    });
    
    // Scroll vers le formulaire
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.redStandard.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de pulsation pour l'icône d'avertissement
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.8, end: 1.1),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.white100.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.white100.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: AppTheme.white100,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Titre avec animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: const Text(
                        '🚫 LIMITE ATTEINTE',
                        style: TextStyle(
                          color: AppTheme.white100,
                          fontSize: 24,
                          fontWeight: AppTheme.fontBold,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Zone d'information avec animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white100,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.black100.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.grey600,
                              size: 28,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Vous avez déjà effectué votre réservation pour ce mois',
                              style: TextStyle(
                                color: AppTheme.grey800,
                                fontSize: 16,
                                fontWeight: AppTheme.fontSemiBold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.grey50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.grey300, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule, color: AppTheme.grey700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Prochaine réservation possible :\n${DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now().add(const Duration(days: 32)))}',
                                      style: TextStyle(
                                        color: AppTheme.grey800,
                                        fontSize: 14,
                                        fontWeight: AppTheme.fontMedium,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Badge de règle avec animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.amber[600]!, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rule, color: Colors.amber[800], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Maximum 1 réservation par mois',
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 14,
                                fontWeight: AppTheme.fontBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Bouton de fermeture avec animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.white100,
                          foregroundColor: AppTheme.grey700,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: AppTheme.grey700),
                            const SizedBox(width: 8),
                            Text(
                              'Compris',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: AppTheme.fontBold,
                                color: AppTheme.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate() || _selectedSunday == null) {
      return;
    }

    if (!_canUserReserve) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà une réservation pour ce mois'),
          backgroundColor: AppTheme.orangeStandard,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reservation = SpecialSongReservationModel(
        id: '',
        personId: _currentUser?.id ?? '',
        fullName: '${_firstNameController.text.trim()} ${_nameController.text.trim()}',
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        songTitle: _songTitleController.text.trim(),
        musicianLink: _musicianLinkController.text.trim().isNotEmpty 
            ? _musicianLinkController.text.trim() 
            : null,
        reservedDate: _selectedSunday!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SpecialSongReservationService.createReservation(reservation);

      if (!mounted) return;
      
      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Réservation confirmée pour le ${DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedSunday!)}',
          ),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 4),
        ),
      );

      // Réinitialiser le formulaire
      _resetForm();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedSunday = null;
      _errorMessage = null;
    });
    
    // Réinitialiser uniquement les champs non liés au profil
    _songTitleController.clear();
    _musicianLinkController.clear();
    
    // Recharger les données utilisateur
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.9),
                const Color(0xFF6366F1),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(
              color: AppTheme.white100,
              size: 28,
            ),
            title: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Réservation Chant Spécial',
                  style: const TextStyle(
                    color: AppTheme.white100,
                    fontWeight: AppTheme.fontBold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Réservez votre moment de louange',
                  style: TextStyle(
                    color: AppTheme.white100.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: AppTheme.fontRegular,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.white100.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: AppTheme.white100,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  );
                },
                child: _buildMainContent(),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.white100,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement...',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Préparation de votre espace de réservation',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.white100,
            const Color(0xFFF8FAFC),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Espace pour l'AppBar étendu
            const SizedBox(height: 140),
            
            // Contenu principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de bienvenue
                  _buildWelcomeHeader(),
                  
                  const SizedBox(height: 24),
                  
                  // Instructions Card
                  _buildInstructionsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Calendar Section
                  _buildCalendarSection(),
                  
                  // Formulaire (affiché seulement si un dimanche est sélectionné)
                  if (_selectedSunday != null) ...[
                    const SizedBox(height: 24),
                    _buildReservationForm(),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.white100,
            AppTheme.grey50.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.blueStandard.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppTheme.white100,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue dans votre espace',
                  style: TextStyle(
                    color: AppTheme.grey800,
                    fontSize: 18,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Réservez facilement votre moment de louange pour enrichir nos cultes',
                  style: TextStyle(
                    color: AppTheme.grey600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(8), // Réduit de 12 à 8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions Card
          _buildInstructionsCard(),
          
          const SizedBox(height: 8), // Réduit de 16 à 8
          
          // Calendar Section
          _buildCalendarSection(),
          
          // Formulaire (affiché seulement si un dimanche est sélectionné)
          if (_selectedSunday != null) ...[
            const SizedBox(height: 12), // Réduit de 20 à 12
            _buildReservationForm(),
          ],
          
          const SizedBox(height: 12), // Réduit de 20 à 12
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, slideValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.grey50,
                    Colors.indigo[50]!,
                    AppTheme.grey100.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.blueStandard.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blueStandard.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppTheme.white100.withOpacity(0.8),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête interactif avec effet de survol
                    AnimatedBuilder(
                      animation: _instructionsController,
                      builder: (context, child) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _showInstructions = !_showInstructions;
                            });
                            if (_showInstructions) {
                              _instructionsController.forward();
                            } else {
                              _instructionsController.reverse();
                            }
                          },
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                              gradient: _showInstructions 
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.1),
                                      AppTheme.primaryColor.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            ),
                            child: Row(
                              children: [
                                // Icône avec effet de glow
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryColor.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_outline,
                                    color: AppTheme.white100,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Titre avec animation
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comment procéder',
                                        style: TextStyle(
                                          color: AppTheme.grey900,
                                          fontWeight: AppTheme.fontBold,
                                          fontSize: 18,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 300),
                                        opacity: _showInstructions ? 0.0 : 1.0,
                                        child: Text(
                                          'Cliquez pour découvrir les étapes',
                                          style: TextStyle(
                                            color: AppTheme.grey600,
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Icône d'expansion avec rotation fluide et glow
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _showInstructions 
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                  child: AnimatedRotation(
                                    turns: _showInstructions ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    child: Icon(
                                      Icons.expand_more_rounded,
                                      color: _showInstructions 
                                        ? AppTheme.primaryColor
                                        : AppTheme.grey700,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Contenu extensible avec animation sophistiquée
                    AnimatedBuilder(
                      animation: _instructionsController,
                      builder: (context, child) {
                        return ClipRect(
                          child: AnimatedAlign(
                            alignment: Alignment.topCenter,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            heightFactor: _instructionsHeightAnimation.value,
                            child: FadeTransition(
                              opacity: _instructionsOpacityAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                ),
                                child: Column(
                                  children: [
                                    // Ligne de séparation élégante
                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            AppTheme.blueStandard.withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Étapes avec animations décalées
                                    ..._buildAnimatedSteps(),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Note importante avec effet de brillance
                                    _buildImportantNote(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAnimatedSteps() {
    final steps = [
      {
        'number': '1',
        'title': 'Choisir une date',
        'description': 'Sélectionnez un dimanche disponible dans le calendrier',
        'icon': Icons.calendar_month_outlined,
        'color': AppTheme.greenStandard,
      },
      {
        'number': '2',
        'title': 'Remplir les informations',
        'description': 'Complétez le formulaire avec les détails du chant',
        'icon': Icons.edit_note_rounded,
        'color': AppTheme.orangeStandard,
      },
      {
        'number': '3',
        'title': 'Confirmer la réservation',
        'description': 'Vérifiez vos informations et validez votre demande',
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.purple,
      },
    ];

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - animationValue), 0),
            child: Opacity(
              opacity: animationValue,
              child: Container(
                margin: EdgeInsets.only(bottom: index < steps.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.white100,
                      (step['color'] as Color).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: (step['color'] as Color).withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (step['color'] as Color).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Numéro avec effet de glow
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            step['color'] as Color,
                            (step['color'] as Color).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (step['color'] as Color).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          step['number'] as String,
                          style: const TextStyle(
                            color: AppTheme.white100,
                            fontWeight: AppTheme.fontBold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Contenu de l'étape
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                step['icon'] as IconData,
                                color: step['color'] as Color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step['title'] as String,
                                  style: TextStyle(
                                    color: AppTheme.grey800,
                                    fontWeight: AppTheme.fontBold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] as String,
                            style: TextStyle(
                              color: AppTheme.grey600,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildImportantNote() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber[50]!,
                    AppTheme.grey50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: Colors.amber[300]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icône avec animation de rotation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 2000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, rotationValue, child) {
                      return Transform.rotate(
                        angle: rotationValue * 0.1,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[600],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: AppTheme.white100,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  
                  // Texte avec effet de brillance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Règle importante',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: AppTheme.fontBold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Une seule réservation par personne et par mois',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 14,
                            fontWeight: AppTheme.fontSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.white100,
            AppTheme.grey50!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: AppTheme.grey200!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppTheme.white100.withOpacity(0.9),
            blurRadius: 15,
            offset: const Offset(0, -5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête moderne du calendrier
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.grey50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppTheme.white100,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisir votre date',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: AppTheme.fontBold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sélectionnez un dimanche disponible pour votre chant',
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          // Calendrier avec padding moderne
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.white100,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.grey100!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.grey500.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: SundayCalendarWidget(
                  onSundaySelected: _onSundaySelected,
                  currentUserId: _currentUser?.id,
                  onReservationCancelled: () {
                    _loadUserData();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationForm() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.white100,
                    AppTheme.grey50!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.grey200!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black100.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppTheme.white100.withOpacity(0.9),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // En-tête élégant du formulaire
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.grey50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppTheme.white100,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Finaliser votre réservation',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 20,
                                      fontWeight: AppTheme.fontBold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Complétez les informations pour confirmer votre chant',
                                    style: TextStyle(
                                      color: AppTheme.grey600,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Date sélectionnée avec style élégant
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.white100,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date sélectionnée',
                                    style: TextStyle(
                                      color: AppTheme.grey600,
                                      fontSize: 12,
                                      fontWeight: AppTheme.fontMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedSunday!),
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 16,
                                      fontWeight: AppTheme.fontBold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Formulaire avec champs modernes
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Section Informations personnelles
                          _buildFormSection(
                            'Vos informations',
                            Icons.person_rounded,
                            [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _firstNameController,
                                      label: 'Prénom',
                                      hint: 'Votre prénom',
                                      icon: Icons.person_outline,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Le prénom est requis';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _nameController,
                                      label: 'Nom',
                                      hint: 'Votre nom de famille',
                                      icon: Icons.badge_outlined,
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
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'votre.email@exemple.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'L\'email est requis';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: _phoneController,
                                label: 'Téléphone',
                                hint: '+33 6 12 34 56 78',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le téléphone est requis';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Section Chant
                          _buildFormSection(
                            'Détails du chant',
                            Icons.music_note_rounded,
                            [
                              _buildModernTextField(
                                controller: _songTitleController,
                                label: 'Titre du chant',
                                hint: 'Nom de votre chant spécial',
                                icon: Icons.library_music_outlined,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Le titre du chant est requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: _musicianLinkController,
                                label: 'Lien musicien (optionnel)',
                                hint: 'YouTube, Spotify, SoundCloud...',
                                icon: Icons.link_outlined,
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Bouton de validation moderne
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réservation confirmée pour',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedSunday!),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 18,
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Section Informations personnelles
            _buildSectionHeader(
              icon: Icons.person,
              title: 'Informations personnelles',
              subtitle: 'Vos coordonnées pour la réservation',
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _firstNameController,
                    label: 'Prénom',
                    icon: Icons.person_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernTextField(
                    controller: _nameController,
                    label: 'Nom',
                    icon: Icons.person,
                    isRequired: true,
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
            
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _emailController,
              label: 'Adresse e-mail',
              icon: Icons.email_outlined,
              isRequired: true,
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
            
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _phoneController,
              label: 'Numéro de téléphone',
              icon: Icons.phone_outlined,
              isRequired: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Section Informations du chant
            _buildSectionHeader(
              icon: Icons.music_note,
              title: 'Détails du chant spécial',
              subtitle: 'Informations sur votre performance',
            ),
            
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _songTitleController,
              label: 'Titre du chant',
              icon: Icons.library_music_outlined,
              isRequired: true,
              hint: 'Ex: Amazing Grace, Il est vivant...',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre du chant est requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            _buildModernTextField(
              controller: _musicianLinkController,
              label: 'Lien de référence (optionnel)',
              icon: Icons.link,
              hint: 'YouTube, Spotify, partition PDF...',
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 28),
            
            // Message d'erreur
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.grey50,
                      AppTheme.grey50.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.redStandard.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.redStandard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: AppTheme.white100,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.grey700,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    onPressed: _isSubmitting ? null : () {
                      setState(() {
                        _selectedSunday = null;
                        _errorMessage = null;
                      });
                    },
                    text: 'Annuler',
                    icon: Icons.close,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildPrimaryButton(
                    onPressed: _isSubmitting ? null : _submitReservation,
                    text: 'Confirmer la réservation',
                    icon: Icons.check_circle,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: AppTheme.fontBold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.grey600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: AppTheme.fontMedium,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.grey300!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.grey300!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.redStandard, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.white100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: AppTheme.grey600,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: AppTheme.grey400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed != null ? [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ] : [
            AppTheme.grey300!,
            AppTheme.grey400!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.white100,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppTheme.white100, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppTheme.white100,
                      fontWeight: AppTheme.fontBold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.grey300!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.grey600, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: AppTheme.grey700,
                fontWeight: AppTheme.fontSemiBold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
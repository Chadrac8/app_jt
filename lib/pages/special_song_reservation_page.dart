import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/special_song_reservation_model.dart';
import '../models/person_model.dart';
import '../services/special_song_reservation_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../widgets/sunday_calendar_widget.dart';
import '../theme.dart';

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
    // Arrêter les animations en cours
    _animationController.stop();
    _pulseController.stop();
    _instructionsController.stop();
    
    // Disposer les contrôleurs d'animation
    _animationController.dispose();
    _pulseController.dispose();
    _instructionsController.dispose();
    
    // Disposer les contrôleurs de texte
    _nameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _songTitleController.dispose();
    _musicianLinkController.dispose();
    
    // Disposer le contrôleur de scroll
    _scrollController.dispose();
    
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      final user = AuthService.currentUser;
      if (user != null) {
        final person = await FirebaseService.getPerson(user.uid);
        if (person != null && mounted) {
          setState(() {
            _currentUser = person;
            _nameController.text = person.lastName;
            _firstNameController.text = person.firstName;
                            _emailController.text = person.email ?? '';
            _phoneController.text = person.phone ?? '';
          });
          
          // Vérifier si l'utilisateur peut réserver
          final canReserve = await SpecialSongReservationService.canPersonReserve(person.id);
          if (mounted) {
            setState(() => _canUserReserve = canReserve);
          }
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des données utilisateur: $e';
        });
      }
    }
  }

  void _onSundaySelected(DateTime sunday) {
    // Vérifier si l'utilisateur a atteint sa limite
    if (!_canUserReserve) {
      _showLimitReachedDialog();
      return;
    }
    
    if (mounted) {
      setState(() {
        _selectedSunday = sunday;
        _errorMessage = null;
      });
      
      // Attendre que le widget soit reconstruit avec le formulaire
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollToReservationForm();
        }
      });
    }
  }

  void _scrollToReservationForm() {
    if (!mounted || !_scrollController.hasClients) return;
    
    // Attendre un petit délai pour que le formulaire soit complètement rendu
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_scrollController.hasClients) return;
      
      // Calculer la position du formulaire
      // Instructions card ≈ 200px + Calendar section ≈ 400px + espacements ≈ 100px
      const double approximateFormPosition = 700.0;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetPosition = approximateFormPosition.clamp(0.0, maxScroll);
      
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
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
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
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
                
                const SizedBox(height: AppTheme.space20),
                
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
                          fontSize: AppTheme.fontSize24,
                          fontWeight: AppTheme.fontBold,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Zone d'information avec animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, opacity, child) {
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                            const SizedBox(height: AppTheme.space12),
                            Text(
                              'Vous avez déjà effectué votre réservation pour ce mois',
                              style: TextStyle(
                                color: AppTheme.grey800,
                                fontSize: AppTheme.fontSize16,
                                fontWeight: AppTheme.fontSemiBold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space12),
                              decoration: BoxDecoration(
                                color: AppTheme.grey50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.grey300, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule, color: AppTheme.grey700, size: 20),
                                  const SizedBox(width: AppTheme.spaceSmall),
                                  Expanded(
                                    child: Text(
                                      'Prochaine réservation possible :\n${DateFormat('MMMM yyyy', 'fr_FR').format(DateTime.now().add(const Duration(days: 32)))}',
                                      style: TextStyle(
                                        color: AppTheme.grey800,
                                        fontSize: AppTheme.fontSize14,
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
                
                const SizedBox(height: AppTheme.space20),
                
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
                          color: AppTheme.warning.withAlpha(51),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: AppTheme.warning, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rule, color: AppTheme.warning, size: 18),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Text(
                              'Maximum 1 réservation par mois',
                              style: TextStyle(
                                color: AppTheme.warning,
                                fontSize: AppTheme.fontSize14,
                                fontWeight: AppTheme.fontBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceLarge),
                
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
                            const SizedBox(width: AppTheme.spaceSmall),
                            Text(
                              'Compris',
                              style: TextStyle(
                                fontSize: AppTheme.fontSize16,
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
    if (mounted) {
      setState(() {
        _selectedSunday = null;
        _errorMessage = null;
      });
    }
    
    // Réinitialiser uniquement les champs non liés au profil
    _songTitleController.clear();
    _musicianLinkController.clear();
    
    // Recharger les données utilisateur
    _loadUserData();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.help_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        title: const Text(
          'Comment réserver un cantique ?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpStep('1', 'Choisissez un dimanche', 'Sélectionnez une date disponible dans le calendrier'),
            const SizedBox(height: 12),
            _buildHelpStep('2', 'Remplissez le formulaire', 'Indiquez le titre du cantique et vos coordonnées'),
            const SizedBox(height: 12),
            _buildHelpStep('3', 'Confirmez', 'Validez votre réservation'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Limite de 1 réservation par mois et par personne',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String title, String description) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }





  Widget _buildCompactProfileImage() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return _currentUser?.profileImageUrl != null && _currentUser!.profileImageUrl!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              _currentUser!.profileImageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildCompactDefaultAvatar();
              },
            ),
          )
        : _buildCompactDefaultAvatar();
  }

  Widget _buildCompactDefaultAvatar() {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getUserInitials();
    
    if (initials.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            initials.length > 1 ? initials.substring(0, 1) : initials,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.person_rounded,
        color: colorScheme.onPrimaryContainer,
        size: 22,
      ),
    );
  }

  String _getUserInitials() {
    if (_currentUser == null) return '';
    
    final firstName = _currentUser!.firstName.trim();
    final lastName = _currentUser!.lastName.trim();
    
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName.substring(0, 1).toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName.substring(0, 1).toUpperCase();
    }
    
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Réserver un Cantique Spécial',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            fontSize: 22,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,  
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        toolbarHeight: 64, // Hauteur augmentée pour plus d'élégance
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
          tooltip: 'Retour',
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Afficher aide contextuelle
              _showHelpDialog();
            },
            icon: const Icon(Icons.help_outline_rounded, size: 24),
            tooltip: 'Aide',
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withBlue(
                  (colorScheme.primary.blue * 0.9).round().clamp(0, 255),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: _buildBody(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions Card
          _buildInstructionsCard(),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Calendar Section
          _buildCalendarSection(),
          
          // Formulaire (affiché seulement si un dimanche est sélectionné)
          if (_selectedSunday != null) ...[
            const SizedBox(height: AppTheme.spaceLarge),
            _buildReservationForm(),
          ],
          
          const SizedBox(height: AppTheme.spaceLarge),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, slideValue, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Transform.translate(
          offset: Offset(0, 24 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                surfaceTintColor: colorScheme.surfaceTint,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // En-tête moderne avec gradient subtil
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer.withOpacity(0.7),
                            colorScheme.primaryContainer.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: InkWell(
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Icône avec animation de pulsation
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (_pulseController.value * 0.1),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.auto_stories_rounded,
                                        color: colorScheme.onPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              
                              // Contenu textuel
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guide de Réservation',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _showInstructions 
                                          ? 'Suivez ces étapes simples'
                                          : 'Découvrez comment réserver facilement',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                        fontSize: 14,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Icône d'expansion avec animation
                              AnimatedRotation(
                                turns: _showInstructions ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onPrimaryContainer.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Contenu extensible avec animations fluides
                    AnimatedBuilder(
                      animation: _instructionsController,
                      builder: (context, child) {
                        return ClipRect(
                          child: AnimatedAlign(
                            alignment: Alignment.topCenter,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                            heightFactor: _instructionsHeightAnimation.value,
                            child: FadeTransition(
                              opacity: _instructionsOpacityAnimation,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  children: [
                                    // Divider élégant avec gradient
                                    Container(
                                      width: 60,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary.withOpacity(0.6),
                                            colorScheme.primary,
                                            colorScheme.primary.withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Étapes modernes
                                    ..._buildModernSteps(),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Note importante redesignée
                                    _buildModernImportantNote(),
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

  List<Widget> _buildModernSteps() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final steps = [
      {
        'number': '1',
        'title': 'Sélectionnez votre date',
        'description': 'Choisissez un dimanche libre dans le calendrier ci-dessous',
        'icon': Icons.event_available_rounded,
      },
      {
        'number': '2',
        'title': 'Complétez les informations',
        'description': 'Renseignez le titre du cantique et vos coordonnées',
        'icon': Icons.edit_note_rounded,
      },
      {
        'number': '3',
        'title': 'Confirmez votre réservation',
        'description': 'Vérifiez et validez votre demande de cantique spécial',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 150)),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animValue, child) {
          return Transform.translate(
            offset: Offset(20 * (1 - animValue), 0),
            child: Opacity(
              opacity: animValue,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Numéro avec design moderne
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          step['number'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Icône et contenu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                step['icon'] as IconData,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step['title'] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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

  Widget _buildModernImportantNote() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.7),
            colorScheme.primaryContainer.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important à retenir',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Une seule réservation par personne et par mois',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.9),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, slideValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                surfaceTintColor: colorScheme.surfaceTint,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    // En-tête moderne avec gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.secondaryContainer.withOpacity(0.8),
                            colorScheme.secondaryContainer.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Icône avec animation
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.08),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.secondary.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: colorScheme.onSecondary,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          
                          // Contenu textuel
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calendrier des Dimanches',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sélectionnez votre date préférée',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                                    fontSize: 14,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Badge indicateur si une date est sélectionnée
                          if (_selectedSunday != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sélectionné',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Calendrier
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SundayCalendarWidget(
                        onSundaySelected: _onSundaySelected,
                        currentUserId: _currentUser?.id,
                        onReservationCancelled: () {
                          _loadUserData();
                          if (_selectedSunday != null && mounted) {
                            setState(() => _selectedSunday = null);
                          }
                        },
                      ),
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

  Widget _buildReservationForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, slideValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                surfaceTintColor: colorScheme.surfaceTint,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // En-tête moderne avec gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.tertiaryContainer.withOpacity(0.9),
                              colorScheme.tertiaryContainer.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            // Icône avec animation
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.06),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.tertiary.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_note_rounded,
                                      color: colorScheme.onTertiary,
                                      size: 26,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 18),
                            
                            // Contenu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informations de Réservation',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedSunday!)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onTertiaryContainer.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Contenu du formulaire
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Informations personnelles
                            _buildModernSectionHeader(
                              customIcon: _buildCompactProfileImage(),
                              title: 'Vos Informations',
                              subtitle: 'Données personnelles pour la réservation',
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Champs nom et prénom en ligne
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _nameController,
                                    label: 'Nom de famille',
                                    icon: Icons.badge_outlined,
                                    isRequired: true,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Le nom est requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernTextField(
                                    controller: _firstNameController,
                                    label: 'Prénom',
                                    icon: Icons.person_outline_rounded,
                                    isRequired: true,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Le prénom est requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildModernTextField(
                              controller: _emailController,
                              label: 'Adresse email',
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
                            
                            const SizedBox(height: 16),
                            
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
                            
                            const SizedBox(height: 28),
                            
                            // Section Cantique
                            _buildModernSectionHeader(
                              icon: Icons.music_note_rounded,
                              title: 'Détails du Cantique',
                              subtitle: 'Informations sur votre performance',
                            ),
                            
                            const SizedBox(height: 20),
                            
                            _buildModernTextField(
                              controller: _songTitleController,
                              label: 'Titre du cantique',
                              icon: Icons.library_music_outlined,
                              isRequired: true,
                              hint: 'Ex: Amazing Grace, Il est vivant...',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le titre du cantique est requis';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildModernTextField(
                              controller: _musicianLinkController,
                              label: 'Lien de référence (optionnel)',
                              icon: Icons.link_rounded,
                              hint: 'YouTube, Spotify, partition PDF...',
                              keyboardType: TextInputType.url,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Message d'erreur
                            if (_errorMessage != null) ...[
                              _buildErrorMessage(),
                              const SizedBox(height: 20),
                            ],
                            
                            // Bouton de confirmation moderne
                            _buildModernSubmitButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSectionHeader({
    IconData? icon,
    Widget? customIcon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: customIcon ?? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon ?? Icons.help,
              color: colorScheme.onPrimaryContainer,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildErrorMessage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSubmitButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 6,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirmer la Réservation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
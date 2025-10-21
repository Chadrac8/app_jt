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
                            _emailController.text = person.email ?? '';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Réservation Chant Spécial',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: AppTheme.fontSemiBold,
            letterSpacing: 0.1,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
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
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, slideValue, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Transform.translate(
          offset: Offset(0, 16 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Card(
              elevation: AppTheme.elevation1,
              surfaceTintColor: colorScheme.surfaceTint,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  // En-tête interactif
                  InkWell(
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      child: Row(
                        children: [
                          // Icône moderne
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceSmall),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMedium),
                          
                          // Titre et sous-titre
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comment procéder',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: AppTheme.fontSemiBold,
                                  ),
                                ),
                                if (!_showInstructions) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cliquez pour découvrir les étapes',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Icône d'expansion
                          AnimatedRotation(
                            turns: _showInstructions ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                    
                                    const SizedBox(height: AppTheme.spaceMedium),
                                    
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
                  
                  // Contenu extensible avec animation
                  AnimatedBuilder(
                    animation: _instructionsController,
                    builder: (context, child) {
                      return ClipRect(
                        child: AnimatedAlign(
                          alignment: Alignment.topCenter,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          heightFactor: _instructionsHeightAnimation.value,
                          child: FadeTransition(
                            opacity: _instructionsOpacityAnimation,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.spaceMedium,
                                0,
                                AppTheme.spaceMedium,
                                AppTheme.spaceMedium,
                              ),
                              child: Column(
                                children: [
                                  // Divider
                                  Divider(
                                    color: colorScheme.outline.withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: AppTheme.spaceMedium),
                                  
                                  // Étapes
                                  ..._buildAnimatedSteps(),
                                  
                                  const SizedBox(height: AppTheme.spaceMedium),
                                  
                                  // Note importante
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
        );
      },
    );
  }

  List<Widget> _buildAnimatedSteps() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final steps = [
      {
        'number': '1',
        'title': 'Choisir une date',
        'description': 'Sélectionnez un dimanche disponible dans le calendrier',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'number': '2',
        'title': 'Remplir les informations',
        'description': 'Complétez le formulaire avec les détails du chant',
        'icon': Icons.edit_note_rounded,
      },
      {
        'number': '3',
        'title': 'Confirmer la réservation',
        'description': 'Vérifiez vos informations et validez votre demande',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final isLast = index == steps.length - 1;
      
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 200 + (index * 100)),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(20 * (1 - animationValue), 0),
            child: Opacity(
              opacity: animationValue,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.spaceSmall),
                child: Card(
                  elevation: AppTheme.elevation1,
                  surfaceTintColor: colorScheme.surfaceTint,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    child: Row(
                      children: [
                        // Badge numéro
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              step['number'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: AppTheme.fontBold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMedium),
                        
                        // Contenu
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
                                  const SizedBox(width: AppTheme.spaceSmall),
                                  Expanded(
                                    child: Text(
                                      step['title'] as String,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: AppTheme.fontSemiBold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceXSmall),
                              Text(
                                step['description'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
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
    }).toList();
  }

  Widget _buildImportantNote() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Transform.scale(
          scale: 0.95 + (0.05 * animationValue),
          child: Opacity(
            opacity: animationValue,
            child: Card(
              elevation: AppTheme.elevation2,
              surfaceTintColor: AppTheme.warning,
              color: AppTheme.warningContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Row(
                  children: [
                    // Icône d'avertissement
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: AppTheme.onWarning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    
                    // Texte
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Règle importante',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.onWarningContainer,
                              fontWeight: AppTheme.fontSemiBold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXSmall),
                          Text(
                            'Une seule réservation par personne et par mois',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.onWarningContainer,
                            ),
                          ),
                        ],
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

  Widget _buildCalendarSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: AppTheme.elevation2,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélectionner une date',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                      Text(
                        'Choisissez un dimanche disponible',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            SundayCalendarWidget(
              onSundaySelected: _onSundaySelected,
              currentUserId: _currentUser?.id,
              onReservationCancelled: () {
                _loadUserData();
                if (_selectedSunday != null) {
                  setState(() => _selectedSunday = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: AppTheme.elevation3,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête du formulaire
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Réservation confirmée pour',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXSmall),
                          Text(
                            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedSunday!),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: AppTheme.fontSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceLarge),
              
              // Section Informations personnelles
              _buildSectionHeader(
                icon: Icons.person,
                title: 'Informations personnelles',
                subtitle: 'Vos coordonnées pour la réservation',
              ),
            
              
              const SizedBox(height: AppTheme.spaceMedium),
              
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
                  const SizedBox(width: AppTheme.spaceMedium),
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
              
              const SizedBox(height: AppTheme.spaceMedium),
              
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
              
              const SizedBox(height: AppTheme.spaceMedium),
              
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
              
              const SizedBox(height: AppTheme.spaceLarge),
              
              // Section Informations du chant
              _buildSectionHeader(
                icon: Icons.music_note,
                title: 'Détails du chant spécial',
                subtitle: 'Informations sur votre performance',
              ),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
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
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              _buildModernTextField(
                controller: _musicianLinkController,
                label: 'Lien de référence (optionnel)',
                icon: Icons.link,
                hint: 'YouTube, Spotify, partition PDF...',
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: AppTheme.spaceLarge),
              
              // Message d'erreur
              if (_errorMessage != null) ...[
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
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
                  const SizedBox(width: AppTheme.spaceMedium),
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
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(AppTheme.spaceSmall),
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium, 
          vertical: AppTheme.spaceMedium,
        ),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          elevation: AppTheme.elevation1,
        ),
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'auth_service.dart';
import '../theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _gradientAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Animation pour le contenu
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animation pour le gradient d'arrière-plan
    _gradientAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    // Animation de pulsation
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Animation de rotation
    _rotationAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.linear,
    ));
    
    _animationController.forward();
    _gradientAnimationController.repeat(reverse: true);
    _pulseAnimationController.repeat(reverse: true);
    _rotationAnimationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gradientAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.signInAnonymously();
      
      if (result == null && mounted) {
        setState(() {
          _errorMessage = 'Impossible de se connecter en mode anonyme pour le moment. Veuillez réessayer ou utiliser votre compte.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connexion anonyme temporairement indisponible. Veuillez réessayer dans quelques instants.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential? result;
      
      if (_isLoginMode) {
        result = await AuthService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        result = await AuthService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (result == null && mounted) {
        setState(() {
          _errorMessage = _isLoginMode 
              ? 'Email ou mot de passe incorrect. Vérifiez vos informations et réessayez.' 
              : 'Impossible de créer votre compte. Veuillez vérifier vos informations et réessayer.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getUserFriendlyErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
  }

  /// Convertit les messages d'erreur techniques en messages compréhensibles par l'utilisateur
  String _getUserFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();
    
    // Erreurs Firebase Auth courantes
    if (error.contains('user-not-found') || error.contains('wrong-password')) {
      return 'Email ou mot de passe incorrect. Vérifiez vos informations.';
    }
    
    if (error.contains('email-already-in-use')) {
      return 'Cette adresse email est déjà utilisée. Essayez de vous connecter ou utilisez un autre email.';
    }
    
    if (error.contains('weak-password')) {
      return 'Votre mot de passe est trop faible. Utilisez au moins 6 caractères avec des lettres et des chiffres.';
    }
    
    if (error.contains('invalid-email')) {
      return 'L\'adresse email saisie n\'est pas valide. Vérifiez le format de votre email.';
    }
    
    if (error.contains('user-disabled')) {
      return 'Votre compte a été désactivé. Contactez l\'administrateur pour plus d\'informations.';
    }
    
    if (error.contains('too-many-requests')) {
      return 'Trop de tentatives de connexion. Attendez quelques minutes avant de réessayer.';
    }
    
    if (error.contains('network') || error.contains('connection')) {
      return 'Problème de connexion internet. Vérifiez votre connexion et réessayez.';
    }
    
    if (error.contains('operation-not-allowed')) {
      return 'Cette méthode de connexion n\'est pas autorisée. Contactez l\'assistance.';
    }
    
    if (error.contains('requires-recent-login')) {
      return 'Pour votre sécurité, veuillez vous reconnecter avant de continuer.';
    }
    
    if (error.contains('credential-already-in-use')) {
      return 'Ces informations de connexion sont déjà utilisées par un autre compte.';
    }
    
    if (error.contains('invalid-credential')) {
      return 'Informations de connexion invalides. Vérifiez votre email et mot de passe.';
    }
    
    // Erreurs génériques
    if (error.contains('permission-denied')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
    }
    
    if (error.contains('unavailable') || error.contains('deadline-exceeded')) {
      return 'Service temporairement indisponible. Veuillez réessayer dans quelques instants.';
    }
    
    // Message par défaut pour les erreurs non reconnues
    return 'Une erreur inattendue s\'est produite. Veuillez réessayer ou contacter l\'assistance si le problème persiste.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _gradientAnimation,
          _pulseAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Arrière-plan de base avec gradient animé
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF860505), // Rouge principal
                      const Color(0xFF860505).withValues(alpha: 0.8),
                      const Color(0xFFB71C1C).withValues(alpha: 0.9),
                      const Color(0xFF860505).withValues(alpha: 0.7),
                    ],
                    stops: [
                      0.0,
                      0.3 + (_gradientAnimation.value * 0.2),
                      0.7 + (_gradientAnimation.value * 0.2),
                      1.0,
                    ],
                  ),
                ),
              ),
              
              // Couche d'effets de particules animées
              ...List.generate(6, (index) {
                final size = 100.0 + (index * 30);
                final opacity = 0.1 - (index * 0.015);
                
                return Positioned(
                  left: (index.isEven ? -50 : MediaQuery.of(context).size.width - 50) + 
                         (50 * (_gradientAnimation.value * (index.isEven ? 1 : -1))),
                  top: 100.0 + (index * 80) + (30 * _pulseAnimation.value),
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159 * (index.isEven ? 1 : -1),
                    child: Container(
                      width: size * _pulseAnimation.value,
                      height: size * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFFFFF).withValues(alpha: opacity),
                            const Color(0xFFFFFFFF).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              
              // Couche d'ondulations
              Positioned.fill(
                child: CustomPaint(
                  painter: WavesPainter(
                    animationValue: _gradientAnimation.value,
                    pulseValue: _pulseAnimation.value,
                  ),
                ),
              ),
              
              // Contenu principal
              SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo avec Material Design 3
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceMedium),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo_jt.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLarge),
                    
                    // Titre principal MD3
                    Text(
                      'Bienvenue',
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: AppTheme.fontLight,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    
                    // Verset biblique avec référence sur la même ligne
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          children: [
                            const TextSpan(
                              text: 'Jésus-Christ est le même hier, aujourd\'hui, et éternellement. ',
                            ),
                            TextSpan(
                              text: '(Hébreux 13.8)',
                              style: textTheme.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: AppTheme.fontMedium,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space40),

                    // Formulaire de connexion MD3
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(AppTheme.spaceLarge),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLoginMode ? 'Connexion' : 'Créer un compte',
                              style: textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: AppTheme.fontRegular,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spaceXLarge),

                            // Champ Email MD3
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Adresse email',
                                hintText: 'Saisissez votre email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'L\'adresse email est obligatoire';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Veuillez saisir une adresse email valide (ex: nom@exemple.com)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.space20),
                            
                            // Champ Mot de passe MD3
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: 'Saisissez votre mot de passe',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                        ? Icons.visibility_outlined 
                                        : Icons.visibility_off_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Le mot de passe est obligatoire';
                                }
                                if (!_isLoginMode) {
                                  if (value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(value)) {
                                    return 'Le mot de passe doit contenir au moins une lettre et un chiffre';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceXLarge),

                            // Bouton principal MD3
                            FilledButton(
                              onPressed: _isLoading ? null : _signInWithEmailPassword,
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      _isLoginMode ? 'Se connecter' : 'Créer le compte',
                                      style: textTheme.labelLarge?.copyWith(
                                        fontWeight: AppTheme.fontMedium,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: AppTheme.spaceMedium),
                            
                            // Bouton de changement de mode MD3
                            TextButton(
                              onPressed: _toggleMode,
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _isLoginMode 
                                    ? 'Pas encore de compte ? Créer un compte'
                                    : 'Déjà un compte ? Se connecter',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: AppTheme.space12),
                            
                            // Divider MD3
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: colorScheme.outlineVariant,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'ou',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: colorScheme.outlineVariant,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: AppTheme.space12),
                            
                            // Bouton accès anonyme MD3 (moins proéminent)
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInAnonymously,
                              icon: Icon(
                                Icons.visibility_off_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              label: Text(
                                'Accès anonyme',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurfaceVariant,
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                                ),
                                minimumSize: const Size(double.infinity, 44),
                              ),
                            ),
                            
                            // Message d'erreur MD3
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppTheme.spaceMedium),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  border: Border.all(
                                    color: colorScheme.error.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: colorScheme.onErrorContainer,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.space12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXLarge),
                    
                    // Footer MD3
                    Text(
                      'Version 1.0.0',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
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
              ),
            ],
          );
        },
      ),
    );
  }
}

// Classe pour dessiner des ondulations animées
class WavesPainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;

  WavesPainter({
    required this.animationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Dessiner plusieurs ondulations
    for (int i = 0; i < 3; i++) {
      final phase = (animationValue + i * 0.3) * 2 * math.pi;
      final amplitude = 20.0 + (10.0 * pulseValue);
      final frequency = 0.02 + (i * 0.01);
      
      final path = Path();
      path.moveTo(0, size.height / 2);
      
      for (double x = 0; x <= size.width; x += 2) {
        final y = size.height / 2 + 
                  amplitude * math.sin(frequency * x + phase) +
                  (amplitude * 0.5) * math.sin(frequency * 2 * x + phase * 1.5);
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      
      paint.color = Colors.white.withValues(alpha: 0.05 / (i + 1));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
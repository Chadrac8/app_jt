import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.signInAnonymously();
    
    if (result == null && mounted) {
      setState(() {
        _errorMessage = 'Erreur lors de la connexion anonyme';
        _isLoading = false;
      });
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

      if (result == null) {
        // L'opération a échoué
        if (mounted) {
          setState(() {
            _errorMessage = _isLoginMode 
                ? 'Erreur lors de la connexion. Vérifiez vos identifiants.'
                : 'Erreur lors de la création du compte. L\'email est peut-être déjà utilisé.';
            _isLoading = false;
          });
        }
      } else {
        // Succès - l'état sera géré par AuthWrapper
        print('✅ ${_isLoginMode ? "Connexion" : "Création de compte"} réussie pour ${_emailController.text}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getErrorMessage(e);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                          padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 24),
                      
                      // Titre principal MD3
                      Text(
                        'Bienvenue',
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Verset biblique avec style MD3
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Jésus-Christ est le même hier, aujourd\'hui, et éternellement.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hébreux 13.8',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Formulaire de connexion MD3
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(24),
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
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              
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
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                    return 'Veuillez saisir un email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
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
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                    return 'Veuillez saisir un mot de passe';
                                  }
                                  if (!_isLoginMode && value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              
                              // Bouton principal MD3
                              FilledButton(
                                onPressed: _isLoading ? null : _signInWithEmailPassword,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
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
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
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
                              
                              const SizedBox(height: 12),
                              
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
                                    fontWeight: FontWeight.w500,
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
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: const Size(double.infinity, 44),
                                ),
                              ),
                              
                              // Message d'erreur MD3
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
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
                                      const SizedBox(width: 12),
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
                      const SizedBox(height: 32),
                      
                      // Footer MD3
                      Text(
                        'Version 1.0.0',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/professional_splash_screen.dart';

/// Wrapper qui gère l'affichage du splash screen pendant l'authentification
class AuthSplashWrapper extends StatefulWidget {
  final Widget child;
  
  const AuthSplashWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthSplashWrapper> createState() => _AuthSplashWrapperState();
}

class _AuthSplashWrapperState extends State<AuthSplashWrapper> {
  bool _isCheckingAuth = true;
  bool _isInitialLoad = true;
  String _loadingMessage = 'Vérification de la connexion...';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      setState(() {
        _loadingMessage = 'Vérification de la connexion...';
      });

      // Attendre que Firebase soit prêt
      await Future.delayed(const Duration(milliseconds: 500));

      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null && mounted) {
        setState(() {
          _loadingMessage = 'Chargement de votre profil...';
        });
        
        // Simuler le chargement du profil
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          setState(() {
            _loadingMessage = 'Préparation de l\'interface...';
          });
          
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Animation de transition finale
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _isCheckingAuth = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMessage = 'Finalisation...';
          _isCheckingAuth = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth || _isInitialLoad) {
      return ProfessionalSplashScreen(
        message: _loadingMessage,
        showProgress: true,
      );
    }

    return widget.child;
  }
}

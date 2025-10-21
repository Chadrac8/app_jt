import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/thematic_passage_service.dart';
import '../../../../theme.dart';

class ThematicPassagesInitializer extends StatefulWidget {
  final Widget child;
  
  const ThematicPassagesInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ThematicPassagesInitializer> createState() => _ThematicPassagesInitializerState();
}

class _ThematicPassagesInitializerState extends State<ThematicPassagesInitializer> {
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndInitializeThemes();
  }

  Future<void> _checkAndInitializeThemes() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await ThematicPassageService.initializeDefaultThemes();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    // Retourner l'enfant seulement si l'initialisation est terminée
    if (_isInitialized) {
      return widget.child;
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.collections_bookmark,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Initialisation des passages thématiques',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              'Préparation des thèmes bibliques par défaut...',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'Erreur d\'initialisation',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize20,
                  fontWeight: AppTheme.fontSemiBold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                'Impossible d\'initialiser les passages thématiques.',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize12,
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isInitialized = true;
                      });
                    },
                    child: Text(
                      'Continuer sans initialisation',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  ElevatedButton(
                    onPressed: _checkAndInitializeThemes,
                    child: Text(
                      'Réessayer',
                      style: GoogleFonts.inter(fontWeight: AppTheme.fontSemiBold),
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
}

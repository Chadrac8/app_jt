import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Splash screen professionnel avec animations fluides
/// Utilisé au lancement de l'app et pendant les chargements de connexion
class ProfessionalSplashScreen extends StatefulWidget {
  final String? message;
  final bool showProgress;
  final double? progress;
  
  const ProfessionalSplashScreen({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<ProfessionalSplashScreen> createState() => _ProfessionalSplashScreenState();
}

class _ProfessionalSplashScreenState extends State<ProfessionalSplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de fade-in du logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation de scale du logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animation shimmer continue pour l'effet premium
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer les animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.black100 : AppTheme.white100,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.black100,
                    const Color(0xFF1a1a1a),
                    const Color(0xFF0d0d0d),
                  ]
                : [
                    AppTheme.white100,
                    const Color(0xFFF5F5F5),
                    const Color(0xFFEEEEEE),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Effet de particules subtil en arrière-plan
              _buildBackgroundParticles(isDark),
              
              // Contenu principal
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo avec animations
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLogo(isDark),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXLarge),
                    
                    // Nom de l'application
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Jubilé Tabernacle',
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize28,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.white100 : AppTheme.black100,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceSmall),
                          Text(
                            'France',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize16,
                              fontWeight: FontWeight.w400,
                              color: isDark 
                                  ? AppTheme.white100.withOpacity(0.7)
                                  : AppTheme.black100.withOpacity(0.6),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXLarge * 2),
                    
                    // Indicateur de chargement
                    if (widget.showProgress) ...[
                      _buildProgressIndicator(isDark),
                      if (widget.message != null) ...[
                        const SizedBox(height: AppTheme.spaceMedium),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            widget.message!,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: isDark 
                                  ? AppTheme.white100.withOpacity(0.6)
                                  : AppTheme.black100.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              
              // Version en bas
              Positioned(
                bottom: AppTheme.spaceLarge,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      color: isDark 
                          ? AppTheme.white100.withOpacity(0.4)
                          : AppTheme.black100.withOpacity(0.3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // Logo image
            Image.asset(
              'assets/logo_jt.png',
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
            
            // Overlay shimmer effect
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        AppTheme.white100.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: [
                        (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                        _shimmerAnimation.value.clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
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
  }

  Widget _buildProgressIndicator(bool isDark) {
    if (widget.progress != null) {
      // Barre de progression déterminée
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXLarge * 2),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              child: LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: isDark
                    ? AppTheme.white100.withOpacity(0.1)
                    : AppTheme.black100.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              '${(widget.progress! * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize12,
                color: isDark 
                    ? AppTheme.white100.withOpacity(0.5)
                    : AppTheme.black100.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // Indicateur circulaire indéterminé
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.primaryColor,
          ),
        ),
      );
    }
  }

  Widget _buildBackgroundParticles(bool isDark) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticlesPainter(
          color: isDark 
              ? AppTheme.white100.withOpacity(0.03)
              : AppTheme.black100.withOpacity(0.02),
        ),
      ),
    );
  }
}

/// Painter pour les particules d'arrière-plan
class _ParticlesPainter extends CustomPainter {
  final Color color;

  _ParticlesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dessiner quelques cercles subtils en arrière-plan
    final random = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.1),
    ];

    for (var offset in random) {
      canvas.drawCircle(offset, 60, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

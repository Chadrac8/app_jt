import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import '../theme.dart';

/// Service d'optimisation des images et assets
class AssetOptimizationService {
  static final Map<String, Uint8List> _imageCache = {};
  static final Map<String, ImageProvider> _providerCache = {};
  
  /// Précharge les images critiques au démarrage
  static Future<void> preloadCriticalImages(BuildContext context) async {
    const criticalImages = [
      'assets/images/logo.png',
      'assets/images/church_icon.png',
      'assets/images/default_avatar.png',
    ];
    
    for (String imagePath in criticalImages) {
      try {
        final imageProvider = AssetImage(imagePath);
        await precacheImage(imageProvider, context);
        _providerCache[imagePath] = imageProvider;
      } catch (e) {
        debugPrint('Erreur de préchargement pour $imagePath: $e');
      }
    }
  }
  
  /// Obtient une image depuis le cache ou la charge
  static ImageProvider getOptimizedImage(String path) {
    if (_providerCache.containsKey(path)) {
      return _providerCache[path]!;
    }
    
    final provider = AssetImage(path);
    _providerCache[path] = provider;
    return provider;
  }
  
  /// Nettoie le cache d'images
  static void clearCache() {
    _imageCache.clear();
    _providerCache.clear();
  }
}

/// Widget d'image optimisé avec mise en cache intelligente
class OptimizedImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final bool isAsset;
  
  const OptimizedImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.isAsset = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: isAsset 
            ? Image(
                image: AssetOptimizationService.getOptimizedImage(imagePath),
                width: width,
                height: height,
                fit: fit,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return placeholder ?? 
                         const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.grey300,
                    child: const Icon(Icons.error, color: AppTheme.errorColor),
                  );
                },
              )
            : FadeInImage.assetNetwork(
                placeholder: 'assets/images/placeholder.png',
                image: imagePath,
                width: width,
                height: height,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.grey300,
                    child: const Icon(Icons.error, color: AppTheme.errorColor),
                  );
                },
              ),
        ),
      ),
    );
  }
}

/// Service d'optimisation des animations
class AnimationOptimizationService {
  static const Duration _fastAnimation = Duration(milliseconds: 150);
  static const Duration _normalAnimation = Duration(milliseconds: 300);
  static const Duration _slowAnimation = Duration(milliseconds: 500);
  
  /// Crée une animation optimisée avec des paramètres par défaut
  static AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration? duration,
    double? value,
  }) {
    return AnimationController(
      duration: duration ?? _normalAnimation,
      vsync: vsync,
      value: value,
    );
  }
  
  /// Animation de fade optimisée
  static Widget createFadeTransition({
    required Animation<double> animation,
    required Widget child,
    Curve curve = Curves.easeInOut,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: RepaintBoundary(child: child),
    );
  }
  
  /// Animation de slide optimisée
  static Widget createSlideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOut,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: RepaintBoundary(child: child),
    );
  }
}

/// Widget de loading optimisé
class OptimizedLoading extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  
  const OptimizedLoading({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
  });
  
  @override
  State<OptimizedLoading> createState() => _OptimizedLoadingState();
}

class _OptimizedLoadingState extends State<OptimizedLoading> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationOptimizationService.createOptimizedController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.color ?? Theme.of(context).primaryColor,
                ),
                strokeWidth: 3.0,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                widget.message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Service de gestion des vibrations pour le feedback haptique
class HapticService {
  static bool _isEnabled = true;
  
  static void enable() => _isEnabled = true;
  static void disable() => _isEnabled = false;
  
  static Future<void> lightImpact() async {
    if (_isEnabled) {
      await HapticFeedback.lightImpact();
    }
  }
  
  static Future<void> mediumImpact() async {
    if (_isEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }
  
  static Future<void> heavyImpact() async {
    if (_isEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }
  
  static Future<void> selectionClick() async {
    if (_isEnabled) {
      await HapticFeedback.selectionClick();
    }
  }
}

/// Widget de bouton avec animation et feedback optimisés
class AnimatedOptimizedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final bool isLoading;
  
  const AnimatedOptimizedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.isLoading = false,
  });
  
  @override
  State<AnimatedOptimizedButton> createState() => _AnimatedOptimizedButtonState();
}

class _AnimatedOptimizedButtonState extends State<AnimatedOptimizedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onTapDown(_) {
    _controller.forward();
  }
  
  void _onTapUp(_) {
    _controller.reverse();
  }
  
  void _onTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: widget.onPressed != null ? _onTapCancel : null,
        onTap: widget.onPressed != null && !widget.isLoading
            ? () {
                HapticService.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null && !widget.isLoading) ...[
                      widget.icon!,
                      const SizedBox(width: AppTheme.spaceSmall),
                    ],
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.textColor ?? Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.textColor ?? Colors.white,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
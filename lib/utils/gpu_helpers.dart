import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Helper pour optimisations GPU
class GPUOptimizationHelper {
  static final Map<String, ui.Picture> _pictureCache = {};
  
  /// Warmup des shaders au démarrage
  static Future<void> warmupShaders(BuildContext context) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Dessiner tous les widgets complexes pour précompiler shaders
    _paintCommonWidgets(canvas, context);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    image.dispose();
    picture.dispose();
  }
  
  static void _paintCommonWidgets(Canvas canvas, BuildContext context) {
    final paint = Paint();
    final theme = Theme.of(context);
    
    // Rounded rectangles (cards)
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(12),
    );
    paint.color = theme.colorScheme.surface;
    canvas.drawRRect(rrect, paint);
    
    // Shadows
    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black26,
      4.0,
      true,
    );
    
    // Circles (avatars)
    paint.color = theme.colorScheme.primary;
    canvas.drawCircle(const Offset(50, 50), 20, paint);
    
    // Text (labels)
    final textPainter = TextPainter(
      text: const TextSpan(text: 'Sample', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }
  
  /// Cache une picture pour réutilisation
  static ui.Picture? getCachedPicture(String key) {
    return _pictureCache[key];
  }
  
  /// Sauvegarder une picture en cache
  static void cachePicture(String key, ui.Picture picture) {
    _pictureCache[key] = picture;
  }
  
  /// Nettoyer le cache
  static void clearCache() {
    for (final picture in _pictureCache.values) {
      picture.dispose();
    }
    _pictureCache.clear();
  }
}

/// CustomPainter optimisé avec cache
abstract class CachedCustomPainter extends CustomPainter {
  ui.Picture? _cachedPicture;
  Size? _cachedSize;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Utiliser cache si taille identique
    if (_cachedPicture != null && _cachedSize == size) {
      canvas.drawPicture(_cachedPicture!);
      return;
    }
    
    // Créer nouveau cache
    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);
    
    doPaint(recordCanvas, size);
    
    _cachedPicture?.dispose();
    _cachedPicture = recorder.endRecording();
    _cachedSize = size;
    
    canvas.drawPicture(_cachedPicture!);
  }
  
  /// Implémentation du painting (à override)
  void doPaint(Canvas canvas, Size size);
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  
  void dispose() {
    _cachedPicture?.dispose();
  }
}

/// Widget optimisé pour réduire layer count
class OptimizedDecoratedBox extends StatelessWidget {
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final ImageProvider? backgroundImage;
  final Widget? child;
  
  const OptimizedDecoratedBox({
    super.key,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.backgroundImage,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage!,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: child,
    );
  }
}

/// Mixin pour tracking de performance
mixin PerformanceTracking {
  DateTime? _lastFrameTime;
  final List<Duration> _frameDurations = [];
  
  void trackFrame() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final duration = now.difference(_lastFrameTime!);
      _frameDurations.add(duration);
      
      // Garder seulement 60 dernières frames
      if (_frameDurations.length > 60) {
        _frameDurations.removeAt(0);
      }
    }
    _lastFrameTime = now;
  }
  
  double get averageFPS {
    if (_frameDurations.isEmpty) return 0;
    
    final avgMs = _frameDurations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b) / _frameDurations.length / 1000;
    
    return 1000 / avgMs;
  }
  
  bool get isRunningAt60FPS => averageFPS >= 55;
}

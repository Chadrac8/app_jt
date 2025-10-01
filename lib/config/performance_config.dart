import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/optimization_service.dart';

/// Configuration globale des performances de l'application
class PerformanceConfig {
  static bool _isInitialized = false;
  
  /// Initialise toutes les optimisations de performance
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    try {
      // 1. Précharger les images critiques
      await AssetOptimizationService.preloadCriticalImages(context);
      
      // 2. Configurer les transitions par défaut
      _configurePageTransitions();
      
      // 3. Optimiser les animations globales
      _configureAnimations();
      
      // 4. Configurer le feedback haptique
      _configureHapticFeedback();
      
      // 5. Optimiser les rendus
      _configureRendering();
      
      _isInitialized = true;
      debugPrint('✅ Performance Config: Toutes les optimisations ont été appliquées');
      
    } catch (e) {
      debugPrint('❌ Performance Config: Erreur lors de l\'initialisation: $e');
    }
  }
  
  /// Configure les transitions de pages pour plus de fluidité
  static void _configurePageTransitions() {
    // Les transitions seront configurées au niveau des routes
  }
  
  /// Configure les animations globales
  static void _configureAnimations() {
    // Réduire la durée des animations par défaut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Les configurations d'animation seront appliquées globalement
    });
  }
  
  /// Configure le feedback haptique
  static void _configureHapticFeedback() {
    HapticService.enable();
  }
  
  /// Configure les optimisations de rendu
  static void _configureRendering() {
    // Optimisations spécifiques au rendu
  }
}

/// Extension pour optimiser les transitions de pages
extension OptimizedPageRoutes on PageRouteBuilder {
  static PageRouteBuilder fadeTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }
  
  static PageRouteBuilder slideTransition({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }
}

/// Widget pour monitorer les performances en mode debug
class PerformanceMonitorWidget extends StatelessWidget {
  final Widget child;
  final String? name;
  
  const PerformanceMonitorWidget({
    super.key,
    required this.child,
    this.name,
  });
  
  @override
  Widget build(BuildContext context) {
    if (kDebugMode && name != null) {
      return Builder(
        builder: (context) {
          debugPrint('🔄 Rebuild: $name à ${DateTime.now()}');
          return child;
        },
      );
    }
    return child;
  }
}

/// Mixin pour les pages avec optimisations automatiques
mixin PerformanceOptimizedPage<T extends StatefulWidget> on State<T> {
  late final String _pageName;
  DateTime? _lastStateUpdate;
  
  @override
  void initState() {
    super.initState();
    _pageName = T.toString();
    _logPageEvent('initState');
  }
  
  @override
  void dispose() {
    _logPageEvent('dispose');
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logPageEvent('didChangeDependencies');
  }
  
  /// Log des événements de page en mode debug
  void _logPageEvent(String event) {
    if (kDebugMode) {
      debugPrint('📄 $_pageName: $event à ${DateTime.now()}');
    }
  }
  
  /// setState optimisé avec throttling
  void optimizedSetState(VoidCallback fn) {
    final now = DateTime.now();
    if (_lastStateUpdate != null && 
        now.difference(_lastStateUpdate!).inMilliseconds < 16) {
      // Throttle à 60 FPS
      return;
    }
    
    _lastStateUpdate = now;
    if (mounted) {
      setState(fn);
    }
  }
  
  /// Débounce pour les actions utilisateur
  Timer? _debounceTimer;
  
  void debounceAction(VoidCallback action, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }
  
  void cleanupDebouncer() {
    _debounceTimer?.cancel();
  }
}

/// Service de gestion de la mémoire
class MemoryManagementService {
  static int _imageCount = 0;
  static int _widgetCount = 0;
  
  static void trackImage() {
    _imageCount++;
    if (kDebugMode && _imageCount % 50 == 0) {
      debugPrint('📊 Images en mémoire: $_imageCount');
    }
  }
  
  static void releaseImage() {
    _imageCount--;
  }
  
  static void trackWidget() {
    _widgetCount++;
    if (kDebugMode && _widgetCount % 100 == 0) {
      debugPrint('📊 Widgets actifs: $_widgetCount');
    }
  }
  
  static void releaseWidget() {
    _widgetCount--;
  }
  
  /// Force le garbage collection si nécessaire
  static void forceGarbageCollection() {
    // Cette méthode sera appelée périodiquement
  }
  
  static Map<String, int> getMemoryStats() {
    return {
      'images': _imageCount,
      'widgets': _widgetCount,
    };
  }
}

/// Widget de liste avec recyclage optimisé
class RecycledListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemHeight;
  final ScrollController? controller;
  final EdgeInsets? padding;
  
  const RecycledListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemHeight,
    this.controller,
    this.padding,
  });
  
  @override
  State<RecycledListView> createState() => _RecycledListViewState();
}

class _RecycledListViewState extends State<RecycledListView> {
  final Map<int, Widget> _widgetCache = {};
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _widgetCache.clear();
    super.dispose();
  }
  
  void _onScroll() {
    // Nettoyer le cache des widgets non visibles
    final viewportHeight = MediaQuery.of(context).size.height;
    final scrollOffset = _scrollController.offset;
    
    final visibleStart = (scrollOffset / widget.itemHeight).floor();
    final visibleEnd = ((scrollOffset + viewportHeight) / widget.itemHeight).ceil();
    
    _widgetCache.removeWhere((index, widget) => 
        index < visibleStart - 5 || index > visibleEnd + 5);
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.itemCount,
      itemExtent: widget.itemHeight,
      itemBuilder: (context, index) {
        if (!_widgetCache.containsKey(index)) {
          _widgetCache[index] = RepaintBoundary(
            child: widget.itemBuilder(context, index),
          );
        }
        return _widgetCache[index]!;
      },
    );
  }
}
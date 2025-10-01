import 'package:flutter/material.dart';
import 'dart:async';

/// Constantes pour améliorer les performances
class PerformanceConstants {
  // Durées d'animation optimisées
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Débounce pour les actions utilisateur
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration inputDebounce = Duration(milliseconds: 500);
  
  // Tailles d'images optimisées
  static const double thumbnailSize = 60.0;
  static const double avatarSize = 40.0;
  static const double iconSize = 24.0;
  
  // Espacement constant
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);
  
  // Rayon de bordure constant
  static const BorderRadius defaultRadius = BorderRadius.all(Radius.circular(8.0));
}

/// Contrôleur d'état optimisé pour PersonFormPage
class PersonFormController extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasChanges = false;
  final Map<String, bool> _sectionExpanded = {
    'basic': true,
    'contact': true,
    'personal': false,
    'roles': false,
    'custom': false,
  };
  
  // Getters
  bool get isLoading => _isLoading;
  bool get hasChanges => _hasChanges;
  Map<String, bool> get sectionExpanded => Map.unmodifiable(_sectionExpanded);
  
  // Méthodes de gestion du loading
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  // Méthodes de gestion des changements
  void markAsChanged() {
    if (!_hasChanges) {
      _hasChanges = true;
      notifyListeners();
    }
  }
  
  void markAsSaved() {
    if (_hasChanges) {
      _hasChanges = false;
      notifyListeners();
    }
  }
  
  // Méthodes de gestion des sections
  void toggleSection(String sectionKey) {
    if (_sectionExpanded.containsKey(sectionKey)) {
      _sectionExpanded[sectionKey] = !_sectionExpanded[sectionKey]!;
      notifyListeners();
    }
  }
  
  void expandSection(String sectionKey) {
    if (_sectionExpanded.containsKey(sectionKey) && 
        !_sectionExpanded[sectionKey]!) {
      _sectionExpanded[sectionKey] = true;
      notifyListeners();
    }
  }
  
  void collapseSection(String sectionKey) {
    if (_sectionExpanded.containsKey(sectionKey) && 
        _sectionExpanded[sectionKey]!) {
      _sectionExpanded[sectionKey] = false;
      notifyListeners();
    }
  }
  
  // Méthodes de gestion de la navigation
  bool get canNavigateAway => !_hasChanges || !_isLoading;
  
  Future<bool> showUnsavedChangesDialog(BuildContext context) async {
    if (!_hasChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text('Vous avez des modifications non sauvegardées. Voulez-vous quitter sans sauvegarder ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Quitter sans sauvegarder'),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// Widget de liste optimisée pour de grosses listes
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemHeight;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemHeight,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  @override
  Widget build(BuildContext context) {
    // Utiliser RepaintBoundary pour chaque élément
    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.items.length,
      itemExtent: widget.itemHeight, // Améliore les performances
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: widget.itemBuilder(context, widget.items[index], index),
        );
      },
    );
  }
}

/// Widget de notification de performance pour identifier les rebuilds excessifs
class PerformanceMonitor extends StatelessWidget {
  final Widget child;
  final String name;
  final bool enableDebug;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.name,
    this.enableDebug = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enableDebug) {
      return Builder(
        builder: (context) {
          debugPrint('🔄 Rebuild: $name at ${DateTime.now()}');
          return child;
        },
      );
    }
    return child;
  }
}

/// Mixin pour optimiser les performances des formulaires
mixin FormPerformanceOptimization<T extends StatefulWidget> on State<T> {
  // Cache des widgets pour éviter les reconstructions
  final Map<String, Widget> _widgetCache = {};
  
  // Debouncer pour les validations
  Timer? _validationDebouncer;
  
  @override
  void dispose() {
    _validationDebouncer?.cancel();
    _widgetCache.clear();
    super.dispose();
  }
  
  /// Cache un widget avec une clé unique
  Widget cacheWidget(String key, Widget Function() builder) {
    if (!_widgetCache.containsKey(key)) {
      _widgetCache[key] = builder();
    }
    return _widgetCache[key]!;
  }
  
  /// Invalide le cache d'un widget
  void invalidateWidget(String key) {
    _widgetCache.remove(key);
  }
  
  /// Invalide tout le cache
  void clearCache() {
    _widgetCache.clear();
  }
  
  /// Validation debouncée pour éviter les appels répétés
  void debounceValidation(VoidCallback validation, {Duration delay = const Duration(milliseconds: 300)}) {
    _validationDebouncer?.cancel();
    _validationDebouncer = Timer(delay, validation);
  }
  
  /// Optimise les setState en groupant les modifications
  void batchSetState(VoidCallback updates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(updates);
      }
    });
  }
}

/// Widget de cache intelligent pour les images
class SmartImageCache extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration cacheDuration;
  
  const SmartImageCache({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheDuration = const Duration(hours: 24),
  });

  @override
  State<SmartImageCache> createState() => _SmartImageCacheState();
}

class _SmartImageCacheState extends State<SmartImageCache> {
  static final Map<String, ImageProvider> _imageCache = {};
  
  @override
  Widget build(BuildContext context) {
    // Utiliser le cache d'images pour éviter les rechargements
    ImageProvider? cachedImage = _imageCache[widget.imageUrl];
    
    if (cachedImage == null) {
      cachedImage = NetworkImage(widget.imageUrl);
      _imageCache[widget.imageUrl] = cachedImage;
    }
    
    return Image(
      image: cachedImage,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return widget.placeholder ?? 
               const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? 
               const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}

/// Widget de gestion des erreurs avec retry automatique
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;
  final VoidCallback? onError;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _retry) ?? 
             _buildDefaultError();
    }
    
    return ErrorListener(
      onError: _handleError,
      child: widget.child,
    );
  }
  
  void _handleError(Object error) {
    setState(() {
      _error = error;
    });
    widget.onError?.call();
  }
  
  void _retry() {
    setState(() {
      _error = null;
    });
  }
  
  Widget _buildDefaultError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Une erreur est survenue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Widget d'écoute des erreurs
class ErrorListener extends StatefulWidget {
  final Widget child;
  final Function(Object error) onError;
  
  const ErrorListener({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorListener> createState() => _ErrorListenerState();
}

class _ErrorListenerState extends State<ErrorListener> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Écouter les erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError(details.exception);
    };
  }
}

/// Mixin pour la gestion des ressources et lifecycle
mixin ResourceManagement<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];
  final List<AnimationController> _animationControllers = [];
  final List<ScrollController> _scrollControllers = [];
  final List<TextEditingController> _textControllers = [];
  
  /// Ajoute un StreamSubscription pour gestion automatique
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
  
  /// Ajoute un AnimationController pour gestion automatique
  void addAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
  }
  
  /// Ajoute un ScrollController pour gestion automatique
  void addScrollController(ScrollController controller) {
    _scrollControllers.add(controller);
  }
  
  /// Ajoute un TextEditingController pour gestion automatique
  void addTextController(TextEditingController controller) {
    _textControllers.add(controller);
  }
  
  @override
  void dispose() {
    // Nettoyer toutes les ressources
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    for (final controller in _textControllers) {
      controller.dispose();
    }
    
    _subscriptions.clear();
    _animationControllers.clear();
    _scrollControllers.clear();
    _textControllers.clear();
    
    super.dispose();
  }
}

/// Extension pour optimiser les animations
extension AnimationOptimization on AnimationController {
  /// Animation optimisée avec détection de visibilité
  void forwardIfVisible(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject = context.findRenderObject();
      if (renderObject != null && renderObject.attached) {
        forward();
      }
    });
  }
  
  /// Animation avec gestion automatique du montage/démontage
  void safeForward() {
    if (!isAnimating && !isCompleted) {
      forward();
    }
  }
  
  void safeReverse() {
    if (!isAnimating && !isDismissed) {
      reverse();
    }
  }
}
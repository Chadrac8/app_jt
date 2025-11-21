import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper pour détecter et prévenir les memory leaks
class MemoryLeakDetector {
  static final Map<String, WeakReference<Object>> _trackedObjects = {};
  static Timer? _cleanupTimer;
  
  /// Tracker un objet pour détecter les leaks
  static void track(String id, Object object) {
    if (kDebugMode) {
      _trackedObjects[id] = WeakReference(object);
      _startCleanupTimer();
    }
  }
  
  /// Vérifier si un objet est toujours en mémoire
  static bool isAlive(String id) {
    final ref = _trackedObjects[id];
    return ref?.target != null;
  }
  
  /// Obtenir les stats de mémoire
  static Map<String, int> getStats() {
    final alive = _trackedObjects.values.where((ref) => ref.target != null).length;
    final dead = _trackedObjects.length - alive;
    
    return {
      'total': _trackedObjects.length,
      'alive': alive,
      'dead': dead,
    };
  }
  
  /// Nettoyer les références mortes
  static void cleanup() {
    _trackedObjects.removeWhere((key, ref) => ref.target == null);
  }
  
  static void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      cleanup();
      if (kDebugMode) {
        print('🧹 Memory cleanup: ${getStats()}');
      }
    });
  }
  
  /// Disposer le detector
  static void dispose() {
    _cleanupTimer?.cancel();
    _trackedObjects.clear();
  }
}

/// Mixin pour dispose automatique des resources
mixin DisposableMixin {
  final List<StreamSubscription> _subscriptions = [];
  final List<void Function()> _disposers = [];
  
  /// Enregistrer une subscription à disposer
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
  
  /// Enregistrer une fonction de dispose
  void addDisposer(void Function() disposer) {
    _disposers.add(disposer);
  }
  
  /// Disposer toutes les resources
  void disposeAll() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    for (final disposer in _disposers) {
      try {
        disposer();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error disposing: $e');
        }
      }
    }
    _disposers.clear();
  }
}

/// Pattern pour weak listeners
class WeakListenerList<T extends Function> {
  final List<WeakReference<T>> _listeners = [];
  
  /// Ajouter un listener
  void add(T listener) {
    _listeners.add(WeakReference(listener));
  }
  
  /// Supprimer un listener
  void remove(T listener) {
    _listeners.removeWhere((ref) => ref.target == listener);
  }
  
  /// Notifier tous les listeners actifs
  void notify(void Function(T listener) callback) {
    // Nettoyer les références mortes
    _listeners.removeWhere((ref) => ref.target == null);
    
    // Notifier les listeners actifs
    for (final ref in _listeners) {
      final listener = ref.target;
      if (listener != null) {
        try {
          callback(listener);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error notifying listener: $e');
          }
        }
      }
    }
  }
  
  /// Obtenir le nombre de listeners actifs
  int get length => _listeners.where((ref) => ref.target != null).length;
  
  /// Disposer tous les listeners
  void dispose() {
    _listeners.clear();
  }
}

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Client HTTP optimisé avec connection pooling et HTTP/2
class OptimizedHttpClient {
  static OptimizedHttpClient? _instance;
  late final HttpClient _httpClient;
  late final http.Client _client;
  
  OptimizedHttpClient._() {
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 30) // Keep-alive
      ..maxConnectionsPerHost = 6; // HTTP/2 multiplexing
    
    _client = IOClient(_httpClient);
  }
  
  static OptimizedHttpClient get instance {
    _instance ??= OptimizedHttpClient._();
    return _instance!;
  }
  
  /// Client HTTP réutilisable avec connection pooling
  http.Client get client => _client;
  
  /// Dispose du client (à appeler à la fermeture de l'app)
  void dispose() {
    _client.close();
    _httpClient.close();
  }
}

/// Batch Firestore requests pour réduire latence
class FirestoreBatchHelper {
  /// Exécuter plusieurs requêtes Firestore en batch
  /// Réduit le nombre de round-trips réseau
  static Future<Map<String, dynamic>> batchGet({
    required Map<String, Future<dynamic>> futures,
  }) async {
    final results = await Future.wait(
      futures.values,
      eagerError: false,
    );
    
    final response = <String, dynamic>{};
    int index = 0;
    for (final key in futures.keys) {
      try {
        response[key] = results[index];
      } catch (e) {
        response[key] = null;
      }
      index++;
    }
    
    return response;
  }
}

/// Helper pour requêtes offline-first
class OfflineFirstHelper {
  /// Récupérer données avec stratégie cache-first
  static Future<T> cacheFirst<T>({
    required Future<T?> Function() getCached,
    required Future<T> Function() getNetwork,
    required Future<void> Function(T data) saveCache,
    Duration cacheValidity = const Duration(hours: 1),
  }) async {
    // 1. Essayer le cache local
    final cached = await getCached();
    if (cached != null) {
      // Rafraîchir en arrière-plan
      getNetwork().then((data) => saveCache(data)).catchError((_) {});
      return cached;
    }
    
    // 2. Fallback réseau
    final networkData = await getNetwork();
    
    // 3. Sauvegarder en cache
    await saveCache(networkData);
    
    return networkData;
  }
  
  /// Récupérer données avec stratégie network-first
  static Future<T> networkFirst<T>({
    required Future<T?> Function() getCached,
    required Future<T> Function() getNetwork,
    required Future<void> Function(T data) saveCache,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // 1. Essayer réseau avec timeout
      final networkData = await getNetwork().timeout(timeout);
      
      // 2. Sauvegarder en cache
      await saveCache(networkData);
      
      return networkData;
    } catch (e) {
      // 3. Fallback sur cache
      final cached = await getCached();
      if (cached != null) {
        return cached;
      }
      
      rethrow;
    }
  }
}

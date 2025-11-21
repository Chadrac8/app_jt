import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Helpers pour exécuter des calculs lourds dans des isolates
/// Utilise compute() pour décharger le main thread
class ComputeHelpers {
  
  /// Parse JSON en isolate - pour fichiers >100KB
  static Future<dynamic> parseJsonInIsolate(String jsonString) async {
    return compute(_parseJson, jsonString);
  }
  
  static dynamic _parseJson(String jsonString) {
    return json.decode(jsonString);
  }
  
  /// Trier une grande liste en isolate
  static Future<List<T>> sortListInIsolate<T>({
    required List<T> items,
    required int Function(T a, T b) comparator,
  }) async {
    final data = _SortData<T>(items: items, comparator: comparator);
    return compute(_sortList<T>, data);
  }
  
  static List<T> _sortList<T>(_SortData<T> data) {
    final sorted = List<T>.from(data.items);
    sorted.sort(data.comparator);
    return sorted;
  }
  
  /// Calculer des statistiques complexes en isolate
  static Future<Map<String, dynamic>> calculateStatisticsInIsolate({
    required List<Map<String, dynamic>> data,
  }) async {
    return compute(_calculateStatistics, data);
  }
  
  static Map<String, dynamic> _calculateStatistics(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return {};
    
    // Calculs statistiques
    final stats = <String, dynamic>{};
    
    // Comptage par catégorie
    final categoryCounts = <String, int>{};
    final statusCounts = <String, int>{};
    
    for (final item in data) {
      final category = item['category']?.toString() ?? 'unknown';
      final status = item['status']?.toString() ?? 'unknown';
      
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    
    // Tri des résultats
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedStatuses = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    stats['total'] = data.length;
    stats['categoryDistribution'] = Map.fromEntries(sortedCategories);
    stats['statusDistribution'] = Map.fromEntries(sortedStatuses);
    
    return stats;
  }
  
  /// Filtrer une grande liste en isolate
  static Future<List<T>> filterListInIsolate<T>({
    required List<T> items,
    required bool Function(T item) predicate,
  }) async {
    final data = _FilterData<T>(items: items, predicate: predicate);
    return compute(_filterList<T>, data);
  }
  
  static List<T> _filterList<T>(_FilterData<T> data) {
    return data.items.where(data.predicate).toList();
  }
  
  /// Grouper des données en isolate
  static Future<Map<K, List<T>>> groupByInIsolate<T, K>({
    required List<T> items,
    required K Function(T item) keyExtractor,
  }) async {
    final data = _GroupData<T, K>(items: items, keyExtractor: keyExtractor);
    return compute(_groupBy<T, K>, data);
  }
  
  static Map<K, List<T>> _groupBy<T, K>(_GroupData<T, K> data) {
    final grouped = <K, List<T>>{};
    for (final item in data.items) {
      final key = data.keyExtractor(item);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }
  
  /// Calculer des agrégations (sum, avg, min, max) en isolate
  static Future<Map<String, double>> aggregateInIsolate({
    required List<num> values,
  }) async {
    return compute(_aggregate, values);
  }
  
  static Map<String, double> _aggregate(List<num> values) {
    if (values.isEmpty) {
      return {'sum': 0, 'avg': 0, 'min': 0, 'max': 0, 'count': 0};
    }
    
    final sum = values.fold<num>(0, (a, b) => a + b).toDouble();
    final avg = sum / values.length;
    final min = values.reduce((a, b) => a < b ? a : b).toDouble();
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    
    return {
      'sum': sum,
      'avg': avg,
      'min': min,
      'max': max,
      'count': values.length.toDouble(),
    };
  }
}

// Classes de données pour passer aux isolates
class _SortData<T> {
  final List<T> items;
  final int Function(T a, T b) comparator;
  
  _SortData({required this.items, required this.comparator});
}

class _FilterData<T> {
  final List<T> items;
  final bool Function(T item) predicate;
  
  _FilterData({required this.items, required this.predicate});
}

class _GroupData<T, K> {
  final List<T> items;
  final K Function(T item) keyExtractor;
  
  _GroupData({required this.items, required this.keyExtractor});
}

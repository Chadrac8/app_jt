import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';

/// Service d'optimisation spécialisé pour les listes
class ListOptimizationService {
  static const int _defaultCacheSize = 100;
  static const double _defaultItemHeight = 80.0;
  
  /// Détermine la hauteur optimale d'un élément de liste
  static double calculateOptimalItemHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Adapter la hauteur en fonction de la taille de l'écran
    if (screenHeight < 600) return 60.0;  // Petits écrans
    if (screenHeight < 800) return 70.0;  // Écrans moyens
    return 80.0;  // Grands écrans
  }
  
  /// Calcule le nombre d'éléments visibles
  static int calculateVisibleItems(BuildContext context, double itemHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight / itemHeight).ceil() + 2; // +2 pour le buffer
  }
}

/// Widget de liste ultra-optimisée pour de gros volumes de données
class UltraOptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double? itemHeight;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final void Function(T item)? onItemTap;
  final Widget? header;
  final Widget? footer;
  final bool enableLazyLoading;
  final VoidCallback? onLoadMore;
  final int? itemsPerPage;
  
  const UltraOptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemHeight,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.onItemTap,
    this.header,
    this.footer,
    this.enableLazyLoading = false,
    this.onLoadMore,
    this.itemsPerPage = 20,
  });
  
  @override
  State<UltraOptimizedListView<T>> createState() => _UltraOptimizedListViewState<T>();
}

class _UltraOptimizedListViewState<T> extends State<UltraOptimizedListView<T>> {
  late ScrollController _scrollController;
  final Map<int, Widget> _widgetCache = {};
  final Set<int> _visibleItems = {};
  double? _itemHeight;
  bool _isLoadingMore = false;
  Timer? _scrollEndTimer;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemHeight = widget.itemHeight ?? 
                   ListOptimizationService.calculateOptimalItemHeight(context);
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _scrollEndTimer?.cancel();
    _widgetCache.clear();
    super.dispose();
  }
  
  void _onScroll() {
    if (_itemHeight == null) return;
    
    // Déterminer les éléments visibles
    final viewportHeight = context.size?.height ?? MediaQuery.of(context).size.height;
    final scrollOffset = _scrollController.offset;
    
    final visibleStart = (scrollOffset / _itemHeight!).floor();
    final visibleEnd = ((scrollOffset + viewportHeight) / _itemHeight!).ceil();
    
    // Mettre à jour les éléments visibles
    _visibleItems.clear();
    for (int i = visibleStart; i <= visibleEnd && i < widget.items.length; i++) {
      if (i >= 0) _visibleItems.add(i);
    }
    
    // Nettoyer le cache des éléments non visibles (garder un buffer)
    _widgetCache.removeWhere((index, _) => 
        index < visibleStart - 5 || index > visibleEnd + 5);
    
    // Lazy loading
    if (widget.enableLazyLoading && !_isLoadingMore) {
      final scrollPercentage = _scrollController.offset / _scrollController.position.maxScrollExtent;
      if (scrollPercentage > 0.8) {
        _triggerLoadMore();
      }
    }
    
    // Débounce pour optimiser les rebuilds pendant le scroll
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  void _triggerLoadMore() {
    if (widget.onLoadMore != null && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
      
      widget.onLoadMore!();
      
      // Reset loading state après un délai
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }
  
  Widget _buildItem(int index) {
    if (!_widgetCache.containsKey(index)) {
      final item = widget.items[index];
      _widgetCache[index] = RepaintBoundary(
        key: ValueKey('item_$index'),
        child: Container(
          height: _itemHeight,
          child: widget.onItemTap != null
              ? InkWell(
                  onTap: () => widget.onItemTap!(item),
                  child: widget.itemBuilder(context, item, index),
                )
              : widget.itemBuilder(context, item, index),
        ),
      );
    }
    return _widgetCache[index]!;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_itemHeight == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RepaintBoundary(
      child: CustomScrollView(
        controller: _scrollController,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        slivers: [
          // Header
          if (widget.header != null)
            SliverToBoxAdapter(child: widget.header!),
          
          // Padding top
          if (widget.padding != null)
            SliverPadding(
              padding: EdgeInsets.only(
                left: widget.padding!.left,
                right: widget.padding!.right,
                top: widget.padding!.top,
              ),
            ),
          
          // Liste principale optimisée
          SliverFixedExtentList(
            itemExtent: _itemHeight!,
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildItem(index),
              childCount: widget.items.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false, // Géré manuellement
            ),
          ),
          
          // Loading indicator pour lazy loading
          if (widget.enableLazyLoading && _isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          
          // Padding bottom
          if (widget.padding != null)
            SliverPadding(
              padding: EdgeInsets.only(bottom: widget.padding!.bottom),
            ),
          
          // Footer
          if (widget.footer != null)
            SliverToBoxAdapter(child: widget.footer!),
        ],
      ),
    );
  }
}

/// Delegate optimisé pour les listes avec recherche
class OptimizedSearchDelegate<T> extends SearchDelegate<T?> {
  final List<T> items;
  final String Function(T item) getSearchText;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final void Function(T item)? onItemSelected;
  
  OptimizedSearchDelegate({
    required this.items,
    required this.getSearchText,
    required this.itemBuilder,
    this.onItemSelected,
  });
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }
  
  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tapez pour rechercher...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    final filteredItems = items.where((item) =>
        getSearchText(item).toLowerCase().contains(query.toLowerCase())).toList();
    
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$query"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return Builder(
      builder: (context) => UltraOptimizedListView<T>(
        items: filteredItems,
        itemBuilder: (context, item, index) => itemBuilder(context, item),
        onItemTap: (item) {
          onItemSelected?.call(item);
          close(context, item);
        },
      ),
    );
  }
}

/// Widget de grid optimisé pour les performances
class OptimizedGrid<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollController? controller;
  
  const OptimizedGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
  });
  
  @override
  State<OptimizedGrid<T>> createState() => _OptimizedGridState<T>();
}

class _OptimizedGridState<T> extends State<OptimizedGrid<T>> {
  final Map<int, Widget> _widgetCache = {};
  
  @override
  void dispose() {
    _widgetCache.clear();
    super.dispose();
  }
  
  Widget _buildItem(int index) {
    if (!_widgetCache.containsKey(index)) {
      final item = widget.items[index];
      _widgetCache[index] = RepaintBoundary(
        key: ValueKey('grid_item_$index'),
        child: widget.itemBuilder(context, item, index),
      );
    }
    return _widgetCache[index]!;
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GridView.builder(
        controller: widget.controller,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, index) => _buildItem(index),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false, // Géré manuellement
      ),
    );
  }
}
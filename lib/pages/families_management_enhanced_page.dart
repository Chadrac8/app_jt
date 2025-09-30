import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/family_service.dart';
import '../../theme.dart';

class FamiliesManagementEnhancedPage extends StatefulWidget {
  const FamiliesManagementEnhancedPage({Key? key}) : super(key: key);

  @override
  State<FamiliesManagementEnhancedPage> createState() => _FamiliesManagementEnhancedPageState();
}

class _FamiliesManagementEnhancedPageState extends State<FamiliesManagementEnhancedPage> {
  // Controllers and state variables
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> _filteredFamilies = [];
  List<String> _selectedFamilyIds = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSelectionMode = false;
  bool _showArchived = false;
  
  // Filter state
  String _selectedFamilyType = 'All';
  String _selectedCity = 'All';
  int _minFamilySize = 0;
  int _maxFamilySize = 20;
  
  // Statistics
  Map<String, dynamic> _statistics = {};
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  
  @override
  void initState() {
    super.initState();
    _loadFamilies();
    _loadStatistics();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFamilies();
    }
  }

  void _onSearchChanged() {
    _filterFamilies();
  }

  Future<void> _loadFamilies() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> families;
      if (_showArchived) {
        families = await FamilyService.getArchivedFamilies();
      } else {
        families = await FamilyService.getAllFamilies(limit: 20);
      }
      
      setState(() {
        _families = families;
        _lastDocument = families.isNotEmpty ? null : null; // This would need proper implementation
        _hasMoreData = families.length == 20;
        _filterFamilies();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des familles: $e');
    }
  }

  Future<void> _loadMoreFamilies() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      List<Map<String, dynamic>> moreFamilies = await FamilyService.getAllFamilies(
        limit: 20,
        startAfter: _lastDocument,
      );
      
      setState(() {
        _families.addAll(moreFamilies);
        _hasMoreData = moreFamilies.length == 20;
        _filterFamilies();
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Erreur lors du chargement de plus de familles: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      Map<String, dynamic> stats = await FamilyService.getAdvancedFamilyStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _filterFamilies() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredFamilies = _families.where((family) {
        // Search filter
        bool matchesSearch = query.isEmpty ||
            family['familyName'].toString().toLowerCase().contains(query) ||
            (family['address']?['city'] ?? '').toString().toLowerCase().contains(query) ||
            (family['phone'] ?? '').toString().contains(query);
        
        // Type filter
        bool matchesType = _selectedFamilyType == 'All' || 
            family['familyType'] == _selectedFamilyType;
        
        // City filter
        bool matchesCity = _selectedCity == 'All' || 
            family['address']?['city'] == _selectedCity;
        
        // Size filter
        int memberCount = (family['memberIds'] as List?)?.length ?? 0;
        bool matchesSize = memberCount >= _minFamilySize && memberCount <= _maxFamilySize;
        
        return matchesSearch && matchesType && matchesCity && matchesSize;
      }).toList();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFamilyIds.clear();
      }
    });
  }

  void _toggleFamilySelection(String familyId) {
    setState(() {
      if (_selectedFamilyIds.contains(familyId)) {
        _selectedFamilyIds.remove(familyId);
      } else {
        _selectedFamilyIds.add(familyId);
      }
    });
  }

  void _selectAllFamilies() {
    setState(() {
      _selectedFamilyIds = _filteredFamilies.map((f) => f['id'] as String).toList();
    });
  }

  void _clearSelection() {
    setState(() => _selectedFamilyIds.clear());
  }

  Future<void> _bulkDelete() async {
    if (_selectedFamilyIds.isEmpty) return;
    
    bool? confirm = await _showConfirmDialog(
      'Supprimer les familles',
      'Voulez-vous vraiment supprimer ${_selectedFamilyIds.length} famille(s) sélectionnée(s) ?',
      isDestructive: true,
    );
    
    if (confirm == true) {
      bool success = await FamilyService.bulkDeleteFamilies(_selectedFamilyIds);
      if (success) {
        _showSuccessSnackBar('${_selectedFamilyIds.length} famille(s) supprimée(s)');
        _selectedFamilyIds.clear();
        _loadFamilies();
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<void> _bulkArchive() async {
    if (_selectedFamilyIds.isEmpty) return;
    
    bool? confirm = await _showConfirmDialog(
      'Archiver les familles',
      'Voulez-vous vraiment archiver ${_selectedFamilyIds.length} famille(s) sélectionnée(s) ?',
    );
    
    if (confirm == true) {
      bool allSuccess = true;
      for (String familyId in _selectedFamilyIds) {
        bool success = await FamilyService.archiveFamily(familyId);
        if (!success) allSuccess = false;
      }
      
      if (allSuccess) {
        _showSuccessSnackBar('${_selectedFamilyIds.length} famille(s) archivée(s)');
        _selectedFamilyIds.clear();
        _loadFamilies();
      } else {
        _showErrorSnackBar('Erreur lors de l\'archivage de certaines familles');
      }
    }
  }

  Future<void> _exportData() async {
    try {
      Map<String, dynamic> backupData = await FamilyService.backupAllFamilyData();
      String jsonData = jsonEncode(backupData);
      
      // Save to file and share
      await Share.shareXFiles([
        XFile.fromData(
          utf8.encode(jsonData),
          mimeType: 'application/json',
          name: 'families_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        )
      ], text: 'Export des données des familles');
      
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'export: $e');
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.single.bytes != null) {
        String jsonData = utf8.decode(result.files.single.bytes!);
        Map<String, dynamic> backupData = jsonDecode(jsonData);
        
        bool? confirm = await _showConfirmDialog(
          'Importer les données',
          'Cette action remplacera toutes les données existantes. Continuer ?',
          isDestructive: true,
        );
        
        if (confirm == true) {
          bool success = await FamilyService.restoreFromBackup(backupData);
          if (success) {
            _showSuccessSnackBar('Données importées avec succès');
            _loadFamilies();
            _loadStatistics();
          } else {
            _showErrorSnackBar('Erreur lors de l\'import');
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'import: $e');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtres avancés'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Family type filter
                DropdownButtonFormField<String>(
                  value: _selectedFamilyType,
                  decoration: const InputDecoration(labelText: 'Type de famille'),
                  items: ['All', 'Nuclear', 'Extended', 'Single', 'Blended', 'Other']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => _selectedFamilyType = value!),
                ),
                const SizedBox(height: 16),
                
                // City filter
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(labelText: 'Ville'),
                  items: ['All', ..._getCities()]
                      .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => _selectedCity = value!),
                ),
                const SizedBox(height: 16),
                
                // Family size range
                Text('Taille de famille: $_minFamilySize - $_maxFamilySize'),
                RangeSlider(
                  values: RangeValues(_minFamilySize.toDouble(), _maxFamilySize.toDouble()),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  labels: RangeLabels(_minFamilySize.toString(), _maxFamilySize.toString()),
                  onChanged: (values) => setDialogState(() {
                    _minFamilySize = values.start.round();
                    _maxFamilySize = values.end.round();
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedFamilyType = 'All';
                  _selectedCity = 'All';
                  _minFamilySize = 0;
                  _maxFamilySize = 20;
                });
              },
              child: const Text('Réinitialiser'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _filterFamilies();
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getCities() {
    Set<String> cities = {};
    for (var family in _families) {
      String? city = family['address']?['city'];
      if (city != null && city.isNotEmpty) {
        cities.add(city);
      }
    }
    return cities.toList()..sort();
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des familles'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard('Total familles', _statistics['totalFamilies']?.toString() ?? '0'),
              _buildStatCard('Total membres', _statistics['totalMembers']?.toString() ?? '0'),
              _buildStatCard('Taille moyenne', _statistics['averageFamilySize']?.toStringAsFixed(1) ?? '0'),
              
              const SizedBox(height: 16),
              const Text('Distribution par type:', style: TextStyle(fontWeight: AppTheme.fontBold)),
              ..._buildDistributionList(_statistics['familyTypeDistribution']),
              
              const SizedBox(height: 16),
              const Text('Distribution par taille:', style: TextStyle(fontWeight: AppTheme.fontBold)),
              ..._buildDistributionList(_statistics['sizeDistribution']),
              
              const SizedBox(height: 16),
              const Text('Top 5 villes:', style: TextStyle(fontWeight: AppTheme.fontBold)),
              ..._buildTopCities(_statistics['locationDistribution']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: AppTheme.fontBold)),
        ],
      ),
    );
  }

  List<Widget> _buildDistributionList(Map<String, dynamic>? distribution) {
    if (distribution == null) return [];
    
    return distribution.entries.map((entry) => Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• ${entry.key}'),
          Text('${entry.value}'),
        ],
      ),
    )).toList();
  }

  List<Widget> _buildTopCities(Map<String, dynamic>? distribution) {
    if (distribution == null) return [];
    
    var sortedEntries = distribution.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return sortedEntries.take(5).map((entry) => Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('• ${entry.key}'),
          Text('${entry.value}'),
        ],
      ),
    )).toList();
  }

  Future<bool?> _showConfirmDialog(String title, String content, {bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: isDestructive 
                ? ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.redStandard,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.greenStandard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedFamilyIds.length} sélectionnée(s)')
            : const Text('Gestion des familles'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllFamilies,
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
            ),
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: _bulkArchive,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _bulkDelete,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: _showStatisticsDialog,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'selection':
                    _toggleSelectionMode();
                    break;
                  case 'export':
                    _exportData();
                    break;
                  case 'import':
                    _importData();
                    break;
                  case 'archived':
                    setState(() {
                      _showArchived = !_showArchived;
                      _loadFamilies();
                    });
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'selection',
                  child: ListTile(
                    leading: Icon(Icons.checklist),
                    title: Text('Mode sélection'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Exporter'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.upload),
                    title: Text('Importer'),
                  ),
                ),
                PopupMenuItem(
                  value: 'archived',
                  child: ListTile(
                    leading: Icon(_showArchived ? Icons.unarchive : Icons.archive),
                    title: Text(_showArchived ? 'Voir actives' : 'Voir archivées'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des familles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterFamilies();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
          
          // Filter chips
          if (_selectedFamilyType != 'All' || _selectedCity != 'All' || _minFamilySize > 0 || _maxFamilySize < 20)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedFamilyType != 'All')
                    Chip(
                      label: Text('Type: $_selectedFamilyType'),
                      onDeleted: () {
                        setState(() => _selectedFamilyType = 'All');
                        _filterFamilies();
                      },
                    ),
                  if (_selectedCity != 'All')
                    Chip(
                      label: Text('Ville: $_selectedCity'),
                      onDeleted: () {
                        setState(() => _selectedCity = 'All');
                        _filterFamilies();
                      },
                    ),
                  if (_minFamilySize > 0 || _maxFamilySize < 20)
                    Chip(
                      label: Text('Taille: $_minFamilySize-$_maxFamilySize'),
                      onDeleted: () {
                        setState(() {
                          _minFamilySize = 0;
                          _maxFamilySize = 20;
                        });
                        _filterFamilies();
                      },
                    ),
                ],
              ),
            ),
          
          // Results info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredFamilies.length} famille(s) trouvée(s)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_showArchived)
                  const Chip(
                    label: Text('Mode archivé'),
                    backgroundColor: AppTheme.orangeStandard,
                  ),
              ],
            ),
          ),
          
          // Family list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFamilies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.family_restroom,
                              size: 64,
                              color: AppTheme.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune famille trouvée',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFamilies,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFamilies.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index >= _filteredFamilies.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            final family = _filteredFamilies[index];
                            final familyId = family['id'] as String;
                            final isSelected = _selectedFamilyIds.contains(familyId);
                            
                            return _buildFamilyCard(family, isSelected);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode 
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Navigate to family form page
                Navigator.pushNamed(context, '/family-form');
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle famille'),
            ),
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> family, bool isSelected) {
    final familyId = family['id'] as String;
    final memberCount = (family['memberIds'] as List?)?.length ?? 0;
    final address = family['address'] as Map<String, dynamic>?;
    final familyType = family['familyType'] as String?;
    
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: _isSelectionMode
            ? () => _toggleFamilySelection(familyId)
            : () {
                // Navigate to family detail page
                Navigator.pushNamed(context, '/family-detail', arguments: familyId);
              },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
          }
          _toggleFamilySelection(familyId);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleFamilySelection(familyId),
                ),
              
              // Family avatar
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.family_restroom,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Family info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family['familyName'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    
                    if (familyType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: Text(familyType),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    
                    if (address != null && address['city'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: AppTheme.grey600),
                            const SizedBox(width: 4),
                            Text(
                              '${address['city']}${address['region'] != null ? ', ${address['region']}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    
                    if (family['phone'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: AppTheme.grey600),
                            const SizedBox(width: 4),
                            Text(
                              family['phone'] as String,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 16, color: AppTheme.grey600),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount membre(s)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action menu
              if (!_isSelectionMode)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        Navigator.pushNamed(context, '/family-form', arguments: family);
                        break;
                      case 'archive':
                        bool success = await FamilyService.archiveFamily(familyId);
                        if (success) {
                          _showSuccessSnackBar('Famille archivée');
                          _loadFamilies();
                        }
                        break;
                      case 'delete':
                        bool? confirm = await _showConfirmDialog(
                          'Supprimer la famille',
                          'Voulez-vous vraiment supprimer cette famille ?',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          // Call delete method
                          _loadFamilies();
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: ListTile(
                        leading: Icon(_showArchived ? Icons.unarchive : Icons.archive),
                        title: Text(_showArchived ? 'Restaurer' : 'Archiver'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: AppTheme.redStandard),
                        title: Text('Supprimer'),
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
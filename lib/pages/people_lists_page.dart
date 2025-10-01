import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/people_lists_firebase_service.dart';
import 'people_list_create_page.dart';
import 'people_list_detail_page.dart';
import '../../theme.dart';

class PeopleListsPage extends StatefulWidget {
  const PeopleListsPage({Key? key}) : super(key: key);

  @override
  State<PeopleListsPage> createState() => _PeopleListsPageState();
}

class _PeopleListsPageState extends State<PeopleListsPage> {
  void _showBirthdayTodayList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PeopleListDetailPage(
          listId: 'anniversaires_aujourdhui',
          listName: "Anniversaires aujourd'hui",
        ),
      ),
    );
  }
  List<PeopleListModel> lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    lists = await PeopleListsFirebaseService.getLists();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listes de personnes'),
        elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.cake),
              tooltip: "Voir les anniversaires d'aujourd'hui",
              onPressed: _showBirthdayTodayList,
            ),
          ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Créer une nouvelle liste',
        child: FloatingActionButton.extended(
          onPressed: () async {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeopleListCreatePage()),
            );
            if (created == true) {
              _loadLists();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle liste'),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : lists.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text('Aucune liste pour le moment.', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text('Créez votre première liste pour commencer.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 500),
                                pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                                  opacity: animation,
                                  child: PeopleListDetailPage(
                                    listId: list.id,
                                    listName: list.name,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'list_avatar_${list.id}',
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.8, end: 1.0),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) {
                                      final colorSeed = list.id.hashCode;
                                      final color = Color((0xFF000000 + (colorSeed & 0x00FFFFFF))).withOpacity(1.0);
                                      return Transform.scale(
                                        scale: scale,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color.withOpacity(0.18),
                                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15), width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.10),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Icon(Icons.list, color: color.computeLuminance() < 0.5 ? AppTheme.white100 : AppTheme.black100, size: 28, semanticLabel: 'Icône liste'),
                                              ),
                                              if (list.filters.length > 0)
                                                Positioned(
                                                  right: 2,
                                                  bottom: 2,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(AppTheme.space2),
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: AppTheme.white100, width: 1),
                                                    ),
                                                    child: Text(
                                                      '${list.filters.length}',
                                                      style: TextStyle(fontSize: AppTheme.fontSize10, color: color.computeLuminance() < 0.5 ? AppTheme.white100 : AppTheme.black100, fontWeight: AppTheme.fontBold),
                                                      semanticsLabel: '${list.filters.length} filtre(s)',
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMedium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(list.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: AppTheme.fontBold)),
                                      const SizedBox(height: AppTheme.spaceXSmall),
                                      Text('${list.filters.length} critère(s)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      await PeopleListsFirebaseService.deleteList(list.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [Icon(Icons.delete, color: AppTheme.redStandard), SizedBox(width: AppTheme.spaceSmall), Text('Liste supprimée')],
                                            ),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                      _loadLists();
                                    } else if (value == 'edit') {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PeopleListCreatePage(
                                            initialName: list.name,
                                            initialFilters: list.filters.map((f) => {
                                              'field': f.field,
                                              'operator': f.operator,
                                              'value': f.value,
                                            }).toList(),
                                            listId: list.id,
                                          ),
                                        ),
                                      );
                                      if (updated == true && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [Icon(Icons.check_circle, color: AppTheme.greenStandard), SizedBox(width: AppTheme.spaceSmall), Text('Liste modifiée')],
                                            ),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        _loadLists();
                                      }
                                    } else if (value == 'duplicate') {
                                      final duplicated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PeopleListCreatePage(
                                            initialName: list.name + ' (copie)',
                                            initialFilters: list.filters.map((f) => {
                                              'field': f.field,
                                              'operator': f.operator,
                                              'value': f.value,
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                      if (duplicated == true && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [Icon(Icons.copy, color: AppTheme.blueStandard), SizedBox(width: AppTheme.spaceSmall), Text('Liste dupliquée')],
                                            ),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        _loadLists();
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Éditer')),
                                    const PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
                                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class PeopleListModel {
  final String id;
  final String name;
  final List<PeopleListFilter> filters;
  final DateTime createdAt;
  final DateTime updatedAt;

  PeopleListModel({
    required this.id,
    required this.name,
    required this.filters,
    required this.createdAt,
    required this.updatedAt,
  });
}

class PeopleListFilter {
  final String field;
  final String operator;
  final dynamic value;

  PeopleListFilter({
    required this.field,
    required this.operator,
    required this.value,
  });
}

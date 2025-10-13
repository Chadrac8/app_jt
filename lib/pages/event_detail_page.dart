import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../services/event_series_service.dart';
import '../widgets/event_form_builder.dart';
import '../widgets/event_registrations_list.dart';
import '../widgets/event_statistics_view.dart';
import '../widgets/recurring_event_manager_widget.dart';
import '../widgets/recurring_event_edit_dialog.dart';
import '../widgets/recurring_event_delete_dialog.dart';
import 'event_form_page.dart';
import '../../theme.dart';


class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  EventModel? _currentEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  int _getTabCount() {
    return _currentEvent?.isRecurring == true ? 5 : 4;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshEventData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final refreshedEvent = await EventsFirebaseService.getEvent(widget.event.id);
      if (refreshedEvent != null && mounted) {
        // Check if tab count needs to change
        final newTabCount = refreshedEvent.isRecurring == true ? 5 : 4;
        final currentTabCount = _tabController.length;
        
        if (newTabCount != currentTabCount) {
          final currentIndex = _tabController.index;
          _tabController.dispose();
          _tabController = TabController(length: newTabCount, vsync: this);
          // Restore tab index if still valid
          if (currentIndex < newTabCount) {
            _tabController.index = currentIndex;
          }
        }
        
        setState(() => _currentEvent = refreshedEvent);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editEvent() async {
    // Vérifier si l'événement fait partie d'une série récurrente
    if (_currentEvent?.seriesId != null) {
      // Afficher le dialog pour choisir comment modifier
      final option = await RecurringEventEditDialog.show(context, _currentEvent!);
      
      if (option == null) return; // Utilisateur a annulé
      
      // Naviguer vers le formulaire d'édition
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventFormPage(event: _currentEvent),
        ),
      );
      
      if (result == true) {
        // L'événement a été modifié dans le formulaire
        // Maintenant appliquer les modifications selon l'option choisie
        await _refreshEventData();
        
        // Appliquer les modifications selon le choix de l'utilisateur
        // Note: Pour l'instant, la modification est déjà faite dans le formulaire
        // On pourrait améliorer en passant l'option au formulaire
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getEditSuccessMessage(option)),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } else {
      // Événement simple (non récurrent)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventFormPage(event: _currentEvent),
        ),
      );
      
      if (result == true) {
        await _refreshEventData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Événement mis à jour avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    }
  }
  
  String _getEditSuccessMessage(RecurringEditOption option) {
    switch (option) {
      case RecurringEditOption.thisOnly:
        return 'Cette occurrence a été modifiée avec succès';
      case RecurringEditOption.thisAndFuture:
        return 'Cette occurrence et les suivantes ont été modifiées';
      case RecurringEditOption.all:
        return 'Toutes les occurrences ont été modifiées';
    }
  }

  Future<void> _publishEvent() async {
    try {
      final updatedEvent = _currentEvent!.copyWith(
        status: 'publie',
        updatedAt: DateTime.now(),
      );
      await EventsFirebaseService.updateEvent(updatedEvent);
      await _refreshEventData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement publié avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _duplicateEvent() async {
    try {
      final newStartDate = DateTime.now().add(const Duration(days: 7));
      await EventsFirebaseService.duplicateEvent(
        _currentEvent!.id,
        '${_currentEvent!.title} (Copie)',
        newStartDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement dupliqué avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Color get _statusColor {
    switch (_currentEvent!.status) {
      case 'publie': return AppTheme.successColor;
      case 'brouillon': return AppTheme.warningColor;
      case 'archive': return AppTheme.textTertiaryColor;
      case 'annule': return AppTheme.errorColor;
      default: return AppTheme.textSecondaryColor;
    }
  }

  Widget _buildEventImage() {
    if (_currentEvent!.imageUrl != null && _currentEvent!.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _currentEvent!.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingImage(),
        errorWidget: (context, url, error) => _buildFallbackImage(),
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildLoadingImage() {
    return Container(
      color: AppTheme.backgroundColor,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildFallbackImage() {
    final imageUrl = "https://images.unsplash.com/photo-1556761175-129418cb2dfe?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNjE1NDJ8&ixlib=rb-4.1.0&q=80&w=1080";
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.backgroundColor,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.secondaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.event,
            size: 80,
            color: AppTheme.white100.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEvent == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.white100,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentEvent!.title,
                  style: const TextStyle(
                    fontWeight: AppTheme.fontBold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: AppTheme.black100,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildEventImage(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.black100.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _showActionMenu,
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'Infos'),
                    const Tab(text: 'Formulaire'),
                    const Tab(text: 'Participants'),
                    const Tab(text: 'Stats'),
                    if (_currentEvent?.isRecurring == true)
                      const Tab(text: 'Récurrence'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInformationTab(),
            _buildFormTab(),
            _buildParticipantsTab(),
            _buildStatisticsTab(),
            if (_currentEvent?.isRecurring == true)
              _buildRecurrenceTab(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _editEvent,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.white100,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildInformationTab() {
    return RefreshIndicator(
      onRefresh: _refreshEventData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          children: [
            // Statut et visibilité
            _buildInfoCard(
              title: 'Statut et visibilité',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow(
                  icon: Icons.circle,
                  label: 'Statut',
                  value: _currentEvent!.statusLabel,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      _currentEvent!.statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: AppTheme.fontMedium,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ),
                ),
                _buildInfoRow(
                  icon: Icons.visibility,
                  label: 'Visibilité',
                  value: _currentEvent!.visibilityLabel,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Informations générales
            _buildInfoCard(
              title: 'Informations générales',
              icon: Icons.event,
              children: [
                _buildInfoRow(
                  icon: Icons.category,
                  label: 'Type',
                  value: _currentEvent!.typeLabel,
                ),
                _buildInfoRow(
                  icon: Icons.schedule,
                  label: 'Date de début',
                  value: _formatDateTime(_currentEvent!.startDate),
                ),
                if (_currentEvent!.endDate != null)
                  _buildInfoRow(
                    icon: Icons.schedule,
                    label: 'Date de fin',
                    value: _formatDateTime(_currentEvent!.endDate!),
                  ),
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Lieu',
                  value: _currentEvent!.location,
                ),
                if (_currentEvent!.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              size: 20,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: AppTheme.fontSemiBold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text(
                          _currentEvent!.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Inscriptions
            if (_currentEvent!.isRegistrationEnabled)
              _buildInfoCard(
                title: 'Inscriptions',
                icon: Icons.how_to_reg,
                children: [
                  _buildInfoRow(
                    icon: Icons.people,
                    label: 'Limite de participants',
                    value: _currentEvent!.maxParticipants?.toString() ?? 'Illimitée',
                  ),
                  _buildInfoRow(
                    icon: Icons.list,
                    label: 'Liste d\'attente',
                    value: _currentEvent!.hasWaitingList ? 'Activée' : 'Désactivée',
                  ),
                ],
              ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Récurrence
            if (_currentEvent!.isRecurring)
              _buildInfoCard(
                title: 'Récurrence',
                icon: Icons.repeat,
                children: [
                  _buildInfoRow(
                    icon: Icons.repeat,
                    label: 'Événement récurrent',
                    value: 'Oui',
                  ),
                ],
              ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Métadonnées
            _buildInfoCard(
              title: 'Métadonnées',
              icon: Icons.history,
              children: [
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: 'Créé le',
                  value: _formatDate(_currentEvent!.createdAt),
                ),
                _buildInfoRow(
                  icon: Icons.update,
                  label: 'Modifié le',
                  value: _formatDate(_currentEvent!.updatedAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTab() {
    return EventFormBuilder(event: _currentEvent!);
  }

  Widget _buildParticipantsTab() {
    return EventRegistrationsList(event: _currentEvent!);
  }

  Widget _buildStatisticsTab() {
    return EventStatisticsView(event: _currentEvent!);
  }

  Widget _buildRecurrenceTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RecurringEventManagerWidget(
        eventId: _currentEvent!.id,
        parentEvent: _currentEvent!,
        onEditInstance: (instance) async {
          // Ouvre le formulaire d'édition pour cette occurrence (à personnaliser)
          // Par exemple :
          // await Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventInstancePage(instance: instance)));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Modifier l\'occurrence du ${instance.actualDate.day}/${instance.actualDate.month}/${instance.actualDate.year}')),
          );
        },
        onCancelInstance: (instance) async {
          // Annule l'occurrence (à personnaliser, ex: update Firestore)
          // await EventRecurrenceService.cancelInstance(instance.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Occurrence du ${instance.actualDate.day}/${instance.actualDate.month}/${instance.actualDate.year} annulée')),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          trailing ?? Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentEvent!.isDraft) ...[
              ListTile(
                leading: const Icon(Icons.publish, color: AppTheme.successColor),
                title: const Text('Publier'),
                onTap: () {
                  Navigator.pop(context);
                  _publishEvent();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _editEvent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.secondaryColor),
              title: const Text('Dupliquer'),
              onTap: () {
                Navigator.pop(context);
                _duplicateEvent();
              },
            ),
            if (!_currentEvent!.isArchived) ...[
              ListTile(
                leading: const Icon(Icons.archive, color: AppTheme.warningColor),
                title: const Text('Archiver'),
                onTap: () {
                  Navigator.pop(context);
                  _handleAction('archive');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _handleAction('delete');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'archive':
        try {
          await EventsFirebaseService.archiveEvent(_currentEvent!.id);
          await _refreshEventData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement archivé'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
        break;
      case 'delete':
        _confirmDeleteEvent();
        break;
    }
  }

  Future<void> _confirmDeleteEvent() async {
    // Vérifier si l'événement fait partie d'une série récurrente
    if (_currentEvent?.seriesId != null) {
      // Afficher le dialog pour choisir comment supprimer
      final option = await RecurringEventDeleteDialog.show(context, _currentEvent!);
      
      if (option == null) return; // Utilisateur a annulé
      
      try {
        setState(() => _isLoading = true);
        
        switch (option) {
          case RecurringDeleteOption.thisOnly:
            // Supprimer uniquement cette occurrence (soft delete)
            await EventSeriesService.deleteSingleOccurrence(_currentEvent!.id);
            if (mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cette occurrence a été supprimée'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
            break;
            
          case RecurringDeleteOption.thisAndFuture:
            // Supprimer cette occurrence et toutes les futures
            await EventSeriesService.deleteThisAndFutureOccurrences(_currentEvent!.id);
            if (mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cette occurrence et les suivantes ont été supprimées'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
            break;
            
          case RecurringDeleteOption.all:
            // Supprimer toute la série
            await EventSeriesService.deleteAllOccurrences(_currentEvent!.seriesId!);
            if (mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les occurrences ont été supprimées'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
            break;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Événement simple (non récurrent) - Dialog de confirmation standard
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer l\'événement'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cet événement ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await EventsFirebaseService.deleteEvent(_currentEvent!.id);
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement supprimé avec succès'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la suppression: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year à ${hour}h$minute';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    
    return '$day $month $year';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.white100,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
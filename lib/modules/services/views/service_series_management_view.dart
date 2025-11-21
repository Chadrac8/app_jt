import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/service_model.dart';
import '../../../services/service_recurrence_service.dart';

import 'service_form_page.dart';

/// Vue pour gérer les séries de services récurrents
/// Style Planning Center Online avec actions sur occurrences individuelles
class ServiceSeriesManagementView extends StatefulWidget {
  final String seriesId;
  final String serviceName;

  const ServiceSeriesManagementView({
    Key? key,
    required this.seriesId,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<ServiceSeriesManagementView> createState() => _ServiceSeriesManagementViewState();
}

class _ServiceSeriesManagementViewState extends State<ServiceSeriesManagementView> {
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String _selectedAction = '';
  Set<String> _selectedServiceIds = {};

  @override
  void initState() {
    super.initState();
    _loadSeriesServices();
  }

  Future<void> _loadSeriesServices() async {
    setState(() => _isLoading = true);
    
    try {
      final services = await ServiceRecurrenceService.getSeriesServices(widget.seriesId);
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.serviceName),
            Text(
              'Série récurrente (${_services.length} occurrences)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleBulkAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_exception',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 8),
                    Text('Ajouter exception'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'modify_future',
                child: Row(
                  children: [
                    Icon(Icons.edit_calendar),
                    SizedBox(width: 8),
                    Text('Modifier futures'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_series',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer série', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildServicesList(),
          
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOccurrence,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter occurrence'),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune occurrence trouvée'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistiques et filtres
        _buildStatsHeader(),
        
        // Liste des occurrences
        Expanded(
          child: ListView.builder(
            itemCount: _services.length,
            itemBuilder: (context, index) => _buildServiceCard(_services[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final now = DateTime.now();
    final pastServices = _services.where((s) => s.dateTime.isBefore(now)).length;
    final futureServices = _services.length - pastServices;
    final modifiedServices = _services.where((s) => s.isModifiedOccurrence).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques de la série',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    _services.length.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Passées',
                    pastServices.toString(),
                    Icons.history,
                    Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Futures',
                    futureServices.toString(),
                    Icons.schedule,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Modifiées',
                    modifiedServices.toString(),
                    Icons.edit,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    final now = DateTime.now();
    final isPast = service.dateTime.isBefore(now);
    final isToday = service.dateTime.day == now.day &&
                   service.dateTime.month == now.month &&
                   service.dateTime.year == now.year;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              service.isSeriesMaster ? Icons.star : Icons.event,
              color: service.isSeriesMaster 
                  ? Colors.amber 
                  : (isPast ? Colors.grey : Theme.of(context).primaryColor),
            ),
            if (service.isModifiedOccurrence)
              const Icon(Icons.edit, size: 12, color: Colors.orange),
          ],
        ),
        
        title: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE dd/MM/yyyy à HH:mm', 'fr_FR').format(service.dateTime),
                style: TextStyle(
                  color: isPast ? Colors.grey : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ),
            if (isToday) _buildTodayBadge(),
            if (service.isSeriesMaster) _buildMasterBadge(),
          ],
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.location),
            if (service.isModifiedOccurrence)
              const Text(
                'Occurrence modifiée',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
        
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleServiceAction(action, service),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Modifier')],
              ),
            ),
            const PopupMenuItem(
              value: 'edit_future',
              child: Row(
                children: [Icon(Icons.edit_calendar), SizedBox(width: 8), Text('Modifier + futures')],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [Icon(Icons.copy), SizedBox(width: 8), Text('Dupliquer')],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [Icon(Icons.cancel, color: Colors.orange), SizedBox(width: 8), Text('Annuler')],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Supprimer')],
              ),
            ),
            if (!service.isSeriesMaster) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete_future',
                child: Row(
                  children: [Icon(Icons.delete_sweep, color: Colors.red), SizedBox(width: 8), Text('Supprimer + futures')],
                ),
              ),
            ],
          ],
        ),
        
        onTap: () => _viewServiceDetails(service),
      ),
    );
  }

  Widget _buildTodayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Aujourd\'hui',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildMasterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Maître',
        style: TextStyle(color: Colors.black, fontSize: 10),
      ),
    );
  }

  void _handleServiceAction(String action, ServiceModel service) async {
    switch (action) {
      case 'edit':
        await _editService(service, false);
        break;
      case 'edit_future':
        await _editService(service, true);
        break;
      case 'duplicate':
        await _duplicateService(service);
        break;
      case 'cancel':
        await _cancelService(service);
        break;
      case 'delete':
        await _deleteService(service, 'this');
        break;
      case 'delete_future':
        await _deleteService(service, 'future');
        break;
    }
  }

  Future<void> _editService(ServiceModel service, bool includeFutures) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceFormPage(service: service),
      ),
    );

    if (result == true) {
      // Recharger la liste après modification
      _loadSeriesServices();
    }
  }

  Future<void> _cancelService(ServiceModel service) async {
    try {
      await ServiceRecurrenceService.updateOccurrence(
        serviceId: service.id,
        updates: {'status': 'annule'},
      );
      _loadSeriesServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service annulé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deleteService(ServiceModel service, String scope) async {
    final scopeText = scope == 'this' 
        ? 'cette occurrence' 
        : 'cette occurrence et toutes les futures';
        
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer $scopeText ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ServiceRecurrenceService.deleteOccurrence(
          serviceId: service.id,
          deleteScope: scope,
        );
        _loadSeriesServices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service(s) supprimé(s)')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _duplicateService(ServiceModel service) async {
    final date = await showDatePicker(
      context: context,
      initialDate: service.dateTime.add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(service.dateTime),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        try {
          final duplicatedService = service.copyWith(
            dateTime: newDateTime,
            seriesId: null, // Pas de série pour une duplication
            isRecurring: false,
            parentServiceId: null,
            isSeriesMaster: false,
            occurrenceIndex: null,
            originalDateTime: null,
            isModifiedOccurrence: false,
            exceptions: [],
            updatedAt: DateTime.now(),
          );

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceFormPage(service: duplicatedService),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  void _handleBulkAction(String action) async {
    switch (action) {
      case 'add_exception':
        await _addException();
        break;
      case 'modify_future':
        await _modifyFutureOccurrences();
        break;
      case 'delete_series':
        await _deleteEntireSeries();
        break;
    }
  }

  Future<void> _addException() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      try {
        await ServiceRecurrenceService.addException(
          seriesId: widget.seriesId,
          exceptionDate: date,
        );
        _loadSeriesServices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exception ajoutée')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _modifyFutureOccurrences() async {
    // TODO: Implémenter la modification en lot des occurrences futures
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  Future<void> _deleteEntireSeries() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toute la série'),
        content: const Text(
          'Cette action supprimera définitivement tous les services de cette série récurrente. Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ServiceRecurrenceService.deleteOccurrence(
          serviceId: _services.first.id,
          deleteScope: 'all',
        );
        Navigator.pop(context, true); // Retourner à l'écran précédent
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _addOccurrence() async {
    // TODO: Implémenter l'ajout d'une occurrence ponctuelle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  void _viewServiceDetails(ServiceModel service) {
    // TODO: Implémenter la vue détaillée du service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails du service: ${service.name}')),
    );
  }
}
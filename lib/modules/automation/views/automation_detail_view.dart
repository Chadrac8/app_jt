import 'package:flutter/material.dart';
import '../models/automation.dart';
import '../models/automation_execution.dart';
import '../services/automation_service.dart';
import '../../../../theme.dart';
import '../../../widgets/custom_card.dart';
import '../../../theme.dart';

/// Vue détaillée d'une automatisation
class AutomationDetailView extends StatefulWidget {
  final Automation? automation;

  const AutomationDetailView({Key? key, this.automation}) : super(key: key);

  @override
  State<AutomationDetailView> createState() => _AutomationDetailViewState();
}

class _AutomationDetailViewState extends State<AutomationDetailView> {
  final AutomationService _automationService = AutomationService();
  
  Automation? _automation;
  List<AutomationExecution> _executions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _automation = widget.automation;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_automation?.id == null) return;

    setState(() => _isLoading = true);
    
    try {
      final executions = await _automationService.executionService
          .getExecutionsByAutomation(_automation!.id!);
      
      setState(() {
        _executions = executions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_automation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Automatisation non trouvée'),
        ),
        body: const Center(
          child: Text('Aucune automatisation trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_automation!.name),
        actions: [
          IconButton(
            icon: Icon(_automation!.isActive ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleActivation,
            tooltip: _automation!.isActive ? 'Désactiver' : 'Activer',
          ),
          IconButton(
            icon: const Icon(Icons.play_circle),
            onPressed: _triggerManually,
            tooltip: 'Tester maintenant',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editAutomation,
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewExecutions,
            tooltip: 'Historique',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: AppTheme.space20),
                  _buildStatsGrid(),
                  const SizedBox(height: AppTheme.space20),
                  _buildTriggerCard(),
                  const SizedBox(height: AppTheme.space20),
                  _buildConditionsCard(),
                  const SizedBox(height: AppTheme.space20),
                  _buildActionsCard(),
                  const SizedBox(height: AppTheme.space20),
                  _buildExecutionsCard(),
                  const SizedBox(height: AppTheme.space20),
                  _buildMetadataCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return CustomCard(
      child: Row(
        children: [
          Icon(
            _automation!.isActive ? Icons.check_circle : Icons.pause_circle,
            size: 32,
            color: _automation!.isActive ? AppTheme.greenStandard : AppTheme.grey500,
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _automation!.status.label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _automation!.isActive ? AppTheme.greenStandard : AppTheme.grey500,
                  ),
                ),
                Text(
                  _automation!.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                Text(
                  '${_automation!.executionCount}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.blueStandard,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Text('Exécutions'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                Text(
                  '${_automation!.successRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.greenStandard,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Text('Succès'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                Text(
                  '${_automation!.failureCount}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.redStandard,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Text('Échecs'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                Text(
                  '${_automation!.actions.length}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.orangeStandard,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Text('Actions'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTriggerIcon(_automation!.trigger),
                color: AppTheme.blueStandard,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Déclencheur',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _automation!.trigger.label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (_automation!.triggerConfig.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSmall),
            const Text('Configuration:'),
            ..._automation!.triggerConfig.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('${entry.key}: ${entry.value}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conditions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          if (_automation!.conditions.isEmpty)
            const Text('Aucune condition définie')
          else
            ..._automation!.conditions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: AppTheme.grey800,
                            fontWeight: AppTheme.fontBold,
                            fontSize: AppTheme.fontSize12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        '${entry.value.field} ${entry.value.operator} ${entry.value.value}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          if (_automation!.actions.isEmpty)
            const Text('Aucune action définie')
          else
            ..._automation!.actions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: entry.value.enabled ? AppTheme.grey100 : AppTheme.grey100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: Icon(
                        _getActionIcon(entry.value.action),
                        color: entry.value.enabled ? AppTheme.grey800 : AppTheme.grey600,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.action.label,
                            style: TextStyle(
                              fontWeight: AppTheme.fontMedium,
                              color: entry.value.enabled ? null : AppTheme.grey600,
                            ),
                          ),
                          if (entry.value.delayMinutes != null && entry.value.delayMinutes! > 0)
                            Text(
                              'Délai: ${entry.value.delayMinutes} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (!entry.value.enabled)
                      Icon(
                        Icons.pause,
                        color: AppTheme.grey600,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExecutionsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Exécutions récentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: _viewExecutions,
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          if (_executions.isEmpty)
            const Text('Aucune exécution')
          else
            ..._executions.take(3).map(
              (execution) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _getExecutionStatusIcon(execution.status),
                      color: _getExecutionStatusColor(execution.status),
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            execution.status.label,
                            style: const TextStyle(fontWeight: AppTheme.fontMedium),
                          ),
                          Text(
                            _formatDateTime(execution.triggeredAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildInfoRow('Créée le', _formatDate(_automation!.createdAt)),
          _buildInfoRow('Modifiée le', _formatDate(_automation!.updatedAt)),
          _buildInfoRow('Créée par', _automation!.createdBy),
          if (_automation!.lastExecutedAt != null)
            _buildInfoRow('Dernière exécution', _formatDate(_automation!.lastExecutedAt!)),
          if (_automation!.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Wrap(
              spacing: 8,
              children: _automation!.tags.map((tag) =>
                Chip(
                  label: Text(tag),
                  backgroundColor: AppTheme.grey100,
                  labelStyle: TextStyle(color: AppTheme.grey800),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: AppTheme.fontMedium),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getTriggerIcon(AutomationTrigger trigger) {
    switch (trigger) {
      case AutomationTrigger.personAdded:
        return Icons.person_add;
      case AutomationTrigger.groupJoined:
        return Icons.group_add;
      case AutomationTrigger.eventRegistered:
        return Icons.event;
      case AutomationTrigger.serviceAssigned:
        return Icons.assignment;
      case AutomationTrigger.dateScheduled:
        return Icons.schedule;
      case AutomationTrigger.fieldChanged:
        return Icons.edit;
      case AutomationTrigger.prayerRequest:
        return Icons.favorite;
      case AutomationTrigger.taskCompleted:
        return Icons.task_alt;
      case AutomationTrigger.blogPostPublished:
        return Icons.article;
      case AutomationTrigger.appointmentBooked:
        return Icons.calendar_today;
    }
  }

  IconData _getActionIcon(AutomationAction action) {
    switch (action) {
      case AutomationAction.sendEmail:
        return Icons.email;
      case AutomationAction.sendNotification:
        return Icons.notifications;
      case AutomationAction.assignTask:
        return Icons.assignment;
      case AutomationAction.addToGroup:
        return Icons.group_add;
      case AutomationAction.updateField:
        return Icons.edit;
      case AutomationAction.createEvent:
        return Icons.event;
      case AutomationAction.scheduleFollowUp:
        return Icons.schedule;
      case AutomationAction.logActivity:
        return Icons.list;
      case AutomationAction.sendSMS:
        return Icons.sms;
      case AutomationAction.createAppointment:
        return Icons.calendar_today;
    }
  }

  IconData _getExecutionStatusIcon(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.pending:
        return Icons.schedule;
      case ExecutionStatus.running:
        return Icons.play_arrow;
      case ExecutionStatus.completed:
        return Icons.check_circle;
      case ExecutionStatus.failed:
        return Icons.error;
      case ExecutionStatus.cancelled:
        return Icons.cancel;
      case ExecutionStatus.skipped:
        return Icons.skip_next;
    }
  }

  Color _getExecutionStatusColor(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.pending:
        return AppTheme.orangeStandard;
      case ExecutionStatus.running:
        return AppTheme.blueStandard;
      case ExecutionStatus.completed:
        return AppTheme.greenStandard;
      case ExecutionStatus.failed:
        return AppTheme.redStandard;
      case ExecutionStatus.cancelled:
        return AppTheme.grey500;
      case ExecutionStatus.skipped:
        return AppTheme.orangeStandard;
    }
  }

  void _toggleActivation() async {
    try {
      if (_automation!.isActive) {
        await _automationService.deactivateAutomation(_automation!.id!);
        setState(() {
          _automation = _automation!.copyWith(status: AutomationStatus.inactive);
        });
      } else {
        await _automationService.activateAutomation(_automation!.id!);
        setState(() {
          _automation = _automation!.copyWith(status: AutomationStatus.active);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _triggerManually() async {
    try {
      await _automationService.triggerAutomation(
        _automation!.id!,
        {'manual': true},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Automatisation déclenchée manuellement')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _editAutomation() {
    Navigator.pushNamed(
      context,
      '/automation/edit',
      arguments: _automation,
    );
  }

  void _viewExecutions() {
    Navigator.pushNamed(
      context,
      '/automation/execution',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
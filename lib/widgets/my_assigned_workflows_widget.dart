import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../pages/workflow_detail_page.dart';
import '../../theme.dart';

class MyAssignedWorkflowsWidget extends StatefulWidget {
  final String personId;
  
  const MyAssignedWorkflowsWidget({
    super.key,
    required this.personId,
  });

  @override
  State<MyAssignedWorkflowsWidget> createState() => _MyAssignedWorkflowsWidgetState();
}

class _MyAssignedWorkflowsWidgetState extends State<MyAssignedWorkflowsWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignedWorkflows = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignedWorkflows();
  }

  @override
  void dispose() {
    // Le widget est en cours de suppression, les vérifications mounted 
    // dans _loadAssignedWorkflows() éviteront les appels setState() invalides
    super.dispose();
  }

  Future<void> _loadAssignedWorkflows() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final workflows = await FirebaseService.getWorkflowsWithPersonAsResponsible(widget.personId);
      
      if (mounted) {
        setState(() {
          _assignedWorkflows = workflows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Erreur lors du chargement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              ElevatedButton(
                onPressed: _loadAssignedWorkflows,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedWorkflows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Aucun suivi assigné',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Cette personne n\'est responsable d\'aucune étape de suivi pour le moment.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignedWorkflows,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: _assignedWorkflows.length,
        itemBuilder: (context, index) {
          final workflowData = _assignedWorkflows[index];
          return _buildWorkflowCard(workflowData);
        },
      ),
    );
  }

  Widget _buildWorkflowCard(Map<String, dynamic> workflowData) {
    final PersonWorkflowModel personWorkflow = workflowData['personWorkflow'];
    final WorkflowModel workflowTemplate = workflowData['workflowTemplate'];
    final PersonModel followedPerson = workflowData['followedPerson'];
    final List<WorkflowStep> assignedSteps = workflowData['assignedSteps'];
    final int totalSteps = workflowData['totalSteps'];
    final int completedSteps = workflowData['completedSteps'];

    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    final statusColor = _getStatusColor(personWorkflow.status);
    final statusText = _getStatusText(personWorkflow.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: Color(int.parse('0xFF${workflowTemplate.color.substring(1)}')).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () => _openWorkflowDetails(personWorkflow, workflowTemplate, followedPerson),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom du workflow et statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${workflowTemplate.color.substring(1)}')).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      _getIconData(workflowTemplate.icon),
                      color: Color(int.parse('0xFF${workflowTemplate.color.substring(1)}')),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflowTemplate.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: AppTheme.fontSemiBold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Suivi de ${followedPerson.fullName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Mes étapes assignées
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_pin,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.space6),
                        Text(
                          'Mes étapes assignées (${assignedSteps.length})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: AppTheme.fontSemiBold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    ...assignedSteps.take(2).map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: personWorkflow.completedSteps.contains(step.id)
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.outline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: Text(
                              step.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: personWorkflow.completedSteps.contains(step.id)
                                    ? Theme.of(context).colorScheme.outline
                                    : null,
                                decoration: personWorkflow.completedSteps.contains(step.id)
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (assignedSteps.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '... et ${assignedSteps.length - 2} autre(s) étape(s)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Barre de progression et infos
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Text(
                              '$completedSteps/$totalSteps étapes',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: AppTheme.fontMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary,
                          ),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.space12),
              
              // Dernière mise à jour
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    'Dernière mise à jour: ${_formatDate(personWorkflow.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
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

  void _openWorkflowDetails(PersonWorkflowModel personWorkflow, WorkflowModel workflowTemplate, PersonModel followedPerson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowDetailPage(
          personWorkflow: personWorkflow,
          workflow: workflowTemplate,
          person: followedPerson,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.greenStandard;
      case 'in_progress':
      case 'active':
        return AppTheme.blueStandard;
      case 'pending':
        return AppTheme.orangeStandard;
      case 'cancelled':
        return AppTheme.redStandard;
      default:
        return AppTheme.grey500;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Terminé';
      case 'in_progress':
        return 'En cours';
      case 'active':
        return 'Actif';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'track_changes':
        return Icons.track_changes;
      case 'person_add':
        return Icons.person_add;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'healing':
        return Icons.healing;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.track_changes;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
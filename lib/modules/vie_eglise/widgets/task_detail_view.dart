import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../../../../theme.dart';

class TaskDetailView extends StatelessWidget {
  final TaskModel task;

  const TaskDetailView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la tâche', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildTaskInfo(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildDescription(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildAssignees(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Row(
            children: [
              _buildPriorityBadge(),
              const SizedBox(width: AppTheme.space12),
              _buildStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          if (task.dueDate != null) ...[
            _buildInfoRow(Icons.access_time, 'Échéance', _formatDate(task.dueDate!)),
            const SizedBox(height: AppTheme.space12),
          ],
          if (task.category != null) ...[
            _buildInfoRow(Icons.category, 'Catégorie', task.category!),
            const SizedBox(height: AppTheme.space12),
          ],
          if (task.estimatedHours != null) ...[
            _buildInfoRow(Icons.schedule, 'Durée estimée', '${task.estimatedHours}h'),
            const SizedBox(height: AppTheme.space12),
          ],
          if (task.location != null) ...[
            _buildInfoRow(Icons.location_on, 'Lieu', task.location!),
            const SizedBox(height: AppTheme.space12),
          ],
          FutureBuilder<String>(
            future: _getCreatorName(task.createdBy),
            builder: (context, snapshot) {
              return _buildInfoRow(
                Icons.person,
                'Créé par',
                snapshot.data ?? 'Utilisateur',
              );
            },
          ),
          const SizedBox(height: AppTheme.space12),
          _buildInfoRow(Icons.calendar_today, 'Créé le', _formatDate(task.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (task.description.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            task.description,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.grey600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignees() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignés (${task.assigneeIds.length})',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          if (task.assigneeIds.isEmpty)
            Text(
              'Aucune personne assignée',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.grey500,
              ),
            )
          else
            ...task.assigneeIds.map((id) => _buildAssigneeItem(id)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.grey500),
        const SizedBox(width: AppTheme.space12),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.grey700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeItem(String userId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.blueStandard.withOpacity(0.1),
            child: Text(
              userId.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize12,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.blueStandard,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          FutureBuilder<String>(
            future: _getUserName(userId),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'Utilisateur $userId',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize14,
                  color: AppTheme.grey700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color = _getPriorityColor(task.priority);
    String label = _getPriorityLabel(task.priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(task.priority), size: 16, color: color),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontSemiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color = _getStatusColor(task.status);
    String label = _getStatusLabel(task.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: AppTheme.fontSize12,
          fontWeight: AppTheme.fontSemiBold,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.redStandard;
      case 'medium':
        return AppTheme.orangeStandard;
      case 'low':
        return AppTheme.greenStandard;
      default:
        return AppTheme.grey500;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.expand_more;
      default:
        return Icons.help_outline;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Faible';
      default:
        return priority;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.greenStandard;
      case 'in_progress':
        return AppTheme.blueStandard;
      case 'todo':
        return AppTheme.orangeStandard;
      default:
        return AppTheme.grey500;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Terminé';
      case 'in_progress':
        return 'En cours';
      case 'todo':
        return 'À faire';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<String> _getCreatorName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ?? data?['displayName'] ?? 'Utilisateur';
      }
      return 'Utilisateur';
    } catch (e) {
      return 'Utilisateur';
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ?? data?['displayName'] ?? 'Utilisateur $userId';
      }
      return 'Utilisateur $userId';
    } catch (e) {
      return 'Utilisateur $userId';
    }
  }
}

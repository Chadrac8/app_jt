import 'package:flutter/material.dart';
import '../models/form_model.dart';
import '../../theme.dart';

class FormCard extends StatefulWidget {
  final FormModel form;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onCopyUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const FormCard({
    super.key,
    required this.form,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onSelectionChanged,
    required this.onCopyUrl,
    this.onEdit,
    this.onDuplicate,
    this.onArchive,
    this.onDelete,
  });

  @override
  State<FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<FormCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Color get _statusColor {
    switch (widget.form.status) {
      case 'brouillon': return AppTheme.warningColor;
      case 'publie': return AppTheme.successColor;
      case 'archive': return AppTheme.textTertiaryColor;
      default: return AppTheme.textSecondaryColor;
    }
  }

  IconData get _statusIcon {
    switch (widget.form.status) {
      case 'brouillon': return Icons.edit;
      case 'publie': return Icons.public;
      case 'archive': return Icons.archive;
      default: return Icons.help_outline;
    }
  }

  IconData get _accessibilityIcon {
    switch (widget.form.accessibility) {
      case 'public': return Icons.public;
      case 'membres': return Icons.people;
      case 'groupe': return Icons.group;
      case 'role': return Icons.admin_panel_settings;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: widget.isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (widget.isSelectionMode) ...[
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) => widget.onSelectionChanged(value ?? false),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon,
                                size: 14,
                                color: AppTheme.white100,
                              ),
                              const SizedBox(width: AppTheme.spaceXSmall),
                              Text(
                                widget.form.statusLabel,
                                style: const TextStyle(
                                  color: AppTheme.white100,
                                  fontSize: AppTheme.fontSize12,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _accessibilityIcon,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: AppTheme.spaceXSmall),
                              Text(
                                widget.form.accessibilityLabel,
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: AppTheme.fontSize12,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isSelectionMode)
                    PopupMenuButton<String>(
                      onSelected: _handleAction,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Modifier'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (widget.form.isPublished)
                          const PopupMenuItem(
                            value: 'copy_url',
                            child: ListTile(
                              leading: Icon(Icons.link),
                              title: Text('Copier le lien'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: ListTile(
                            leading: Icon(Icons.content_copy),
                            title: Text('Dupliquer'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (widget.form.status != 'archive')
                          const PopupMenuItem(
                            value: 'archive',
                            child: ListTile(
                              leading: Icon(Icons.archive),
                              title: Text('Archiver'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: AppTheme.errorColor),
                            title: Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      child: const Icon(
                        Icons.more_vert,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
            
            // Form content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.form.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (widget.form.description.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      widget.form.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  // Stats and info
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.quiz,
                        label: '${widget.form.fields.where((f) => f.isInputField).length} champs',
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      if (widget.form.hasSubmissionLimit)
                        _buildInfoChip(
                          icon: Icons.people,
                          label: 'Max ${widget.form.submissionLimit}',
                          color: AppTheme.warningColor,
                        ),
                      const Spacer(),
                      Text(
                        _formatDate(widget.form.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  // Publication dates
                  if (widget.form.publishDate != null || widget.form.closeDate != null) ...[
                    const SizedBox(height: AppTheme.space12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.form.publishDate != null)
                          _buildDateChip(
                            icon: Icons.schedule,
                            label: 'Publié le ${_formatDate(widget.form.publishDate!)}',
                            color: AppTheme.successColor,
                          ),
                        if (widget.form.closeDate != null)
                          _buildDateChip(
                            icon: Icons.event_busy,
                            label: 'Ferme le ${_formatDate(widget.form.closeDate!)}',
                            color: AppTheme.errorColor,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSize10,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        widget.onEdit?.call();
        break;
      case 'copy_url':
        widget.onCopyUrl();
        break;
      case 'duplicate':
        _showDuplicateConfirmation();
        break;
      case 'archive':
        _showArchiveConfirmation();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDuplicateConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dupliquer le formulaire'),
        content: Text(
          'Voulez-vous créer une copie du formulaire "${widget.form.title}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDuplicate?.call();
            },
            child: const Text('Dupliquer'),
          ),
        ],
      ),
    );
  }

  void _showArchiveConfirmation() {
    final isArchived = widget.form.isArchived;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArchived ? 'Restaurer le formulaire' : 'Archiver le formulaire'),
        content: Text(
          isArchived
              ? 'Voulez-vous restaurer le formulaire "${widget.form.title}" ?'
              : 'Voulez-vous archiver le formulaire "${widget.form.title}" ?\n\nLe formulaire ne sera plus accessible au public mais les données seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onArchive?.call();
            },
            child: Text(isArchived ? 'Restaurer' : 'Archiver'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le formulaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer définitivement le formulaire "${widget.form.title}" ?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible. Toutes les réponses associées seront également supprimées.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme.dart';

class ActionStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ActionStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: AppTheme.fontBold,
                  color: color,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spaceXSmall),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ActionStatsGrid extends StatelessWidget {
  final int totalActions;
  final int activeActions;
  final int inactiveActions;
  final int totalGroups;
  final Map<String, int> actionsByType;
  final Map<String, int> actionsByCategory;

  const ActionStatsGrid({
    Key? key,
    required this.totalActions,
    required this.activeActions,
    required this.inactiveActions,
    required this.totalGroups,
    required this.actionsByType,
    required this.actionsByCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _getCrossAxisCount(context),
      childAspectRatio: 1.5,
      mainAxisSpacing: AppTheme.spaceSmall,
      crossAxisSpacing: AppTheme.spaceSmall,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ActionStatsCard(
          title: 'Total Actions',
          value: totalActions.toString(),
          icon: Icons.apps,
          color: AppTheme.primaryColor,
          subtitle: 'Toutes catégories',
        ),
        ActionStatsCard(
          title: 'Actions Actives',
          value: activeActions.toString(),
          icon: Icons.check_circle,
          color: AppTheme.successColor,
          subtitle: '${_getPercentage(activeActions, totalActions)}% du total',
          trailing: Icon(
            Icons.trending_up,
            color: AppTheme.successColor,
            size: 16,
          ),
        ),
        ActionStatsCard(
          title: 'Actions Inactives',
          value: inactiveActions.toString(),
          icon: Icons.cancel,
          color: AppTheme.warningColor,
          subtitle: '${_getPercentage(inactiveActions, totalActions)}% du total',
          trailing: Icon(
            Icons.trending_down,
            color: AppTheme.warningColor,
            size: 16,
          ),
        ),
        ActionStatsCard(
          title: 'Groupes',
          value: totalGroups.toString(),
          icon: Icons.group_work,
          color: AppTheme.secondaryColor,
          subtitle: 'Catégories organisées',
        ),
        
        // Stats par type
        ...actionsByType.entries.map((entry) => ActionStatsCard(
          title: _getActionTypeLabel(entry.key),
          value: entry.value.toString(),
          icon: _getActionTypeIcon(entry.key),
          color: _getActionTypeColor(entry.key),
          subtitle: '${_getPercentage(entry.value, totalActions)}% du total',
        )),
        
        // Stats par catégorie (top 3)
        ..._getTopCategories()
          .map((entry) => ActionStatsCard(
            title: _getCategoryLabel(entry.key),
            value: entry.value.toString(),
            icon: _getCategoryIcon(entry.key),
            color: _getCategoryColor(entry.key),
            subtitle: '${_getPercentage(entry.value, totalActions)}% du total',
          )),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  List<MapEntry<String, int>> _getTopCategories() {
    final sortedEntries = actionsByCategory.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).toList();
  }

  String _getPercentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).round().toString();
  }

  String _getActionTypeLabel(String actionType) {
    switch (actionType) {
      case 'navigation':
        return 'Navigation';
      case 'form':
        return 'Formulaire';
      case 'external':
        return 'Externe';
      case 'contact':
        return 'Contact';
      case 'info':
        return 'Information';
      default:
        return actionType;
    }
  }

  IconData _getActionTypeIcon(String actionType) {
    switch (actionType) {
      case 'navigation':
        return Icons.navigation;
      case 'form':
        return Icons.edit_note;
      case 'external':
        return Icons.open_in_new;
      case 'contact':
        return Icons.contact_phone;
      case 'info':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'navigation':
        return AppTheme.primaryColor;
      case 'form':
        return AppTheme.secondaryColor;
      case 'external':
        return AppTheme.warningColor;
      case 'contact':
        return AppTheme.tertiaryColor;
      case 'info':
        return AppTheme.infoColor;
      default:
        return AppTheme.grey600;
    }
  }

  String _getCategoryLabel(String category) {
    const categoryLabels = {
      'seigneur': 'Seigneur',
      'pasteur': 'Pasteur',
      'culte': 'Culte',
      'formation': 'Formation',
      'communaute': 'Communauté',
      'general': 'Général',
    };
    return categoryLabels[category] ?? category;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'seigneur':
        return Icons.church;
      case 'pasteur':
        return Icons.person;
      case 'culte':
        return Icons.celebration;
      case 'formation':
        return Icons.school;
      case 'communaute':
        return Icons.groups;
      case 'general':
        return Icons.category;
      default:
        return Icons.label;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'seigneur':
        return AppTheme.primaryColor;
      case 'pasteur':
        return AppTheme.secondaryColor;
      case 'culte':
        return AppTheme.tertiaryColor;
      case 'formation':
        return AppTheme.infoColor;
      case 'communaute':
        return AppTheme.successColor;
      case 'general':
        return AppTheme.grey600;
      default:
        return AppTheme.grey500;
    }
  }
}
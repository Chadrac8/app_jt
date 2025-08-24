import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/home_widget_model.dart';

class HomeWidgetRenderer extends StatelessWidget {
  final HomeWidgetModel widget;
  final bool isPreview;

  const HomeWidgetRenderer({
    super.key,
    required this.widget,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && !isPreview) {
      return const SizedBox.shrink();
    }

    switch (widget.type) {
      case 'quick_action':
        return _buildQuickActionWidget(context);
      case 'verse_card':
        return _buildVerseCardWidget(context);
      case 'sermon_card':
        return _buildSermonCardWidget(context);
      case 'donation_card':
        return _buildDonationCardWidget(context);
      case 'text_card':
        return _buildTextCardWidget(context);
      default:
        return _buildDefaultWidget(context);
    }
  }

  Widget _buildQuickActionWidget(BuildContext context) {
    final config = widget.configuration;
    final actions = config['actions'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...actions.map<Widget>((action) => _buildQuickActionItem(context, action)),
          ])));
  }

  Widget _buildQuickActionItem(BuildContext context, Map<String, dynamic> action) {
    final iconName = action['icon'] as String?;
    final color = action['color'] != null ? _parseColor(action['color']) : AppTheme.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isPreview ? null : () => _handleAction(context, action['action']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(_getIconData(iconName), color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor)),
                    if (action['subtitle'] != null)
                      Text(
                        action['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor)),
                  ])),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiaryColor),
            ]))));
  }

  Widget _buildVerseCardWidget(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor)),
              ]),
            const SizedBox(height: 16),
            Text(
              '"Car Dieu a tant aimé le monde qu\'il a donné son Fils unique..."',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 12),
            Text(
              'Jean 3:16',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor)),
          ])));
  }

  Widget _buildSermonCardWidget(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: AppTheme.primaryColor))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                if (widget.description != null)
                  Text(
                    widget.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor)),
              ])),
        ]));
  }

  Widget _buildDonationCardWidget(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor)),
              ]),
            const SizedBox(height: 12),
            if (widget.description != null)
              Text(
                widget.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPreview ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('Faire un don'))),
          ])));
  }

  Widget _buildTextCardWidget(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
            if (widget.description != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.description!,
                style: Theme.of(context).textTheme.bodyMedium),
            ],
          ])));
  }

  Widget _buildDefaultWidget(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Text(
              'Type: ${widget.type}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiaryColor)),
          ])));
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'location_on':
        return Icons.location_on;
      case 'favorite':
        return Icons.favorite;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'group':
        return Icons.group;
      case 'music_note':
        return Icons.music_note;
      case 'book':
        return Icons.book;
      default:
        return Icons.help_outline;
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return AppTheme.primaryColor;
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  void _handleAction(BuildContext context, Map<String, dynamic>? action) {
    if (action == null) return;
    
    final type = action['type'] as String?;
    final route = action['route'] as String?;
    
    if (type == 'internal' && route != null) {
      Navigator.pushNamed(context, route);
    }
  }
}

import 'package:flutter/material.dart';
import '../routes/simple_routes.dart';
import '../../theme.dart';

class CustomPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showLogo;
  final VoidCallback? onLogoTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final List<Widget>? additionalActions;

  const CustomPageAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showLogo = false,
    this.onLogoTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.additionalActions,
  });

  @override
  State<CustomPageAppBar> createState() => _CustomPageAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56.0); // Hauteur standard Material Design
}

class _CustomPageAppBarState extends State<CustomPageAppBar> {
  bool _useBackButton = true;

  @override
  void initState() {
    super.initState();
    _useBackButton = widget.showBackButton;
  }

  void _toggleLeading() {
    setState(() {
      _useBackButton = !_useBackButton;
    });
  }

  Widget _buildLeading() {
    if (_useBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Retour',
      );
    } else if (widget.showLogo) {
      return _buildLogoWidget();
    } else {
      return Container();
    }
  }

  Widget _buildLogoWidget() {
    return InkWell(
      onTap: widget.onLogoTap,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        child: const Icon(
          Icons.church,
          size: 28,
          color: AppTheme.white100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      toolbarHeight: 56.0, // Hauteur standard Material Design (était 44 - trop petit)
      title: GestureDetector(
        onDoubleTap: _toggleLeading,
        child: Text(
          widget.title,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
      ),
      backgroundColor: theme.primaryColor,
      foregroundColor: AppTheme.white100,
      elevation: 2,
      leading: _buildLeading(),
      centerTitle: true,
      actions: [
        // Icône de notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: widget.onNotificationTap ?? () {
            // Navigation vers les notifications
            Navigator.of(context).pushNamed('/member/notifications');
          },
          tooltip: 'Notifications',
        ),
        // Icône de profil
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: widget.onProfileTap ?? () {
            // Navigation vers le profil
            Navigator.of(context).pushNamed('/member/profile');
          },
          tooltip: 'Profil',
        ),
        // Actions supplémentaires si fournies
        if (widget.additionalActions != null)
          ...widget.additionalActions!,
        const SizedBox(width: 8), // Espacement pour le bord
      ],
    );
  }
}

/// Version simplifiée de la barre d'application pour les pages membres
class SimpleMemberAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;

  const SimpleMemberAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onNotificationTap,
    this.onProfileTap,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0); // Hauteur standard Material Design

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      toolbarHeight: 56.0, // Hauteur standard Material Design (était 44 - trop petit)
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
      backgroundColor: theme.primaryColor,
      foregroundColor: AppTheme.white100,
      elevation: 1,
      leading: showBackButton 
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour',
          )
        : null,
      centerTitle: true,
      actions: [
        // Icône de notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onNotificationTap ?? () {
            // Navigation vers les notifications
            Navigator.of(context).pushNamed('/member/notifications');
          },
          tooltip: 'Notifications',
        ),
        // Icône de profil
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: onProfileTap ?? () {
            // Navigation vers le profil
            Navigator.of(context).pushNamed('/member/profile');
          },
          tooltip: 'Profil',
        ),
        // Actions personnalisées
        if (actions != null) ...actions!,
        const SizedBox(width: 8), // Espacement pour le bord
      ],
    );
  }
}

/// Barre d'application moderne avec style élégant
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double elevation;

  const ModernAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72.0 : 56.0); // Hauteurs standard Material Design

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      toolbarHeight: subtitle != null ? 72.0 : 56.0, // Hauteurs standard Material Design
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.white100.withOpacity(0.8),
                fontWeight: AppTheme.fontRegular,
              ),
            ),
        ],
      ),
      backgroundColor: backgroundColor ?? theme.primaryColor,
      foregroundColor: AppTheme.white100,
      elevation: elevation,
      leading: leading ?? (showBackButton 
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Retour',
          )
        : null),
      centerTitle: false,
      actions: actions,
    );
  }
}
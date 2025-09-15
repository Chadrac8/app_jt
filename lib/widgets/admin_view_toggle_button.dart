import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/roles/services/permission_provider.dart';
import '../widgets/admin_navigation_wrapper.dart';

/// Widget bouton pour basculer vers la vue administrateur
/// Ne s'affiche que si l'utilisateur a des privilèges administrateur
class AdminViewToggleButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  
  const AdminViewToggleButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.iconSize = 20,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, child) {
        // Vérifier si l'utilisateur a des privilèges administrateur
        // TEST TEMPORAIRE - Force l'affichage pour debug
        final hasAdminRole = true; // permissionProvider.hasAdminRole();
        
        if (!hasAdminRole) {
          return const SizedBox.shrink(); // N'affiche rien si pas admin
        }
        
        return Container(
          margin: margin ?? const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNavigationWrapper(),
                ),
              );
            },
            tooltip: 'Vue Administrateur',
            iconSize: iconSize,
            color: iconColor ?? Colors.white,
          ),
        );
      },
    );
  }
}

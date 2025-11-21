import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/roles/providers/permission_provider.dart';
import '../widgets/admin_navigation_wrapper.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';

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
    // Méthode de secours : vérifier directement avec AuthService
    final hasDirectAdminRole = AuthService.hasRole('admin') || 
                              AuthService.hasRole('pastor') ||
                              AuthService.hasPermission('admin_access');
    
    if (hasDirectAdminRole) {
      print('✅ AdminViewToggleButton - Accès admin détecté via AuthService');
      return Container(
        margin: margin ?? const EdgeInsets.only(right: 8),
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
          color: iconColor ?? AppTheme.white100,
        ),
      );
    }
    
    // Méthode principale avec PermissionProvider
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, child) {
        // Vérifier si l'utilisateur a des privilèges administrateur
        return FutureBuilder<bool>(
          future: permissionProvider.hasAdminRole(),
          builder: (context, snapshot) {
            final hasAdminRole = snapshot.data ?? false;
            
            // Debug: Afficher le statut du bouton
            print('🔍 AdminViewToggleButton - PermissionProvider hasAdminRole: $hasAdminRole, connectionState: ${snapshot.connectionState}, error: ${snapshot.error}');
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Si on attend et qu'on n'a pas détecté d'accès direct, ne rien afficher
              return const SizedBox.shrink();
            }
            
            if (!hasAdminRole) {
              return const SizedBox.shrink(); // N'affiche rien si pas admin
            }
        
            return Container(
              margin: margin ?? const EdgeInsets.only(right: 8),
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
                color: iconColor ?? AppTheme.white100,
              ),
            );
          },
        );
      },
    );
  }
}

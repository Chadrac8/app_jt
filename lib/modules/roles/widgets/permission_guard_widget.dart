import 'package:flutter/material.dart';

/// Widget de protection d'accès basé sur les permissions
class PermissionGuardWidget extends StatelessWidget {
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const PermissionGuardWidget({
    super.key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    // Pour l'instant, on affiche toujours l'enfant
    // Dans une implémentation complète, vous devriez vérifier
    // les permissions via votre service de permissions
    return child;
    
    // Implémentation complète avec vérification des permissions :
    /*
    return Consumer<PermissionProvider>(
      builder: (context, provider, _) {
        final hasPermission = provider.hasPermission(requiredPermission);
        
        if (hasPermission) {
          return child;
        }
        
        if (showFallback && fallback != null) {
          return fallback!;
        }
        
        return const SizedBox.shrink();
      },
    );
    */
  }
}
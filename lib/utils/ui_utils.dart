import 'package:flutter/material.dart';

/// Service de gestion des notifications optimisé
class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();
  
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey => 
      _scaffoldMessengerKey;
  
  static void showSuccess(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green[600],
      icon: Icons.check_circle,
      duration: duration ?? const Duration(seconds: 2),
    );
  }
  
  static void showError(String message, {Duration? duration, VoidCallback? onRetry}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red[600],
      icon: Icons.error,
      duration: duration ?? const Duration(seconds: 4),
      action: onRetry != null
          ? SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }
  
  static void showWarning(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange[600],
      icon: Icons.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  static void showInfo(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue[600],
      icon: Icons.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  static void showLoading(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 30), // Long duration for loading
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
  static void hideCurrentSnackBar() {
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }
  
  static void _showSnackBar({
    required String message,
    required Color? backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Widget de dialog de confirmation optimisé
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
  
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }
}

/// Widget de loading overlay optimisé
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;
  final Color? backgroundColor;
  
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (loadingText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          loadingText!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget de bouton d'action flottant adaptatif
class AdaptiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final bool isExtended;
  final bool isLoading;
  
  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.isExtended = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    if (isLoading) {
      return FloatingActionButton(
        onPressed: null,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    
    if (isExtended && !isSmallScreen && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
      );
    }
    
    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

/// Widget de responsive grid pour organiser les éléments
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int minItemsPerRow;
  final int maxItemsPerRow;
  final double minItemWidth;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.minItemsPerRow = 1,
    this.maxItemsPerRow = 4,
    this.minItemWidth = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (spacing * 2);
    
    // Calculer le nombre d'éléments par ligne
    int itemsPerRow = (availableWidth / minItemWidth).floor();
    itemsPerRow = itemsPerRow.clamp(minItemsPerRow, maxItemsPerRow);
    
    // Organiser les enfants en lignes
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += itemsPerRow) {
      final rowChildren = children.skip(i).take(itemsPerRow).toList();
      
      // Compléter la ligne si nécessaire
      while (rowChildren.length < itemsPerRow && i + rowChildren.length < children.length) {
        rowChildren.add(const SizedBox.shrink());
      }
      
      rows.add(
        Row(
          children: rowChildren
              .map((child) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                      child: child,
                    ),
                  ))
              .toList(),
        ),
      );
    }
    
    return Column(
      children: rows
          .map((row) => Padding(
                padding: EdgeInsets.symmetric(vertical: runSpacing / 2),
                child: row,
              ))
          .toList(),
    );
  }
}

/// Extension pour les validations d'état
extension FormStateExtension on GlobalKey<FormState> {
  bool validateAndSave() {
    final form = currentState;
    if (form == null) return false;
    
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }
  
  void resetForm() {
    currentState?.reset();
  }
  
  bool isValid() {
    return currentState?.validate() ?? false;
  }
}

/// Mixin pour gérer la navigation avec gestion des changements non sauvegardés
mixin NavigationGuard<T extends StatefulWidget> on State<T> {
  bool get hasUnsavedChanges;
  
  Future<bool> _onWillPop() async {
    if (!hasUnsavedChanges) return true;
    
    final result = await ConfirmationDialog.show(
      context,
      title: 'Modifications non sauvegardées',
      content: 'Vous avez des modifications non sauvegardées. Voulez-vous quitter sans sauvegarder ?',
      confirmText: 'Quitter',
      cancelText: 'Rester',
      isDestructive: true,
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: buildContent(context),
    );
  }
  
  Widget buildContent(BuildContext context);
}
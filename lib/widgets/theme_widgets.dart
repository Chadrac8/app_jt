import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' as providers;
import '../theme.dart';

/// Widget de bouton pour basculer rapidement entre les thèmes
class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  final EdgeInsets? padding;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.iconSize = 24.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        if (showLabel) {
          return _buildButtonWithLabel(context, themeProvider, isDark);
        } else {
          return _buildIconButton(context, themeProvider, isDark);
        }
      },
    );
  }

  Widget _buildIconButton(
    BuildContext context, 
    providers.ThemeProvider themeProvider, 
    bool isDark,
  ) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return RotationTransition(
            turns: animation,
            child: child,
          );
        },
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey<bool>(isDark),
          size: iconSize,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onPressed: () => _toggleTheme(themeProvider),
      tooltip: isDark ? 'Activer le thème clair' : 'Activer le thème sombre',
      padding: padding,
    );
  }

  Widget _buildButtonWithLabel(
    BuildContext context, 
    providers.ThemeProvider themeProvider, 
    bool isDark,
  ) {
    return FilledButton.icon(
      onPressed: () => _toggleTheme(themeProvider),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey<bool>(isDark),
          size: iconSize,
        ),
      ),
      label: Text(
        isDark ? 'Mode clair' : 'Mode sombre',
        style: TextStyle(
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
      style: FilledButton.styleFrom(
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
      ),
    );
  }

  void _toggleTheme(providers.ThemeProvider themeProvider) {
    // Basculer entre clair et sombre (pas automatique)
    final newMode = themeProvider.themeMode == providers.ThemeMode.light 
        ? providers.ThemeMode.dark 
        : providers.ThemeMode.light;
    
    themeProvider.setThemeMode(newMode);
  }
}

/// Widget de sélecteur de thème complet (pour les paramètres)
class ThemeSelector extends StatelessWidget {
  final bool showPreview;

  const ThemeSelector({
    super.key,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Thème de l\'application',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Options de thème
                _buildThemeOption(
                  context,
                  themeProvider,
                  providers.ThemeMode.light,
                  'Thème clair',
                  'Interface claire et lumineuse',
                  Icons.light_mode,
                ),
                
                _buildThemeOption(
                  context,
                  themeProvider,
                  providers.ThemeMode.dark,
                  'Thème sombre',
                  'Interface sombre, économe en énergie',
                  Icons.dark_mode,
                ),
                
                _buildThemeOption(
                  context,
                  themeProvider,
                  providers.ThemeMode.system,
                  'Automatique',
                  'Suit les paramètres de votre appareil',
                  Icons.brightness_auto,
                ),
                
                if (showPreview && themeProvider.themeMode != providers.ThemeMode.system)
                  _buildThemePreview(context, themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    providers.ThemeProvider themeProvider,
    providers.ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return RadioListTile<providers.ThemeMode>(
      value: mode,
      groupValue: themeProvider.themeMode,
      onChanged: (value) {
        if (value != null) {
          themeProvider.setThemeMode(value);
        }
      },
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildThemePreview(
    BuildContext context,
    providers.ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;
    final previewColorScheme = isDark 
        ? AppTheme.darkTheme.colorScheme 
        : AppTheme.lightTheme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: previewColorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: previewColorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu du thème',
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontSemiBold,
              color: previewColorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: previewColorScheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Bouton',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize11,
                    color: previewColorScheme.onPrimary,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              Icon(
                Icons.favorite,
                color: previewColorScheme.primary,
                size: 16,
              ),
              
              const Spacer(),
              
              Text(
                isDark ? '🌙 Sombre' : '☀️ Clair',
                style: TextStyle(
                  fontSize: AppTheme.fontSize12,
                  color: previewColorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bouton flottant pour basculer le thème
class ThemeToggleFAB extends StatelessWidget {
  final VoidCallback? onPressed;

  const ThemeToggleFAB({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        
        return FloatingActionButton.small(
          onPressed: onPressed ?? () {
            themeProvider.toggleTheme();
            
            // Afficher un feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: AppTheme.white,
                      size: 18,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Thème ${isDark ? 'clair' : 'sombre'} activé',
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
            );
          },
          heroTag: 'theme_toggle_fab',
          tooltip: isDark ? 'Activer le thème clair' : 'Activer le thème sombre',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey<bool>(isDark),
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';
import '../providers/theme_provider.dart' as providers;

class MemberSettingsPage extends StatefulWidget {
  const MemberSettingsPage({super.key});

  @override
  State<MemberSettingsPage> createState() => _MemberSettingsPageState();
}

class _MemberSettingsPageState extends State<MemberSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  
  // Paramètres de notification
  bool _enableNotifications = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  
  // Paramètres d'affichage
  String _language = 'Français';
  
  // Statistiques
  int _shareCount = 0;
  
  final List<String> _availableLanguages = [
    'Français',
    'English',
    'Español',
    'Português',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _enableNotifications = prefs.getBool('enable_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        
        _language = prefs.getString('language') ?? 'Français';
        
        _shareCount = prefs.getInt('app_share_count') ?? 0;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les paramètres de notification
      await prefs.setBool('enable_notifications', _enableNotifications);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);
      
      // Sauvegarder la langue (le thème est géré par ThemeProvider)
      await prefs.setString('language', _language);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                const Text('Paramètres sauvegardés avec succès'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: AppTheme.white,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('Erreur lors de la sauvegarde : $e')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
    
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _changeEmail() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangeEmailDialog(),
    );
    
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email modifié avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est définitive et irréversible.',
              style: TextStyle(
                fontWeight: AppTheme.fontBold,
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(height: AppTheme.spaceMedium),
            Text('Toutes vos données seront supprimées :'),
            SizedBox(height: AppTheme.spaceSmall),
            Text('• Profil et informations personnelles'),
            Text('• Historique des événements'),
            Text('• Réponses aux formulaires'),
            Text('• Historique des services'),
            Text('• Tous vos fichiers et images'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'Notre politique de confidentialité décrit comment nous collectons, '
            'utilisons et protégeons vos informations personnelles.\n\n'
            'Nous nous engageons à protéger votre vie privée et à utiliser vos '
            'données de manière responsable et transparente.\n\n'
            'Pour plus de détails, visitez notre site web ou contactez-nous.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Ouvrir le lien vers la politique de confidentialité
            },
            child: const Text('Voir en ligne'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jubilé Tabernacle',
              style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
            ),
            SizedBox(height: AppTheme.spaceSmall),
            Text('Version: 1.0.0'),
            SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Application officielle du Jubilé Tabernacle.\n\n'
              'Restez connecté avec votre communauté, accédez aux ressources '
              'spirituelles et participez à la vie de l\'église.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: AppTheme.primaryColor),
            SizedBox(width: AppTheme.spaceSmall),
            Text('Partager l\'application'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aidez-nous à faire connaître Jubilé Tabernacle !',
              style: TextStyle(fontWeight: AppTheme.fontSemiBold),
            ),
            SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Votre partage permet à d\'autres personnes de découvrir notre communauté spirituelle et de bénéficier de nos ressources.',
            ),
            SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                Icon(Icons.group, size: 16, color: AppTheme.primaryColor),
                SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('Grandir en communauté')),
              ],
            ),
            SizedBox(height: AppTheme.spaceXSmall),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: AppTheme.primaryColor),
                SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('Partager la bénédiction')),
              ],
            ),
            SizedBox(height: AppTheme.spaceXSmall),
            Row(
              children: [
                Icon(Icons.connect_without_contact, size: 16, color: AppTheme.primaryColor),
                SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('Connecter les cœurs')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _performShare();
            },
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  Future<void> _performShare() async {
    try {
      const String shareText = 
          '🙏 Découvrez l\'application Jubilé Tabernacle !\n\n'
          '✨ Restez connecté avec votre communauté spirituelle :\n'
          '📖 Bible & Messages inspirants\n'
          '🏛️ Vie de l\'Église & Événements\n'
          '🍞 Pain Quotidien\n'
          '🙏 Prières & Témoignages\n'
          '🎵 Chants & Louanges\n\n'
          '💝 Une expérience spirituelle enrichissante vous attend !\n\n'
          '📱 Téléchargez gratuitement :\n'
          '🤖 Play Store : https://play.google.com/store/apps/details?id=com.jubile.tabernacle.france\n'
          '🍎 App Store : https://apps.apple.com/app/jubile-tabernacle-france/id123456789\n\n'
          '🌐 Site web : https://jubile-tabernacle-france.com\n\n'
          '#JubileTabernacle #Foi #Communauté #Spiritualité';
      
      await Share.share(
        shareText,
        subject: 'Jubilé Tabernacle - Application Mobile',
      );
      
      // Enregistrer l'action de partage
      final prefs = await SharedPreferences.getInstance();
      final shareCount = prefs.getInt('app_share_count') ?? 0;
      await prefs.setInt('app_share_count', shareCount + 1);
      
      // Mettre à jour l'interface
      setState(() {
        _shareCount = shareCount + 1;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.white100),
                SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('✅ Merci de partager l\'application !')),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppTheme.white100),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('❌ Erreur lors du partage: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: AppTheme.white100,
              onPressed: _performShare,
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer un feedback'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Partagez vos commentaires, suggestions ou signalez un problème...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Merci pour votre feedback !'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion : $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                children: [
                  _buildAccountSection(),
                  const SizedBox(height: AppTheme.spaceLarge),
                  _buildNotificationsSection(),
                  const SizedBox(height: AppTheme.spaceLarge),
                  _buildDisplaySection(),
                  const SizedBox(height: AppTheme.spaceLarge),
                  _buildInfoSection(),
                  const SizedBox(height: AppTheme.spaceLarge),
                  _buildDangerSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? headerColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: (headerColor ?? AppTheme.primaryColor).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: headerColor ?? AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                    color: headerColor ?? AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    final user = AuthService.currentUser;
    
    return _buildSectionCard(
      title: 'Compte',
      icon: Icons.account_circle,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Compte connecté'),
          subtitle: Text(user?.email ?? 'Non connecté'),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Changer d\'email'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _changeEmail,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Changer de mot de passe'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _changePassword,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSectionCard(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text('Activer les notifications'),
          subtitle: const Text('Recevoir toutes les notifications'),
          value: _enableNotifications,
          onChanged: (value) {
            setState(() {
              _enableNotifications = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Notifications par email'),
          subtitle: const Text('Recevoir les notifications par email'),
          value: _emailNotifications && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _emailNotifications = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Notifications push'),
          subtitle: const Text('Notifications en temps réel sur l\'appareil'),
          value: _pushNotifications && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _pushNotifications = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildSectionCard(
          title: 'Affichage',
          icon: Icons.display_settings,
          children: [
            // Sélecteur de mode de thème
            _buildThemeModeSelector(themeProvider),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Option langue
            _buildLanguageSelector(),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Informations sur les avantages des thèmes
            _buildThemeAdvantages(),
          ],
        );
      },
    );
  }

  Widget _buildThemeAdvantages() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Avantages des thèmes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTheme.fontSemiBold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          _buildAdvantageItem(
            icon: Icons.battery_saver,
            title: 'Économie d\'énergie',
            description: 'Le thème sombre consomme moins d\'énergie sur les écrans OLED',
          ),
          
          _buildAdvantageItem(
            icon: Icons.remove_red_eye,
            title: 'Confort visuel',
            description: 'Réduit la fatigue oculaire dans les environnements sombres',
          ),
          
          _buildAdvantageItem(
            icon: Icons.bedtime,
            title: 'Utilisation nocturne',
            description: 'Parfait pour la lecture et la méditation en soirée',
          ),
          
          _buildAdvantageItem(
            icon: Icons.auto_awesome,
            title: 'Thème automatique',
            description: 'S\'adapte automatiquement selon l\'heure et vos paramètres système',
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(width: AppTheme.spaceSmall),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(providers.ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          child: Row(
            children: [
              Icon(
                Icons.brightness_6,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
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
        ),
        
        const SizedBox(height: AppTheme.spaceSmall),
        
        // Options de thème
        RadioListTile<providers.ThemeMode>(
          title: const Text('Thème clair'),
          subtitle: const Text('Interface claire et lumineuse'),
          value: providers.ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
          secondary: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: Border.all(color: AppTheme.outline),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.light_mode,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
        ),
        
        RadioListTile<providers.ThemeMode>(
          title: const Text('Thème sombre'),
          subtitle: const Text('Interface sombre, idéale pour la nuit'),
          value: providers.ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
          secondary: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A110F),
              border: Border.all(color: const Color(0xFF534340)),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.dark_mode,
              color: Color(0xFFFFB4A9),
              size: 18,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
        ),
        
        RadioListTile<providers.ThemeMode>(
          title: const Text('Automatique'),
          subtitle: const Text('Suit les paramètres système'),
          value: providers.ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
          secondary: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.white,
                  Color(0xFF1A110F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppTheme.outline),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.brightness_auto,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
        ),
        
        // Aperçu du thème actuel
        if (themeProvider.themeMode != providers.ThemeMode.system)
          _buildThemePreview(themeProvider),
      ],
    );
  }

  Widget _buildThemePreview(providers.ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final previewColorScheme = isDark 
        ? AppTheme.darkTheme.colorScheme 
        : AppTheme.lightTheme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: previewColorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: previewColorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: previewColorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Aperçu du thème',
                style: TextStyle(
                  fontSize: AppTheme.fontSize12,
                  fontWeight: AppTheme.fontSemiBold,
                  color: previewColorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Aperçu des éléments
          Row(
            children: [
              // Bouton principal
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
                    fontSize: AppTheme.fontSize12,
                    color: previewColorScheme.onPrimary,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // Bouton secondaire
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: previewColorScheme.outline),
                ),
                child: Text(
                  'Contour',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize12,
                    color: previewColorScheme.onSurface,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Icône
              Icon(
                Icons.favorite,
                color: previewColorScheme.primary,
                size: 20,
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Texte d'aperçu
          Text(
            'Texte principal dans ce thème',
            style: TextStyle(
              fontSize: AppTheme.fontSize14,
              color: previewColorScheme.onSurface,
            ),
          ),
          
          Text(
            'Texte secondaire dans ce thème',
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              color: previewColorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Langue'),
      subtitle: Text(_language),
      trailing: PopupMenuButton<String>(
        initialValue: _language,
        onSelected: (String value) {
          setState(() {
            _language = value;
          });
        },
        itemBuilder: (BuildContext context) {
          return _availableLanguages.map((String language) {
            return PopupMenuItem<String>(
              value: language,
              child: Row(
                children: [
                  Text(language),
                  if (language == _language) ...[
                    const Spacer(),
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: const Icon(Icons.arrow_drop_down),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
    );
  }



  Widget _buildInfoSection() {
    return _buildSectionCard(
      title: 'Informations',
      icon: Icons.info_outline,
      children: [
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Politique de confidentialité'),
          subtitle: const Text('Consultez notre politique de confidentialité'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showPrivacyPolicy,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('À propos'),
          subtitle: const Text('Informations sur l\'application'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showAbout,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.share,
              color: AppTheme.primaryColor,
            ),
          ),
          title: const Text(
            'Partager l\'application',
            style: TextStyle(fontWeight: AppTheme.fontSemiBold),
          ),
          subtitle: Text(
            _shareCount > 0 
              ? 'Partagez la bénédiction avec vos proches\nVous avez partagé $_shareCount fois - Merci ! 🙏'
              : 'Partagez la bénédiction avec vos proches\nAidez-nous à grandir en communauté',
            style: const TextStyle(fontSize: AppTheme.fontSize13),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _shareApp,
          contentPadding: EdgeInsets.zero,
          isThreeLine: true,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('Feedback'),
          subtitle: const Text('Envoyez-nous vos commentaires'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _sendFeedback,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return _buildSectionCard(
      title: 'Zone de danger',
      icon: Icons.warning,
      headerColor: AppTheme.errorColor,
      children: [
        ListTile(
          leading: const Icon(Icons.logout, color: AppTheme.warningColor),
          title: const Text('Se déconnecter'),
          subtitle: const Text('Déconnecter ce compte'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _signOut,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
          title: const Text(
            'Supprimer mon compte',
            style: TextStyle(color: AppTheme.errorColor),
          ),
          subtitle: const Text('Suppression définitive et irréversible'),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.errorColor),
          onTap: _deleteAccount,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer de mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe actuel';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un nouveau mot de passe';
                }
                if (value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Implémenter le changement de mot de passe
              Navigator.pop(context, true);
            }
          },
          child: const Text('Modifier'),
        ),
      ],
    );
  }
}

class _ChangeEmailDialog extends StatefulWidget {
  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer d\'email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Nouvel email',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un email';
                }
                if (!value.contains('@')) {
                  return 'Veuillez saisir un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Implémenter le changement d'email
              Navigator.pop(context, true);
            }
          },
          child: const Text('Modifier'),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/action_service.dart';
import '../services/action_group_service.dart';
import '../../../pages/form_public_page.dart';
import '../../../pages/special_song_reservation_page.dart';

class PourVousTabDynamic extends StatefulWidget {
  const PourVousTabDynamic({Key? key}) : super(key: key);

  @override
  State<PourVousTabDynamic> createState() => _PourVousTabDynamicState();
}

class _PourVousTabDynamicState extends State<PourVousTabDynamic> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ActionService _actionService = ActionService();
  final ActionGroupService _groupService = ActionGroupService();
  
  List<PourVousAction> _actions = [];
  List<ActionGroup> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadData();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Charger les actions et groupes depuis Firebase
      final actionsStream = _actionService.getActiveActions();
      final groupsStream = _groupService.getActiveGroups();

      // Écouter les streams
      actionsStream.listen((actions) {
        if (mounted) {
          setState(() {
            _actions = actions;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur lors du chargement des actions: $error';
            _isLoading = false;
          });
        }
      });

      groupsStream.listen((groups) {
        if (mounted) {
          setState(() {
            _groups = groups;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur lors du chargement des groupes: $error';
            _isLoading = false;
          });
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(colorScheme),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Chargement des actions...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_actions.isEmpty) {
      return _buildEmptyState();
    }

    // Organiser les actions par groupe
    final actionsByGroup = _organizeActionsByGroup();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Afficher les actions par groupe
          ...actionsByGroup.entries.map((entry) {
            final groupName = entry.key;
            final actions = entry.value;
            
            return SliverToBoxAdapter(
              child: _buildActionGroup(groupName, actions, colorScheme),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucune action disponible',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Les actions seront bientôt disponibles',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<PourVousAction>> _organizeActionsByGroup() {
    final Map<String, List<PourVousAction>> actionsByGroup = {};
    
    for (final action in _actions) {
      final group = _groups.where((g) => g.id == action.groupId).firstOrNull;
      final groupName = group?.name ?? 'Général';
      
      actionsByGroup.putIfAbsent(groupName, () => []);
      actionsByGroup[groupName]!.add(action);
    }
    
    // Trier les actions dans chaque groupe par ordre
    for (final actions in actionsByGroup.values) {
      actions.sort((a, b) => a.order.compareTo(b.order));
    }
    
    return actionsByGroup;
  }

  Widget _buildActionGroup(String groupName, List<PourVousAction> actions, ColorScheme colorScheme) {
    final crossAxisCount = _getCrossAxisCount(context);
    final spacing = AppTheme.isApplePlatform ? 16.0 : 12.0; // Enhanced spacing for premium feel

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSmall,
        vertical: AppTheme.spaceSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: AppTheme.isApplePlatform ? 6.0 : 4.0,
              bottom: AppTheme.isApplePlatform ? 8.0 : 6.0,
              top: AppTheme.spaceSmall,
            ),
            child: Row(
              children: [
                // Elegant accent with gradient
                Container(
                  width: 5.0,
                  height: AppTheme.isApplePlatform ? 24.0 : 22.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                
                // Refined spacing
                SizedBox(width: AppTheme.isApplePlatform ? 16.0 : 14.0),
                
                // Premium section title
                Expanded(
                  child: Text(
                    groupName,
                    style: AppTheme.isApplePlatform
                        ? GoogleFonts.inter(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            height: 1.15,
                            color: colorScheme.onSurface,
                          )
                        : GoogleFonts.inter(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: colorScheme.onSurface,
                          ),
                  ),
                ),
                
                // Subtle decorative element
                Container(
                  width: 20.0,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(0.75),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXSmall),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: _getChildAspectRatio(context),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              return _buildActionCard(actions[index], colorScheme);
            },
          ),
          // Enhanced spacing between sections for better visual separation
          SizedBox(height: AppTheme.isApplePlatform ? 40.0 : 32.0),
        ],
      ),
    );
  }

  Widget _buildActionCard(PourVousAction action, ColorScheme colorScheme) {
    final actionColor = _getActionColor(action.color) ?? colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        // Subtle gradient overlay for premium feel
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.isApplePlatform ? 22.0 : 20.0,
        ),
        border: Border.all(
          color: AppTheme.isApplePlatform
              ? colorScheme.outline.withValues(alpha: 0.12)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: AppTheme.isApplePlatform ? 1.0 : 1.2,
        ),
        // Professional multi-layer shadows
        boxShadow: [
          // Primary depth shadow
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: AppTheme.isApplePlatform ? 0.12 : 0.08,
            ),
            offset: const Offset(0, 3),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          // Secondary ambient shadow
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: AppTheme.isApplePlatform ? 0.06 : 0.04,
            ),
            offset: const Offset(0, 1),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          AppTheme.isApplePlatform ? 22.0 : 20.0,
        ),
        child: InkWell(
          onTap: () => _handleActionTap(action),
          borderRadius: BorderRadius.circular(
            AppTheme.isApplePlatform ? 22.0 : 20.0,
          ),
          splashColor: actionColor.withValues(alpha: 0.12),
          highlightColor: actionColor.withValues(alpha: 0.08),
          hoverColor: actionColor.withValues(alpha: 0.04),
          child: Container(
            padding: EdgeInsets.all(AppTheme.isDesktop ? 16.0 : 14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Compact icon container for square cards
                Container(
                  width: AppTheme.isDesktop ? 48 : 42,
                  height: AppTheme.isDesktop ? 48 : 42,
                  decoration: BoxDecoration(
                    // Multi-layer gradient for depth
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 1.2,
                      colors: [
                        actionColor.withValues(alpha: 0.18),
                        actionColor.withValues(alpha: 0.12),
                        actionColor.withValues(alpha: 0.06),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.isApplePlatform ? 14.0 : 12.0,
                    ),
                    border: Border.all(
                      color: actionColor.withValues(alpha: 0.25),
                      width: AppTheme.isApplePlatform ? 1.0 : 0.8,
                    ),
                    // Subtle inner shadow for depth
                    boxShadow: [
                      BoxShadow(
                        color: actionColor.withValues(alpha: 0.08),
                        offset: const Offset(0, 1),
                        blurRadius: 6,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Icon(
                    action.icon,
                    color: actionColor,
                    size: AppTheme.isDesktop ? 24 : 22,
                  ),
                ),
                
                // Compact spacing for square format
                SizedBox(height: AppTheme.isApplePlatform ? 10.0 : 8.0),
                
                // Compact title for square cards
                Text(
                  action.title,
                  style: AppTheme.isApplePlatform 
                      ? GoogleFonts.inter(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          height: 1.15,
                          color: colorScheme.onSurface,
                        )
                      : GoogleFonts.inter(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: colorScheme.onSurface,
                        ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Tight spacing for square format
                const SizedBox(height: 4.0),
                
                // Centered description for square cards with 2-line guarantee
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Text(
                    action.description,
                    style: AppTheme.isApplePlatform
                        ? GoogleFonts.inter(
                            fontSize: 12.0,
                            letterSpacing: -0.1,
                            height: 1.2,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                          )
                        : GoogleFonts.inter(
                            fontSize: 12.0,
                            height: 1.2,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                          ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 3;
    if (width > 400) return 2;
    return 2;
  }

  double _getChildAspectRatio(BuildContext context) {
    // Cartes carrées avec ratio 1:1 pour un design équilibré
    return 1.0; // Cartes parfaitement carrées
  }

  Color? _getActionColor(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleActionTap(PourVousAction action) async {
    try {
      // Vibration haptique
      HapticFeedback.lightImpact();

      switch (action.actionType) {
        case 'navigation':
          _handleNavigation(action);
          break;
        case 'navigate_module':
          _handleNavigateModule(action);
          break;
        case 'external':
          _handleExternalLink(action);
          break;
        case 'form':
          _handleForm(action);
          break;
        case 'contact':
          _handleContact(action);
          break;
        case 'info':
          _handleInfo(action);
          break;
        case 'target_module':
          _handleTargetModule(action);
          break;
        default:
          _showSnackBar('Action non supportée: ${action.actionType}');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'exécution de l\'action: $e');
    }
  }

  void _handleNavigation(PourVousAction action) {
    final targetRoute = action.targetRoute;
    if (targetRoute == null || targetRoute.isEmpty) {
      _showSnackBar('Route de navigation non définie');
      return;
    }

    // Navigation vers la route spécifiée
    Navigator.pushNamed(context, targetRoute).catchError((e) {
      _showSnackBar('Impossible de naviguer vers: $targetRoute');
      return null;
    });
  }

  Future<void> _handleExternalLink(PourVousAction action) async {
    final url = action.actionData?['url'] as String?;
    if (url == null || url.isEmpty) {
      _showSnackBar('URL non définie');
      return;
    }

    try {
      final uri = Uri.parse(url);
      
      // Vérification et nettoyage de l'URL avant de l'ouvrir
      if (!uri.hasScheme) {
        _showSnackBar('URL invalide: $url');
        return;
      }
      
      // Configuration spéciale pour iOS pour éviter les erreurs de pasteboard
      final launchMode = Theme.of(context).platform == TargetPlatform.iOS 
          ? LaunchMode.externalApplication 
          : LaunchMode.platformDefault;
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: launchMode,
          webOnlyWindowName: '_blank',
        );
      } else {
        _showSnackBar('Impossible d\'ouvrir le lien: $url');
      }
    } catch (e) {
      // Log détaillé pour le debugging sans exposer l'erreur technique à l'utilisateur
      debugPrint('Erreur lors de l\'ouverture du lien: $e');
      _showSnackBar('Impossible d\'ouvrir ce lien');
    }
  }

  void _handleForm(PourVousAction action) {
    final module = action.actionData?['module'] as String?;
    final page = action.actionData?['page'] as String?;
    
    if (module == null || page == null) {
      _showSnackBar('Configuration de formulaire incomplète');
      return;
    }

    // Navigation vers le formulaire spécifique
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormPublicPage(
          formId: page,
        ),
      ),
    ).catchError((e) {
      _showSnackBar('Erreur lors de l\'ouverture du formulaire: $e');
      return null;
    });
  }

  Future<void> _handleContact(PourVousAction action) async {
    final contactType = action.actionData?['contactType'] as String?;
    final contactValue = action.actionData?['contactValue'] as String?;
    
    if (contactType == null || contactValue == null) {
      _showSnackBar('Information de contact manquante');
      return;
    }

    try {
      Uri uri;
      switch (contactType) {
        case 'email':
          uri = Uri.parse('mailto:$contactValue');
          break;
        case 'phone':
          uri = Uri.parse('tel:$contactValue');
          break;
        case 'sms':
          uri = Uri.parse('sms:$contactValue');
          break;
        default:
          _showSnackBar('Type de contact non supporté: $contactType');
          return;
      }

      // Configuration spéciale pour iOS pour éviter les erreurs de pasteboard
      final launchMode = Theme.of(context).platform == TargetPlatform.iOS 
          ? LaunchMode.externalApplication 
          : LaunchMode.platformDefault;

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: launchMode);
      } else {
        _showSnackBar('Impossible d\'initier le contact: $contactValue');
      }
    } catch (e) {
      // Log détaillé pour le debugging sans exposer l'erreur technique à l'utilisateur
      debugPrint('Erreur lors du contact: $e');
      _showSnackBar('Impossible d\'initier ce contact');
    }
  }

  void _handleInfo(PourVousAction action) {
    final infoText = action.actionData?['infoText'] as String? ?? action.description;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action.title),
        content: Text(infoText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleNavigateModule(PourVousAction action) {
    final targetModule = action.targetModule;
    if (targetModule == null || targetModule.isEmpty) {
      _showSnackBar('Module cible non spécifié');
      return;
    }

    try {
      // Mapper les noms de modules vers les routes définies dans l'application
      String? route = _mapModuleToRoute(targetModule);
      
      if (route != null) {
        // Navigation vers la route spécifique du module
        Navigator.of(context).pushNamed(route).catchError((e) {
          _showSnackBar('Impossible de naviguer vers le module $targetModule');
          return null;
        });
      } else {
        // Gérer la navigation vers les modules principaux (onglets)
        if (_handleMainTabNavigation(targetModule)) {
          return; // Navigation réussie vers un onglet principal
        }
        
        // Si aucune route spécifique, afficher un message informatif selon le module
        String message = _getNavigationHint(targetModule);
        _showSnackBar(message);
      }
    } catch (e) {
      _showSnackBar('Impossible de naviguer vers le module $targetModule: $e');
    }
  }

  String? _mapModuleToRoute(String module) {
    // Mapper les noms de modules vers les routes disponibles dans simple_routes.dart
    switch (module.toLowerCase()) {
      case 'groupes':
      case 'groups':
        return '/member/groups';
      case 'evenements':
      case 'events':
        return '/member/events';
      case 'services':
        return '/member/services';
      case 'formulaires':
      case 'forms':
        return '/member/forms';
      case 'taches':
      case 'tasks':
        return '/member/tasks';
      case 'rendezvous':
      case 'appointments':
        return '/member/appointments';
      case 'chants':
      case 'songs':
        // Le module songs n'a pas de route directe dans simple_routes.dart
        // Il est géré par le BottomNavigationWrapper
        return null;
      case 'bible':
        // Idem pour bible
        return null;
      case 'vie_eglise':
        // On est déjà dans vie_eglise
        return null;
      default:
        return null; // Pas de route connue
    }
  }

  bool _handleMainTabNavigation(String module) {
    // Tenter de naviguer vers les onglets principaux
    switch (module.toLowerCase()) {
      case 'chants':
      case 'songs':
        // Retourner à l'écran principal et sélectionner l'onglet chants
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/member/dashboard', 
          (route) => false,
          arguments: {'initialTab': 'songs'},
        );
        return true;
      case 'bible':
        // Retourner à l'écran principal et sélectionner l'onglet bible
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/member/dashboard', 
          (route) => false,
          arguments: {'initialTab': 'bible'},
        );
        return true;
      case 'vie_eglise':
        // On est déjà dans vie_eglise
        _showSnackBar('Vous êtes déjà dans le module Vie d\'église');
        return true;
      default:
        return false; // Pas un onglet principal connu
    }
  }

  String _getNavigationHint(String module) {
    switch (module.toLowerCase()) {
      case 'chants':
      case 'songs':
        return 'Utilisez l\'onglet "Chants" dans la navigation principale';
      case 'bible':
        return 'Utilisez l\'onglet "Bible" dans la navigation principale';
      case 'vie_eglise':
        return 'Vous êtes déjà dans le module Vie d\'église';
      default:
        return 'Module $module disponible dans la navigation principale';
    }
  }

  Future<void> _handleTargetModule(PourVousAction action) async {
    final actionData = action.actionData;
    if (actionData == null) {
      _showSnackBar('Configuration du module cible manquante');
      return;
    }

    final targetType = actionData['targetType'] as String?;
    if (targetType == null) {
      _showSnackBar('Type de module cible non spécifié');
      return;
    }

    try {
      switch (targetType) {
        case 'form':
          await _handleTargetModuleForm(actionData);
          break;
        case 'special_song':
          await _handleTargetModuleSpecialSong();
          break;
        default:
          _showSnackBar('Type de module cible non supporté: $targetType');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ouverture du module cible: $e');
    }
  }

  Future<void> _handleTargetModuleForm(Map<String, dynamic> actionData) async {
    final formId = actionData['formId'] as String?;
    if (formId == null || formId.isEmpty) {
      _showSnackBar('ID du formulaire non spécifié');
      return;
    }

    // Naviguer vers le formulaire spécifique
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormPublicPage(formId: formId),
      ),
    ).catchError((e) {
      _showSnackBar('Erreur lors de l\'ouverture du formulaire: $e');
      return null;
    });
  }

  Future<void> _handleTargetModuleSpecialSong() async {
    // Naviguer vers la page de réservation de chants spéciaux
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpecialSongReservationPage(),
      ),
    ).catchError((e) {
      _showSnackBar('Erreur lors de l\'ouverture de la réservation de chants: $e');
      return null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
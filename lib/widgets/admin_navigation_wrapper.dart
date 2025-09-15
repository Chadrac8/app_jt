import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/people_home_page.dart';
import '../pages/groups_home_page.dart';
import '../pages/events_home_page.dart';
import '../modules/services/views/services_home_page.dart';
import '../pages/forms_home_page.dart';
import '../pages/tasks_home_page.dart';




import '../pages/pages_home_page.dart';
import '../modules/songs/views/songs_home_page.dart';
import '../modules/bible/bible_admin_page.dart';
import '../modules/vie_eglise/views/vie_eglise_admin_view.dart';
import '../modules/message/views/message_admin_view.dart';

import '../pages/appointments_admin_page.dart';
import '../modules/roles/views/new_roles_management_screen.dart';
import '../pages/blog_home_page.dart';
import '../pages/prayers_home_page.dart';



import '../pages/admin/modules_configuration_page.dart';
import '../pages/initial_profile_setup_page.dart';

import '../widgets/member_view_toggle_button.dart';
import 'bottom_navigation_wrapper.dart';

class AdminNavigationWrapper extends StatefulWidget {
  final String initialRoute;

  const AdminNavigationWrapper({
    Key? key,
    this.initialRoute = 'dashboard',
  }) : super(key: key);

  @override
  State<AdminNavigationWrapper> createState() => _AdminNavigationWrapperState();
}

class _AdminNavigationWrapperState extends State<AdminNavigationWrapper> {
  String _currentRoute = 'dashboard';
  int _selectedIndex = 0;

  // Méthode pour vérifier si le profil est complet (synchronized with AuthWrapper)
  Future<bool> _isProfileComplete() async {
    try {
      final profile = await AuthService.getCurrentUserProfile();
      if (profile == null) return false;

      // Required fields for profile completion (synchronized with AuthWrapper)
      final hasFirstName = profile.firstName.isNotEmpty;
      final hasLastName = profile.lastName.isNotEmpty;
      final hasPhone = profile.phone != null && profile.phone!.isNotEmpty;
      final hasAddress = profile.address != null && profile.address!.isNotEmpty;
      final hasBirthDate = profile.birthDate != null;
      final hasGender = profile.gender != null && profile.gender!.isNotEmpty;
      
      final isComplete = hasFirstName && hasLastName && hasPhone && hasAddress && hasBirthDate && hasGender;
      
      if (!isComplete) {
        print('🔄 AdminNavigationWrapper: Profil incomplet détecté');
        print('  - Prénom: ${hasFirstName ? "✅" : "❌"}');
        print('  - Nom: ${hasLastName ? "✅" : "❌"}');
        print('  - Téléphone: ${hasPhone ? "✅" : "❌"}');
        print('  - Adresse: ${hasAddress ? "✅" : "❌"}');
        print('  - Date de naissance: ${hasBirthDate ? "✅" : "❌"}');
        print('  - Genre: ${hasGender ? "✅" : "❌"}');
      }
      
      return isComplete;
    } catch (e) {
      print('❌ Erreur lors de la vérification du profil dans AdminNavigationWrapper: $e');
      return false;
    }
  }

  // Pages principales de l'admin
  final List<AdminMenuItem> _primaryPages = [
    AdminMenuItem(
      route: 'dashboard',
      title: 'Dashboard',
      icon: Icons.dashboard,
      page: const AdminDashboardPage(),
    ),
    AdminMenuItem(
      route: 'people',
      title: 'Personnes',
      icon: Icons.people,
      page: const PeopleHomePage(),
    ),
    AdminMenuItem(
      route: 'groups',
      title: 'Groupes',
      icon: Icons.groups,
      page: const GroupsHomePage(),
    ),
    AdminMenuItem(
      route: 'events',
      title: 'Événements',
      icon: Icons.event,
      page: const EventsHomePage(),
    ),
    AdminMenuItem(
      route: 'blog',
      title: 'Blog',
      icon: Icons.article,
      page: const BlogHomePage(),
    ),
  ];

  // Pages secondaires (dans le menu "Plus")
  final List<AdminMenuItem> _secondaryPages = [
    AdminMenuItem(
      route: 'services',
      title: 'Services',
      icon: Icons.church,
      page: const ServicesHomePage(),
    ),
    AdminMenuItem(
      route: 'forms',
      title: 'Formulaires',
      icon: Icons.assignment,
      page: const FormsHomePage(),
    ),
    AdminMenuItem(
      route: 'tasks',
      title: 'Tâches',
      icon: Icons.task,
      page: const TasksHomePage(),
    ),

    AdminMenuItem(
      route: 'appointments',
      title: 'Rendez-vous',
      icon: Icons.schedule,
      page: const AppointmentsAdminPage(),
    ),
    AdminMenuItem(
      route: 'prayers',
      title: 'Mur de Prière',
      icon: Icons.pan_tool,
      page: const PrayersHomePage(),
    ),
    AdminMenuItem(
      route: 'vie-eglise',
      title: 'Vie de l\'Église',
      icon: Icons.church,
      page: const VieEgliseAdminView(),
    ),
    AdminMenuItem(
      route: 'message',
      title: 'Le Message',
      icon: Icons.audiotrack,
      page: const MessageAdminView(),
    ),
    AdminMenuItem(
      route: 'pages',
      title: 'Pages',
      icon: Icons.web,
      page: const PagesHomePage(),
    ),
    AdminMenuItem(
      route: 'songs',
      title: 'Cantiques',
      icon: Icons.music_note,
      page: const SongsHomePage(),
    ),
    AdminMenuItem(
      route: 'bible',
      title: 'La Bible',
      icon: Icons.menu_book,
      page: const BibleAdminPage(),
    ),

    AdminMenuItem(
      route: 'roles',
      title: 'Rôles',
      icon: Icons.admin_panel_settings,
      page: const NewRolesManagementScreen(),
    ),

    AdminMenuItem(
      route: 'modules-config',
      title: 'Configuration des Modules',
      icon: Icons.widgets,
      page: const ModulesConfigurationPage(),
    ),


  ];

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final index = _primaryPages.indexWhere((page) => page.route == _currentRoute);
    if (index != -1) {
      _selectedIndex = index;
    } else {
      // Si la route est dans les pages secondaires, on garde l'index actuel
      // mais on change juste la route
      _selectedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isProfileComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Si le profil n'est pas complet, rediriger vers la configuration
        if (snapshot.hasData && !snapshot.data!) {
          return const InitialProfileSetupPage();
        }
        
        // Si le profil est complet, afficher l'interface admin
        return Scaffold(
          body: _getCurrentPage(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _getCurrentPage() {
    // Chercher d'abord dans les pages principales
    final primaryPage = _primaryPages.firstWhere(
      (page) => page.route == _currentRoute,
      orElse: () => AdminMenuItem(
        route: '',
        title: '',
        icon: Icons.error,
        page: Container(),
      ),
    );

    if (primaryPage.route.isNotEmpty) {
      return primaryPage.page;
    }

    // Chercher dans les pages secondaires
    final secondaryPage = _secondaryPages.firstWhere(
      (page) => page.route == _currentRoute,
      orElse: () => AdminMenuItem(
        route: '',
        title: '',
        icon: Icons.error,
        page: Container(),
      ),
    );

    if (secondaryPage.route.isNotEmpty) {
      return secondaryPage.page;
    }

    // Page par défaut
    return const AdminDashboardPage();
  }

  Widget _buildBottomNavigationBar() {
    final items = List<BottomNavigationBarItem>.from(
      _primaryPages.map((page) => BottomNavigationBarItem(
        icon: Icon(page.icon),
        label: page.title,
      )),
    );

    // Ajouter le bouton "Plus" s'il y a des pages secondaires
    if (_secondaryPages.isNotEmpty) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz),
        label: 'Plus',
      ));
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex >= 0 && _selectedIndex < _primaryPages.length 
          ? _selectedIndex 
          : 0,
      onTap: _onNavItemTapped,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      items: items,
    );
  }

  void _onNavItemTapped(int index) {
    if (index < _primaryPages.length) {
      // Navigation vers une page principale
      setState(() {
        _currentRoute = _primaryPages[index].route;
        _selectedIndex = index;
      });
    } else {
      // Ouvrir le menu "Plus"
      _showMoreMenu();
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Titre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.more_horiz, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Plus de modules',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  // Bouton basculement vers vue membre
                  MemberViewToggleButton(
                    onToggle: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const BottomNavigationWrapper(initialRoute: 'dashboard'),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Grid des modules secondaires
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _secondaryPages.length,
                itemBuilder: (context, index) {
                  final page = _secondaryPages[index];
                  return _buildModuleCard(page);
                },
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(AdminMenuItem page) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _currentRoute = page.route;
          _selectedIndex = -1; // Désélectionner la bottom nav
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              page.icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              page.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminMenuItem {
  final String route;
  final String title;
  final IconData icon;
  final Widget page;

  const AdminMenuItem({
    required this.route,
    required this.title,
    required this.icon,
    required this.page,
  });
}
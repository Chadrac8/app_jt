import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../models/user_role_model.dart';
import '../services/enhanced_permission_provider.dart';
import '../services/roles_permissions_service.dart';

/// Écran d'assignation de rôles aux utilisateurs avec Material Design 3
class RoleAssignmentScreen extends StatefulWidget {
  const RoleAssignmentScreen({super.key});

  @override
  State<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends State<RoleAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Charger les rôles au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PermissionProvider>().loadRoles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignation des Rôles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Par Utilisateur',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Assignations en masse',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: Assignation par utilisateur
          const UserRoleAssignmentWidget(),
          
          // Onglet 2: Assignations en masse
          const BulkRoleAssignmentWidget(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/permission_provider.dart';
import '../widgets/user_role_assignment_widget.dart';
import '../widgets/bulk_role_assignment_widget.dart';

/// Écran principal pour l'assignation de rôles
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

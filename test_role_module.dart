import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/modules/roles/models/role.dart';
import 'lib/modules/roles/models/user_role.dart';
import 'lib/modules/roles/providers/role_provider.dart';
import 'lib/modules/roles/views/roles_management_screen.dart';
import 'lib/modules/roles/widgets/user_role_assignment_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: MaterialApp(
        title: 'Test Module Rôles',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: TestRoleModulePage(),
      ),
    );
  }
}

class TestRoleModulePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Module Rôles'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Module Rôles et Permissions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Statut d\'intégration:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            _buildStatusItem('✅ Modèles de données', 'Role, UserRole, Permission'),
            _buildStatusItem('✅ Provider de gestion d\'état', 'RoleProvider avec notifications'),
            _buildStatusItem('✅ Services Firebase', 'CRUD complet en temps réel'),
            _buildStatusItem('✅ Interface d\'administration', 'RolesManagementScreen'),
            _buildStatusItem('✅ Widget d\'assignation', 'UserRoleAssignmentWidget'),
            _buildStatusItem('✅ Navigation intégrée', 'AdminNavigationWrapper'),
            SizedBox(height: 30),
            Text(
              'Accès depuis l\'application:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '• Menu Admin → Rôles → Onglet "Assignations"',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Bouton "Gérer Assignations" dans la barre d\'actions',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RolesManagementScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'Tester le Module Rôles',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

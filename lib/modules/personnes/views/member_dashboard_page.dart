import 'package:flutter/material.dart';
import '../../../../theme.dart';
import '../../../widgets/admin_view_toggle_button.dart';
import '../../../theme.dart';

class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Accueil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
        actions: [
          // Toggle to admin view - only for administrators
          AdminViewToggleButton(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            iconColor: AppTheme.textPrimaryColor,
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Dashboard membre (module personnes) en construction',
          style: TextStyle(
            fontSize: AppTheme.fontSize18,
            color: AppTheme.grey500,
          ),
        ),
      ),
    );
  }
}

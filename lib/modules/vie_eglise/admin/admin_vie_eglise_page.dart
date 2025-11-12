import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import 'admin_pour_vous_complete.dart';

/// Page d'administration principale pour la vie de l'église
class AdminVieEglisePage extends StatefulWidget {
  const AdminVieEglisePage({Key? key}) : super(key: key);

  @override
  State<AdminVieEglisePage> createState() => _AdminVieEglisePageState();
}

class _AdminVieEglisePageState extends State<AdminVieEglisePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text(
          'Administration - Vie de l\'Église',
          style: GoogleFonts.inter(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Pour Vous',
            ),
            Tab(
              icon: Icon(Icons.event),
              text: 'Événements',
            ),
            Tab(
              icon: Icon(Icons.group),
              text: 'Groupes',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Pour Vous - Notre interface complète
          const AdminPourVousTabComplete(),
          
          // Onglet Événements - Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event,
                  size: 64,
                  color: AppTheme.grey400,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Gestion des Événements',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Fonctionnalité à implémenter',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Onglet Groupes - Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_work,
                  size: 64,
                  color: AppTheme.grey400,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Gestion des Groupes',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Fonctionnalité à implémenter',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
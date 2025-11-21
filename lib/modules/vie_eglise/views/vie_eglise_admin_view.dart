import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../widgets/admin_pour_vous_tab.dart';
import '../widgets/admin_sermons_tab.dart';

class VieEgliseAdminView extends StatefulWidget {
  const VieEgliseAdminView({Key? key}) : super(key: key);

  @override
  State<VieEgliseAdminView> createState() => _VieEgliseAdminViewState();
}

class _VieEgliseAdminViewState extends State<VieEgliseAdminView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onPrimaryColor)), // Texte blanc sur fond primaire
        backgroundColor: AppTheme.primaryColor, // Couleur primaire cohérente
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white), // Icônes blanches
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.onPrimaryColor, // Texte blanc
          unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
          indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontSemiBold),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium),
          tabs: const [
            Tab(
              icon: Icon(Icons.person, size: 20),
              text: 'Pour vous'),
            Tab(
              icon: Icon(Icons.play_circle, size: 20),
              text: 'Sermons'),
          ])),
      backgroundColor: AppTheme.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          const AdminPourVousTab(),
          const AdminSermonsTab(),
        ]));
  }
}

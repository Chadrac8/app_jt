import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'widgets/pepites_or_tab.dart';
import 'widgets/audio_player_tab_perfect13.dart';
import 'widgets/read_message_tab.dart';

/// Module principal "Le Message" avec 3 onglets
class MessageModule extends StatefulWidget {
  const MessageModule({Key? key}) : super(key: key);

  @override
  State<MessageModule> createState() => _MessageModuleState();
}

class _MessageModuleState extends State<MessageModule>
    with TickerProviderStateMixin {
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
    return Column(
      children: [
        // TabBar moderne - Style identique au module Vie de l'église
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.textTertiaryColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textTertiaryColor,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.headphones, size: 20),
                text: 'Écouter',
              ),
              Tab(
                icon: Icon(Icons.menu_book, size: 20),
                text: 'Lire',
              ),
              Tab(
                icon: Icon(Icons.auto_awesome, size: 20),
                text: 'Pépites d\'Or',
              ),
            ],
          ),
        ),
        // TabBarView
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.05), // Rouge bordeaux très léger
                  AppTheme.backgroundColor, // Background F8F9FA
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                AudioPlayerTabPerfect13(),
                ReadMessageTab(),
                PepitesOrTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

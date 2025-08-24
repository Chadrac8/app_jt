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
        // TabBar directement visible
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor, // Rouge bordeaux
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryActive.withOpacity(0.3), // Ombre avec couleur active
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.backgroundColor, // Indicateur blanc cassé sur rouge bordeaux
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 14,
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

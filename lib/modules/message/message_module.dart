import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
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
        // TabBar moderne - Material Design 3 conforme
        Container(
          height: 50, // Hauteur Material Design standard
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor, // Harmonisé avec AppBar transparente membre
            boxShadow: [
              BoxShadow(
                color: AppTheme.black100.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3.0, // Poids standard Material Design
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: AppTheme.fontSemiBold,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: AppTheme.fontMedium,
            ),
            tabs: const [
              Tab(
                text: 'Écouter',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                text: 'Lire',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                text: 'Pépites d\'Or',
                iconMargin: EdgeInsets.only(bottom: 4),
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

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
        // TabBar - Style MD3 moderne avec couleur primaire cohérente
        Material(
          color: AppTheme.primaryColor, // Couleur primaire identique à l'AppBar
          elevation: 0,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.onPrimaryColor, // Texte blanc sur fond primaire
            unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
            indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc sur fond primaire
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3.0,
            labelStyle: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontSemiBold,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              letterSpacing: 0.1,
            ),
            splashFactory: InkRipple.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppTheme.primaryColor.withValues(alpha: 0.12); // Overlay rouge sur fond clair
                }
                if (states.contains(WidgetState.hovered)) {
                  return AppTheme.primaryColor.withValues(alpha: 0.08); // Hover rouge sur fond clair
                }
                return null;
              },
            ),
            tabs: const [
              Tab(
                text: 'Écouter',
              ),
              Tab(
                text: 'Lire',
              ),
              Tab(
                text: 'Pépites d\'Or',
              ),
            ],
          ),
        ),
        
        // Divider subtil MD3
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
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

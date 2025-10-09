import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'widgets/pepites_or_tab.dart';
import 'widgets/audio_player_tab_perfect13.dart';
import 'widgets/read_message_tab.dart';

/// Module principal "Le Message" avec 3 onglets
class MessageModule extends StatefulWidget {
  final TabController? tabController; // MD3: TabController fourni par le wrapper
  
  const MessageModule({Key? key, this.tabController}) : super(key: key);

  @override
  State<MessageModule> createState() => _MessageModuleState();
}

class _MessageModuleState extends State<MessageModule>
    with TickerProviderStateMixin {
  TabController? _internalTabController; // TabController interne (si non fourni)
  
  // MD3: Getter pour obtenir le TabController (externe ou interne)
  TabController get _tabController => 
      widget.tabController ?? _internalTabController!;

  @override
  void initState() {
    super.initState();
    // MD3: Créer un TabController interne seulement si non fourni par le wrapper
    if (widget.tabController == null) {
      _internalTabController = TabController(length: 3, vsync: this);
    }
  }

  @override
  void dispose() {
    // MD3: Disposer uniquement le TabController interne (pas celui du wrapper)
    _internalTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MD3: Construction du body
    final body = Column(
      children: [
        // MD3: Afficher le TabBar seulement si non fourni par le wrapper
        if (widget.tabController == null) ...[
          // TabBar intégrée - Style MD3 avec fond Surface (clair)
          Container(
            color: AppTheme.surface, // MD3: Fond clair comme l'AppBar
            child: TabBar(
              controller: _tabController,
              // Les couleurs sont héritées du TabBarTheme (primaryColor pour actif, gris pour inactif)
              tabs: const [
                Tab(
                  icon: Icon(Icons.headphones_rounded),
                  text: 'Écouter',
                ),
                Tab(
                  icon: Icon(Icons.menu_book_rounded),
                  text: 'Lire',
                ),
                Tab(
                  icon: Icon(Icons.auto_awesome_rounded),
                  text: 'Pépites d\'Or',
                ),
              ],
            ),
          ),
          // Divider subtil MD3
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.grey300.withOpacity(0.5),
          ),
        ],
        
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
    
    // MD3: Si dans le wrapper (TabController fourni), retourner directement le body
    return body;
  }
}

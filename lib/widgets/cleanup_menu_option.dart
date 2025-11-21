import 'package:flutter/material.dart';
import '../pages/group_cleanup_admin_page.dart';
import '../services/group_cleanup_service.dart';
import '../theme.dart';

/// Widget pour afficher l'option de nettoyage dans un menu admin
class CleanupMenuOption extends StatefulWidget {
  const CleanupMenuOption({super.key});

  @override
  State<CleanupMenuOption> createState() => _CleanupMenuOptionState();
}

class _CleanupMenuOptionState extends State<CleanupMenuOption> {
  int? _orphanCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrphanCount();
  }

  Future<void> _loadOrphanCount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await GroupCleanupService.getOrphanStats();
      if (mounted) {
        setState(() {
          _orphanCount = stats.totalOrphans;
        });
      }
    } catch (e) {
      print('Erreur chargement stats orphelins: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            Icons.cleaning_services,
            color: _orphanCount != null && _orphanCount! > 0
                ? AppTheme.orangeStandard
                : AppTheme.grey600,
          ),
          if (_orphanCount != null && _orphanCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.redStandard,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$_orphanCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: const Text('Nettoyage groupes'),
      subtitle: _isLoading
          ? const Text('Chargement...')
          : _orphanCount != null
              ? Text(
                  _orphanCount! > 0
                      ? '$_orphanCount élément${_orphanCount! > 1 ? 's' : ''} orphelin${_orphanCount! > 1 ? 's' : ''}'
                      : 'Base de données propre',
                  style: TextStyle(
                    color: _orphanCount! > 0
                        ? AppTheme.orangeStandard
                        : AppTheme.greenStandard,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
      trailing: _orphanCount != null && _orphanCount! > 0
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GroupCleanupAdminPage(),
          ),
        ).then((_) {
          // Recharger le compteur au retour
          _loadOrphanCount();
        });
      },
    );
  }
}

/// Badge simple pour afficher le nombre d'orphelins
class OrphanCountBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const OrphanCountBadge({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.orangeStandard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              '$count orphelin${count > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemple d'intégration dans un menu admin
class AdminMenuExample extends StatelessWidget {
  const AdminMenuExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: Icon(Icons.group),
          title: Text('Gestion des groupes'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const ListTile(
          leading: Icon(Icons.event),
          title: Text('Gestion des événements'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(),
        
        // Option de nettoyage
        const CleanupMenuOption(),
        
        const Divider(),
        const ListTile(
          leading: Icon(Icons.settings),
          title: Text('Paramètres'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ],
    );
  }
}

/// Exemple d'utilisation du badge dans un AppBar
class AdminAppBarExample extends StatelessWidget implements PreferredSizeWidget {
  final int orphanCount;

  const AdminAppBarExample({
    super.key,
    this.orphanCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Administration'),
      actions: [
        if (orphanCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: OrphanCountBadge(
              count: orphanCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GroupCleanupAdminPage(),
                  ),
                );
              },
            ),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';

class MemberNotificationsPage extends StatefulWidget {
  final bool scaffolded;

  /// If [scaffolded] is false the widget will return only the page body
  /// so it can be embedded inside another Scaffold (for example the
  /// application's main Shell). Default is true which returns a full
  /// Scaffold with its own AppBar (used when navigated to as a standalone
  /// route).
  const MemberNotificationsPage({super.key, this.scaffolded = true});

  @override
  State<MemberNotificationsPage> createState() => _MemberNotificationsPageState();
}

class _MemberNotificationsPageState extends State<MemberNotificationsPage> {
  final _col = FirebaseFirestore.instance.collection('notifications');
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      final guestBody = const Center(child: Text('Veuillez vous connecter pour voir vos notifications'));
      if (widget.scaffolded) {
        return Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: guestBody,
        );
      }
      return guestBody;
    }

    final stream = _col
  .where('targetUserId', isEqualTo: _user.uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

    // Build the main content (the list) and return either a full Scaffold
    // (when used as a standalone route) or only the body so it can be
    // embedded inside the application's shell Scaffold.
    final content = StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data() as Map<String, dynamic>;
            final title = (data['title'] ?? 'Notification').toString();
            final body = (data['body'] ?? '').toString();
            final isRead = data['isRead'] == true;
            final ts = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();

            return Dismissible(
              key: ValueKey(d.id),
              background: _swipeBackground(AppTheme.greenStandard, Icons.mark_email_read, 'Marquer lu'),
              secondaryBackground: _swipeBackground(AppTheme.redStandard, Icons.delete, 'Supprimer'),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // mark read
                  if (!isRead) await d.reference.update({'isRead': true});
                  return false; // don't dismiss to keep item visible
                } else {
                  // delete
                  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer ?'),
                    content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer'))],
                  ));
                  if (ok == true) await d.reference.delete();
                  return ok == true;
                }
              },
              child: Card(
                elevation: isRead ? 0 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final route = data['route'] as String?;
                    if (route != null && route.isNotEmpty) {
                      Navigator.of(context).pushNamed(route, arguments: data['args']);
                    }
                    if (!isRead) await d.reference.update({'isRead': true});
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isRead ? AppTheme.grey500 : Theme.of(context).colorScheme.primary.withAlpha((0.15 * 255).round()),
                        child: Text(title.isNotEmpty ? title[0].toUpperCase() : 'N', style: TextStyle(color: isRead ? AppTheme.grey500 : Theme.of(context).colorScheme.primary, fontWeight: AppTheme.fontBold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: AppTheme.fontSemiBold, color: isRead ? AppTheme.grey800 : AppTheme.black100))),
                          const SizedBox(width: 8),
                          Text(_formatTimestamp(ts), style: TextStyle(fontSize: 12, color: AppTheme.grey600)),
                        ]),
                        const SizedBox(height: 6),
                        Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isRead ? AppTheme.grey700 : AppTheme.grey800)),
                        const SizedBox(height: 8),
                        if (!isRead) Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6)), child: const Text('Nouveau', style: TextStyle(color: AppTheme.white100, fontSize: 12))))
                      ])),
                    ]),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.scaffolded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            IconButton(
              tooltip: 'Marquer toutes comme lues',
              icon: const Icon(Icons.mark_email_read),
              onPressed: () async {
                try {
                  final query = await _col
                      .where('targetUserId', isEqualTo: _user.uid)
                      .where('isRead', isEqualTo: false)
                      .get();

                  if (query.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune notification non lue')));
                    return;
                  }

                  final batch = FirebaseFirestore.instance.batch();
                  int updated = 0;
                  for (final doc in query.docs) {
                    batch.update(doc.reference, {'isRead': true});
                    updated++;
                    if (updated >= 500) break;
                  }
                  await batch.commit();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marqué $updated notifications comme lues')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
            ),
          ],
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none, size: 72, color: AppTheme.grey500),
          const SizedBox(height: 12),
          Text('Aucune notification', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.grey700)),
          const SizedBox(height: 8),
          Text('Vous êtes à jour. Les notifications importantes apparaîtront ici.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey600)),
        ]),
      ),
    );
  }

  Widget _swipeBackground(Color color, IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [Icon(icon, color: AppTheme.white100), const SizedBox(width:8), Text(label, style: const TextStyle(color: AppTheme.white100))]),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'À l’instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return DateFormat.EEEE('fr_FR').format(dt); // e.g., Lundi
    return DateFormat.yMMMd('fr_FR').format(dt);
  }
}

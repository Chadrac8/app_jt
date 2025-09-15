import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberNotificationsPage extends StatefulWidget {
  const MemberNotificationsPage({super.key});

  @override
  State<MemberNotificationsPage> createState() => _MemberNotificationsPageState();
}

class _MemberNotificationsPageState extends State<MemberNotificationsPage> {
  final _col = FirebaseFirestore.instance.collection('notifications');
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Veuillez vous connecter pour voir vos notifications')),
      );
    }

    final stream = _col
  .where('targetUserId', isEqualTo: _user.uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text('Aucune notification')); 
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Notification';
              final body = data['body'] ?? '';
              final isRead = data['isRead'] == true;

              return ListTile(
                tileColor: isRead ? null : Colors.blue.shade50,
                title: Text(title),
                subtitle: Text(body),
                trailing: isRead
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.mark_email_read),
                        onPressed: () async {
                          await d.reference.update({'isRead': true});
                        },
                      ),
                onTap: () async {
                  // If notification has a route, try to navigate
                  final route = data['route'] as String?;
                  if (route != null && route.isNotEmpty) {
                    Navigator.of(context).pushNamed(route, arguments: data['args']);
                  }

                  if (!isRead) {
                    await d.reference.update({'isRead': true});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

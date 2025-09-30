import 'package:flutter/material.dart';
// import '../../services/push_notification_service.dart';  // Temporarily disabled

class NotificationsAdminPage extends StatefulWidget {
  const NotificationsAdminPage({super.key});

  @override
  State<NotificationsAdminPage> createState() => _NotificationsAdminPageState();
}

class _NotificationsAdminPageState extends State<NotificationsAdminPage> {
  String? _token;
  final _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    // final token = await PushNotificationService.getToken();  // Temporarily disabled
    final token = "Push notifications temporarily disabled";
    setState(() => _token = token);
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications admin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('FCM Token:', style: Theme.of(context).textTheme.titleSmall),
            SelectableText(_token ?? 'No token yet. Initialize notifications.'),
            const SizedBox(height: 16),
            TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'Topic name')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_topicController.text.trim().isEmpty) return;
                    // await PushNotificationService.subscribeToTopic(_topicController.text.trim());  // Temporarily disabled
                    print('Push notifications temporarily disabled');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribed')));
                  },
                  child: const Text('Subscribe')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_topicController.text.trim().isEmpty) return;
                    // await PushNotificationService.unsubscribeFromTopic(_topicController.text.trim());  // Temporarily disabled
                    print('Push notifications temporarily disabled');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unsubscribed')));
                  },
                  child: const Text('Unsubscribe')),
              ),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // await PushNotificationService.showTestNotification(title: 'Test', body: 'This is a test');  // Temporarily disabled
                print('Test notification temporarily disabled');
              },
              child: const Text('Show local test notification'),
            ),
          ],
        ),
      ),
    );
  }
}

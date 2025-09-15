import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OutboxNotificationsPage extends StatefulWidget {
  const OutboxNotificationsPage({super.key});

  @override
  State<OutboxNotificationsPage> createState() => _OutboxNotificationsPageState();
}

class _OutboxNotificationsPageState extends State<OutboxNotificationsPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _topicController = TextEditingController();
  bool _sendToAll = false;
  bool _sendToTopic = true;
  bool _sendNow = true;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final doc = FirebaseFirestore.instance.collection('outbox_notifications').doc();
    final payload = {
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    if (_sendToAll) {
      payload['targetType'] = 'all';
    } else if (_sendToTopic) {
      payload['targetType'] = 'topic';
      payload['topic'] = _topicController.text.trim();
    } else {
      payload['targetType'] = 'tokens';
      payload['tokens'] = [];
    }

    if (!_sendNow && _scheduledAt != null) {
      payload['scheduledAt'] = Timestamp.fromDate(_scheduledAt!);
    }

    await doc.set(payload);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification saved to outbox')));
    _titleController.clear();
    _bodyController.clear();
    _topicController.clear();
    setState(() { _sendToAll = false; _sendToTopic = true; _sendNow = true; _scheduledAt = null; });
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days:365)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _sendNow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outbox - Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height:8),
            TextField(controller: _bodyController, decoration: const InputDecoration(labelText: 'Body'), maxLines: 4),
            const SizedBox(height:12),
            SwitchListTile(
              title: const Text('Send to all members'),
              value: _sendToAll,
              onChanged: (v) => setState(() { _sendToAll = v; if (v) _sendToTopic = false; }),
            ),
            if (!_sendToAll) ...[
              RadioListTile<bool>(
                title: const Text('Topic'),
                value: true,
                groupValue: _sendToTopic,
                onChanged: (v) => setState(() => _sendToTopic = v ?? true),
              ),
              if (_sendToTopic) TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'Topic name (ex: annonces)')),
            ],
            const SizedBox(height:12),
            SwitchListTile(
              title: const Text('Send now'),
              value: _sendNow,
              onChanged: (v) => setState(() { _sendNow = v; if (v) _scheduledAt = null; }),
            ),
            if (!_sendNow) ...[
              ListTile(
                title: Text(_scheduledAt == null ? 'Pick date/time' : 'Scheduled at: ${_scheduledAt.toString()}'),
                trailing: ElevatedButton(onPressed: _pickSchedule, child: const Text('Pick')),
              )
            ],
            const SizedBox(height:16),
            ElevatedButton(onPressed: _submit, child: const Text('Save to Outbox')),
            const SizedBox(height:24),
            const Divider(),
            const SizedBox(height:12),
            const Text('Pending Outbox', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('outbox_notifications').orderBy('createdAt', descending: true).limit(50).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final docs = snap.data!.docs;
                return Column(children: docs.map((d) {
                  final data = d.data() as Map<String,dynamic>;
                  return ListTile(
                    title: Text(data['title'] ?? 'No title'),
                    subtitle: Text('Status: ${data['status'] ?? 'unknown'} • Target: ${data['targetType'] ?? '-'}'),
                    trailing: TextButton(onPressed: () async {
                      await d.reference.update({'status': 'cancelled'});
                    }, child: const Text('Cancel')),
                  );
                }).toList());
              }
            )
          ],
        ),
      ),
    );
  }
}

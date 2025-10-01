import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../theme.dart';

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
  // segment support
  bool _sendToSegment = false;
  String? _selectedSegmentId;
  List<Map<String, String>> _segments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  Future<void> _loadSegments() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('userSegments')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      setState(() {
        _segments = snap.docs.map((d) {
          final data = d.data();
          return {'id': d.id, 'name': (data['name'] ?? d.id).toString()};
        }).toList();
      });
    } catch (e) {
      debugPrint('Failed to load segments: $e');
    }
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
    } else if (_sendToSegment) {
      payload['targetType'] = 'segment';
      if (_selectedSegmentId != null) payload['segmentId'] = _selectedSegmentId as Object;
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
    setState(() { _sendToAll = false; _sendToTopic = true; _sendToSegment = false; _selectedSegmentId = null; _sendNow = true; _scheduledAt = null; });
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
                onChanged: (v) => setState(() { _sendToTopic = v ?? true; _sendToSegment = false; }),
              ),
              if (_sendToTopic) TextField(controller: _topicController, decoration: const InputDecoration(labelText: 'Topic name (ex: annonces)')),

              RadioListTile<bool>(
                title: const Text('Segment'),
                value: true,
                groupValue: _sendToSegment,
                onChanged: (v) => setState(() { _sendToSegment = v ?? true; _sendToTopic = false; }),
              ),
              if (_sendToSegment) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedSegmentId,
                  items: _segments.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? s['id']!))).toList(),
                  onChanged: (v) => setState(() => _selectedSegmentId = v),
                  decoration: const InputDecoration(labelText: 'Select segment'),
                ),
              ),
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
            const Text('Pending Outbox', style: TextStyle(fontWeight: AppTheme.fontBold)),
            const SizedBox(height:8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('outbox_notifications').orderBy('createdAt', descending: true).limit(50).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final docs = snap.data!.docs;
                return Column(children: docs.map((d) {
                  final data = d.data() as Map<String,dynamic>;
                  final createdCount = data['createdNotificationsCount'] ?? 0;
                  final sample = (data['sampleCreatedFor'] as List<dynamic>?)?.take(5).join(', ') ?? '';
                  final sendResult = data['sendResult'];
                  return ListTile(
                    title: Text(data['title'] ?? 'No title'),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Status: ${data['status'] ?? 'unknown'} • Target: ${data['targetType'] ?? '-'}'),
                      if (createdCount > 0) Text('Created: $createdCount • Sample: $sample', style: const TextStyle(fontSize: AppTheme.fontSize12, color: AppTheme.black100)),
                      if (sendResult != null) Text('SendResult: ${sendResult.totalSuccess ?? sendResult.successCount ?? '-'} success', style: const TextStyle(fontSize: AppTheme.fontSize12, color: AppTheme.black100)),
                    ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(onPressed: () async {
                        await d.reference.update({'status': 'cancelled'});
                      }, child: const Text('Cancel')),
                      const SizedBox(width:8),
                      TextButton(onPressed: () async {
                        // Requeue to pending and schedule immediate send
                        await d.reference.update({'status': 'pending', 'scheduledAt': FieldValue.serverTimestamp()});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outbox requeued')));
                      }, child: const Text('Run now'))
                    ]),
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

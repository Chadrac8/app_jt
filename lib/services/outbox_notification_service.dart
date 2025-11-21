import 'package:cloud_firestore/cloud_firestore.dart';

class OutboxNotificationService {
  static final _col = FirebaseFirestore.instance.collection('outbox_notifications');

  /// Create a new outbox notification document.
  static Future<DocumentReference> create(Map<String, dynamic> data) async {
    final doc = _col.doc();
    await doc.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    return doc;
  }

  static Future<void> updateStatus(String docId, String status, {Map<String, dynamic>? meta}) async {
    final ref = _col.doc(docId);
    final payload = {'status': status, 'updatedAt': FieldValue.serverTimestamp()};
    if (meta != null) payload.addAll({'meta': meta});
    await ref.update(payload);
  }
}

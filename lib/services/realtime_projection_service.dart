import 'package:firebase_database/firebase_database.dart';

class RealtimeProjectionService {
  final String sessionId;
  final DatabaseReference _sessionRef;

  RealtimeProjectionService(this.sessionId)
      : _sessionRef = FirebaseDatabase.instance.ref('projection_sessions/$sessionId');

  Stream<Map<String, dynamic>> get onStateChanged => _sessionRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return Map<String, dynamic>.from(data as Map);
        }
        return {};
      });

  Future<void> updateState(Map<String, dynamic> state) async {
    await _sessionRef.set(state);
  }

  Future<void> dispose() async {
    await _sessionRef.remove();
  }
}

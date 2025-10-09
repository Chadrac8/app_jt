import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

void main() async {
  print('🔍 Vérification des événements récurrents...\n');
  
  final firestore = FirebaseFirestore.instance;
  
  // Récupérer les événements marqués comme récurrents
  final eventsQuery = await firestore
      .collection('events')
      .where('isRecurring', isEqualTo: true)
      .limit(5)
      .get();
  
  if (eventsQuery.docs.isEmpty) {
    print('❌ Aucun événement récurrent trouvé dans Firestore');
    exit(0);
  }
  
  print('📊 ${eventsQuery.docs.length} événements récurrents trouvés\n');
  
  for (var doc in eventsQuery.docs) {
    final data = doc.data();
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📅 Événement: ${data['title']}');
    print('🆔 ID: ${doc.id}');
    print('🔄 isRecurring: ${data['isRecurring']}');
    print('📝 recurrence field: ${data['recurrence']}');
    print('🏷️  Type: ${data['type']}');
    print('📍 isServiceEvent: ${data['isServiceEvent']}');
    
    if (data['recurrence'] == null) {
      print('⚠️  PROBLÈME: recurrence est NULL alors que isRecurring = true');
    } else {
      print('✅ recurrence contient: ${data['recurrence']}');
    }
    print('');
  }
  
  exit(0);
}

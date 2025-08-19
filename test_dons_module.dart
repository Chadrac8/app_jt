import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/modules/dons/models/don_model.dart';
import '../lib/modules/dons/services/dons_service.dart';

void main() {
  group('Module Dons Tests', () {
    test('Don model creation and conversion', () {
      final don = Don(
        id: 'test_id',
        donorId: 'donor_123',
        donorName: 'Jean Dupont',
        donorEmail: 'jean@example.com',
        amount: 50.0,
        currency: 'EUR',
        type: 'one_time',
        purpose: 'general',
        status: 'pending',
        isAnonymous: false,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(don.amount, 50.0);
      expect(don.donorName, 'Jean Dupont');
      expect(don.type, 'one_time');
      expect(don.status, 'pending');
      expect(don.isAnonymous, false);
      expect(don.isRecurring, false);

      // Test conversion to Firestore
      final firestoreData = don.toFirestore();
      expect(firestoreData['amount'], 50.0);
      expect(firestoreData['donorName'], 'Jean Dupont');
      expect(firestoreData['type'], 'one_time');
      expect(firestoreData['isAnonymous'], false);
    });

    test('DonType enum validation', () {
      expect(DonType.oneTime.value, 'one_time');
      expect(DonType.oneTime.label, 'Don unique');
      expect(DonType.monthly.value, 'monthly');
      expect(DonType.monthly.label, 'Don mensuel');
      expect(DonType.yearly.value, 'yearly');
      expect(DonType.yearly.label, 'Don annuel');

      // Test fromValue method
      expect(DonType.fromValue('one_time'), DonType.oneTime);
      expect(DonType.fromValue('monthly'), DonType.monthly);
      expect(DonType.fromValue('yearly'), DonType.yearly);
      expect(DonType.fromValue('invalid'), DonType.oneTime); // Should return default
    });

    test('DonPurpose enum validation', () {
      expect(DonPurpose.general.value, 'general');
      expect(DonPurpose.general.label, 'Don général');
      expect(DonPurpose.missions.value, 'missions');
      expect(DonPurpose.missions.label, 'Missions');
      expect(DonPurpose.building.value, 'building');
      expect(DonPurpose.building.label, 'Bâtiment');

      // Test fromValue method
      expect(DonPurpose.fromValue('general'), DonPurpose.general);
      expect(DonPurpose.fromValue('missions'), DonPurpose.missions);
      expect(DonPurpose.fromValue('building'), DonPurpose.building);
      expect(DonPurpose.fromValue('invalid'), DonPurpose.general); // Should return default
    });

    test('DonStatus enum validation', () {
      expect(DonStatus.pending.value, 'pending');
      expect(DonStatus.pending.label, 'En attente');
      expect(DonStatus.completed.value, 'completed');
      expect(DonStatus.completed.label, 'Terminé');
      expect(DonStatus.failed.value, 'failed');
      expect(DonStatus.failed.label, 'Échoué');
      expect(DonStatus.cancelled.value, 'cancelled');
      expect(DonStatus.cancelled.label, 'Annulé');

      // Test fromValue method
      expect(DonStatus.fromValue('pending'), DonStatus.pending);
      expect(DonStatus.fromValue('completed'), DonStatus.completed);
      expect(DonStatus.fromValue('failed'), DonStatus.failed);
      expect(DonStatus.fromValue('cancelled'), DonStatus.cancelled);
      expect(DonStatus.fromValue('invalid'), DonStatus.pending); // Should return default
    });

    test('Don copyWith method', () {
      final originalDon = Don(
        id: 'test_id',
        donorId: 'donor_123',
        amount: 50.0,
        currency: 'EUR',
        type: 'one_time',
        purpose: 'general',
        status: 'pending',
        isAnonymous: false,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedDon = originalDon.copyWith(
        amount: 100.0,
        status: 'completed',
        isAnonymous: true,
      );

      expect(updatedDon.amount, 100.0);
      expect(updatedDon.status, 'completed');
      expect(updatedDon.isAnonymous, true);
      // Verify unchanged fields
      expect(updatedDon.id, originalDon.id);
      expect(updatedDon.donorId, originalDon.donorId);
      expect(updatedDon.currency, originalDon.currency);
      expect(updatedDon.type, originalDon.type);
      expect(updatedDon.purpose, originalDon.purpose);
    });

    test('Anonymous don validation', () {
      final anonymousDon = Don(
        id: 'test_id',
        donorId: 'donor_123',
        amount: 50.0,
        currency: 'EUR',
        type: 'one_time',
        purpose: 'general',
        status: 'pending',
        isAnonymous: true,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(anonymousDon.isAnonymous, true);
      expect(anonymousDon.donorName, null);
      expect(anonymousDon.donorEmail, null);
    });

    test('Recurring don validation', () {
      final recurringDon = Don(
        id: 'test_id',
        donorId: 'donor_123',
        amount: 50.0,
        currency: 'EUR',
        type: 'monthly',
        purpose: 'general',
        status: 'pending',
        isAnonymous: false,
        isRecurring: true,
        nextPaymentDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(recurringDon.isRecurring, true);
      expect(recurringDon.type, 'monthly');
      expect(recurringDon.nextPaymentDate, isNotNull);
    });
  });
}

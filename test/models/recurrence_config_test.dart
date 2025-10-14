import 'package:flutter_test/flutter_test.dart';
import 'package:jubile_tabernacle_france/models/recurrence_config.dart';

void main() {
  group('RecurrenceConfig', () {
    test('fromJson - daily frequency', () {
      final json = {
        'frequency': 'daily',
        'interval': 1,
        'startDate': '2025-10-14T19:30:00.000',
        'endType': 'never',
      };

      final config = RecurrenceConfig.fromJson(json);

      expect(config.frequency, RecurrenceFrequency.daily);
      expect(config.interval, 1);
      expect(config.startDate.year, 2025);
      expect(config.startDate.month, 10);
      expect(config.startDate.day, 14);
      expect(config.endType, RecurrenceEndType.never);
      expect(config.endDate, isNull);
      expect(config.occurrences, isNull);
    });

    test('fromJson - weekly frequency with days', () {
      final json = {
        'frequency': 'weekly',
        'interval': 2,
        'startDate': '2025-10-14T19:30:00.000',
        'endType': 'after',
        'occurrences': 10,
        'daysOfWeek': [1, 3, 5], // Lundi, Mercredi, Vendredi
      };

      final config = RecurrenceConfig.fromJson(json);

      expect(config.frequency, RecurrenceFrequency.weekly);
      expect(config.interval, 2);
      expect(config.daysOfWeek, [1, 3, 5]);
      expect(config.endType, RecurrenceEndType.after);
      expect(config.occurrences, 10);
    });

    test('fromJson - monthly frequency on day of month', () {
      final json = {
        'frequency': 'monthly',
        'interval': 1,
        'startDate': '2025-10-14T19:30:00.000',
        'endType': 'on',
        'endDate': '2026-10-14T19:30:00.000',
        'monthlyType': 'dayOfMonth',
      };

      final config = RecurrenceConfig.fromJson(json);

      expect(config.frequency, RecurrenceFrequency.monthly);
      expect(config.monthlyType, MonthlyRecurrenceType.dayOfMonth);
      expect(config.endType, RecurrenceEndType.on);
      expect(config.endDate, isNotNull);
      expect(config.endDate!.year, 2026);
    });

    test('fromJson - monthly frequency on day of week', () {
      final json = {
        'frequency': 'monthly',
        'interval': 1,
        'startDate': '2025-10-14T19:30:00.000',
        'endType': 'never',
        'monthlyType': 'dayOfWeek',
        'weekOfMonth': 2, // 2ème semaine
        'dayOfWeek': 2, // Mardi
      };

      final config = RecurrenceConfig.fromJson(json);

      expect(config.monthlyType, MonthlyRecurrenceType.dayOfWeek);
      expect(config.weekOfMonth, 2);
      expect(config.dayOfWeek, 2);
    });

    test('fromJson - yearly frequency', () {
      final json = {
        'frequency': 'yearly',
        'interval': 1,
        'startDate': '2025-10-14T19:30:00.000',
        'endType': 'never',
      };

      final config = RecurrenceConfig.fromJson(json);

      expect(config.frequency, RecurrenceFrequency.yearly);
      expect(config.interval, 1);
    });

    test('toJson - daily frequency', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14, 19, 30),
        endType: RecurrenceEndType.never,
      );

      final json = config.toJson();

      expect(json['frequency'], 'daily');
      expect(json['interval'], 1);
      expect(json['startDate'], isNotNull);
      expect(json['endType'], 'never');
      expect(json['endDate'], isNull);
      expect(json['occurrences'], isNull);
    });

    test('toJson - weekly with days', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        startDate: DateTime(2025, 10, 14, 19, 30),
        endType: RecurrenceEndType.after,
        occurrences: 10,
        daysOfWeek: [1, 3, 5],
      );

      final json = config.toJson();

      expect(json['frequency'], 'weekly');
      expect(json['daysOfWeek'], [1, 3, 5]);
      expect(json['occurrences'], 10);
    });

    test('isValid - valid daily config', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      expect(config.isValid(), true);
    });

    test('isValid - invalid interval (0)', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 0,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      expect(config.isValid(), false);
    });

    test('isValid - invalid weekly (no days selected)', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
        daysOfWeek: [],
      );

      expect(config.isValid(), false);
    });

    test('isValid - invalid endDate (before startDate)', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.on,
        endDate: DateTime(2025, 10, 10), // Avant startDate
      );

      expect(config.isValid(), false);
    });

    test('isValid - invalid occurrences (0)', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.after,
        occurrences: 0,
      );

      expect(config.isValid(), false);
    });

    test('getNextOccurrence - daily', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 2,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      final next = config.getNextOccurrence(DateTime(2025, 10, 14));

      expect(next.day, 16); // +2 jours
    });

    test('getNextOccurrence - weekly', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        startDate: DateTime(2025, 10, 14), // Mardi
        endType: RecurrenceEndType.never,
        daysOfWeek: [2, 4], // Mardi, Jeudi
      );

      final next = config.getNextOccurrence(DateTime(2025, 10, 14));

      expect(next.day, 16); // Jeudi suivant
      expect(next.weekday, 4);
    });

    test('getNextOccurrence - monthly dayOfMonth', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
        monthlyType: MonthlyRecurrenceType.dayOfMonth,
      );

      final next = config.getNextOccurrence(DateTime(2025, 10, 14));

      expect(next.month, 11);
      expect(next.day, 14);
    });

    test('getNextOccurrence - yearly', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.yearly,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      final next = config.getNextOccurrence(DateTime(2025, 10, 14));

      expect(next.year, 2026);
      expect(next.month, 10);
      expect(next.day, 14);
    });

    test('shouldGenerateOccurrence - before startDate', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      expect(
        config.shouldGenerateOccurrence(DateTime(2025, 10, 10)),
        false,
      );
    });

    test('shouldGenerateOccurrence - after endDate', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.on,
        endDate: DateTime(2025, 10, 20),
      );

      expect(
        config.shouldGenerateOccurrence(DateTime(2025, 10, 25)),
        false,
      );
    });

    test('shouldGenerateOccurrence - in excludeDates', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
        excludeDates: [DateTime(2025, 10, 15)],
      );

      expect(
        config.shouldGenerateOccurrence(DateTime(2025, 10, 15)),
        false,
      );
    });

    test('shouldGenerateOccurrence - valid', () {
      final config = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      expect(
        config.shouldGenerateOccurrence(DateTime(2025, 10, 15)),
        true,
      );
    });

    test('copyWith - updates fields', () {
      final original = RecurrenceConfig(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2025, 10, 14),
        endType: RecurrenceEndType.never,
      );

      final updated = original.copyWith(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
      );

      expect(updated.frequency, RecurrenceFrequency.weekly);
      expect(updated.interval, 2);
      expect(updated.startDate, original.startDate);
      expect(updated.endType, original.endType);
    });
  });

  group('RecurrenceFrequency', () {
    test('fromString - valid values', () {
      expect(
        RecurrenceFrequency.fromString('daily'),
        RecurrenceFrequency.daily,
      );
      expect(
        RecurrenceFrequency.fromString('weekly'),
        RecurrenceFrequency.weekly,
      );
      expect(
        RecurrenceFrequency.fromString('monthly'),
        RecurrenceFrequency.monthly,
      );
      expect(
        RecurrenceFrequency.fromString('yearly'),
        RecurrenceFrequency.yearly,
      );
    });

    test('fromString - invalid value', () {
      expect(
        () => RecurrenceFrequency.fromString('invalid'),
        throwsException,
      );
    });

    test('displayName - French labels', () {
      expect(RecurrenceFrequency.daily.displayName, 'Quotidien');
      expect(RecurrenceFrequency.weekly.displayName, 'Hebdomadaire');
      expect(RecurrenceFrequency.monthly.displayName, 'Mensuel');
      expect(RecurrenceFrequency.yearly.displayName, 'Annuel');
    });
  });

  group('MonthlyRecurrenceType', () {
    test('fromString - valid values', () {
      expect(
        MonthlyRecurrenceType.fromString('dayOfMonth'),
        MonthlyRecurrenceType.dayOfMonth,
      );
      expect(
        MonthlyRecurrenceType.fromString('dayOfWeek'),
        MonthlyRecurrenceType.dayOfWeek,
      );
    });

    test('displayName - French labels', () {
      expect(
        MonthlyRecurrenceType.dayOfMonth.displayName,
        'Le 14 de chaque mois',
      );
      expect(
        MonthlyRecurrenceType.dayOfWeek.displayName,
        'Le 2ème mardi',
      );
    });
  });

  group('RecurrenceEndType', () {
    test('fromString - valid values', () {
      expect(RecurrenceEndType.fromString('never'), RecurrenceEndType.never);
      expect(RecurrenceEndType.fromString('on'), RecurrenceEndType.on);
      expect(RecurrenceEndType.fromString('after'), RecurrenceEndType.after);
    });

    test('displayName - French labels', () {
      expect(RecurrenceEndType.never.displayName, 'Jamais');
      expect(RecurrenceEndType.on.displayName, 'Le');
      expect(RecurrenceEndType.after.displayName, 'Après');
    });
  });

  group('GroupEditScope', () {
    test('fromString - valid values', () {
      expect(
        GroupEditScope.fromString('thisOccurrenceOnly'),
        GroupEditScope.thisOccurrenceOnly,
      );
      expect(
        GroupEditScope.fromString('thisAndFutureOccurrences'),
        GroupEditScope.thisAndFutureOccurrences,
      );
      expect(
        GroupEditScope.fromString('allOccurrences'),
        GroupEditScope.allOccurrences,
      );
    });
  });
}

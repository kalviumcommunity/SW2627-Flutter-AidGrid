import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/models/distribution_record.dart';

void main() {
  group('DistributionRecord Model Tests', () {
    test(
      'DistributionRecord parses standard fields with Timestamp correctly',
      () {
        final now = DateTime(2026, 10, 12, 14, 30);
        final data = {
          'itemId': 'inv_rice_01',
          'itemName': 'Rice (Basmati)',
          'siteId': 'site_jaipur_01',
          'siteName': 'Jaipur North',
          'quantity': 25,
          'unit': 'kg',
          'volunteerId': 'user_vol_101',
          'volunteerName': 'Rahul Sharma',
          'distributedAt': Timestamp.fromDate(now),
          'assignmentId': 'assign_123',
        };

        final record = DistributionRecord.fromMap(data, 'dist_doc_1');

        expect(record.id, equals('dist_doc_1'));
        expect(record.itemId, equals('inv_rice_01'));
        expect(record.itemName, equals('Rice (Basmati)'));
        expect(record.siteId, equals('site_jaipur_01'));
        expect(record.siteName, equals('Jaipur North'));
        expect(record.quantity, equals(25));
        expect(record.unit, equals('kg'));
        expect(record.volunteerId, equals('user_vol_101'));
        expect(record.volunteerName, equals('Rahul Sharma'));
        expect(record.distributedAt, equals(now));
        expect(record.assignmentId, equals('assign_123'));
      },
    );

    test(
      'DistributionRecord handles missing and malformed fields gracefully',
      () {
        final data = <String, dynamic>{};

        final record = DistributionRecord.fromMap(data, 'dist_empty');

        expect(record.id, equals('dist_empty'));
        expect(record.itemId, equals(''));
        expect(record.itemName, equals('Unknown item'));
        expect(record.siteId, equals(''));
        expect(record.siteName, equals('Unknown site'));
        expect(record.quantity, equals(0));
        expect(record.unit, equals('units'));
        expect(record.volunteerId, equals(''));
        expect(record.volunteerName, equals('Volunteer'));
        expect(record.assignmentId, isNull);
        expect(record.distributedAt, isA<DateTime>());
      },
    );

    test(
      'DistributionRecord parses string and double quantities accurately',
      () {
        final data1 = {'quantity': '15.5'};
        final data2 = {'quantity': 40.25};

        final r1 = DistributionRecord.fromMap(data1, 'r1');
        final r2 = DistributionRecord.fromMap(data2, 'r2');

        expect(r1.quantity, equals(15.5));
        expect(r2.quantity, equals(40.25));
      },
    );

    test('DistributionRecord parses ISO string and milliseconds timestamp', () {
      final isoStr = '2026-10-12T10:00:00.000Z';
      final millis = 1791800000000;

      final rIso = DistributionRecord.fromMap({'distributedAt': isoStr}, 'iso');
      final rMillis = DistributionRecord.fromMap({
        'distributedAt': millis,
      }, 'millis');

      expect(rIso.distributedAt.year, equals(2026));
      expect(rMillis.distributedAt.millisecondsSinceEpoch, equals(millis));
    });

    test('DistributionRecord toMap serializes correctly for Firestore', () {
      final testDate = DateTime(2026, 10, 12, 11, 0);
      final record = DistributionRecord(
        id: 'dist_save_1',
        itemId: 'inv_dal_02',
        itemName: 'Dal / Lentils',
        siteId: 'site_ajmer_01',
        siteName: 'Ajmer Central',
        quantity: 10,
        unit: 'kg',
        volunteerId: 'vol_456',
        volunteerName: 'Ananya Verma',
        distributedAt: testDate,
        assignmentId: 'assign_456',
      );

      final map = record.toMap();

      expect(map['itemId'], equals('inv_dal_02'));
      expect(map['itemName'], equals('Dal / Lentils'));
      expect(map['siteId'], equals('site_ajmer_01'));
      expect(map['siteName'], equals('Ajmer Central'));
      expect(map['quantity'], equals(10));
      expect(map['unit'], equals('kg'));
      expect(map['volunteerId'], equals('vol_456'));
      expect(map['volunteerName'], equals('Ananya Verma'));
      expect(map['assignmentId'], equals('assign_456'));
      expect(map['distributedAt'], isA<Timestamp>());
    });

    test('DistributionRecord copyWith creates modified instance', () {
      final original = DistributionRecord(
        id: 'orig_1',
        itemId: 'item_1',
        itemName: 'Rice',
        siteId: 'site_1',
        siteName: 'Jaipur North',
        quantity: 20,
        unit: 'kg',
        volunteerId: 'vol_1',
        volunteerName: 'Rahul',
        distributedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        quantity: 30,
        volunteerName: 'Rahul S.',
      );

      expect(updated.quantity, equals(30));
      expect(updated.volunteerName, equals('Rahul S.'));
      expect(updated.itemName, equals('Rice'));
      expect(updated.id, equals('orig_1'));
    });
  });
}

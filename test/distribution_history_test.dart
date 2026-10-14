import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/models/distribution_record.dart';
import 'package:food_distribution_app/services/distribution_history_service.dart';

void main() {
  group('Distribution History Integration & UI Testing', () {
    test('Default sample distributions contain valid, complete data', () {
      final samples = DistributionHistoryService.getDefaultSampleDistributions();

      expect(samples.length, greaterThanOrEqualTo(4));
      for (final sample in samples) {
        expect(sample.id, isNotEmpty);
        expect(sample.itemId, isNotEmpty);
        expect(sample.itemName, isNotEmpty);
        expect(sample.siteId, isNotEmpty);
        expect(sample.siteName, isNotEmpty);
        expect(sample.quantity, greaterThan(0));
        expect(sample.unit, isNotEmpty);
        expect(sample.volunteerId, isNotEmpty);
        expect(sample.volunteerName, isNotEmpty);
        expect(sample.distributedAt, isNotNull);
      }
    });

    test('Records sort chronologically newest first', () {
      final now = DateTime.now();
      final recordOlder = DistributionRecord(
        id: 'rec_1',
        itemId: 'inv_1',
        itemName: 'Rice',
        siteId: 'site_1',
        siteName: 'Jaipur North',
        quantity: 10,
        unit: 'kg',
        volunteerId: 'vol_1',
        volunteerName: 'Rahul',
        distributedAt: now.subtract(const Duration(hours: 2)),
      );

      final recordNewer = DistributionRecord(
        id: 'rec_2',
        itemId: 'inv_2',
        itemName: 'Dal',
        siteId: 'site_2',
        siteName: 'Jaipur South',
        quantity: 15,
        unit: 'kg',
        volunteerId: 'vol_2',
        volunteerName: 'Ananya',
        distributedAt: now.subtract(const Duration(minutes: 10)),
      );

      final list = [recordOlder, recordNewer];
      list.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));

      expect(list.first.id, equals('rec_2'));
      expect(list.last.id, equals('rec_1'));
    });

    test('Record Distribution schema matches Distribution History read schema', () {
      final now = DateTime(2026, 10, 14, 12, 0);
      final recordedData = {
        'itemId': 'inv_wheat_03',
        'itemName': 'Wheat Flour',
        'siteId': 'site_ajmer_01',
        'siteName': 'Ajmer Central',
        'quantity': 25,
        'unit': 'kg',
        'volunteerId': 'vol_uid_789',
        'volunteerName': 'Volunteer Arya',
        'distributedAt': Timestamp.fromDate(now),
        'assignmentId': 'assign_task_1',
      };

      final parsed = DistributionRecord.fromMap(recordedData, 'dist_doc_789');

      expect(parsed.id, equals('dist_doc_789'));
      expect(parsed.itemId, equals('inv_wheat_03'));
      expect(parsed.itemName, equals('Wheat Flour'));
      expect(parsed.siteId, equals('site_ajmer_01'));
      expect(parsed.siteName, equals('Ajmer Central'));
      expect(parsed.quantity, equals(25));
      expect(parsed.unit, equals('kg'));
      expect(parsed.volunteerId, equals('vol_uid_789'));
      expect(parsed.volunteerName, equals('Volunteer Arya'));
      expect(parsed.distributedAt, equals(now));
      expect(parsed.assignmentId, equals('assign_task_1'));
    });

    test('Handles missing volunteer and assignment info safely', () {
      final minimalData = {
        'itemId': 'inv_oil_04',
        'itemName': 'Cooking Oil',
        'siteId': 'site_jaipur_01',
        'siteName': 'Jaipur North',
        'quantity': 5,
        'unit': 'liters',
      };

      final parsed = DistributionRecord.fromMap(minimalData, 'doc_min');

      expect(parsed.id, equals('doc_min'));
      expect(parsed.itemName, equals('Cooking Oil'));
      expect(parsed.quantity, equals(5));
      expect(parsed.unit, equals('liters'));
      expect(parsed.volunteerName, equals('Volunteer'));
      expect(parsed.volunteerId, equals(''));
      expect(parsed.assignmentId, isNull);
      expect(parsed.distributedAt, isNotNull);
    });
  });
}

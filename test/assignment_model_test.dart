import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_distribution_app/models/assignment.dart';

void main() {
  group('Assignment Model & Status Tests', () {
    test('AssignmentStatus fromString parses all statuses accurately', () {
      expect(
        AssignmentStatus.fromString('Pending'),
        equals(AssignmentStatus.pending),
      );
      expect(
        AssignmentStatus.fromString('In Progress'),
        equals(AssignmentStatus.inProgress),
      );
      expect(
        AssignmentStatus.fromString('inprogress'),
        equals(AssignmentStatus.inProgress),
      );
      expect(
        AssignmentStatus.fromString('Completed'),
        equals(AssignmentStatus.completed),
      );
      expect(
        AssignmentStatus.fromString('unknown'),
        equals(AssignmentStatus.pending),
      );
      expect(
        AssignmentStatus.fromString(null),
        equals(AssignmentStatus.pending),
      );
    });

    test('Assignment fromMap parses standard fields correctly', () {
      final now = DateTime.now();
      final data = {
        'siteId': 'site_jaipur_01',
        'volunteerId': 'user_vol_123',
        'taskDescription': 'Distribute 50 kg grain packs',
        'assignedAt': Timestamp.fromDate(now),
        'status': 'Pending',
        'siteName': 'Jaipur North',
      };

      final assignment = Assignment.fromMap(data, 'doc_assignment_1');

      expect(assignment.id, equals('doc_assignment_1'));
      expect(assignment.siteId, equals('site_jaipur_01'));
      expect(assignment.volunteerId, equals('user_vol_123'));
      expect(
        assignment.taskDescription,
        equals('Distribute 50 kg grain packs'),
      );
      expect(assignment.status, equals(AssignmentStatus.pending));
      expect(assignment.siteName, equals('Jaipur North'));
    });

    test('Assignment handles missing or malformed fields safely', () {
      final data = <String, dynamic>{};

      final assignment = Assignment.fromMap(data, 'doc_empty');

      expect(assignment.id, equals('doc_empty'));
      expect(assignment.siteId, equals(''));
      expect(assignment.volunteerId, equals(''));
      expect(assignment.taskDescription, equals('No description provided'));
      expect(assignment.status, equals(AssignmentStatus.pending));
      expect(assignment.siteName, isNull);
    });

    test('Assignment toMap converts data back to Firestore structure', () {
      final testDate = DateTime(2026, 10, 9, 10, 0);
      final assignment = Assignment(
        id: 'doc_2',
        siteId: 'site_ajmer_02',
        volunteerId: 'user_456',
        taskDescription: 'Coordinate delivery truck',
        assignedAt: testDate,
        status: AssignmentStatus.inProgress,
        siteName: 'Ajmer Central',
      );

      final map = assignment.toMap();

      expect(map['siteId'], equals('site_ajmer_02'));
      expect(map['volunteerId'], equals('user_456'));
      expect(map['taskDescription'], equals('Coordinate delivery truck'));
      expect(map['status'], equals('In Progress'));
      expect(map['siteName'], equals('Ajmer Central'));
      expect(map['assignedAt'], isA<Timestamp>());
    });

    test('Assignment copyWith updates values accurately', () {
      final assignment = Assignment(
        id: 'doc_3',
        siteId: 'site_1',
        volunteerId: 'user_1',
        taskDescription: 'Deliver rations',
        assignedAt: DateTime.now(),
        status: AssignmentStatus.pending,
      );

      final updated = assignment.copyWith(
        status: AssignmentStatus.completed,
        siteName: 'Jaipur South',
      );

      expect(updated.status, equals(AssignmentStatus.completed));
      expect(updated.siteName, equals('Jaipur South'));
      expect(updated.taskDescription, equals('Deliver rations'));
    });
  });
}

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
      expect(assignment.volunteerIds, equals(['user_vol_123']));
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
      expect(assignment.volunteerIds, isEmpty);
      expect(assignment.taskDescription, equals('No description provided'));
      expect(assignment.status, equals(AssignmentStatus.pending));
      expect(assignment.siteName, isNull);
    });

    test('Assignment toMap converts data back to Firestore structure', () {
      final testDate = DateTime(2026, 10, 9, 10, 0);
      final assignment = Assignment(
        id: 'doc_2',
        siteId: 'site_ajmer_02',
        volunteerIds: ['user_456', 'user_789'],
        taskDescription: 'Coordinate delivery truck',
        assignedAt: testDate,
        status: AssignmentStatus.inProgress,
        siteName: 'Ajmer Central',
      );

      final map = assignment.toMap();

      expect(map['siteId'], equals('site_ajmer_02'));
      expect(map['volunteerIds'], equals(['user_456', 'user_789']));
      expect(map['taskDescription'], equals('Coordinate delivery truck'));
      expect(map['status'], equals('In Progress'));
      expect(map['siteName'], equals('Ajmer Central'));
      expect(map['assignedAt'], isA<Timestamp>());
    });

    test('Assignment copyWith updates values accurately', () {
      final assignment = Assignment(
        id: 'doc_3',
        siteId: 'site_1',
        volunteerIds: ['user_1'],
        taskDescription: 'Deliver rations',
        assignedAt: DateTime.now(),
        status: AssignmentStatus.pending,
      );

      final updated = assignment.copyWith(
        status: AssignmentStatus.completed,
        siteName: 'Jaipur South',
        volunteerIds: ['user_1', 'user_2'],
      );

      expect(updated.status, equals(AssignmentStatus.completed));
      expect(updated.siteName, equals('Jaipur South'));
      expect(updated.taskDescription, equals('Deliver rations'));
      expect(updated.volunteerIds, equals(['user_1', 'user_2']));
    });

    test('Active assignment count includes pending and inProgress, excludes completed', () {
      final now = DateTime.now();
      final assignments = [
        Assignment(
          id: 'a1',
          siteId: 's1',
          volunteerIds: ['vol_1'],
          taskDescription: 'Task 1',
          assignedAt: now,
          status: AssignmentStatus.pending,
        ),
        Assignment(
          id: 'a2',
          siteId: 's1',
          volunteerIds: ['vol_1', 'vol_2'],
          taskDescription: 'Task 2',
          assignedAt: now,
          status: AssignmentStatus.inProgress,
        ),
        Assignment(
          id: 'a3',
          siteId: 's1',
          volunteerIds: ['vol_1'],
          taskDescription: 'Task 3',
          assignedAt: now,
          status: AssignmentStatus.completed,
        ),
      ];

      var pending = 0;
      var inProgress = 0;

      for (final a in assignments) {
        if (a.status == AssignmentStatus.pending) {
          pending++;
        } else if (a.status == AssignmentStatus.inProgress) {
          inProgress++;
        }
      }

      final activeCount = pending + inProgress;

      expect(pending, equals(1));
      expect(inProgress, equals(1));
      expect(activeCount, equals(2));
    });

    test('Assignments deduplicate by document ID when merging legacy and new queries', () {
      final now = DateTime.now();
      final legacyAssignment = Assignment(
        id: 'dup_1',
        siteId: 's1',
        volunteerIds: ['vol_1'],
        taskDescription: 'Legacy task',
        assignedAt: now,
        status: AssignmentStatus.pending,
      );

      final multiAssignment = Assignment(
        id: 'dup_1',
        siteId: 's1',
        volunteerIds: ['vol_1', 'vol_2'],
        taskDescription: 'Multi volunteer updated task',
        assignedAt: now,
        status: AssignmentStatus.inProgress,
      );

      final merged = <String, Assignment>{};
      merged[legacyAssignment.id] = legacyAssignment;
      merged[multiAssignment.id] = multiAssignment;

      expect(merged.length, equals(1));
      expect(merged['dup_1']!.status, equals(AssignmentStatus.inProgress));
      expect(merged['dup_1']!.volunteerIds, contains('vol_1'));
    });
  });
}

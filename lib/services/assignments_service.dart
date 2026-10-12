import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/assignment.dart';

/// Service responsible for managing Firestore operations for the `Assignments` collection.
///
/// Strictly isolated to the Volunteer Assignments module.
/// Does not modify or store data inside `Inventory` or `Sites`.
///
/// Features resilient fallback for local development when Firestore security
/// rules are pending in the Firebase Console.
class AssignmentsService {
  final FirebaseFirestore _firestore;

  AssignmentsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assignmentsCollection =>
      _firestore.collection('Assignments');

  /// Indicates whether the service is operating in fallback mode due to
  /// pending/restricted Firestore security rules in the Firebase Console.
  static bool isUsingFallback = false;
  static String? lastFirestoreError;

  /// Default sample assignments for demonstration and testing.
  static List<Assignment> getDefaultSampleAssignments({String? volunteerId}) {
    final vId = (volunteerId != null && volunteerId.isNotEmpty)
        ? volunteerId
        : 'vol_demo';
    final now = DateTime.now();
    return [
      Assignment(
        id: 'assign-sample-1',
        siteId: 'jaipur-north',
        volunteerId: vId,
        taskDescription: 'Distribute 50 kg grain packs to Zone A shelters',
        assignedAt: now.subtract(const Duration(hours: 2)),
        status: AssignmentStatus.pending,
        siteName: 'Jaipur North',
      ),
      Assignment(
        id: 'assign-sample-2',
        siteId: 'jaipur-south',
        volunteerId: vId,
        taskDescription: 'Coordinate delivery truck and verify inventory distribution counts',
        assignedAt: now.subtract(const Duration(hours: 5)),
        status: AssignmentStatus.inProgress,
        siteName: 'Jaipur South',
      ),
      Assignment(
        id: 'assign-sample-3',
        siteId: 'ajmer-central',
        volunteerId: vId,
        taskDescription:
            'Handover emergency medical supplies and dry ration kits',
        assignedAt: now.subtract(const Duration(days: 1)),
        status: AssignmentStatus.completed,
        siteName: 'Ajmer Central',
      ),
    ];
  }

  /// In-memory cache to guarantee interactive volunteer workflows even when
  /// cloud security rules are pending.
  static final List<Assignment> _localAssignments = [];
  static final StreamController<List<Assignment>> _localStreamController =
      StreamController<List<Assignment>>.broadcast();

  static void _ensureInitialized({String? volunteerId}) {
    if (_localAssignments.isEmpty) {
      _localAssignments.addAll(
        getDefaultSampleAssignments(volunteerId: volunteerId),
      );
    }
  }

  static List<Assignment> _filterByVolunteer(
    List<Assignment> list,
    String volunteerId,
  ) {
    if (volunteerId.isEmpty) return List<Assignment>.from(list);
    final filtered = list
        .where(
          (a) =>
              a.volunteerId == volunteerId ||
              a.volunteerId == 'vol_demo' ||
              a.id.startsWith('assign-sample-'),
        )
        .toList();
    filtered.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    return filtered;
  }

  /// Streams assignments specifically assigned to the logged-in volunteer's UID.
  ///
  /// This query is explicitly structured with `.where('volunteerId', isEqualTo: volunteerId)`
  /// to ensure full compatibility with narrowly-scoped Firestore security rules.
  Stream<List<Assignment>> getVolunteerAssignmentsStream(String volunteerId) {
    _ensureInitialized(volunteerId: volunteerId);

    late StreamController<List<Assignment>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<Assignment>>(
      onListen: () {
        // Immediately emit local cache so the UI never hangs on loading
        controller.add(_filterByVolunteer(_localAssignments, volunteerId));

        // Connect to Firestore
        firestoreSub = _assignmentsCollection
            .where('volunteerId', isEqualTo: volunteerId)
            .snapshots()
            .listen(
              (snapshot) {
                isUsingFallback = false;
                lastFirestoreError = null;
                final remoteAssignments = snapshot.docs
                    .map((doc) => Assignment.fromFirestore(doc))
                    .toList();
                remoteAssignments.sort(
                  (a, b) => b.assignedAt.compareTo(a.assignedAt),
                );

                // Update local cache
                _localAssignments
                  ..removeWhere((a) => a.volunteerId == volunteerId)
                  ..addAll(remoteAssignments);

                if (!controller.isClosed) {
                  controller.add(remoteAssignments);
                }
              },
              onError: (error) {
                isUsingFallback = true;
                lastFirestoreError = error.toString();
                if (!controller.isClosed) {
                  controller.add(
                    _filterByVolunteer(_localAssignments, volunteerId),
                  );
                }
              },
            );

        // Listen for local mutations (e.g. status updates)
        localSub = _localStreamController.stream.listen((all) {
          if (!controller.isClosed) {
            controller.add(_filterByVolunteer(all, volunteerId));
          }
        });
      },
      onCancel: () {
        firestoreSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Streams all assignments across the organization (intended for ADMIN users).
  Stream<List<Assignment>> getAllAssignmentsStream() {
    _ensureInitialized();

    late StreamController<List<Assignment>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<Assignment>>(
      onListen: () {
        final sorted = List<Assignment>.from(_localAssignments)
          ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
        controller.add(sorted);

        firestoreSub = _assignmentsCollection.snapshots().listen(
          (snapshot) {
            isUsingFallback = false;
            lastFirestoreError = null;
            final remoteAssignments = snapshot.docs
                .map((doc) => Assignment.fromFirestore(doc))
                .toList();
            remoteAssignments.sort(
              (a, b) => b.assignedAt.compareTo(a.assignedAt),
            );

            _localAssignments
              ..clear()
              ..addAll(remoteAssignments);

            if (!controller.isClosed) {
              controller.add(remoteAssignments);
            }
          },
          onError: (error) {
            isUsingFallback = true;
            lastFirestoreError = error.toString();
            final current = List<Assignment>.from(_localAssignments)
              ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
            if (!controller.isClosed) {
              controller.add(current);
            }
          },
        );

        localSub = _localStreamController.stream.listen((all) {
          if (!controller.isClosed) {
            final sorted = List<Assignment>.from(all)
              ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
            controller.add(sorted);
          }
        });
      },
      onCancel: () {
        firestoreSub?.cancel();
        localSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Updates an assignment's status.
  ///
  /// Enforces client-side authorization check: a volunteer can only update
  /// their own assignment, while admins can manage any assignment.
  /// Returns `true` if persisted to Firestore, `false` if saved to local fallback cache.
  Future<bool> updateAssignmentStatus({
    required String assignmentId,
    required AssignmentStatus newStatus,
    required String currentUserId,
    bool isAdmin = false,
    String? assignedVolunteerId,
  }) async {
    // Client-side guard: Prevent volunteers from updating assignments belonging to someone else
    if (!isAdmin &&
        assignedVolunteerId != null &&
        assignedVolunteerId.isNotEmpty &&
        currentUserId.isNotEmpty &&
        assignedVolunteerId != currentUserId &&
        !assignmentId.startsWith('assign-sample-')) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message:
            'Volunteers are only permitted to update their own assignments.',
      );
    }

    bool persisted = false;
    try {
      await _assignmentsCollection.doc(assignmentId).update({
        'status': newStatus.label,
      });
      persisted = true;
    } catch (e) {
      isUsingFallback = true;
      lastFirestoreError = e.toString();
    }

    // Update in-memory cache so status transitions reflect in the UI immediately
    final index = _localAssignments.indexWhere((a) => a.id == assignmentId);
    if (index != -1) {
      _localAssignments[index] = _localAssignments[index].copyWith(
        status: newStatus,
      );
      _localStreamController.add(List<Assignment>.from(_localAssignments));
    }

    return persisted;
  }

  /// Creates a new assignment in the `Assignments` collection.
  Future<String> createAssignment({
    required String siteId,
    required String volunteerId,
    required String taskDescription,
    DateTime? assignedAt,
    String? siteName,
  }) async {
    final assignment = Assignment(
      id: 'assign_${DateTime.now().millisecondsSinceEpoch}',
      siteId: siteId.trim(),
      volunteerId: volunteerId.trim(),
      taskDescription: taskDescription.trim(),
      assignedAt: assignedAt ?? DateTime.now(),
      status: AssignmentStatus.pending,
      siteName: siteName?.trim(),
    );

    String docId = assignment.id;
    try {
      final docRef = await _assignmentsCollection.add(assignment.toMap());
      docId = docRef.id;
    } catch (e) {
      isUsingFallback = true;
      lastFirestoreError = e.toString();
    }

    final localItem = assignment.copyWith(id: docId);
    _localAssignments.insert(0, localItem);
    _localStreamController.add(List<Assignment>.from(_localAssignments));

    return docId;
  }

  /// Deletes an assignment (admin only).
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _assignmentsCollection.doc(assignmentId).delete();
    } catch (e) {
      isUsingFallback = true;
      lastFirestoreError = e.toString();
    }

    _localAssignments.removeWhere((a) => a.id == assignmentId);
    _localStreamController.add(List<Assignment>.from(_localAssignments));
  }
}

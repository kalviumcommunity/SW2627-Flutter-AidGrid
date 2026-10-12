import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/distribution_record.dart';

/// Dedicated service responsible for retrieving distribution records from Firestore.
///
/// Strictly isolated to the Distribution History module:
/// - Reads from the `Distributions` Firestore collection.
/// - Does not modify or deduct inventory quantities.
/// - Does not create production distributions.
/// - Provides fallback handling when Firestore security rules are pending in Firebase Console.
class DistributionHistoryService {
  final FirebaseFirestore _firestore;

  DistributionHistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _distributionsCollection =>
      _firestore.collection('Distributions');

  /// Indicates whether the service is operating in fallback mode due to
  /// pending/restricted Firestore security rules in Firebase Console.
  static bool isUsingFallback = false;
  static String? lastFirestoreError;

  /// Default sample distributions for demonstration when Firestore security rules
  /// are not yet deployed in the Firebase Console.
  static List<DistributionRecord> getDefaultSampleDistributions() {
    final now = DateTime.now();
    return [
      DistributionRecord(
        id: 'dist-sample-1',
        itemId: 'inv_rice_01',
        itemName: 'Rice (Basmati)',
        siteId: 'jaipur-north',
        siteName: 'Jaipur North',
        quantity: 20,
        unit: 'kg',
        volunteerId: 'vol_rahul',
        volunteerName: 'Rahul',
        distributedAt: now.subtract(const Duration(minutes: 18)),
        assignmentId: 'assign-sample-1',
      ),
      DistributionRecord(
        id: 'dist-sample-2',
        itemId: 'inv_dal_02',
        itemName: 'Dal / Lentils',
        siteId: 'jaipur-north',
        siteName: 'Jaipur North',
        quantity: 10,
        unit: 'kg',
        volunteerId: 'vol_ananya',
        volunteerName: 'Ananya',
        distributedAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        assignmentId: 'assign-sample-2',
      ),
      DistributionRecord(
        id: 'dist-sample-3',
        itemId: 'inv_wheat_03',
        itemName: 'Wheat Ration Packs',
        siteId: 'jaipur-south',
        siteName: 'Jaipur South',
        quantity: 15,
        unit: 'kg',
        volunteerId: 'vol_arya',
        volunteerName: 'Arya Tiwari',
        distributedAt: now.subtract(const Duration(hours: 3)),
      ),
      DistributionRecord(
        id: 'dist-sample-4',
        itemId: 'inv_rice_01',
        itemName: 'Rice (Basmati)',
        siteId: 'ajmer-central',
        siteName: 'Ajmer Central',
        quantity: 35,
        unit: 'kg',
        volunteerId: 'vol_rahul',
        volunteerName: 'Rahul',
        distributedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static final List<DistributionRecord> _localDistributions = [];
  static final StreamController<List<DistributionRecord>>
  _localStreamController =
      StreamController<List<DistributionRecord>>.broadcast();

  static void _ensureInitialized() {
    if (_localDistributions.isEmpty) {
      _localDistributions.addAll(getDefaultSampleDistributions());
    }
  }

  /// Streams real-time distribution history across the entire organization,
  /// sorted newest first.
  Stream<List<DistributionRecord>> getDistributionHistoryStream() {
    _ensureInitialized();

    late StreamController<List<DistributionRecord>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    controller = StreamController<List<DistributionRecord>>(
      onListen: () {
        if (isUsingFallback) {
          final sorted = List<DistributionRecord>.from(_localDistributions)
            ..sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
          controller.add(sorted);
        }

        // Connect to Firestore collection
        firestoreSub = _distributionsCollection.snapshots().listen(
          (snapshot) {
            isUsingFallback = false;
            lastFirestoreError = null;
            final records = snapshot.docs
                .map((doc) => DistributionRecord.fromFirestore(doc))
                .toList();
            records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));

            _localDistributions
              ..clear()
              ..addAll(records);

            if (!controller.isClosed) {
              controller.add(records);
            }
          },
          onError: (error) {
            isUsingFallback = true;
            lastFirestoreError = error.toString();
            final sorted = List<DistributionRecord>.from(_localDistributions)
              ..sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
            if (!controller.isClosed) {
              controller.add(sorted);
            }
          },
        );

        localSub = _localStreamController.stream.listen((records) {
          if (!controller.isClosed) {
            final sorted = List<DistributionRecord>.from(records)
              ..sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
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

  /// Streams distribution history for a specific volunteer UID.
  Stream<List<DistributionRecord>> getVolunteerDistributionHistoryStream(
    String volunteerId,
  ) {
    _ensureInitialized();

    late StreamController<List<DistributionRecord>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? localSub;

    List<DistributionRecord> filter(List<DistributionRecord> list) {
      if (volunteerId.isEmpty) return list;
      return list
          .where(
            (r) =>
                r.volunteerId == volunteerId || r.id.startsWith('dist-sample-'),
          )
          .toList()
        ..sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
    }

    controller = StreamController<List<DistributionRecord>>(
      onListen: () {
        controller.add(filter(_localDistributions));

        firestoreSub = _distributionsCollection
            .where('volunteerId', isEqualTo: volunteerId)
            .snapshots()
            .listen(
              (snapshot) {
                isUsingFallback = false;
                lastFirestoreError = null;
                final records = snapshot.docs
                    .map((doc) => DistributionRecord.fromFirestore(doc))
                    .toList();
                records.sort(
                  (a, b) => b.distributedAt.compareTo(a.distributedAt),
                );

                if (!controller.isClosed) {
                  controller.add(records);
                }
              },
              onError: (error) {
                isUsingFallback = true;
                lastFirestoreError = error.toString();
                if (!controller.isClosed) {
                  controller.add(filter(_localDistributions));
                }
              },
            );

        localSub = _localStreamController.stream.listen((records) {
          if (!controller.isClosed) {
            controller.add(filter(records));
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
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/distribution_record.dart';

/// Dedicated service responsible for retrieving distribution records from Cloud Firestore.
///
/// Strictly isolated to the Distribution History module:
/// - Reads from the `Distributions` Firestore collection.
/// - Converts Firestore documents into immutable `DistributionRecord` instances.
/// - Sorts records newest first (`distributedAt` descending).
/// - Exposes real-time streams for reactive UI updates.
/// - Does NOT write to `Distributions` or modify `Inventory`.
class DistributionHistoryService {
  final FirebaseFirestore _firestore;

  DistributionHistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _distributionsCollection =>
      _firestore.collection('Distributions');

  /// Streams real-time distribution history across the entire organization,
  /// sorted newest first.
  ///
  /// Emits real Firestore data. If the collection is empty, emits an empty list `[]`.
  /// Propagates Firestore errors (e.g., permission-denied) to the stream.
  Stream<List<DistributionRecord>> getDistributionHistoryStream() {
    return _distributionsCollection.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => DistributionRecord.fromFirestore(doc))
          .toList();
      records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
      return records;
    });
  }

  /// Streams distribution history specifically recorded by a volunteer's UID,
  /// sorted newest first.
  ///
  /// Uses `.where('volunteerId', isEqualTo: volunteerId)` to adhere to scoped
  /// Firestore security rules and prevent unauthorized data leakage.
  Stream<List<DistributionRecord>> getVolunteerDistributionHistoryStream(
    String volunteerId,
  ) {
    final vId = volunteerId.trim();
    if (vId.isEmpty) {
      return Stream.value(<DistributionRecord>[]);
    }

    return _distributionsCollection
        .where('volunteerId', isEqualTo: vId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => DistributionRecord.fromFirestore(doc))
              .toList();
          records.sort((a, b) => b.distributedAt.compareTo(a.distributedAt));
          return records;
        });
  }

  /// Default sample distributions for automated unit testing and preview fixtures.
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
}

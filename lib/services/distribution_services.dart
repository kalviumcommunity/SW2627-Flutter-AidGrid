import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/distribution_record.dart';

class DistributionService {
  final FirebaseFirestore _firestore;

  DistributionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Deducts inventory and records a distribution atomically.
  Future<String> recordDistribution({
    required String itemId,
    required String siteId,
    required int quantity,
    String? assignmentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to record a distribution.');
    }
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    final itemRef = _firestore.collection('Inventory').doc(itemId);
    final siteRef = _firestore.collection('Sites').doc(siteId);
    final distributionRef = _firestore.collection('Distributions').doc();

    await _firestore.runTransaction((transaction) async {
      // Read both documents before making any writes.
      final itemSnapshot = await transaction.get(itemRef);
      final siteSnapshot = await transaction.get(siteRef);

      if (!itemSnapshot.exists) {
        throw StateError('The selected inventory item no longer exists.');
      }

      if (!siteSnapshot.exists) {
        throw StateError('The selected site no longer exists.');
      }

      final itemData = itemSnapshot.data()!;
      final siteData = siteSnapshot.data()!;

      final rawStock = itemData['quantity'];
      if (rawStock is! num) {
        throw StateError('The inventory quantity is invalid.');
      }

      final availableStock = rawStock.toInt();

      if (availableStock < quantity) {
        throw StateError('Insufficient stock. Available: $availableStock.');
      }

      final itemName = itemData['name'];
      final unit = itemData['unit'];
      final siteName = siteData['name'];

      if (itemName is! String || unit is! String || siteName is! String) {
        throw StateError('The inventory or site data is incomplete.');
      }

      final record = DistributionRecord(
        id: distributionRef.id,
        itemId: itemId,
        itemName: itemName,
        siteId: siteId,
        siteName: siteName,
        quantity: quantity,
        unit: unit,
        volunteerId: user.uid,
        volunteerName: user.displayName ?? user.email ?? 'Unknown',
        distributedAt: DateTime.now(),
        assignmentId: assignmentId,
      );

      transaction.update(itemRef, {'quantity': availableStock - quantity});

      transaction.set(distributionRef, record.toMap());
    });

    return distributionRef.id;
  }
}

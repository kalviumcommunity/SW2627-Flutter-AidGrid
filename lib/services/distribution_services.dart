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
    required String volunteerId,
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
    final volunteerRef = _firestore.collection('users').doc(volunteerId);
    final assignmentRef = assignmentId == null
        ? null
        : _firestore.collection('Assignments').doc(assignmentId);

    await _firestore.runTransaction((transaction) async {
      // Read both documents before making any writes.
      String? assignmentDescription;
      final itemSnapshot = await transaction.get(itemRef);
      final siteSnapshot = await transaction.get(siteRef);
      final volunteerSnapshot = await transaction.get(volunteerRef);
      final assignmentSnapshot = assignmentRef == null
          ? null
          : await transaction.get(assignmentRef);

      if (!itemSnapshot.exists) {
        throw StateError('The selected inventory item no longer exists.');
      }

      if (!siteSnapshot.exists) {
        throw StateError('The selected site no longer exists.');
      }

      if (!volunteerSnapshot.exists) {
        throw StateError('The selected volunteer no longer exists.');
      }

      final volunteerData = volunteerSnapshot.data()!;

      if (volunteerData['role'] != 'VOLUNTEER') {
        throw StateError('The selected user is not a volunteer.');
      }

      if (assignmentSnapshot != null) {
        if (!assignmentSnapshot.exists) {
          throw StateError('The selected assignment no longer exists.');
        }

        final assignmentData = assignmentSnapshot.data()!;
        assignmentDescription = assignmentData['taskDescription'] as String?;

        final rawVolunteerIds = assignmentData['volunteerIds'];

        final assignedVolunteerIds = rawVolunteerIds is List
            ? rawVolunteerIds.whereType<String>().toList()
            : [
                if (assignmentData['volunteerId'] is String)
                  assignmentData['volunteerId'] as String,
              ];

        if (!assignedVolunteerIds.contains(volunteerId)) {
          throw StateError(
            'The selected assignment does not belong to this volunteer.',
          );
        }

        if (assignmentData['siteId'] != siteId) {
          throw StateError(
            'The selected assignment belongs to a different site.',
          );
        }

        final status = assignmentData['status'];

        if (status != 'Pending' && status != 'In Progress') {
          throw StateError(
            'The selected assignment is no longer eligible for distribution.',
          );
        }
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
        volunteerId: volunteerId,
        volunteerName:
            volunteerData['name'] as String? ??
            volunteerData['email'] as String? ??
            'Unknown',
        distributedAt: DateTime.now(),
        assignmentId: assignmentId,
        assignmentDescription: assignmentDescription,
      );

      transaction.update(itemRef, {'quantity': availableStock - quantity});

      transaction.set(distributionRef, record.toMap());
    });

    return distributionRef.id;
  }
}

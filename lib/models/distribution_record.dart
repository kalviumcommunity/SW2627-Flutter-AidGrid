import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a recorded food or aid distribution in the AidGrid application.
///
/// Firestore collection: `Distributions`
/// Document schema:
/// - `itemId`: String (Inventory document ID)
/// - `itemName`: String (Name of the food / inventory item)
/// - `siteId`: String (Site document ID)
/// - `siteName`: String (Name of the community site)
/// - `quantity`: Number (Quantity distributed)
/// - `unit`: String (Unit of measurement, e.g., 'kg', 'packs', 'bags')
/// - `volunteerId`: String (UID of the distributing user)
/// - `volunteerName`: String (Display name or email of the volunteer)
/// - `distributedAt`: Timestamp (Date and time of distribution)
/// - `assignmentId`: String? (Optional reference to an associated volunteer assignment)
class DistributionRecord {
  final String id;
  final String itemId;
  final String itemName;
  final String siteId;
  final String siteName;
  final num quantity;
  final String unit;
  final String volunteerId;
  final String volunteerName;
  final DateTime distributedAt;
  final String? assignmentId;
  final String? assignmentDescription;

  const DistributionRecord({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.siteId,
    required this.siteName,
    required this.quantity,
    required this.unit,
    required this.volunteerId,
    required this.volunteerName,
    required this.distributedAt,
    this.assignmentId,
    this.assignmentDescription,
  });

  /// Factory constructor to parse a Firestore document snapshot.
  factory DistributionRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return DistributionRecord.fromMap(data, doc.id);
  }

  /// Factory constructor to parse map data with a known document ID.
  factory DistributionRecord.fromMap(Map<String, dynamic> data, String id) {
    // Parse quantity safely
    final rawQuantity = data['quantity'];
    num parsedQuantity = 0;
    if (rawQuantity is num) {
      parsedQuantity = rawQuantity;
    } else if (rawQuantity is String) {
      parsedQuantity = num.tryParse(rawQuantity) ?? 0;
    }

    // Parse date/timestamp safely
    DateTime parsedDate;
    final rawDate = data['distributedAt'] ?? data['timestamp'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return DistributionRecord(
      id: id,
      itemId: (data['itemId'] as String?)?.trim() ?? '',
      itemName: (data['itemName'] as String?)?.trim() ?? 'Unknown item',
      siteId: (data['siteId'] as String?)?.trim() ?? '',
      siteName: (data['siteName'] as String?)?.trim() ?? 'Unknown site',
      quantity: parsedQuantity,
      unit: (data['unit'] as String?)?.trim() ?? 'units',
      volunteerId: (data['volunteerId'] as String?)?.trim() ?? '',
      volunteerName: (data['volunteerName'] as String?)?.trim() ?? 'Volunteer',
      distributedAt: parsedDate,
      assignmentId: (data['assignmentId'] as String?)?.trim(),
      assignmentDescription: (data['assignmentDescription'] as String?)?.trim(),
    );
  }

  /// Converts the DistributionRecord model to a map for Firestore persistence.
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'siteId': siteId,
      'siteName': siteName,
      'quantity': quantity,
      'unit': unit,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'distributedAt': Timestamp.fromDate(distributedAt),
      if (assignmentId != null && assignmentId!.isNotEmpty)
        'assignmentId': assignmentId,
      if (assignmentDescription != null && assignmentDescription!.isNotEmpty)
        'assignmentDescription': assignmentDescription,
    };
  }

  DistributionRecord copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? siteId,
    String? siteName,
    num? quantity,
    String? unit,
    String? volunteerId,
    String? volunteerName,
    DateTime? distributedAt,
    String? assignmentId,
    String? assignmentDescription,
  }) {
    return DistributionRecord(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      distributedAt: distributedAt ?? this.distributedAt,
      assignmentId: assignmentId ?? this.assignmentId,
      assignmentDescription: assignmentDescription ?? this.assignmentDescription,
    );
  }
}

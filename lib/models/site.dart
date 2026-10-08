import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a distribution site or community hub in the AidGrid network.
///
/// Firestore collection: `Sites`
/// Document schema:
/// - `name`: String
/// - `location`: String
/// - `beneficiaries`: Number (integer)
/// - `isActive`: Boolean
class Site {
  final String id;
  final String name;
  final String location;
  final int beneficiaries;
  final bool isActive;

  const Site({
    required this.id,
    required this.name,
    required this.location,
    required this.beneficiaries,
    required this.isActive,
  });

  /// Factory constructor to parse a Firestore document snapshot.
  factory Site.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Site.fromMap(data, doc.id);
  }

  /// Factory constructor to parse map data with a known document ID.
  factory Site.fromMap(Map<String, dynamic> data, String id) {
    final rawBeneficiaries = data['beneficiaries'];
    int beneficiariesCount = 0;
    if (rawBeneficiaries is num) {
      beneficiariesCount = rawBeneficiaries.toInt();
    } else if (rawBeneficiaries is String) {
      beneficiariesCount = int.tryParse(rawBeneficiaries) ?? 0;
    }

    return Site(
      id: id,
      name: (data['name'] as String?)?.trim() ?? 'Unnamed Site',
      location: (data['location'] as String?)?.trim() ?? 'Unknown Location',
      beneficiaries: beneficiariesCount,
      isActive: data['isActive'] == true,
    );
  }

  /// Converts the Site model to a map for Firestore persistence.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'beneficiaries': beneficiaries,
      'isActive': isActive,
    };
  }

  Site copyWith({
    String? id,
    String? name,
    String? location,
    int? beneficiaries,
    bool? isActive,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      isActive: isActive ?? this.isActive,
    );
  }
}

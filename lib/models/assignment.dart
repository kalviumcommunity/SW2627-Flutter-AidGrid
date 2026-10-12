import 'package:cloud_firestore/cloud_firestore.dart';

/// The three canonical statuses for a volunteer assignment.
enum AssignmentStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  final String label;
  const AssignmentStatus(this.label);

  static AssignmentStatus fromString(String? value) {
    if (value == null) return AssignmentStatus.pending;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'in progress' ||
        normalized == 'inprogress' ||
        normalized == 'in_progress') {
      return AssignmentStatus.inProgress;
    }
    if (normalized == 'completed') {
      return AssignmentStatus.completed;
    }
    return AssignmentStatus.pending;
  }
}

/// Represents an assignment for a volunteer in the AidGrid application.
///
/// Firestore collection: `Assignments`
/// Document schema:
/// - `siteId`: String
/// - `volunteerId`: String (UID of the assigned volunteer)
/// - `taskDescription`: String
/// - `assignedAt`: Timestamp / DateTime
/// - `status`: String ('Pending', 'In Progress', 'Completed')
/// - Optional cached `siteName` for display convenience
class Assignment {
  final String id;
  final String siteId;
  final String volunteerId;
  final String taskDescription;
  final DateTime assignedAt;
  final AssignmentStatus status;
  final String? siteName;

  const Assignment({
    required this.id,
    required this.siteId,
    required this.volunteerId,
    required this.taskDescription,
    required this.assignedAt,
    required this.status,
    this.siteName,
  });

  /// Factory constructor to parse a Firestore document snapshot.
  factory Assignment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Assignment.fromMap(data, doc.id);
  }

  /// Factory constructor to parse map data with a known document ID.
  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate;
    final rawDate = data['assignedAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Assignment(
      id: id,
      siteId: (data['siteId'] as String?)?.trim() ?? '',
      volunteerId: (data['volunteerId'] as String?)?.trim() ?? '',
      taskDescription:
          (data['taskDescription'] as String?)?.trim() ??
          'No description provided',
      assignedAt: parsedDate,
      status: AssignmentStatus.fromString(data['status'] as String?),
      siteName: (data['siteName'] as String?)?.trim(),
    );
  }

  /// Converts the Assignment model to a map for Firestore persistence.
  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'volunteerId': volunteerId,
      'taskDescription': taskDescription,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'status': status.label,
      if (siteName != null && siteName!.isNotEmpty) 'siteName': siteName,
    };
  }

  Assignment copyWith({
    String? id,
    String? siteId,
    String? volunteerId,
    String? taskDescription,
    DateTime? assignedAt,
    AssignmentStatus? status,
    String? siteName,
  }) {
    return Assignment(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      volunteerId: volunteerId ?? this.volunteerId,
      taskDescription: taskDescription ?? this.taskDescription,
      assignedAt: assignedAt ?? this.assignedAt,
      status: status ?? this.status,
      siteName: siteName ?? this.siteName,
    );
  }
}

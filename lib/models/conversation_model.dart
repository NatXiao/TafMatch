import 'package:cloud_firestore/cloud_firestore.dart';

/// A thread between an employer and a student, scoped to one job posting.
///
/// The document id is deterministic (`employerId_studentId_jobId`) so that an
/// employer tapping "Message" twice on the same posting always lands on the
/// same thread — while two different postings give two separate threads, even
/// with the same candidate.
class Conversation {
  final String id;
  final String employerId;
  final String studentId;
  final List<String> participants;

  /// The posting this thread belongs to. Part of the thread identity, not
  /// just context — see [buildId].
  final String jobId;
  final String jobTitle;

  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;

  /// Unread counter per participant uid, e.g. `{ 'uidA': 0, 'uidB': 3 }`.
  final Map<String, int> unreadCount;

  final DateTime? createdAt;

  const Conversation({
    required this.id,
    required this.employerId,
    required this.studentId,
    required this.participants,
    required this.jobId,
    this.jobTitle = '',
    this.lastMessage = '',
    this.lastSenderId = '',
    this.lastMessageAt,
    this.unreadCount = const {},
    this.createdAt,
  });

  /// Deterministic document id. The employer always comes first because only
  /// an employer can create a thread.
  static String buildId(String employerId, String studentId, String jobId) =>
      '${employerId}_${studentId}_$jobId';

  /// The uid of the person on the other side of the thread.
  String otherParticipant(String uid) =>
      uid == employerId ? studentId : employerId;

  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  bool get hasMessages => lastMessage.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'studentId': studentId,
      'participants': participants,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageAt':
          lastMessageAt == null ? null : Timestamp.fromDate(lastMessageAt!),
      'unreadCount': unreadCount,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return Conversation(
      id: doc.id,
      employerId: data['employerId'] ?? '',
      studentId: data['studentId'] ?? '',
      participants: List<String>.from(data['participants'] ?? const []),
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastSenderId: data['lastSenderId'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: (data['unreadCount'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

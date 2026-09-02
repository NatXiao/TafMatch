import 'package:cloud_firestore/cloud_firestore.dart';

/// A one-to-one thread between an employer and a student.
///
/// The document id is deterministic (`employerId_studentId`) so that an
/// employer tapping "Message" twice always lands on the same thread.
class Conversation {
  final String id;
  final String employerId;
  final String studentId;
  final List<String> participants;

  /// The job the employer was looking at when the thread was opened.
  /// Kept for context only — the thread itself is per pair, not per job.
  final String? originJobId;
  final String? originJobTitle;

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
    this.originJobId,
    this.originJobTitle,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.lastMessageAt,
    this.unreadCount = const {},
    this.createdAt,
  });

  /// Deterministic document id. The employer always comes first because only
  /// an employer can create a thread.
  static String buildId(String employerId, String studentId) =>
      '${employerId}_$studentId';

  /// The uid of the person on the other side of the thread.
  String otherParticipant(String uid) => uid == employerId ? studentId : employerId;

  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  bool get hasMessages => lastMessage.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'employerId': employerId,
      'studentId': studentId,
      'participants': participants,
      'originJobId': originJobId,
      'originJobTitle': originJobTitle,
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
      originJobId: data['originJobId'],
      originJobTitle: data['originJobTitle'],
      lastMessage: data['lastMessage'] ?? '',
      lastSenderId: data['lastSenderId'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: (data['unreadCount'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

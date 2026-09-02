import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside `conversations/{conversationId}/messages`.
class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'sentAt': sentAt == null ? null : Timestamp.fromDate(sentAt!),
    };
  }

  factory Message.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}

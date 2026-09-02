import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taf_match/models/conversation_model.dart';
import 'package:taf_match/models/message_model.dart';

class FirestoreChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

  /// All threads [userId] takes part in, most recently active first.
  ///
  /// Requires a composite index on `participants` (array-contains) +
  /// `lastMessageAt` (desc). Firestore logs a link to create it on first run.
  Stream<List<Conversation>> watchForUser(String userId) {
    return _conversations
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  /// Newest first — pair this with a `reverse: true` ListView so new messages
  /// appear at the bottom without having to scroll manually.
  Stream<List<Message>> watchMessages(String conversationId,
      {int limit = 200}) {
    return _messages(conversationId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<Conversation?> findById(String conversationId) async {
    final snapshot = await _conversations.doc(conversationId).get();
    if (!snapshot.exists) return null;
    return Conversation.fromFirestore(snapshot);
  }

  /// Returns the existing thread for this (employer, student, job) triplet,
  /// or creates it. Only an employer should ever call this — the Firestore
  /// rules enforce it.
  Future<Conversation> openConversation({
    required String employerId,
    required String studentId,
    required String jobId,
    required String jobTitle,
  }) async {
    final id = Conversation.buildId(employerId, studentId, jobId);
    final ref = _conversations.doc(id);

    final existing = await ref.get();
    if (existing.exists) {
      final conversation = Conversation.fromFirestore(existing);
      if (conversation.deletedAt == null) return conversation;

      // The employer had deleted this thread: revive it empty rather than
      // resurrecting a stale one.
      await ref.update({
        'deletedAt': null,
        'jobTitle': jobTitle,
        'lastMessageAt': Timestamp.now(),
        'unreadCount': {employerId: 0, studentId: 0},
      });
      return Conversation.fromFirestore(await ref.get());
    }

    final now = Timestamp.now();
    await ref.set({
      'employerId': employerId,
      'studentId': studentId,
      'participants': [employerId, studentId],
      'jobId': jobId,
      'jobTitle': jobTitle,
      'lastMessage': '',
      'lastSenderId': '',
      'lastMessageAt': now,
      'unreadCount': {employerId: 0, studentId: 0},
      'createdAt': now,
    });

    final created = await ref.get();
    return Conversation.fromFirestore(created);
  }

  /// Writes the message and updates the thread preview + the recipient's
  /// unread counter in a single batch, so the list screen never shows a
  /// preview that doesn't match the last message.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final now = Timestamp.now();
    final batch = _firestore.batch();

    batch.set(_messages(conversationId).doc(), {
      'senderId': senderId,
      'text': text,
      'sentAt': now,
    });

    batch.update(_conversations.doc(conversationId), {
      'lastMessage': text,
      'lastSenderId': senderId,
      'lastMessageAt': now,
      'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> markRead({
    required String conversationId,
    required String userId,
  }) async {
    await _conversations.doc(conversationId).update({
      'unreadCount.$userId': 0,
    });
  }

  /// Deletes the thread for both sides. Firestore has no cascade delete, so
  /// the messages subcollection has to go explicitly, in batches of 500 —
  /// the write limit per batch.
  Future<void> deleteConversation(String conversationId) async {
    final messages = await _messages(conversationId).get();

    for (var i = 0; i < messages.docs.length; i += 500) {
      final batch = _firestore.batch();
      for (final doc in messages.docs.skip(i).take(500)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final ref = _conversations.doc(conversationId);
    final snapshot = await ref.get();
    final participants =
        List<String>.from(snapshot.data()?['participants'] ?? const []);

    await ref.update({
      'deletedAt': Timestamp.now(),
      'lastMessage': '',
      'lastSenderId': '',
      // Reset each counter by name: a whole-map write is merged rather than
      // replaced by some Firestore implementations.
      for (final uid in participants) 'unreadCount.$uid': 0,
    });
  }


}

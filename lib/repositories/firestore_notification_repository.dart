import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taf_match/models/notification_model.dart';


class FirestoreNotificationRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('notifications');

  Stream<List<AppNotification>> watchForUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Creates a notification document, which fans out to a push via the
  /// Cloud Function trigger.
  Future<void> create({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? jobId,
    String? applicationId,
    String? conversationId,
    int? unreadCount,
  }) async {
    if(conversationId != null && unreadCount != null) {
      await upsertMessageNotification(
        userId: userId,
        conversationId: conversationId,
        jobId: jobId ?? '',
        jobTitle: title,
        unreadCount: unreadCount,

      );
      return;
    }else {
    await _collection.add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'jobId': jobId,
      'applicationId': applicationId,
      'isRead': false,
      'createdAt': Timestamp.now(),
      'conversationId': conversationId,
      'unreadCount': unreadCount,
    });
    }
  }

  Future<void> upsertMessageNotification({
    required String userId,
    required String conversationId,
    required String jobId,
    required String jobTitle,
    required int unreadCount,
  }) async {
    if (unreadCount <= 0) return;

    final notificationId = '${conversationId}_$userId';

    await _collection.doc(notificationId).set({
      'userId': userId,
      'title': 'New messages',
      'message': unreadCount == 1
          ? '1 unread message in "$jobTitle"'
          : '$unreadCount unread messages in "$jobTitle"',
      'type': 'new_message',
      'jobId': jobId,
      'conversationId': conversationId,
      'unreadCount': unreadCount,
      'isRead': false,
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final unread = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
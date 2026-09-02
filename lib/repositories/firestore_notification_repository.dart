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
  }) async {
    await _collection.add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'jobId': jobId,
      'applicationId': applicationId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
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
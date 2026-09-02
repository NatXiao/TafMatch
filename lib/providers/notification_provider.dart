import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taf_match/models/notification_model.dart';
import 'package:taf_match/repositories/firestore_notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({FirestoreNotificationRepository? repository})
      : _repository = repository ?? FirestoreNotificationRepository();

  final FirestoreNotificationRepository _repository;

  StreamSubscription<List<AppNotification>>? _subscription;

  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void listenToNotifications(String userId) {
    _subscription?.cancel();

    if (userId.isEmpty) {
      _notifications = [];
      notifyListeners();
      return;
    }

    _subscription = _repository.watchForUser(userId).listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    });
  }

  /// Creates a notification for [userId]. This is what screens should call
  /// instead of touching FirestoreNotificationRepository directly — e.g.
  /// after a student applies, or an employer accepts/rejects an applicant.
  /// Writing the document is also what triggers the actual push, via the
  /// Cloud Function listening on the notifications collection.
  Future<void> notify({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? jobId,
    String? applicationId,
  }) {
    return _repository.create(
      userId: userId,
      title: title,
      message: message,
      type: type,
      jobId: jobId,
      applicationId: applicationId,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _repository.markAllAsRead(userId);
  }

  void clear() {
    _subscription?.cancel();
    _notifications = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taf_match/models/notification_model.dart';
import 'package:taf_match/repositories/firestore_notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreNotificationRepository _repository = FirestoreNotificationRepository();

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
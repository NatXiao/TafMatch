import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taf_match/models/notification_model.dart';
import 'package:taf_match/repositories/firestore_notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    FirestoreNotificationRepository? repository,
  }) : _repository = repository ?? FirestoreNotificationRepository();

  static GlobalKey<NavigatorState>? navigatorKey;

  final FirestoreNotificationRepository _repository;

  StreamSubscription<List<AppNotification>>? _subscription;

  List<AppNotification> _notifications = [];

  String? _listeningUserId;

  List<AppNotification> get notifications => _notifications;

  int get unreadCount {
    return _notifications
        .where((notification) => !notification.isRead)
        .length;
  }

  void listenToNotifications(String userId) {
    if (userId.isEmpty) {
      clear();
      return;
    }

    if (_listeningUserId == userId && _subscription != null) {
      return;
    }

    _subscription?.cancel();
    _listeningUserId = userId;
    _notifications = [];
    notifyListeners();

    _subscription = _repository.watchForUser(userId).listen(
      (notifications) {
        final previousIds = _notifications
            .map((notification) => notification.id)
            .toSet();

        final newUnreadCount = notifications
            .where(
              (notification) =>
                  !notification.isRead && !previousIds.contains(notification.id),
            )
            .length;

        _notifications = notifications;
        notifyListeners();

        if (_notifications.isNotEmpty && previousIds.isNotEmpty && newUnreadCount > 0) {
          _showNewNotificationPopup(newUnreadCount);
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Notification stream error for user $userId: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
      onDone: () {
        debugPrint('Notification stream closed for user $userId');
      },
    );
  }

  void _showNewNotificationPopup(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey?.currentContext;

      if (context == null) {
        debugPrint(
          'Cannot show notification popup: navigator context is null',
        );
        return;
      }

      final message = count == 1
          ? 'You have a new notification!'
          : 'You have $count new notifications!';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message),
            duration: const Duration(seconds: 4),
          ),
        );
    });
  }

  Future<void> notify({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? jobId,
    String? applicationId,
    String? conversationId,
    int? unreadCount,
  }) {
    return _repository.create(
      userId: userId,
      title: title,
      message: message,
      type: type,
      jobId: jobId,
      applicationId: applicationId,
      conversationId: conversationId,
      unreadCount: unreadCount,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );

    if (index != -1) {
      final updated = List<AppNotification>.from(_notifications);

      updated[index] = updated[index].copyWith(
        isRead: true,
      );

      _notifications = updated;

      notifyListeners();
    }

    await _repository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    _notifications = _notifications
        .map(
          (notification) =>
              notification.copyWith(isRead: true),
        )
        .toList();

    notifyListeners();

    await _repository.markAllAsRead(userId);
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;

    _listeningUserId = null;
    _notifications = [];

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
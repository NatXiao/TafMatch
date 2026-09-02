import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/notification_model.dart';
import 'package:taf_match/providers/notification_provider.dart';

import '../fakes.dart';

void main() {
  test('counts unread notifications', () {
    final repository = FakeNotificationRepository();
    final provider = NotificationProvider(repository: repository);

    provider.listenToNotifications('user-1');
    repository.emit([
      AppNotification(
        id: 'n1',
        userId: 'user-1',
        title: 'First',
        message: 'Message 1',
        type: 'general',
        isRead: false,
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: 'n2',
        userId: 'user-1',
        title: 'Second',
        message: 'Message 2',
        type: 'general',
        isRead: true,
        createdAt: DateTime.now(),
      ),
    ]);

    expect(provider.notifications.length, 2);
    expect(provider.unreadCount, 1);

    provider.dispose();
    repository.dispose();
  });

  test('marks a notification as read and updates unread count', () async {
    final repository = FakeNotificationRepository();
    final provider = NotificationProvider(repository: repository);

    provider.listenToNotifications('user-1');
    repository.emit([
      AppNotification(
        id: 'n1',
        userId: 'user-1',
        title: 'First',
        message: 'Message 1',
        type: 'general',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ]);

    await provider.markAsRead('n1');

    expect(provider.notifications.first.isRead, isTrue);
    expect(provider.unreadCount, 0);
    expect(repository.markAsReadCallCount, 1);

    provider.dispose();
    repository.dispose();
  });

  test('marks all notifications as read', () async {
    final repository = FakeNotificationRepository();
    final provider = NotificationProvider(repository: repository);

    provider.listenToNotifications('user-1');
    repository.emit([
      AppNotification(
        id: 'n1',
        userId: 'user-1',
        title: 'First',
        message: 'Message 1',
        type: 'general',
        isRead: false,
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: 'n2',
        userId: 'user-1',
        title: 'Second',
        message: 'Message 2',
        type: 'general',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ]);

    await provider.markAllAsRead('user-1');

    expect(provider.unreadCount, 0);
    expect(provider.notifications.every((n) => n.isRead), isTrue);
    expect(repository.markAllAsReadCallCount, 1);

    provider.dispose();
    repository.dispose();
  });
}

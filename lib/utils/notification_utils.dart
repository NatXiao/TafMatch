import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'General notifications',
  description: 'Job matches, applications and status updates',
  importance: Importance.high,
);

/// Must stay top-level: FCM invokes this in its own isolate when a push
/// arrives while the app is backgrounded or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android/iOS already display the notification automatically from the
  // "notification" payload when the app isn't in the foreground. Add
  // custom handling of message.data here if you need it later.
}

class NotificationUtils {
   static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Call once, before runApp(), so background/terminated pushes work and
  /// foreground pushes get displayed.
  static Future<void> setupBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  static Future<void> initialize(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus ==
        AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();

    if (token != null) {
      await saveToken(userId, token);
    }

    _messaging.onTokenRefresh.listen(
      (newToken) => saveToken(userId, newToken),
    );
  }

  static Future<void> saveToken(
    String userId,
    String token,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }

  /// Call on logout so a stale token on this device doesn't receive pushes
  /// meant for whichever user logs in next.
  static Future<void> clearToken(String userId) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}
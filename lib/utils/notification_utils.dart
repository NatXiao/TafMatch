import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationUtils {
   static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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
}
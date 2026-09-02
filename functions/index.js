const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Fires whenever a document is added to /notifications/{notificationId}
 * (e.g. by FirestoreNotificationRepository.create in the Flutter app) and
 * sends a push to every FCM token stored on that user's profile.
 */
exports.sendNotificationPush = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const notification = event.data?.data();
    if (!notification) return;

    const { userId, title, message, type, jobId, applicationId } = notification;
    if (!userId) return;

    const db = getFirestore();
    const userDoc = await db.collection('users').doc(userId).get();
    const tokens = userDoc.data()?.fcmTokens ?? [];

    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: title ?? 'Taf Match',
        body: message ?? '',
      },
      data: {
        type: type ?? '',
        jobId: jobId ?? '',
        applicationId: applicationId ?? '',
      },
    });

    // Drop tokens for uninstalled apps / expired registrations so the
    // array doesn't grow forever and future sends don't waste calls on them.
    const staleTokens = [];
    response.responses.forEach((res, i) => {
      if (!res.success && res.error?.code === 'messaging/registration-token-not-registered') {
        staleTokens.push(tokens[i]);
      }
    });

    if (staleTokens.length > 0) {
      await db.collection('users').doc(userId).update({
        fcmTokens: FieldValue.arrayRemove(...staleTokens),
      });
    }
  }
);
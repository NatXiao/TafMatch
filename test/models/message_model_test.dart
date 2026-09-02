import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/message_model.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  /// Writes [data] and reads it back as a real snapshot, so fromFirestore is
  /// exercised the same way it is in production.
  Future<Message> readBack(String id, Map<String, dynamic> data) async {
    final ref = firestore
        .collection('conversations')
        .doc('emp_stu_job')
        .collection('messages')
        .doc(id);
    await ref.set(data);
    return Message.fromFirestore(await ref.get());
  }

  group('fromFirestore', () {
    test('maps every field', () async {
      final sentAt = DateTime(2026, 3, 14, 9, 30);

      final message = await readBack('msg_1', {
        'senderId': 'emp',
        'text': 'Are you available Monday?',
        'sentAt': Timestamp.fromDate(sentAt),
      });

      expect(message.id, 'msg_1');
      expect(message.senderId, 'emp');
      expect(message.text, 'Are you available Monday?');
      expect(message.sentAt, sentAt);
    });

    test('survives a document with missing fields', () async {
      final message = await readBack('msg_1', {});

      expect(message.id, 'msg_1');
      expect(message.senderId, '');
      expect(message.text, '');
      expect(message.sentAt, isNull);
    });

    test('keeps an empty text as empty rather than null', () async {
      final message = await readBack('msg_1', {
        'senderId': 'emp',
        'text': '',
      });

      expect(message.text, '');
    });
  });

  group('toMap', () {
    test('round-trips through Firestore without losing data', () async {
      final sentAt = DateTime(2026, 3, 14, 9, 30);
      final original = Message(
        id: 'msg_1',
        senderId: 'emp',
        text: 'Hello',
        sentAt: sentAt,
      );

      final restored = await readBack(original.id, original.toMap());

      expect(restored.senderId, original.senderId);
      expect(restored.text, original.text);
      expect(restored.sentAt, original.sentAt);
    });

    test('writes a null timestamp when the message has none', () {
      const message = Message(id: 'msg_1', senderId: 'emp', text: 'Hello');

      expect(message.toMap()['sentAt'], isNull);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/conversation_model.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  /// Writes [data] and reads it back as a real snapshot, so fromFirestore is
  /// exercised the same way it is in production.
  Future<Conversation> readBack(
    String id,
    Map<String, dynamic> data,
  ) async {
    final ref = firestore.collection('conversations').doc(id);
    await ref.set(data);
    return Conversation.fromFirestore(await ref.get());
  }

  group('buildId', () {
    test('joins employer, student and job in that order', () {
      expect(
        Conversation.buildId('emp', 'stu', 'job'),
        'emp_stu_job',
      );
    });

    test('gives a different id for each posting', () {
      expect(
        Conversation.buildId('emp', 'stu', 'job_1'),
        isNot(Conversation.buildId('emp', 'stu', 'job_2')),
      );
    });

    test('is stable across calls', () {
      expect(
        Conversation.buildId('emp', 'stu', 'job'),
        Conversation.buildId('emp', 'stu', 'job'),
      );
    });
  });

  group('otherParticipant', () {
    const conversation = Conversation(
      id: 'emp_stu_job',
      employerId: 'emp',
      studentId: 'stu',
      participants: ['emp', 'stu'],
      jobId: 'job',
    );

    test('returns the student when asked by the employer', () {
      expect(conversation.otherParticipant('emp'), 'stu');
    });

    test('returns the employer when asked by the student', () {
      expect(conversation.otherParticipant('stu'), 'emp');
    });
  });

  group('unreadFor', () {
    test('returns the stored counter', () {
      const conversation = Conversation(
        id: 'emp_stu_job',
        employerId: 'emp',
        studentId: 'stu',
        participants: ['emp', 'stu'],
        jobId: 'job',
        unreadCount: {'emp': 0, 'stu': 3},
      );

      expect(conversation.unreadFor('stu'), 3);
      expect(conversation.unreadFor('emp'), 0);
    });

    test('falls back to zero for an unknown uid', () {
      const conversation = Conversation(
        id: 'emp_stu_job',
        employerId: 'emp',
        studentId: 'stu',
        participants: ['emp', 'stu'],
        jobId: 'job',
      );

      expect(conversation.unreadFor('someone_else'), 0);
    });
  });

  group('hasMessages', () {
    test('is false on a freshly opened thread', () {
      const conversation = Conversation(
        id: 'emp_stu_job',
        employerId: 'emp',
        studentId: 'stu',
        participants: ['emp', 'stu'],
        jobId: 'job',
      );

      expect(conversation.hasMessages, isFalse);
    });

    test('is true once a message has been sent', () {
      const conversation = Conversation(
        id: 'emp_stu_job',
        employerId: 'emp',
        studentId: 'stu',
        participants: ['emp', 'stu'],
        jobId: 'job',
        lastMessage: 'Hello',
      );

      expect(conversation.hasMessages, isTrue);
    });
  });

  group('fromFirestore', () {
    test('maps every field', () async {
      final sentAt = DateTime(2026, 3, 14, 9, 30);

      final conversation = await readBack('emp_stu_job', {
        'employerId': 'emp',
        'studentId': 'stu',
        'participants': ['emp', 'stu'],
        'jobId': 'job',
        'jobTitle': 'Barista',
        'lastMessage': 'Hello',
        'lastSenderId': 'emp',
        'lastMessageAt': Timestamp.fromDate(sentAt),
        'unreadCount': {'emp': 0, 'stu': 2},
        'createdAt': Timestamp.fromDate(sentAt),
      });

      expect(conversation.id, 'emp_stu_job');
      expect(conversation.employerId, 'emp');
      expect(conversation.studentId, 'stu');
      expect(conversation.participants, ['emp', 'stu']);
      expect(conversation.jobId, 'job');
      expect(conversation.jobTitle, 'Barista');
      expect(conversation.lastMessage, 'Hello');
      expect(conversation.lastSenderId, 'emp');
      expect(conversation.lastMessageAt, sentAt);
      expect(conversation.unreadFor('stu'), 2);
      expect(conversation.createdAt, sentAt);
    });

    test('survives a document with missing fields', () async {
      final conversation = await readBack('legacy_thread', {
        'employerId': 'emp',
        'studentId': 'stu',
      });

      expect(conversation.participants, isEmpty);
      expect(conversation.jobId, '');
      expect(conversation.jobTitle, '');
      expect(conversation.lastMessage, '');
      expect(conversation.lastMessageAt, isNull);
      expect(conversation.unreadFor('stu'), 0);
    });

    test('reads counters stored as any numeric type', () async {
      final conversation = await readBack('emp_stu_job', {
        'unreadCount': {'stu': 2.0},
      });

      expect(conversation.unreadFor('stu'), 2);
    });
  });

  group('toMap', () {
    test('round-trips through Firestore without losing data', () async {
      final createdAt = DateTime(2026, 3, 14, 9, 30);
      final original = Conversation(
        id: 'emp_stu_job',
        employerId: 'emp',
        studentId: 'stu',
        participants: const ['emp', 'stu'],
        jobId: 'job',
        jobTitle: 'Barista',
        lastMessage: 'Hello',
        lastSenderId: 'emp',
        lastMessageAt: createdAt,
        unreadCount: const {'emp': 0, 'stu': 2},
        createdAt: createdAt,
      );

      final restored = await readBack(original.id, original.toMap());

      expect(restored.employerId, original.employerId);
      expect(restored.studentId, original.studentId);
      expect(restored.jobId, original.jobId);
      expect(restored.jobTitle, original.jobTitle);
      expect(restored.lastMessage, original.lastMessage);
      expect(restored.lastSenderId, original.lastSenderId);
      expect(restored.lastMessageAt, original.lastMessageAt);
      expect(restored.unreadCount, original.unreadCount);
      expect(restored.createdAt, original.createdAt);
    });
  });
}

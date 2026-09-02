import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/conversation_model.dart';
import 'package:taf_match/repositories/firestore_chat_repository.dart';

const employerId = 'employer_1';
const studentId = 'student_1';
const jobId = 'job_1';
const jobTitle = 'Barista';
final conversationId = Conversation.buildId(employerId, studentId, jobId);

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreChatRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreChatRepository(firestore: firestore);
  });

  /// Shorthand for the thread used across most tests.
  Future<Conversation> openDefaultThread() => repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: jobId,
        jobTitle: jobTitle,
      );

  group('openConversation', () {
    test('creates the thread with a deterministic id and both participants',
        () async {
      final conversation = await openDefaultThread();

      expect(conversation.id, 'employer_1_student_1_job_1');
      expect(conversation.employerId, employerId);
      expect(conversation.studentId, studentId);
      expect(conversation.participants, containsAll([employerId, studentId]));
      expect(conversation.jobId, jobId);
      expect(conversation.jobTitle, jobTitle);
      expect(conversation.unreadFor(employerId), 0);
      expect(conversation.unreadFor(studentId), 0);
    });

    test('reusing the same posting reuses the same thread', () async {
      final first = await openDefaultThread();

      await repository.sendMessage(
        conversationId: first.id,
        senderId: employerId,
        recipientId: studentId,
        text: 'Hello',
      );

      final second = await openDefaultThread();

      expect(second.id, first.id);
      // The existing thread is returned untouched, not reset.
      expect(second.lastMessage, 'Hello');

      final all = await firestore.collection('conversations').get();
      expect(all.docs.length, 1);
    });

    test('two postings with the same student create two separate threads',
        () async {
      final barista = await repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: 'job_1',
        jobTitle: 'Barista',
      );
      final waiter = await repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: 'job_2',
        jobTitle: 'Waiter',
      );

      expect(barista.id, isNot(waiter.id));
      expect(barista.jobTitle, 'Barista');
      expect(waiter.jobTitle, 'Waiter');

      final all = await firestore.collection('conversations').get();
      expect(all.docs.length, 2);
    });

    test('messages stay confined to their own posting thread', () async {
      final barista = await repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: 'job_1',
        jobTitle: 'Barista',
      );
      final waiter = await repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: 'job_2',
        jobTitle: 'Waiter',
      );

      await repository.sendMessage(
        conversationId: barista.id,
        senderId: employerId,
        recipientId: studentId,
        text: 'About the barista role',
      );

      final baristaThread = await repository.findById(barista.id);
      final waiterThread = await repository.findById(waiter.id);

      expect(baristaThread!.lastMessage, 'About the barista role');
      expect(waiterThread!.lastMessage, '');
      expect(baristaThread.unreadFor(studentId), 1);
      expect(waiterThread.unreadFor(studentId), 0);
    });
  });

  group('findById', () {
    test('returns null for a thread that does not exist', () async {
      expect(await repository.findById('nope_nope_nope'), isNull);
    });
  });

  group('sendMessage', () {
    test('stores the message and updates the thread preview', () async {
      await openDefaultThread();

      await repository.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'Are you available Monday?',
      );

      final messages = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      expect(messages.docs.length, 1);
      expect(messages.docs.first.data()['text'], 'Are you available Monday?');
      expect(messages.docs.first.data()['senderId'], employerId);

      final thread = await repository.findById(conversationId);
      expect(thread!.lastMessage, 'Are you available Monday?');
      expect(thread.lastSenderId, employerId);
      expect(thread.lastMessageAt, isNotNull);
    });

    test('increments the recipient unread counter only', () async {
      await openDefaultThread();

      await repository.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'First',
      );
      await repository.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'Second',
      );

      final thread = await repository.findById(conversationId);
      expect(thread!.unreadFor(studentId), 2);
      expect(thread.unreadFor(employerId), 0);
    });

    test('a reply increments the employer counter', () async {
      await openDefaultThread();

      await repository.sendMessage(
        conversationId: conversationId,
        senderId: studentId,
        recipientId: employerId,
        text: 'Yes I am',
      );

      final thread = await repository.findById(conversationId);
      expect(thread!.unreadFor(employerId), 1);
      expect(thread.unreadFor(studentId), 0);
    });
  });

  group('markRead', () {
    test('resets the counter for that user only', () async {
      await openDefaultThread();
      await repository.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'Hello',
      );
      await repository.sendMessage(
        conversationId: conversationId,
        senderId: studentId,
        recipientId: employerId,
        text: 'Yes',
      );

      await repository.markRead(
          conversationId: conversationId, userId: studentId);

      final thread = await repository.findById(conversationId);
      expect(thread!.unreadFor(studentId), 0);
      expect(thread.unreadFor(employerId), 1);
    });
  });

  group('watchMessages', () {
    test('emits newest first so the chat can render in reverse', () async {
      await openDefaultThread();

      await repository.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'First',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repository.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'Second',
      );

      final messages = await repository
          .watchMessages(conversationId)
          .firstWhere((list) => list.length == 2);

      expect(messages.first.text, 'Second');
      expect(messages.last.text, 'First');
    });
  });

  group('watchForUser', () {
    test('emits the thread to both sides', () async {
      final employerStream = repository.watchForUser(employerId);
      final studentStream = repository.watchForUser(studentId);

      await openDefaultThread();

      final employerList =
          await employerStream.firstWhere((list) => list.isNotEmpty);
      final studentList =
          await studentStream.firstWhere((list) => list.isNotEmpty);

      expect(employerList.first.id, conversationId);
      expect(studentList.first.id, conversationId);
    });

    test('emits one entry per posting', () async {
      await repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: 'job_1',
        jobTitle: 'Barista',
      );
      await repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: 'job_2',
        jobTitle: 'Waiter',
      );

      final threads = await repository
          .watchForUser(studentId)
          .firstWhere((list) => list.length == 2);

      expect(
          threads.map((t) => t.jobTitle), containsAll(['Barista', 'Waiter']));
    });

    test('does not emit threads the user is not part of', () async {
      await openDefaultThread();

      final outsider = await repository
          .watchForUser('someone_else')
          .first
          .timeout(const Duration(seconds: 2));

      expect(outsider, isEmpty);
    });
  });
}

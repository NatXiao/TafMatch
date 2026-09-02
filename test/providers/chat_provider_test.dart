import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taf_match/models/conversation_model.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/repositories/firestore_chat_repository.dart';

const employerId = 'employer_1';
const studentId = 'student_1';
const jobId = 'job_1';
const jobTitle = 'Barista';
final conversationId = Conversation.buildId(employerId, studentId, jobId);

/// Lets the Firestore stream deliver before we assert on provider state.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreChatRepository repository;
  late ChatProvider provider;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreChatRepository(firestore: firestore);
    provider = ChatProvider(repository: repository);
  });

  tearDown(() => provider.dispose());

  Future<Conversation> openDefaultThread() => repository.openConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: jobId,
        jobTitle: jobTitle,
      );

  Future<void> employerSays(String text, {String? conversation}) =>
      repository.sendMessage(
        conversationId: conversation ?? conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: text,
      );

  group('startConversation', () {
    test('delegates to the repository and returns the thread', () async {
      final conversation = await provider.startConversation(
        employerId: employerId,
        studentId: studentId,
        jobId: jobId,
        jobTitle: jobTitle,
      );

      expect(conversation.id, conversationId);
      expect(await repository.findById(conversationId), isNotNull);
    });
  });

  group('listenToConversations', () {
    test('exposes the threads of the signed-in user', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await settle();

      expect(provider.conversations.length, 1);
      expect(provider.conversations.first.jobTitle, jobTitle);
    });

    test('an empty uid clears the list instead of querying', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await settle();
      expect(provider.conversations, isNotEmpty);

      provider.listenToConversations('');
      expect(provider.conversations, isEmpty);
    });

    test('switching user replaces the previous stream', () async {
      await openDefaultThread();

      provider.listenToConversations(studentId);
      await settle();
      expect(provider.conversations.length, 1);

      provider.listenToConversations('outsider');
      await settle();
      expect(provider.conversations, isEmpty);
    });

    test('notifies its listeners when a thread arrives', () async {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.listenToConversations(studentId);
      await openDefaultThread();
      await settle();

      expect(notifications, greaterThan(0));
    });

    test('hides threads the employer deleted', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await employerSays('Hello');
      await settle();
      expect(provider.conversations.length, 1);

      await repository.deleteConversation(conversationId);
      await settle();

      // The document is still in Firestore; the provider filters it out.
      expect(provider.conversations, isEmpty);
    });

    test('hides deleted threads from the employer too', () async {
      provider.listenToConversations(employerId);
      await openDefaultThread();
      await settle();

      await provider.deleteConversation(conversationId);
      await settle();

      expect(provider.conversations, isEmpty);
    });

    test('a revived thread comes back into the list', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await settle();

      await repository.deleteConversation(conversationId);
      await settle();
      expect(provider.conversations, isEmpty);

      await openDefaultThread();
      await settle();

      expect(provider.conversations.length, 1);
      expect(provider.conversations.first.hasMessages, isFalse);
    });
  });

  group('totalUnread', () {
    test('counts the messages waiting for the signed-in user', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await employerSays('Hello');
      await settle();

      expect(provider.totalUnread, 1);
    });

    test('stays at zero for the sender', () async {
      provider.listenToConversations(employerId);
      await openDefaultThread();
      await employerSays('Hello');
      await settle();

      expect(provider.totalUnread, 0);
      expect(provider.conversations.length, 1);
    });

    test('adds up across postings', () async {
      provider.listenToConversations(studentId);

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

      await employerSays('One', conversation: barista.id);
      await employerSays('Two', conversation: waiter.id);
      await settle();

      expect(provider.totalUnread, 2);

      // Reading one thread leaves the other one pending.
      await provider.markRead(barista.id, studentId);
      await settle();
      expect(provider.totalUnread, 1);
    });

    test('drops the count of a deleted thread', () async {
      provider.listenToConversations(studentId);

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

      await employerSays('One', conversation: barista.id);
      await employerSays('Two', conversation: waiter.id);
      await settle();
      expect(provider.totalUnread, 2);

      await repository.deleteConversation(barista.id);
      await settle();

      // The badge must not keep counting a thread nobody can open.
      expect(provider.totalUnread, 1);
    });
  });

  group('deleteConversation', () {
    test('removes the thread and its messages', () async {
      await openDefaultThread();
      await employerSays('Hello');

      await provider.deleteConversation(conversationId);

      final thread = await repository.findById(conversationId);
      expect(thread!.deletedAt, isNotNull);

      final messages = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();
      expect(messages.docs, isEmpty);
    });
  });

  group('markRead', () {
    test('clears the counter and the badge follows', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await employerSays('Hello');
      await settle();
      expect(provider.totalUnread, 1);

      await provider.markRead(conversationId, studentId);
      await settle();

      expect(provider.totalUnread, 0);
    });

    test('falls back to the uid of the signed-in user', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await employerSays('Hello');
      await settle();

      await provider.markRead(conversationId);
      await settle();

      expect(provider.totalUnread, 0);
    });

    test('is a no-op when no user is set', () async {
      await openDefaultThread();
      await employerSays('Hello');

      // This is the bug that kept the badge stuck: no uid, silent return.
      await provider.markRead(conversationId);

      final thread = await repository.findById(conversationId);
      expect(thread!.unreadFor(studentId), 1);
    });
  });

  group('openConversation', () {
    test('streams the messages of that thread', () async {
      await openDefaultThread();
      await employerSays('Hello');

      provider.openConversation(conversationId);
      await settle();

      expect(provider.activeConversationId, conversationId);
      expect(provider.isLoadingMessages, isFalse);
      expect(provider.messages.single.text, 'Hello');
    });

    test('switching thread replaces the message list', () async {
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

      await employerSays('About barista', conversation: barista.id);
      await employerSays('About waiter', conversation: waiter.id);

      provider.openConversation(barista.id);
      await settle();
      expect(provider.messages.single.text, 'About barista');

      provider.openConversation(waiter.id);
      await settle();
      expect(provider.messages.single.text, 'About waiter');
    });

    test('reopening the same thread keeps the stream alive', () async {
      await openDefaultThread();
      await employerSays('Hello');

      provider.openConversation(conversationId);
      await settle();

      provider.openConversation(conversationId);
      // No reload flicker: the messages are still there.
      expect(provider.isLoadingMessages, isFalse);
      expect(provider.messages, isNotEmpty);
    });

    test('the message list empties when the thread is deleted', () async {
      await openDefaultThread();
      await employerSays('Hello');
      provider.openConversation(conversationId);
      await settle();
      expect(provider.messages, isNotEmpty);

      await provider.deleteConversation(conversationId);
      await settle();

      expect(provider.messages, isEmpty);
    });
  });

  group('closeConversation', () {
    test('drops the active thread and its messages', () async {
      await openDefaultThread();
      await employerSays('Hello');
      provider.openConversation(conversationId);
      await settle();

      provider.closeConversation();

      expect(provider.activeConversationId, isNull);
      expect(provider.messages, isEmpty);
      expect(provider.isLoadingMessages, isFalse);
    });
  });

  group('sendMessage', () {
    test('writes the message through to the thread', () async {
      await openDefaultThread();

      await provider.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: 'Hello',
      );

      final thread = await repository.findById(conversationId);
      expect(thread!.lastMessage, 'Hello');
    });

    test('trims the text before sending', () async {
      await openDefaultThread();

      await provider.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: '   Hello   ',
      );

      final thread = await repository.findById(conversationId);
      expect(thread!.lastMessage, 'Hello');
    });

    test('ignores a blank message', () async {
      await openDefaultThread();

      await provider.sendMessage(
        conversationId: conversationId,
        senderId: employerId,
        recipientId: studentId,
        text: '    ',
      );

      final thread = await repository.findById(conversationId);
      expect(thread!.hasMessages, isFalse);
      expect(thread.unreadFor(studentId), 0);
    });
  });

  group('clear', () {
    test('wipes state on sign-out', () async {
      provider.listenToConversations(studentId);
      await openDefaultThread();
      await employerSays('Hello');
      provider.openConversation(conversationId);
      await settle();

      provider.clear();

      expect(provider.conversations, isEmpty);
      expect(provider.messages, isEmpty);
      expect(provider.activeConversationId, isNull);
      expect(provider.totalUnread, 0);
    });
  });
}
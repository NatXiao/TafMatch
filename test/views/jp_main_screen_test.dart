import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/repositories/firestore_chat_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/jp_main_screen.dart';

/// AuthProvider needs a real Firestore repository to be built, so the screen
/// gets a stand-in instead. A null user keeps initState from starting any
/// stream, which is all this navigation test needs.
class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  User? get user => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ChatProvider chatProvider;

  setUp(() {
    chatProvider = ChatProvider(
      repository: FirestoreChatRepository(firestore: FakeFirebaseFirestore()),
    );
  });

  tearDown(() => chatProvider.dispose());

  /// Mounts JpMainScreen with all three tabs stubbed out, so no tab reaches
  /// Firebase on its own.
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Widget postings,
    required Widget chat,
    required Widget profile,
  }) {
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _FakeAuthProvider(),
          ),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: MaterialApp(
          theme: buildThemeData(),
          home: JpMainScreen(
            postingsScreen: postings,
            chatScreen: chat,
            profileScreen: profile,
          ),
        ),
      ),
    );
  }

  testWidgets('JpMainScreen displays navigation tabs', (tester) async {
    await pumpScreen(
      tester,
      postings: const Placeholder(key: Key('postings')),
      chat: const Placeholder(key: Key('chat')),
      profile: const Placeholder(key: Key('profile')),
    );

    expect(find.text('Postings'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('JpMainScreen opens on the postings tab', (tester) async {
    await pumpScreen(
      tester,
      postings: const Placeholder(key: Key('postings')),
      chat: const Placeholder(key: Key('chat')),
      profile: const Placeholder(key: Key('profile')),
    );

    // IndexedStack keeps every tab mounted, so assert on what is visible.
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 0);
  });

  testWidgets('JpMainScreen switches to the Messages tab', (tester) async {
    await pumpScreen(
      tester,
      postings: const Placeholder(key: Key('postings')),
      chat: const Placeholder(key: Key('chat')),
      profile: const Placeholder(key: Key('profile')),
    );

    await tester.tap(find.text('Messages'));
    await tester.pump();

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 1);
  });

  testWidgets('JpMainScreen switches to the Profile tab', (tester) async {
    await pumpScreen(
      tester,
      postings: const Placeholder(key: Key('postings')),
      chat: const Placeholder(key: Key('chat')),
      profile: const Placeholder(key: Key('profile')),
    );

    await tester.tap(find.text('Profile'));
    await tester.pump();

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 2);
  });

  testWidgets('the Messages tab shows no badge when nothing is unread',
      (tester) async {
    await pumpScreen(
      tester,
      postings: const Placeholder(key: Key('postings')),
      chat: const Placeholder(key: Key('chat')),
      profile: const Placeholder(key: Key('profile')),
    );

    expect(chatProvider.totalUnread, 0);
    expect(find.text('1'), findsNothing);
  });
}

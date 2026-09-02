import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taf_match/models/conversation_model.dart';
import 'package:taf_match/models/message_model.dart';
import 'package:taf_match/repositories/firestore_chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({FirestoreChatRepository? repository})
      : _repository = repository ?? FirestoreChatRepository();

  final FirestoreChatRepository _repository;

  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;

  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  String _currentUserId = '';
  String? _activeConversationId;
  bool _loadingMessages = false;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  String? get activeConversationId => _activeConversationId;
  bool get isLoadingMessages => _loadingMessages;

  /// Total unread messages across every thread — use this for the tab badge.
  int get totalUnread => _conversations.fold<int>(
        0,
        (sum, conversation) => sum + conversation.unreadFor(_currentUserId),
      );

  /// Start listening to every thread [userId] takes part in. Call once, after
  /// login (same place you call `listenToNotifications`).
  void listenToConversations(String userId) {
    _conversationsSubscription?.cancel();
    _currentUserId = userId;

    if (userId.isEmpty) {
      _conversations = [];
      notifyListeners();
      return;
    }

    _conversationsSubscription = _repository.watchForUser(userId).listen(
      (conversations) {
        _conversations = conversations;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('ChatProvider.watchForUser error: $e');
      },
    );
  }

  /// Called by the employer from the applicants screen. Creates the thread if
  /// it doesn't exist yet and returns it so the caller can navigate.
  Future<Conversation> startConversation({
    required String employerId,
    required String studentId,
    required String jobId,
    required String jobTitle,
  }) {
    return _repository.openConversation(
      employerId: employerId,
      studentId: studentId,
      jobId: jobId,
      jobTitle: jobTitle,
    );
  }

  /// Opens the message stream for a thread. Call from the chat screen.
  void openConversation(String conversationId) {
    if (_activeConversationId == conversationId &&
        _messagesSubscription != null) {
      return;
    }

    _messagesSubscription?.cancel();
    _activeConversationId = conversationId;
    _messages = [];
    _loadingMessages = true;
    notifyListeners();

    _messagesSubscription = _repository.watchMessages(conversationId).listen(
      (messages) {
        _messages = messages;
        _loadingMessages = false;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('ChatProvider.watchMessages error: $e');
      },
    );
  }

  /// Stops the message stream when leaving the chat screen.
  void closeConversation() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _activeConversationId = null;
    _messages = [];
    _loadingMessages = false;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _repository.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      text: trimmed,
    );
  }

  Future<void> markRead(String conversationId, [String? userId]) async {
    final uid = userId ?? _currentUserId;
    if (uid.isEmpty) return;
    await _repository.markRead(conversationId: conversationId, userId: uid);
  }

  void clear() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _conversations = [];
    _messages = [];
    _activeConversationId = null;
    _currentUserId = '';
    notifyListeners();
  }

  /// Called by the proxy provider whenever the signed-in user changes.
  void syncUser(String userId) {
    if (userId == _currentUserId) return;
    _currentUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenToConversations(userId);
    });
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/conversation_model.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/chat_screen.dart';

/// Shared by both roles: lists every thread the signed-in user takes part in.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Future<Map<String, UserModel>>? _participantsFuture;
  String _participantsKey = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final currentUserId = context.read<AuthProvider>().user?.uid ?? '';
    final conversations = context.watch<ChatProvider>().conversations;

    // Resolve the display name/photo of everyone on the other side, batched.
    final otherIds = conversations
        .map((conversation) => conversation.otherParticipant(currentUserId))
        .toSet()
        .toList();
    final key = otherIds.join('|');
    if (key != _participantsKey) {
      _participantsKey = key;
      _participantsFuture =
          context.read<UserProvider>().getUsersByIds(otherIds);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: colors.text,
        title: Text(
          'Messages',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: colors.text),
        ),
      ),
      body: SafeArea(
        child: conversations.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No conversations yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: colors.muted),
                  ),
                ),
              )
            : FutureBuilder<Map<String, UserModel>>(
                future: _participantsFuture,
                builder: (context, snapshot) {
                  final users = snapshot.data ?? const <String, UserModel>{};

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 82,
                      color: colors.border,
                    ),
                    itemBuilder: (_, i) {
                      final conversation = conversations[i];
                      final otherId =
                          conversation.otherParticipant(currentUserId);
                      return _ConversationTile(
                        colors: colors,
                        conversation: conversation,
                        other: users[otherId],
                        currentUserId: currentUserId,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.colors,
    required this.conversation,
    required this.other,
    required this.currentUserId,
  });

  final AppColors colors;
  final Conversation conversation;
  final UserModel? other;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadFor(currentUserId);
    final photoUrl = other?.profilePictureUrl ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colors.avatar,
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? Icon(Icons.person, color: colors.muted, size: 24)
            : null,
      ),
      title: Text(
        other?.fullName ?? 'Unknown user',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
          color: colors.text,
        ),
      ),
      isThreeLine: true,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (conversation.jobTitle.isNotEmpty)
            Text(
              conversation.jobTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            conversation.hasMessages
                ? conversation.lastMessage
                : 'Conversation started',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: unread > 0 ? colors.text : colors.muted,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _shortTime(conversation.lastMessageAt),
            style: TextStyle(fontSize: 12, color: colors.muted),
          ),
          const SizedBox(height: 6),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            otherUserId: conversation.otherParticipant(currentUserId),
            otherUserName: other?.fullName ?? 'Unknown user',
            otherUserPhotoUrl: other?.profilePictureUrl ?? '',
            jobTitle: conversation.jobTitle,
          ),
        ),
      ),
    );
  }

  String _shortTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (sameDay) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }
}

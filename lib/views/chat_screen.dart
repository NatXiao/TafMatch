import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/message_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl = '',
    this.jobTitle,
  });

  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String? jobTitle;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      chat.openConversation(widget.conversationId);
      chat.markRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final senderId = context.read<AuthProvider>().user?.uid ?? '';
    if (senderId.isEmpty) return;

    setState(() => _sending = true);
    _controller.clear();

    final chat = context.read<ChatProvider>();
    final notifications = context.read<NotificationProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await chat.sendMessage(
        conversationId: widget.conversationId,
        senderId: senderId,
        recipientId: widget.otherUserId,
        text: text,
      );

      // Reuse the existing notification pipeline so the recipient gets a push.
      await notifications.notify(
        userId: widget.otherUserId,
        title: 'New message',
        message: text.length > 80 ? '${text.substring(0, 80)}…' : text,
        type: 'new_message',
      );
    } catch (e) {
      if (mounted) {
        _controller.text = text; // don't lose what the user typed
        messenger.showSnackBar(
          SnackBar(content: Text('Could not send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final currentUserId = context.read<AuthProvider>().user?.uid ?? '';
    final chat = context.watch<ChatProvider>();
    final messages = chat.activeConversationId == widget.conversationId
        ? chat.messages
        : const <Message>[];

    // Any message arriving while the screen is open is read immediately.
    if (messages.isNotEmpty && messages.first.senderId != currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ChatProvider>().markRead(widget.conversationId);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: colors.text,
        titleSpacing: 0,
        title: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: widget.otherUserId),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.avatar,
                backgroundImage: widget.otherUserPhotoUrl.isNotEmpty
                    ? NetworkImage(widget.otherUserPhotoUrl)
                    : null,
                child: widget.otherUserPhotoUrl.isEmpty
                    ? Icon(Icons.person, color: colors.muted, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.otherUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.text),
                    ),
                    if (widget.jobTitle != null && widget.jobTitle!.isNotEmpty)
                      Text(
                        widget.jobTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: colors.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Say hello to ${widget.otherUserName}.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: colors.muted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          // Newest first from Firestore + reverse list = new
                          // messages land at the bottom, already scrolled to.
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _MessageBubble(
                            colors: colors,
                            message: messages[i],
                            isMine: messages[i].senderId == currentUserId,
                          ),
                        ),
            ),
            _composer(colors),
          ],
        ),
      ),
    );
  }

  Widget _composer(AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: TextStyle(fontSize: 15, color: colors.text),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TextStyle(fontSize: 15, color: colors.muted),
                filled: true,
                fillColor: colors.softAccent,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _sending ? null : _send,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _sending ? colors.muted : colors.accent,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.colors,
    required this.message,
    required this.isMine,
  });

  final AppColors colors;
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? colors.accent : colors.softAccent,
                borderRadius: radius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _time(message.sentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine ? Colors.white70 : colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/views/jp_my_posting_screen.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/profile_screen.dart';
import 'package:taf_match/providers/chat_provider.dart';
import 'package:taf_match/views/chat_list_screen.dart';

/// Main screen for employers, with a bottom navigation bar to switch between
/// Postings, Messages and Profile.
class JpMainScreen extends StatefulWidget {
  const JpMainScreen({
    super.key,
    this.postingsScreen,
    this.chatScreen,
    this.profileScreen,
  });
  final Widget? postingsScreen;
  final Widget? chatScreen;
  final Widget? profileScreen;

  @override
  State<JpMainScreen> createState() => _JpMainScreenState();
}

class _JpMainScreenState extends State<JpMainScreen> {
  // Current index of the selected tab in the bottom navigation bar.
  int _currentIndex = 0;

  // `late final` : build after state initialisation.
  late final List<Widget> _screens = [
    widget.postingsScreen ?? const MyPostingsScreen(),
    widget.chatScreen ?? const ChatListScreen(),
    widget.profileScreen ?? const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _bottomNav(colors),
    );
  }

  // Builds the bottom navigation bar with three tabs: Postings, Messages and
  // Profile.
  Widget _bottomNav(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(colors, 'Postings', 0, const Key('postings_tab')),
            _messagesNavItem(colors, 1, const Key('messages_tab')),
            _navItem(colors, 'Profile', 2, const Key('profile_tab')),
          ],
        ),
      ),
    );
  }

  /// Same as [_navItem], with an unread badge fed by ChatProvider.
  Widget _messagesNavItem(AppColors colors, int index, Key key) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        final unread = chat.totalUnread;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _navItem(colors, 'Messages', index, key),
            if (unread > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _navItem(AppColors colors, String label, int index, Key key) {
    final active = _currentIndex == index;
    final color = active ? colors.accent : colors.muted;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? colors.accent : colors.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              key: key,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
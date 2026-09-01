import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/views/js_job_list_screen.dart';
import 'package:taf_match/views/js_applications_screen.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/profile_screen.dart';

/// Main screen for job seekers, with bottom navigation bar to switch between Jobs, Applications, and Profile.
class JeMainScreen extends StatefulWidget {
  const JeMainScreen({super.key});

  @override
  State<JeMainScreen> createState() => _JeMainScreenState();
}

class _JeMainScreenState extends State<JeMainScreen> {
  // Current index of the selected tab in the bottom navigation bar.
  int _currentIndex = 0;

  final _screens = const [
    JobListScreen(),
    ApplicationsScreen(),
    ProfileScreen(),
  ];
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;

      if (user != null) {
        context
            .read<NotificationProvider>()
            .listenToNotifications(user.uid);
      }
    });
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

  // Builds the bottom navigation bar with three tabs: Jobs, Applications, and Profile.
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
            _navItem(colors, 'Jobs', 0),
            _navItem(colors, 'Applications', 1),
            _navItem(colors, 'Profile', 2),
          ],
        ),
      ),
    );
  }

  Widget _navItem(AppColors colors, String label, int index) {
    final active = _currentIndex == index;
    final color = active ? colors.accent : colors.muted;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: active ? colors.accent : colors.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
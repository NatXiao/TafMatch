import 'package:flutter/material.dart';
import 'package:taf_match/views/jp_my_posting_screen.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/profile_screen.dart';

/// Main screen for job seekers, with bottom navigation bar to switch between Jobs, Applications, and Profile.
class JpMainScreen extends StatefulWidget {
  const JpMainScreen({super.key, this.postingsScreen});
  final Widget? postingsScreen;
  @override
  State<JpMainScreen> createState() => _JpMainScreenState();
}

class _JpMainScreenState extends State<JpMainScreen> {
  // Current index of the selected tab in the bottom navigation bar.
  int _currentIndex = 0;

  final _screens = const [
    MyPostingsScreen(),
    ProfileScreen(),
  ];

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
            _navItem(colors, 'Postings', 0),
            _navItem(colors, 'Profile', 1),
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
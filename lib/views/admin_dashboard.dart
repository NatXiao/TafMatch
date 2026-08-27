import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/utils/theme.dart';

String _shortDate(DateTime? d) {
  if (d == null) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Controller for the search field
  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load users when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final userProvider = Provider.of<UserProvider>(context);

    final query = _filterController.text.trim().toLowerCase();
    final users = userProvider.users.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.uid.toLowerCase().contains(query);
    }).toList();

    // Count users by role
    final seekers = userProvider.users.where((u) => u.role == 'user').length;
    final providers = userProvider.users.where((u) => u.role == 'employer').length;

    // Access control: only admins can access this screen
    if (!userProvider.isAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Access denied',
              style: TextStyle(fontSize: 20, color: colors.text)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // --- Titre + logout ---
              Row(
                children: [
                  Text('Users',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.text)),
                  const Spacer(),
                  InkWell(
                    onTap: () =>
                        Provider.of<AuthProvider>(context, listen: false).signOut(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: colors.softAccent, shape: BoxShape.circle),
                      child: Icon(Icons.logout, size: 18, color: colors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // --- Stat cards ---
              Row(
                children: [
                  Expanded(child: _statCard(colors, '$seekers', 'Job seekers')),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard(colors, '$providers', 'Job providers')),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard(colors, '${userProvider.users.length}', 'All users')),
                ],
              ),
              const SizedBox(height: 18),
              // --- Recherche ---
              TextField(
                controller: _filterController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 15, color: colors.text),
                decoration: InputDecoration(
                  hintText: 'Search a user…',
                  hintStyle: TextStyle(fontSize: 15, color: colors.muted),
                  prefixIcon: Icon(Icons.circle, size: 10, color: colors.muted),
                  filled: true,
                  fillColor: colors.field,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.accent, width: 1.5)),
                ),
              ),
              const SizedBox(height: 18),
              // --- Liste ---
              Expanded(child: _buildList(colors, userProvider, users)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(AppColors colors, UserProvider provider, List<UserModel> users) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!, style: TextStyle(color: colors.muted)));
    }
    if (users.isEmpty) {
      return Center(
        child: Text('No users found.', style: TextStyle(fontSize: 15, color: colors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _userCard(colors, users[i]),
    );
  }

  Widget _statCard(AppColors colors, String count, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.softAccent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.accent)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: colors.muted)),
        ],
      ),
    );
  }

  Widget _userCard(AppColors colors, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: const [BoxShadow(color: Color(0x242E3D8C), offset: Offset(0, 14), blurRadius: 34)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.avatar,
            backgroundImage: user.profilePictureUrl.isNotEmpty
                ? NetworkImage(user.profilePictureUrl)
                : null,
            child: user.profilePictureUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 26)
                : null,
          ),
          const SizedBox(width: 12),
          // Nom + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.text)),
                const SizedBox(height: 2),
                Text(user.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge de rôle + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _roleBadge(colors, user.role),
              const SizedBox(height: 10),
              Text(_shortDate(user.createdAt),
                  style: TextStyle(fontSize: 13, color: colors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(AppColors colors, String role) {
    late final String label;
    switch (role) {
      case 'employer':
        label = 'Employer';
      case 'admin':
        label = 'Admin';
      default:
        label = 'Student';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: colors.softAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accent)),
    );
  }
}
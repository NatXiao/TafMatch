import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/views/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final query = _filterController.text.trim().toLowerCase();
    final users = userProvider.users.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.uid.toLowerCase().contains(query);
    }).toList();

    if (!userProvider.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access denied',
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(children: [
                Expanded(
                    child: _buildStatCard(
                        count: users
                            .where((user) => user.role == 'student')
                            .length
                            .toString(),
                        label: "Job seekers")),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        count: users
                            .where((user) => user.role == 'employer')
                            .length
                            .toString(),
                        label: "Job providers")),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        count: users.length.toString(), label: "All users")),
              ]),
              TextField(
                controller: _filterController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Search a user :',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (userProvider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (userProvider.errorMessage != null)
                Expanded(
                  child: Center(child: Text(userProvider.errorMessage!)),
                )
              else if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No users found."),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(users[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildStatCard({
  required String count,
  required String label,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    ),
  );
}

Widget _buildUserCard(UserModel user) {
  return Card(
    child: ListTile(
      title: Text(user.fullName),
      leading: const Icon(Icons.person),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: ${user.email}'),
          Text('UUID: ${user.uid}'),
          Text('Created At: ${user.createdAt}'),
          Text('Role: ${user.role}'),
        ],
      ),
    ),
  );
}

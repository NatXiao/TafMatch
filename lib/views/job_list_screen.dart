import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/views/login_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  JobListScreenState createState() => JobListScreenState();
}

class JobListScreenState extends State<JobListScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text("Jobs"),
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

              Text(
                "Search Jobs :",
              ),

              Text(
                "UUID : ${user?.uid ?? ''}",
              ),

              Text(
                "Full Name : ${user?.fullName ?? ''}",
              ),

              Text(
                "Email : ${user?.email ?? ''}",
              ),

              Text(
                "Address : ${user?.address ?? ''}",
              ),

              Text(
                "Created At : ${user?.createdAt ?? ''}",
              ),

              Text(
                "Role : ${user?.role ?? ''}",
              ),

            ],
          ),
        ),
      ),

    );
  }
}

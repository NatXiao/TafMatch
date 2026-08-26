import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.profile;

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
        title: Text("Admin Dashboard"),
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
              Row(
                children: [
                  Column(
                    children: [
                      Text(
                        "XXX",
                      ),
                      Text(
                        "Job seekers"
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "XXX",
                      ),
                    Text(
                      "Job providers"
                      ),
                    ],
                  )

                ],
              ),
              Text(
                "Search a user :",
              ),
              TextFormField(
                controller: _filterController,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a search term';
                  }
                  return null;
                },
              ),
              // list of users
              Row(
                children: [   
                  Container(
                    width: 150.0,
                    height: 150.0,
                    child: Icon(
                      Icons.account_circle,
                      color: Colors.blue,
                      size: 150.0,
                    ),
                  ),
        
                  Text(
                    "Profile Picture : ${user?.profilePictureUrl ?? ''}",
                  ),
                  Column(
                    children: [
                      Text(
                        "Full Name : ${user?.fullName ?? ''}",
                      ),
                      Text(
                        "UUID : ${user?.uid ?? ''}",
                      ),
                      Text(
                        "Email : ${user?.email ?? ''}",
                      ),                 

                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "Created At : ${user?.createdAt ?? ''}",
                      ),

                      Text(
                        "Role : ${user?.role ?? ''}",
                      ),
                    ],
                  ),

                ],  
              )
            ],
          ),
        ),
      ),

    );
  }
}

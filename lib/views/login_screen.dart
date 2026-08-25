import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/face_login_screen.dart';
import 'package:taf_match/views/job_list_screen.dart';
import 'package:taf_match/views/signup_screen.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_isLogin ? 'Login' : 'Register'),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              Text(
                "Hi There !",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28.0),
              ),

              Text(
                "Log in to find your next job",
                style: TextStyle(fontSize: 14.0, color: Colors.blueGrey),
              ),

              const SizedBox(height: 20),

              // ElevatedButton(
              //   onPressed: authProvider.isLoading ? null : () => _authenticate(context),
              //   child: authProvider.isLoading
              //       ? const SizedBox(
              //           height: 20,
              //           width: 20,
              //           child: CircularProgressIndicator(strokeWidth: 2),
              //         )
              //       : Text("Log in"),
              // ),

              // ElevatedButton(
              //   onPressed: authProvider.isLoading ? null : () => navigate,
              //   child: authProvider.isLoading
              //       ? const SizedBox(
              //           height: 20,
              //           width: 20,
              //           child: CircularProgressIndicator(strokeWidth: 2),
              //         )
              //       : Text("Sign up"),
              // ),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
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
                    return 'Please enter an email';
                  }
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              if (authProvider.errorMessage != null) ...[
                Text(
                  authProvider.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 10),
              ],

              FilledButton(
                onPressed: authProvider.isLoading ? null : () => _authenticate(context),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Log in'),
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => FaceLoginScreen()),
                  );
                },
                child: Text('Log in with photo'),
              ),


              const SizedBox(height: 10),

              // TODO : Ceci est un bouton provisoire
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
                child: Text('Create account'),
              ),



            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        elevation: 0,
        height: 40,
        child: Align(
          alignment: Alignment.center,
          child: InkWell(
            child: Text("About developers - v1.0"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutScreen()),
              );
            }
          )
        ),
        
      ),


    );
  }

  void _authenticate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text;
    final role = 'user'; // Rôle par défaut pour l'inscription
    final password = _passwordController.text;

    final navigator = Navigator.of(context);

    final success = await authProvider.signInWithEmailAndPassword(email, password);

    if (success) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const JobListScreen()),
      );
    }
  }
}
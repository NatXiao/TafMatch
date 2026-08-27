import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/job_list_screen.dart';

import '../providers/auth_provider.dart';

class FaceLoginScreen extends StatefulWidget {
  const FaceLoginScreen({super.key});

  @override
  FaceLoginScreenState createState() => FaceLoginScreenState();
}

class FaceLoginScreenState extends State<FaceLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;

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
                "Log in with a photo",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22.0),
              ),

              const SizedBox(height: 20),

              // TextFormField(
              //   controller: _emailController,
              //   decoration: InputDecoration(
              //     labelText: 'Email',
              //     focusedBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(15.0),
              //       borderSide: BorderSide(
              //         color: Theme.of(context).colorScheme.primary,
              //         width: 2.0,
              //       ),
              //     ),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(15.0),
              //       borderSide: BorderSide(
              //         color: Colors.black,
              //       ),
              //     ),
              //   ),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter an email';
              //     }
              //     final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              //     if (!regex.hasMatch(value)) {
              //       return 'Please enter a valid email';
              //     }
              //     return null;
              //   },
                
              // ),

              Container(
                width: 150.0,
                height: 150.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
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

              // OutlinedButton(
              //   onPressed: authProvider.isLoading ? null : () => _authenticate(context),
              //   child: Text('Log in with photo'),
              // ),


              InkWell(
                child: Text("Retake photo"),
              )



              // TextButton(
              //   onPressed: authProvider.isLoading
              //       ? null
              //       : () {
              //           context.read<AuthProvider>().clearError();
              //           setState(() {
              //             _isLogin = !_isLogin;
              //           });
              //         },
              //   child: Text(_isLogin ? 'Create an account' : 'Already have an account? Login'),
              // ),
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

// TODO : Authentication with image
void _authenticate(BuildContext context) async {
  FocusScope.of(context).unfocus();

  if (!(_formKey.currentState?.validate() ?? false)) return;

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final email = _emailController.text;
  final password = _passwordController.text;

  await authProvider.signInWithEmailAndPassword(email, password);
  // Pas de navigation ici : main.dart route selon le rôle.
}
}

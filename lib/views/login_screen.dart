import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/views/about_screen.dart';
import 'package:taf_match/views/face_login_screen.dart';

import 'package:taf_match/views/signup_screen.dart';
import 'package:taf_match/utils/theme.dart'; // pour AppColors

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Logo rond ---
                Center(
                  child: Container(
                    width: 92, height: 92,
                    decoration: BoxDecoration(color: colors.softAccent, shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Hi there!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.text)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text('Log in to find your next job',
                      style: TextStyle(fontSize: 14, color: colors.muted)),
                ),
                const SizedBox(height: 28),

                // --- Champs ---
                _label(colors, 'Email'),
                _field(colors, _emailController, hint: 'name@edu.hes-so.ch',
                    validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an email';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(value)) return 'Please enter a valid email';
                  return null;
                }),
                const SizedBox(height: 16),

                _label(colors, 'Password'),
                _field(colors, _passwordController, hint: '••••••••', obscure: true,
                  textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _authenticate(context),
                    validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 6) return 'Password must be at least 6 characters long';
                  return null;
                }),

                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(authProvider.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 20),

                // --- Bouton Log in ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : () => _authenticate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent, foregroundColor: Colors.white,
                      elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Log in'),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Bouton Log in with a photo ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FaceLoginScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accent,
                      side: BorderSide(color: colors.accent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Log in with a photo'),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Lien vers l'inscription ---
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(fontSize: 14, color: colors.muted)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: Text('Register',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: colors.accent)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                // --- Footer About ---
                Center(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AboutScreen()),
                    ),
                    child: Text('About · developers · v1.0',
                        style: TextStyle(fontSize: 13, color: colors.muted)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(AppColors colors, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, color: colors.muted)),
      );

  Widget _field(AppColors colors, TextEditingController c,
      {String? hint,
      bool obscure = false,
      String? Function(String?)? validator,
      TextInputAction? textInputAction,
      void Function(String)? onSubmitted}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(fontSize: 15, color: colors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: colors.muted),
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
    );
  }

  void _authenticate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text;
    final password = _passwordController.text;

    await authProvider.signInWithEmailAndPassword(email, password);
  }
}
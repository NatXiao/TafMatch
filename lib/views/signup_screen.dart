import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/utils/constants.dart';
import 'package:taf_match/utils/theme.dart'; // for AppColors

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  var roleState = Constants.roleStudent;

  String? _imageUrl;
  bool _isUploading = false;
  String? _uploadError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 22, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 30, color: colors.text),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Text('Create account',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Avatar + add button ---
                      Center(
                        child: InkWell(
                          onTap: _isUploading ? null : () => _pickImage(),
                          borderRadius: BorderRadius.circular(999),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: colors.avatar,
                                backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                                child: _isUploading
                                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                    : (_imageUrl == null
                                        ? const Icon(Icons.person, color: Colors.white, size: 48)
                                        : null),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: colors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _isUploading ? null : () => _pickImage(),
                          child: Text('Add a profile photo',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.accent)),
                        ),
                      ),

                      if (_uploadError != null) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Text(_uploadError!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // --- Role selector (pill) ---
                      _label(colors, 'I am a...'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colors.field,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            _roleTab(colors, 'Student', Constants.roleStudent),
                            _roleTab(colors, 'Employer', Constants.roleEmployer),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // --- Fields ---
                      _label(colors, 'Full name'),
                      _field(colors, _fullnameController, hint: 'Marie Rossier',
                          validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null),
                      const SizedBox(height: 16),

                      _label(colors, 'Email'),
                      _field(colors, _emailController, hint: 'name@edu.hes-so.ch',
                          validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an email';
                        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!regex.hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      }),
                      const SizedBox(height: 16),

                      _label(colors, 'Address'),
                      _field(colors, _addressController, hint: 'Street, city',
                          validator: (v) => (v == null || v.isEmpty) ? 'Please enter your address' : null),
                      const SizedBox(height: 16),

                      _label(colors, 'Password'),
                      _field(colors, _passwordController, hint: '••••••••', obscure: true,
                          validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        if (!isValidPassword(value)) return 'Password must be at least 6 characters long and contains a least one uppercase letter, lowercase letter, number and special character'; 
                        return null;
                      }),
                      const SizedBox(height: 16),

                      _label(colors, 'Confirm password'),
                      _field(colors, _confirmController, hint: '••••••••', obscure: true,
                          validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (!_confirmationIsValid(value)) return 'Confirmation must be equal your password';
                        return null;
                      }),
                      const SizedBox(height: 28),

                      // --- Main button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _createAccount(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent, foregroundColor: Colors.white,
                            elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Create account'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- Log in link ---
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: TextStyle(fontSize: 14, color: colors.muted)),
                            GestureDetector(
                              onTap: () => Navigator.maybePop(context),
                              child: Text('Log in',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accent)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Role tab (half of the pill)
  Widget _roleTab(AppColors colors, String label, String value) {
    final selected = roleState == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _swapRoleState(context, value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x1A2E3D8C), offset: Offset(0, 4), blurRadius: 12)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? colors.text : colors.muted,
              )),
        ),
      ),
    );
  }

  Widget _label(AppColors colors, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, color: colors.muted)),
      );

  Widget _field(AppColors colors, TextEditingController c,
      {String? hint, bool obscure = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      validator: validator,
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

  void _createAccount(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    
    final email = _emailController.text;
    final password = _passwordController.text;
    final fullname = _fullnameController.text;
    final address = _addressController.text;
    final role = roleState;
    final profilePictureUrl = _imageUrl ?? '';

    final success = await authProvider.register(email, password, fullname, role, address, profilePictureUrl : profilePictureUrl);

    if (success) {
      navigator.pop();
    }
  }

  bool isValidPassword(String value) {

    if (!isLong(value)) return false;
    if (!hasNumber(value)) return false;
    if (!hasMaj(value)) return false;
    if (!hasMin(value)) return false;
    if (!hasSpecial(value)) return false;

    return true;
  }

  bool isLong(String value) {
    return value.length > 6;
  }

  bool hasNumber(String value) {

    const numbers = "1234567890";

    for (var i = 0; i < numbers.length; i++) {
      if (value.contains(numbers[i])) return true;
    }

    return false;
  }

  bool hasSpecial(String value) {

    const special = "!@#\$%^&*()_+€£µ§?/\\|{}[]";

    for (var i = 0; i < special.length; i++) {
      if (value.contains(special[i])) return true;
    }

    return false;
  }

  bool hasMaj(String value) {

    const maj = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    for (var i = 0; i < maj.length; i++) {
      if (value.contains(maj[i])) return true;
    }

    return false;
  }

  bool hasMin(String value) {

    const min = "abcdefghijklmnopqrstuvwxyz";

    for (var i = 0; i < min.length; i++) {
      if (value.contains(min[i])) return true;
    }

    return false;
  }

  void _swapRoleState(BuildContext context, String state) {
    roleState = state;
    setState(() {});
  }

  bool _confirmationIsValid(String value) {
    return _passwordController.text == value;
  }

  void _pickImage() async {
    final imageRepository = context.read<ImageStorageRepository>();
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final url = await imageRepository.uploadImage(bytes, picked.name);
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = 'Image upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/utils/constants.dart';
import 'package:taf_match/views/job_list_screen.dart';

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

  var roleState = Constants.ROLE_STUDENT;

  String? _imageUrl;
  bool _isUploading = false;
  String? _uploadError;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Create account"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              InkWell(
                onTap: _isUploading ? null : () => _pickImage(),
                child: _imageUrl == null
                  ? SizedBox(
                      width: 160.0,
                      height: 160.0,
                      child: _isUploading
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(
                          Icons.account_circle,
                          color: Colors.blue,
                          size: 150.0,
                        ),
                    )
                  : ClipOval(
                    child: Image.network(
                      _imageUrl!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
              ),

              const SizedBox(height: 16),

              if (_uploadError != null) ...[
                Text(
                  _uploadError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
              ],

              Table(
                children: [
                  TableRow(
                    children: [

                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                        child: roleState == Constants.ROLE_STUDENT
                          ? FilledButton(
                              onPressed: () => _swapRoleState(context, Constants.ROLE_STUDENT),
                              child: Text("Student"),
                            )
                          : OutlinedButton(
                              onPressed: () => _swapRoleState(context, Constants.ROLE_STUDENT),
                              child: Text("Student"),
                            ),
                      ),

                      Container(
                        margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: roleState == Constants.ROLE_EMPLOYER 
                          ? FilledButton(
                              onPressed: () => _swapRoleState(context, Constants.ROLE_EMPLOYER),
                              child: Text('Employer'),
                            )
                          : OutlinedButton(
                              onPressed: () => _swapRoleState(context, Constants.ROLE_EMPLOYER),
                              child: Text('Employer'),
                            ),
                      ),
                  
                    ]
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
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
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

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
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
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
                    return 'Please enter your address';
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

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Confirmation',
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
                    return 'Please confirme your password';
                  }
                  if (!_confirmationIsValid(value)) {
                    return 'Confirmation must be equal your password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: () => _createAccount(context),
                child: Text('Create account'),
              ),


            ],
          ),
        ),
      ),

    );
  }

  void _createAccount(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final email = _emailController.text;
    final password = _passwordController.text;
    final fullname = _fullnameController.text;
    final address = _addressController.text;
    final role = roleState; // Rôle par défaut pour l'inscription
    final profilePictureUrl = _imageUrl ?? '';

    final navigator = Navigator.of(context);

    final success = await authProvider.register(email, password, fullname, role, address, profilePictureUrl: profilePictureUrl);

    if (success) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const JobListScreen()),
      );
    }
  }

  void _swapRoleState(BuildContext context, String state) {
    roleState = state;
    setState(() {});
  }

  bool _confirmationIsValid(String value) {
    final password = _passwordController.text;

    if (password == value) {
      return true;
    }

    return false;
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
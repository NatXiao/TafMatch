import 'dart:core';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/providers/skill_provider.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/services/camera_service.dart';
import 'package:taf_match/utils/theme.dart'; // pour AppColors

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
  
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _cameraService = CameraService();

  Set<String> _selectedSkills = {};
  Set<String> _initialSkills = {};

  List<double> _vector = [];
  
  bool _saving = false;
  bool _initialized = false;
  bool _isUploading = false;
  
  String? _imageUrl;
  String? _uploadError;
  String? _saveError;

  String _initialFullName = '';
  String _initialEmail = '';
  String _initialAddress = '';
  String _initialImageUrl = '';

  List<double> _initialVector = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final skillProvider = context.read<SkillProvider>();

      if (skillProvider.skills.isEmpty && !skillProvider.isLoading) {
        skillProvider.loadSkills();
      }

      context.read<UserProvider>().loadUsers();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = context.read<UserProvider>().profile;

    if (user != null && !_initialized) {
    _initialFullName = user.fullName;
    _initialEmail = user.email;
    _initialAddress = user.address;
    _initialImageUrl = user.profilePictureUrl;
    _initialVector = user.vector;

    _initialSkills = user.skills.toSet();
    _selectedSkills = Set<String>.from(_initialSkills);

    _fullnameController.text = _initialFullName;
    _emailController.text = _initialEmail;
    _addressController.text = _initialAddress;
    _vector = _initialVector;
    _initialized = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullnameController.dispose();
    _addressController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final user = context.watch<UserProvider>().profile;
    final displayedImageUrl =
      _imageUrl ?? user?.profilePictureUrl ?? '';

    
    return PopScope(
    canPop: !_hasUnsavedChanges,
    onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;

    await _handleBackNavigation();
  },
  child : Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Barre du haut ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 22, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 30, color: colors.text),
                    onPressed: () => _handleBackNavigation(),
                  ),
                  Text('Edit profile',
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
                      // --- Avatar + bouton + ---
                      Center(
                        child: InkWell(
                          onTap: _isUploading ? null : () => _pickImage(),
                          borderRadius: BorderRadius.circular(999),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: colors.avatar,
                                backgroundImage: displayedImageUrl.isNotEmpty
                                    ? NetworkImage(displayedImageUrl)
                                    : null,
                                onBackgroundImageError: displayedImageUrl.isNotEmpty
                                    ? (e, s) => debugPrint('avatar load failed: $e')
                                    : null,
                                child: displayedImageUrl.isEmpty
                                    ? Icon(Icons.person, color: colors.muted, size: 30)
                                    : null,
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
                          child: Text('Change photo',
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
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.softAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Face login photo",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: colors.text),
                                ),
                                const SizedBox(width: 8),
                                
                                if (_initialVector.isNotEmpty || (_initialVector.isEmpty && _vector.isNotEmpty))
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              "Take a selfie so you can log in with the camera",
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                onPressed: () => showCameraModal(),
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // --- Field ---
                      _label(colors, 'Full name'),
                      _field(colors, _fullnameController,  key: const Key('fullNameField'), hint: user?.fullName ?? 'Marie Rossier'),
                      const SizedBox(height: 16),

                      _label(colors, 'Email'),
                      _field(colors, _emailController, key: const Key('emailField'), hint: user?.email ?? 'name@edu.hes-so.ch',
                          validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!regex.hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      }),
                      const SizedBox(height: 16),

                      _label(colors, 'Address'),
                      _field(colors, _addressController, key: const Key('addressField'),  hint: user?.address ?? 'Street, city'),
                      const SizedBox(height: 16),

                      // --- Skills ---
                      Text(
                      "SKILLS - TAP TO SELECT",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colors.muted),
                      ),
                      const SizedBox(height: 10),
                      Consumer<SkillProvider>(
                        builder: (context, skillProvider, _) {
                          if (skillProvider.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (skillProvider.skills.isEmpty) {
                            return Text('No skills available', style: TextStyle(color: colors.muted));
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skillProvider.skills.map((skill) {
                              final selected = _selectedSkills.contains(skill.id);
                              return GestureDetector(
                                onTap: () => _toggleSkill(skill.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? colors.accent : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: selected ? colors.accent : colors.muted.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    skill.name,
                                    style: TextStyle(
                                      color: selected ? Colors.white : colors.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                  
                      const SizedBox(height: 28),
                        if (_saveError != null) ...[
                          Text(_saveError!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                          const SizedBox(height: 12),
                        ],
                      // --- Bouton principal ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateProfile(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent, foregroundColor: Colors.white,
                            elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Update profile'),
                        ),
                      ),
                      const SizedBox(height: 12),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )
      ),
    );
  }

  Widget _label(AppColors colors, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(fontSize: 13, color: colors.muted)),
      );

  Widget _field(AppColors colors, TextEditingController c,
      {String? hint, bool obscure = false, String? Function(String?)? validator, required Key key}) {
    return TextFormField(
      key: key,
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

  Future<void> _updateProfile(BuildContext context) async {
    if (_saving) return;

    final user = context.read<UserProvider>().profile;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Captures avant les await : le BuildContext ne doit plus etre relu
    // apres un gap asynchrone.
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final navigator = Navigator.of(context);

    final email = _emailController.text.trim().isEmpty
        ? user.email
        : _emailController.text.trim();
    final fullname = _fullnameController.text.trim().isEmpty
        ? user.fullName
        : _fullnameController.text.trim();
    final address = _addressController.text.trim().isEmpty
        ? user.address
        : _addressController.text.trim();
    final profilePictureUrl = _imageUrl ?? user.profilePictureUrl;
    final vector = _vector.isEmpty ? user.vector : _vector;

    final updatedUser = user.copyWith(
      email: email,
      fullName: fullname,
      address: address,
      profilePictureUrl: profilePictureUrl,
      skills: _selectedSkills.toList(),
      vector: vector,
    );

    setState(() => _saving = true);
    try {
      final success = await authProvider.updateProfile(updatedUser);
      if (!success) return;
      await userProvider.loadProfile(updatedUser.uid);
      if (!mounted) return;
      navigator.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  bool get _hasUnsavedChanges {
    return _fullnameController.text.trim() != _initialFullName ||
        _emailController.text.trim() != _initialEmail ||
        _addressController.text.trim() != _initialAddress ||
        (_imageUrl != null && _imageUrl != _initialImageUrl)||
        !setEquals(_selectedSkills, _initialSkills) ||
        !listEquals(_vector, _initialVector);
  }

  void _toggleSkill(String skillId) {
    setState(() {
      if (_selectedSkills.contains(skillId)) {
        _selectedSkills.remove(skillId);
      } else {
        _selectedSkills.add(skillId);
      }
    });
  }

  Future<String?> _showUnsavedChangesDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'You have unsaved changes. Would you like to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Continue editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
  Future<void> _handleBackNavigation() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final action = await _showUnsavedChangesDialog();

    if (!mounted) return;

    if (action == 'discard') {
      Navigator.of(context).pop();
    }

    if (action == 'save') {
      _updateProfile(context);
    }
  }

  void applyVectorCallback(Float32List vector) {
    Navigator.pop(context);
    _cameraService.dispose();
    setState(() {
      _vector = vector.toList(); 
    });
  }

  Future<String?> showCameraModal() {
    final colors = Theme.of(context).extension<AppColors>()!;

    _cameraService.initCameraAndDetector(applyVectorCallback);

    return showGeneralDialog<String>(

      context: context,
      pageBuilder: (context, _, __) {

        return Scaffold(
          body: SafeArea(
            child: ListenableBuilder(
              listenable: _cameraService,
              builder: (context, _) {

                final controller = _cameraService.cameraController;
                final error = _cameraService.cameraError;

                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 30),
                          onPressed: () {
                            _cameraService.dispose();
                            Navigator.maybePop(context);
                          },
                        ),
                      ],
                    ),

                    Expanded(
                      child: Builder(
                        builder: (context) {
                          debugPrint('controller: $controller');
                          debugPrint('isInitialized: ${controller?.value.isInitialized}');
                          
                          if (controller == null || !controller.value.isInitialized) {
                            return ColoredBox(
                              color: colors.field,
                              child: Center(child: CircularProgressIndicator(color: colors.accent)),
                            );
                          }
                          return ColoredBox(
                            color: colors.field,
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: CameraPreview(controller),
                            ),
                          );
                        },
                      ),
                    ),

                    Visibility(
                      visible: error != null,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(error ?? '', style: const TextStyle(color: Colors.red)),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _cameraService.requestDetection,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Detect', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),

                  ],

                );

              }
            ),
          ),
        );
      },
          
    );

  }

  void requestDetection() {
    _cameraService.requestDetection();
  }

}
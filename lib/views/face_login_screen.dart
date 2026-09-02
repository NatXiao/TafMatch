import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:face_detection_tflite/face_detection_tflite_native.dart' hide FaceDetector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/services/camera_service.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/about_screen.dart';
import '../providers/auth_provider.dart';

class FaceLoginScreen extends StatefulWidget {
  const FaceLoginScreen({super.key});

  @override
  FaceLoginScreenState createState() => FaceLoginScreenState();
}

class FaceLoginScreenState extends State<FaceLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late List<UserModel> users;

  CameraService cameraService = CameraService();
  UserModel? potentialUser;
  bool userNotFound = false;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().loadUsers();
    });

    cameraService.initCameraAndDetector(findUserCallback, updateCallback).then((_) {
      if (!mounted) return;
      setState(() {});
    });
    
  }

  @override
  void dispose() {

    cameraService.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: 
          
          SingleChildScrollView(
            child: Column(
              children: [
                // --- Retour en arrière ---
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 30),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Log in with a photo",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22.0),
                      ),
                      const SizedBox(height: 20),
                      
                      if (potentialUser == null)
                        Container(
                          width: 150.0,
                          height: 150.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),

                      if (potentialUser != null)
                        CircleAvatar(
                          radius: 75,
                          backgroundColor: colors.avatar,
                          backgroundImage: potentialUser?.profilePictureUrl != null
                              ? NetworkImage(potentialUser!.profilePictureUrl)
                              : null,
                          onBackgroundImageError: potentialUser?.profilePictureUrl != null
                              ? (e, s) => debugPrint('avatar load failed: $e')
                              : null,
                          child: potentialUser?.profilePictureUrl == null
                              ? Icon(Icons.person, color: colors.muted, size: 30)
                              : null,
                        ),


                      const SizedBox(height: 16),

                      if (cameraService.getCameraController() != null)
                        SizedBox(
                          height: 400,
                          child: buildCameraOverlay(),
                        ),
                      if (cameraService.getCameraController() == null)
                        Container(
                            height: 400,
                            color: colors.field,
                            child: Center(child: CircularProgressIndicator(color: colors.accent)),
                          ),

                      OutlinedButton(
                        onPressed: () => requestDetection(),
                        child: const Text('Detect'),
                      ),

                      if (cameraService.cameraError != null)
                        Text(cameraService.cameraError!, style: TextStyle(color: Colors.red)),

                      if (potentialUser != null)
                        Text("You are ${potentialUser!.fullName} (${potentialUser?.email ?? "No email"}), enter your password to access to your account", style: TextStyle(color: colors.muted),),

                      if (userNotFound)
                        Text("Account not found, retry or activate face login in profile page !", style: TextStyle(color: Colors.red)),

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
                            borderSide: const BorderSide(color: Colors.black),
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
                            : const Text('Log in'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            child: const Text("About developers - v1.0"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AboutScreen()),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget buildCameraOverlay() {
    return CameraPreview(cameraService.getCameraController()!);
  }


  void requestDetection() {
    setState(() {
      userNotFound = false;
    });
    cameraService.requestDetection();
  }

  void findUserCallback(Float32List vector) {
    setState(() {
      potentialUser = findUser(vector);
    });
  }

  void updateCallback() {
    if (!mounted) return;
    setState(() {});
  }


  UserModel? findUser(Float32List vector) {

    final users = Provider.of<UserProvider>(context, listen: false).users;

    for (var user in users) {
      if (user.vector.length == vector.length) {
        double result = FaceDetector.compareFaces(vector, Float32List.fromList(user.vector));
        if (result > 0.6) {
          return user;
        }
      }
    }

    userNotFound = true;
    return null;
  }


  void _authenticate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = potentialUser?.email ?? "";
    final password = _passwordController.text;

    bool result = await authProvider.signInWithEmailAndPassword(email, password);

    if (result == true) {
      Navigator.maybePop(context);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/repositories/cloudinary_image_repository.dart';
import 'package:taf_match/repositories/firestore_task_repository.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/services/firebase_auth_service.dart';
import 'package:taf_match/utils/cloudinary_config.dart';
import 'package:taf_match/utils/firebase_options.dart';
import 'package:taf_match/utils/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'views/login_screen.dart';
import 'views/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ImageStorageRepository>(
          create: (_) => CloudinaryImageRepository(
            cloudName: CloudinaryConfig.cloudName,
            uploadPreset: CloudinaryConfig.uploadPreset,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider(FirebaseAuthService())),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(FirestoreTaskRepository()),
          update: (_, authProvider, taskProvider) =>
          taskProvider!..updateAuthProvider(authProvider),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Taf Match',
            theme: buildThemeData(),
            home: auth.user != null ? const TaskListScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}

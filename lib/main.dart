import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/providers/review_provider.dart';
import 'package:taf_match/repositories/cloudinary_image_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/services/firebase_auth_service.dart';
import 'package:taf_match/utils/cloudinary_config.dart';
import 'package:taf_match/utils/firebase_options.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/admin_dashboard.dart';
import 'package:taf_match/views/job_list_screen.dart';
import 'providers/auth_provider.dart';
import 'views/login_screen.dart';

import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/repositories/firestore_job_repository.dart';
import 'package:taf_match/views/jp_my_posting_screen.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';

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
        ChangeNotifierProvider(
          create: (_) => ApplicationProvider(FirestoreApplicationRepository()),
        ),
        ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(FirebaseAuthService(), FirestoreUserRepository())),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(FirestoreUserRepository()),
          update: (_, authProvider, userProvider) =>
              userProvider!..updateAuthProvider(authProvider),
        ),
        ChangeNotifierProvider(
            create: (_) => JobProvider(FirestoreJobRepository())),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(FirestoreReviewRepository()),
        ),
      ],
      child: Consumer2<AuthProvider, UserProvider>(
        builder: (context, auth, userProvider, _) {
          Widget home;
          if (auth.user == null) {
            // 1. Pas connecté
            home = const LoginScreen();
          } else if (userProvider.profile == null) {
            // 2. Connecté, mais le profil se charge encore
            home = const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (userProvider.profile!.role == 'employer') {
            // 3a. Employeur
            home = const MyPostingsScreen();
          } else if (userProvider.profile!.role == 'admin') {
            // 3a. Admin
            home = const AdminDashboardScreen();
          } else {
            // 3b. Étudiant (ou tout autre rôle)
            home = const JobListScreen();
          }
          return MaterialApp(
            title: 'Taf Match',
            theme: buildThemeData(),
            home: home,
          );
        },
      ),
    );
  }
}

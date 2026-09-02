import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/providers/notification_provider.dart';
import 'package:taf_match/providers/application_provider.dart';
import 'package:taf_match/providers/skill_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/providers/review_provider.dart';
import 'package:taf_match/repositories/cloudinary_image_repository.dart';
import 'package:taf_match/repositories/firestore_application_repository.dart';
import 'package:taf_match/repositories/firestore_skill_repository.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/repositories/firestore_review_repository.dart';
import 'package:taf_match/repositories/image_storage_repository.dart';
import 'package:taf_match/services/firebase_auth_service.dart';
import 'package:taf_match/utils/cloudinary_config.dart';
import 'package:taf_match/utils/firebase_options.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/admin_dashboard.dart';
import 'providers/auth_provider.dart';
import 'views/login_screen.dart';

import 'package:taf_match/providers/job_provider.dart';
import 'package:taf_match/repositories/firestore_job_repository.dart';
import 'package:taf_match/views/jp_main_screen.dart';
import 'package:taf_match/views/js_main_screen.dart';

import 'package:taf_match/services/salary_model.dart';
import 'package:taf_match/services/salary_estimator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  NotificationProvider.navigatorKey = GlobalKey<NavigatorState>();

  final salaryModel = await SalaryModel.loadAsset(); 

  runApp(
     MyApp(salaryModel: salaryModel));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.salaryModel});
  
  final SalaryModel salaryModel;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SalaryEstimator>.value(
          value: SalaryEstimator(salaryModel),
        ),


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
          create: (_) => AuthProvider(FirebaseAuthService(), FirestoreUserRepository()),
        ),
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
        ChangeNotifierProvider(
          create: (_) => SkillProvider(FirestoreSkillRepository()),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
          } else {
              final uid = auth.user!.uid;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (auth.user != null) {
                  context.read<NotificationProvider>().listenToNotifications(uid);
                }
              });
              final role = userProvider.profile!.role.trim().toLowerCase();
              if (role == 'employer') {
                home = const JpMainScreen();
              } else if (role == 'admin') {
                home = const AdminDashboardScreen();
              } else {
                home = const JeMainScreen();
              }
            }

          return MaterialApp(
            navigatorKey: NotificationProvider.navigatorKey,
            title: 'Taf Match',
            theme: buildThemeData(),
            home: home,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:taf_match/services/firebase_auth_service.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/repositories/firestore_job_repository.dart';
import 'package:taf_match/utils/firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'views/my_postings_screen.dart';

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
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            FirebaseAuthService(),
            FirestoreUserRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => JobProvider(FirestoreJobRepository()),
        ),
      ],
      child: const MaterialApp(
        title: 'Taf Match',
        home: MyPostingsScreen(),
      ),
    );
  }
}
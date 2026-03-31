import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/main_nav_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EduApp());
}

class EduApp extends StatelessWidget {
  const EduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Edu Mate',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/mainNav': (_) => const MainNavScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isSessionValid() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) return false;

    try {
      // يحدث بيانات المستخدم من Firebase
      await user.reload();
      final refreshedUser = auth.currentUser;

      if (refreshedUser == null) {
        await auth.signOut();
        return false;
      }

      // تأكد أن بياناته ما تزال موجودة في Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      if (!doc.exists) {
        await auth.signOut();
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-user-token') {
        await auth.signOut();
        return false;
      }
      await auth.signOut();
      return false;
    } catch (_) {
      await auth.signOut();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<bool>(
          future: _isSessionValid(),
          builder: (context, validationSnapshot) {
            if (validationSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (validationSnapshot.data == true) {
              return const MainNavScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/character_creation_screen.dart';
import 'services/database_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LifeQuestRPG());
}

class LifeQuestRPG extends StatelessWidget {
  const LifeQuestRPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeQuest RPG',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.amber),
      // IMPROVEMENT #1: Show splash screen first, then auth wrapper
      home: SplashScreen(nextScreen: const AuthWrapper()),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DatabaseService _db = DatabaseService();
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() => _isSigningIn = true);
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint("Auth Error: $e");
      } finally {
        if (mounted) setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null || _isSigningIn) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
      );
    }

    return StreamBuilder(
      stream: _db.getUserStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1B2A),
            body: Center(
              child: Text(
                'Connection error.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D1B2A),
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
          );
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          return const HomeScreen();
        }
        return const CharacterCreationScreen();
      },
    );
  }
}

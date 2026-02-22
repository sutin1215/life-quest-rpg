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

  // 1. Safe Initialization of Environment and Firebase
  try {
    // Attempt to load .env, but don't crash if it's missing (helps during Git moves)
    await dotenv
        .load(fileName: ".env")
        .catchError((e) => print("Warning: .env file not found"));

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Critical Init Error: $e");
  }

  runApp(const LifeQuestRPG());
}

class LifeQuestRPG extends StatelessWidget {
  const LifeQuestRPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeQuest RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        // Using a deep background to match your AuthWrapper
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
      // Starts with Splash, then moves to AuthWrapper
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
    // Check if we actually need to sign in
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) setState(() => _isSigningIn = true);
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
    // 2. Handle the "Authenticating" state
    if (FirebaseAuth.instance.currentUser == null || _isSigningIn) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
        ),
      );
    }

    // 3. Handle the "User Data" state via Firestore
    return StreamBuilder(
      stream: _db.getUserStats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Connection error.\nPlease check internet or keys.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
            ),
          );
        }

        // If the document exists, the user has already finished Character Creation
        if (snapshot.hasData && snapshot.data!.exists) {
          return const HomeScreen();
        }

        // New users or deleted accounts go to Character Creation
        return const CharacterCreationScreen();
      },
    );
  }
}

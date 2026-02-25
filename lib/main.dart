import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/character_creation_screen.dart';
import 'services/database_service.dart';
import 'firebase_options.dart';

void main() async {
  // Required for accessing platform channels before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1. LOAD DOTENV FIRST (Crucial: FirebaseOptions now depends on this)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment loaded successfully");
  } catch (e) {
    debugPrint("Warning: .env file missing or failed to load: $e");
    // We don't return/stop here, because DefaultFirebaseOptions
    // might have a fallback or throw a clearer error later.
  }

  // 2. INITIALIZE FIREBASE
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase Initialized");
    }
  } catch (e) {
    // This catches the [core/duplicate-app] error or API key issues
    debugPrint("Firebase Init Error: $e");
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
    // 1. Handle the "Authenticating" state
    if (FirebaseAuth.instance.currentUser == null || _isSigningIn) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
        ),
      );
    }

    // 2. Handle the "User Data" state via Firestore
    // We use FutureBuilder and .first so it only checks ONCE on app load,
    // preventing it from instantly auto-routing while the pop-up is showing!
    return FutureBuilder<DocumentSnapshot>(
      future: _db.getUserStats().first,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Connection error: ${snapshot.error}\nPlease check internet or keys.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
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

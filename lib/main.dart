import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/character_creation_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LifeQuestRPG());
}

class LifeQuestRPG extends StatelessWidget {
  const LifeQuestRPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeQuest RPG',
      theme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.amber),
      home: const AuthWrapper(),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // PRE-LOAD THE MAP: This prevents the frame skip lag later
    precacheImage(
        const AssetImage("assets/images/map_background.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.getUserStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          return const HomeScreen();
        }
        return const CharacterCreationScreen();
      },
    );
  }
}

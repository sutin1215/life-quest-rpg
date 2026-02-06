import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart'; // <--- THIS WAS MISSING

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _bioController = TextEditingController();
  final _ai = AiService();
  final _db = DatabaseService();
  bool _isLoading = false;

  void _awakenHero() async {
    if (_bioController.text.isEmpty) return;
    setState(() => _isLoading = true);

    // 1. Ask AI to judge the soul
    final result = await _ai.generateCharacter(_bioController.text);

    // 2. Save the Hero to DB
    await _db.initializeUser(result);

    if (!mounted) return;

    // 3. NAVIGATE TO PROFILE REVEAL
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              Text("WHO ARE YOU?",
                  style: GoogleFonts.vt323(fontSize: 40, color: Colors.white)),
              const SizedBox(height: 10),
              Text(
                "Tell the Fate Weaver about your daily life, your studies, and your hobbies...",
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _bioController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText:
                      "e.g., I am a Computer Science student. I love lifting weights, drinking coffee, and solving puzzles.",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 10),
                        Text("Weaving Destiny...",
                            style: TextStyle(color: Colors.amber))
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.all(20),
                        ),
                        onPressed: _awakenHero,
                        child: Text("AWAKEN",
                            style: GoogleFonts.vt323(
                                fontSize: 24, color: Colors.black)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

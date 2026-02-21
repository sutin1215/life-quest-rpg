import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import 'profile_screen.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _bioController = TextEditingController();
  final _mainQuestController = TextEditingController();
  final _ai = AiService();
  final _db = DatabaseService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bioController.dispose();
    _mainQuestController.dispose();
    super.dispose();
  }

  void _awakenHero() async {
    if (_bioController.text.trim().isEmpty ||
        _mainQuestController.text.trim().isEmpty) {
      setState(
          () => _errorMessage = "Fill in both fields to awaken your hero!");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ai.generateCharacter(
          _bioController.text, _mainQuestController.text);

      result['mainQuest'] = _mainQuestController.text;
      result['bio'] = _bioController.text;
      await _db.initializeUser(result);

      if (!mounted) return;

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()));
    } catch (e) {
      // IMPROVEMENT #12: User-friendly error if AI/network fails
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "The Fate Weaver is unreachable. Check your connection and try again.";
        });
      }
    }
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
                enabled: !_isLoading,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText:
                      "e.g., I am a Computer Science student. I love lifting weights, drinking coffee, and solving puzzles.",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text("WHAT IS YOUR MAIN QUEST?",
                  style: GoogleFonts.vt323(fontSize: 32, color: Colors.white)),
              const SizedBox(height: 10),
              Text(
                "Describe the primary goal you wish to achieve...",
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _mainQuestController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                enabled: !_isLoading,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: "e.g., Get in shape and run a 5K",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                ),
              ),

              // IMPROVEMENT #12: Show error message if something goes wrong
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                        fontSize: 18, color: Colors.redAccent),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              _isLoading
                  ? Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.amber),
                        const SizedBox(height: 16),
                        Text("Weaving Destiny...",
                            style: GoogleFonts.vt323(
                                fontSize: 22, color: Colors.amber)),
                        const SizedBox(height: 4),
                        Text("The Fate Weaver is judging your soul...",
                            style: GoogleFonts.vt323(
                                fontSize: 16, color: Colors.white54)),
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

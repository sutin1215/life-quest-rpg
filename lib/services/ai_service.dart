import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';

class AiService {
  late final GenerativeModel _model;

  AiService() {
    // 2026 Standard: FREE Gemini Developer API
    final ai = FirebaseAI.googleAI();
    _model = ai.generativeModel(model: 'gemini-2.5-flash');
  }

  // --- EXISTING QUEST GENERATION ---
  Future<Map<String, dynamic>> generateQuest(String userTask) async {
    final prompt = [
      Content.text('''
        You are an RPG Guildmaster. Task: "$userTask".
        1. Categorize: Physical->STR, Mental->INT, Speed/Social->DEX.
        2. Gold = XP / 2.
        Return ONLY JSON: {"title": "Epic Name", "description": "Short desc", "xp": 50, "gold": 25, "statType": "STR"}
      ''')
    ];
    return _safeGenerate(prompt, {
      "title": "Unknown Task",
      "description": "Task: $userTask",
      "xp": 10,
      "gold": 5,
      "statType": "STR"
    });
  }

  // --- NEW: ORIGIN STORY GENERATION ---
  Future<Map<String, dynamic>> generateCharacter(String bio) async {
    final prompt = [
      Content.text('''
        You are the Fate Weaver. Analyze this bio: "$bio".
        1. Create a creative RPG Class Name (e.g., "Code Warlock", "Iron Chef", "Shadow Runner").
        2. Assign base stats (STR, INT, DEX) that sum to exactly 15.
        3. Write a 1-sentence "Origin Story".
        Return ONLY JSON:
        {"className": "Name", "story": "Story", "str": 5, "int": 5, "dex": 5}
      ''')
    ];
    return _safeGenerate(prompt, {
      "className": "Novice Adventurer",
      "story": "A hero begins their journey.",
      "str": 5,
      "int": 5,
      "dex": 5
    });
  }

  // Helper to handle errors/JSON cleaning
  Future<Map<String, dynamic>> _safeGenerate(
      List<Content> prompt, Map<String, dynamic> fallback) async {
    try {
      final response = await _model.generateContent(prompt);
      if (response.text == null) throw Exception("Empty AI response");
      String clean = response.text!.trim();
      if (clean.contains('```'))
        clean = clean.split('```')[1].replaceFirst('json', '').trim();
      return jsonDecode(clean);
    } catch (e) {
      print("AI ERROR: $e");
      return fallback;
    }
  }
}

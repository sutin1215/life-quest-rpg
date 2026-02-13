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
  Future<Map<String, dynamic>> generateCharacter(
      String bio, String mainQuest) async {
    final prompt = [
      Content.text('''
        You are the Fate Weaver. A new hero approaches with a bio and a goal.
        Bio: "$bio"
        Main Quest: "$mainQuest"

        1. Create a creative RPG Class Name inspired by their bio and main quest (e.g., "Code Warlock", "Iron Chef").
        2. Write a 1-sentence "Origin Story" that connects their past (bio) to their future (main quest).
        3. Assign base stats (STR, INT, DEX) that sum to exactly 15, reflecting what they'll need for their quest.
        
        Return ONLY JSON:
        {"className": "Name", "story": "Story", "str": 5, "int": 5, "dex": 5}
      ''')
    ];
    return _safeGenerate(prompt, {
      "className": "Novice Adventurer",
      "story": "A hero begins their journey towards '$mainQuest'.",
      "str": 5,
      "int": 5,
      "dex": 5
    });
  }

  Future<List<Map<String, dynamic>>> generateStarterQuests(
      String bio, String mainQuest) async {
    final prompt = [
      Content.text('''
        You are the Quest Giver in an RPG. A new hero needs their first quests.
        Their background: "$bio"
        Their ultimate goal: "$mainQuest"

        Generate a JSON array of 3-4 simple, real-world, beginner-friendly quests. These should be logical first steps towards their main quest, inspired by their bio.
        
        For each quest, include:
        - "title": "Creative Quest Name"
        - "description": "A short, actionable description of the task."
        - "xp": An appropriate amount of XP (10-30 for starter quests).
        - "gold": XP divided by 2.
        - "statType": "STR", "INT", or "DEX" based on the task category.

        Return ONLY the JSON array. Example:
        [
          {"title": "Research Local Gyms", "description": "Find three gyms nearby and note their prices.", "xp": 20, "gold": 10, "statType": "INT"},
          {"title": "Morning Jog", "description": "Go for a 15-minute jog or walk.", "xp": 15, "gold": 8, "statType": "STR"}
        ]
      ''')
    ];
    return _safeGenerateList(prompt, [
      {
        "title": "Review Your Main Quest",
        "description": "Take 5 minutes to think about your main quest.",
        "xp": 10,
        "gold": 5,
        "statType": "INT"
      }
    ]);
  }

  // Helper to handle errors/JSON cleaning
  Future<Map<String, dynamic>> _safeGenerate(
      List<Content> prompt, Map<String, dynamic> fallback) async {
    try {
      final response = await _model.generateContent(prompt);
      if (response.text == null) {
        throw Exception("Empty AI response");
      }
      String clean = response.text!.trim();
      if (clean.contains('```')) {
        clean = clean.split('```')[1].replaceFirst('json', '').trim();
      }
      return jsonDecode(clean);
    } catch (e) {
      // TODO: Add proper logging
      return fallback;
    }
  }

  // Helper to handle list generation
  Future<List<Map<String, dynamic>>> _safeGenerateList(
      List<Content> prompt, List<Map<String, dynamic>> fallback) async {
    try {
      final response = await _model.generateContent(prompt);
      if (response.text == null) {
        throw Exception("Empty AI response");
      }
      String clean = response.text!.trim();
      if (clean.contains('```')) {
        clean = clean.split('```')[1].replaceFirst('json', '').trim();
      }
      final decoded = jsonDecode(clean) as List;
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      // TODO: Add proper logging
      return fallback;
    }
  }
}

import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';

class AiService {
  late final GenerativeModel _model;
  late final GenerativeModel _jsonModel;

  AiService() {
    final ai = FirebaseAI.googleAI();

    // Standard model for creative text
    _model = ai.generativeModel(
      model: 'gemini-2.5-flash',
    );

    // JSON Model for structured data (Quests/Character)
    _jsonModel = ai.generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  // --- BATTLE NARRATION SYSTEM ---

  /// BRIDGE METHOD: This fixes the compilation error in BattleScreen
  Future<String> generateBattleNarration({
    required String heroClass,
    required int heroLevel,
    required String bossName,
    required int bossLevel,
    required bool didWin,
    required String intensity,
  }) async {
    // If the intensity is "Beginning", use the Taunt logic
    if (intensity == "Beginning") {
      return await generateBossTaunt(bossName);
    }
    // Otherwise, use the Result logic for the end of the fight
    else {
      return await generateBattleResult(
        heroClass: heroClass,
        bossName: bossName,
        didWin: didWin,
        turnsTaken: 5, // Estimated average for narration context
        remainingHp: 10,
      );
    }
  }

  // Generates a menacing taunt before the fight begins
  Future<String> generateBossTaunt(String bossName) async {
    final prompt = [
      Content.text('''
        You are the boss "$bossName" in a retro RPG. 
        Write a short, menacing taunt to the player (max 1 sentence).
        Style: 16-bit villain. No emojis.
      ''')
    ];
    try {
      final response = await _model.generateContent(prompt);
      return response.text?.trim() ?? "$bossName glares at you menacingly.";
    } catch (e) {
      return "$bossName prepares to attack!";
    }
  }

  // Generates the final victory or defeat story
  Future<String> generateBattleResult({
    required String heroClass,
    required String bossName,
    required bool didWin,
    required int turnsTaken,
    required int remainingHp,
  }) async {
    final prompt = [
      Content.text('''
        Write a 2-sentence RPG narration for a battle outcome.
        Hero: $heroClass. Boss: $bossName.
        Outcome: ${didWin ? "Victory" : "Defeat"}.
        Context: The battle lasted $turnsTaken turns.
        Style: Epic, dramatic, retro game style.
      ''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text?.trim() ??
          (didWin
              ? "The $bossName falls! You are victorious!"
              : "You black out... the $bossName was too strong.");
    } catch (e) {
      return didWin ? "Victory!" : "Defeat...";
    }
  }

  // --- QUEST GENERATION ---

  Future<Map<String, dynamic>> generateQuest(String userTask) async {
    final prompt = [
      Content.text('''
        You are an RPG Guildmaster. Task: "$userTask".
        1. Categorize: Physical->STR, Mental->INT, Speed/Social->DEX.
        2. Gold = XP / 2.
        Return JSON object: {"title": "Epic Name", "description": "Short desc", "xp": 50, "gold": 25, "statType": "STR"}
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

  // --- ORIGIN STORY GENERATION ---

  Future<Map<String, dynamic>> generateCharacter(
      String bio, String mainQuest) async {
    final prompt = [
      Content.text('''
        You are the Fate Weaver. A new hero approaches with a bio and a goal.
        Bio: "$bio"
        Main Quest: "$mainQuest"

        1. Create a creative RPG Class Name inspired by their bio (e.g., "Code Warlock").
        2. Write a 1-sentence "Origin Story" connecting their past to their future.
        3. Assign base stats (STR, INT, DEX) that sum to exactly 15.
        
        Return JSON object:
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

  // --- STARTER QUESTS ---

  Future<List<Map<String, dynamic>>> generateStarterQuests(
      String bio, String mainQuest) async {
    final prompt = [
      Content.text('''
        You are the Quest Giver in an RPG. A new hero needs their first quests.
        Their background: "$bio"
        Their ultimate goal: "$mainQuest"

        Generate a JSON array of 3 simple, real-world, beginner-friendly quests.
        Format:
        [
          {"title": "Quest Name", "description": "Short desc", "xp": 20, "gold": 10, "statType": "STR"},
          ...
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

  // --- HELPERS ---

  Future<Map<String, dynamic>> _safeGenerate(
      List<Content> prompt, Map<String, dynamic> fallback) async {
    try {
      final response = await _jsonModel.generateContent(prompt);
      final text = response.text!.trim();
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      print("AI Generation Error: $e");
      return fallback;
    }
  }

  Future<List<Map<String, dynamic>>> _safeGenerateList(
      List<Content> prompt, List<Map<String, dynamic>> fallback) async {
    try {
      final response = await _jsonModel.generateContent(prompt);
      final text = response.text!.trim();
      final decoded = jsonDecode(text) as List;
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print("AI List Generation Error: $e");
      return fallback;
    }
  }
}

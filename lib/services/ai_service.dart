import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  late final GenerativeModel _model;
  late final GenerativeModel _jsonModel;

  AiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('WARNING: GEMINI_API_KEY not found in .env file!');
    }

    // gemini-2.5-flash-lite: fastest & cheapest currently available model
    // — perfect for real-time battle calls (taunts, narration)
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite-preview-06-17',
      apiKey: apiKey,
    );

    // gemini-2.5-flash: smarter, better JSON reliability
    // — used for one-time generation (character, quests, starter quests)
    _jsonModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RETRY HELPER
  // Retries up to [maxRetries] times on quota/rate-limit errors.
  // Reads the suggested wait time from the error message if available.
  // ---------------------------------------------------------------------------
  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await fn();
      } catch (e) {
        final errStr = e.toString();
        final isQuota = errStr.contains('quota') ||
            errStr.contains('429') ||
            errStr.contains('RESOURCE_EXHAUSTED');

        if (!isQuota || attempt == maxRetries - 1) rethrow;

        int waitSeconds = 10 * (attempt + 1); // 10s, 20s, 30s
        final retryMatch = RegExp(r'retry in (\d+)').firstMatch(errStr);
        if (retryMatch != null) {
          waitSeconds = int.tryParse(retryMatch.group(1) ?? '') ?? waitSeconds;
          waitSeconds = waitSeconds.clamp(5, 60);
        }

        debugPrint(
            'AI quota hit — waiting ${waitSeconds}s before retry ${attempt + 1}/$maxRetries...');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }
    throw Exception('AI request failed after $maxRetries retries.');
  }

  // ---------------------------------------------------------------------------
  // BATTLE NARRATION
  // ---------------------------------------------------------------------------

  /// Bridge method used by BattleScreen
  Future<String> generateBattleNarration({
    required String heroClass,
    required int heroLevel,
    required String bossName,
    required int bossLevel,
    required bool didWin,
    required String intensity,
  }) async {
    if (intensity == "Beginning") {
      return await generateBossTaunt(bossName);
    } else if (intensity == "MidBattle") {
      return await generateMidBattleTaunt(bossName);
    } else {
      return await generateBattleResult(
        heroClass: heroClass,
        bossName: bossName,
        didWin: didWin,
        turnsTaken: 5,
        remainingHp: 10,
      );
    }
  }

  /// Menacing opening taunt before fight begins
  Future<String> generateBossTaunt(String bossName) async {
    final prompt = '''
      You are the boss "$bossName" in a retro RPG.
      Write a short, menacing opening taunt to the player (max 1 sentence).
      Style: 16-bit villain. No emojis.
    ''';
    try {
      return await _withRetry(() async {
        final response = await _model.generateContent([Content.text(prompt)]);
        return response.text?.trim() ?? "$bossName glares at you menacingly.";
      });
    } catch (e) {
      debugPrint('generateBossTaunt error: $e');
      return "$bossName prepares to attack!";
    }
  }

  /// Mid-battle taunt when boss HP drops below 50%
  Future<String> generateMidBattleTaunt(String bossName) async {
    final prompt = '''
      You are the boss "$bossName" in a retro RPG. Your health is dropping.
      Write a short, desperate and angry mid-battle taunt (max 1 sentence).
      Style: 16-bit villain growing desperate. No emojis.
    ''';
    try {
      return await _withRetry(() async {
        final response = await _model.generateContent([Content.text(prompt)]);
        return response.text?.trim() ?? "$bossName roars with fury!";
      });
    } catch (e) {
      debugPrint('generateMidBattleTaunt error: $e');
      return "$bossName is enraged!";
    }
  }

  /// Final victory or defeat narration
  Future<String> generateBattleResult({
    required String heroClass,
    required String bossName,
    required bool didWin,
    required int turnsTaken,
    required int remainingHp,
  }) async {
    final prompt = '''
      Write a 2-sentence RPG narration for a battle outcome.
      Hero: $heroClass. Boss: $bossName.
      Outcome: ${didWin ? "Victory" : "Defeat"}.
      Context: The battle lasted $turnsTaken turns.
      Style: Epic, dramatic, retro game style.
    ''';
    try {
      return await _withRetry(() async {
        final response = await _model.generateContent([Content.text(prompt)]);
        return response.text?.trim() ??
            (didWin
                ? "The $bossName falls! You are victorious!"
                : "You black out... the $bossName was too strong.");
      });
    } catch (e) {
      debugPrint('generateBattleResult error: $e');
      return didWin ? "Victory!" : "Defeat...";
    }
  }

  // ---------------------------------------------------------------------------
  // QUEST GENERATION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> generateQuest(String userTask) async {
    final prompt = '''
      You are an RPG Guildmaster. A hero wants to accomplish: "$userTask".

      1. Create an epic, lore-flavored quest title (e.g., "Slay the Scrolls of Calculus").
      2. Write a short in-world description (1 sentence, flavored as an RPG quest).
      3. Categorize: Physical activity -> STR, Mental/study -> INT, Speed/social/agility -> DEX.
      4. Set xp between 20-100 based on difficulty. Set gold = xp / 2.

      Return ONLY a JSON object:
      {"title": "Epic Name", "description": "In-world desc", "xp": 50, "gold": 25, "statType": "STR"}
    ''';
    return _safeGenerate(prompt, {
      "title": "Unknown Task",
      "description": "A mysterious task awaits the brave.",
      "xp": 10,
      "gold": 5,
      "statType": "STR",
    });
  }

  // ---------------------------------------------------------------------------
  // CHARACTER GENERATION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> generateCharacter(
      String bio, String mainQuest) async {
    final prompt = '''
      You are the Fate Weaver. A new hero approaches with a bio and a goal.
      Bio: "$bio"
      Main Quest: "$mainQuest"

      1. Create a creative RPG Class Name inspired by their bio (e.g., "Code Warlock", "Iron Scholar").
      2. Write a 1-sentence "Origin Story" connecting their past to their future quest.
      3. Assign base stats (STR, INT, DEX) that sum to exactly 15, reflecting the bio.

      Return ONLY a JSON object:
      {"className": "Name", "story": "Story", "str": 5, "int": 5, "dex": 5}
    ''';
    return _safeGenerate(prompt, {
      "className": "Novice Adventurer",
      "story": "A hero begins their journey towards '$mainQuest'.",
      "str": 5,
      "int": 5,
      "dex": 5,
    });
  }

  // ---------------------------------------------------------------------------
  // STARTER QUESTS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> generateStarterQuests(
      String bio, String mainQuest) async {
    final prompt = '''
      You are the Quest Giver in an RPG. A new hero needs their first quests.
      Their background: "$bio"
      Their ultimate goal: "$mainQuest"

      Generate a JSON array of exactly 3 simple, real-world, beginner-friendly quests.
      Each quest description should be written in lore-flavored RPG language.
      Format:
      [
        {"title": "Quest Name", "description": "In-world description", "xp": 20, "gold": 10, "statType": "STR"},
        ...
      ]
      Return ONLY the JSON array, no extra text.
    ''';
    return _safeGenerateList(prompt, [
      {
        "title": "First Steps of the Chosen",
        "description":
            "The Fate Weaver commands: review thy main quest and forge thy resolve.",
        "xp": 10,
        "gold": 5,
        "statType": "INT",
      }
    ]);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _safeGenerate(
      String prompt, Map<String, dynamic> fallback) async {
    try {
      return await _withRetry(() async {
        final response =
            await _jsonModel.generateContent([Content.text(prompt)]);
        final text = response.text!.trim();
        final clean = text
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        return jsonDecode(clean) as Map<String, dynamic>;
      });
    } catch (e) {
      debugPrint('AI Generation Error: $e');
      return fallback;
    }
  }

  Future<List<Map<String, dynamic>>> _safeGenerateList(
      String prompt, List<Map<String, dynamic>> fallback) async {
    try {
      return await _withRetry(() async {
        final response =
            await _jsonModel.generateContent([Content.text(prompt)]);
        final text = response.text!.trim();
        final clean = text
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        final decoded = jsonDecode(clean) as List;
        return decoded.map((item) => item as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('AI List Generation Error: $e');
      return fallback;
    }
  }
}

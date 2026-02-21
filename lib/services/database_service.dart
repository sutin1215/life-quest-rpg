import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in!");
    return user.uid;
  }

  // --- STREAMS ---

  Stream<QuerySnapshot> getQuests() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('quests')
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getUserStats() {
    return _db.collection('users').doc(userId).snapshots();
  }

  // --- ACTIONS ---

  Future<void> initializeUser(Map<String, dynamic> aiData) async {
    await _db.collection('users').doc(userId).set({
      'className': aiData['className'],
      'story': aiData['story'],
      'mainQuest': aiData['mainQuest'],
      'bio': aiData['bio'],
      'level': 1,
      'xp': 0,
      'gold': 0,
      'str': aiData['str'],
      'int': aiData['int'],
      'dex': aiData['dex'],
      'currentZone': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addQuest(Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).collection('quests').add({
      ...data,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // FIX #7: Guard against duplicate starter quests being added if the user
  // somehow reaches ProfileScreen again. Only adds quests if none exist yet.
  Future<void> addQuests(List<Map<String, dynamic>> quests) async {
    final userQuestRef =
        _db.collection('users').doc(userId).collection('quests');

    // Check if quests already exist to prevent duplicates
    final existing = await userQuestRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final quest in quests) {
      final newQuestRef = userQuestRef.doc();
      batch.set(newQuestRef, {
        ...quest,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> completeQuest(
      String questId, int xp, int gold, String statType) async {
    final userRef = _db.collection('users').doc(userId);
    final questRef = userRef.collection('quests').doc(questId);

    await _db.runTransaction((t) async {
      final snap = await t.get(userRef);
      if (!snap.exists) return;

      final d = snap.data() as Map<String, dynamic>;
      int lvl = d['level'] ?? 1;
      int curXp = d['xp'] ?? 0;
      int curStat = d[statType.toLowerCase()] ?? 0;

      int newXp = curXp + xp;
      int xpNeed = lvl * 100;

      if (newXp >= xpNeed) {
        lvl++;
        newXp -= xpNeed;
      }

      t.update(userRef, {
        'level': lvl,
        'xp': newXp,
        'gold': (d['gold'] ?? 0) + gold,
        statType.toLowerCase(): curStat + 1,
      });
      t.update(questRef, {'isCompleted': true});
    });
  }

  // FIX #2: defeatBoss now runs inside a transaction and applies the same
  // level-up logic as completeQuest, instead of raw FieldValue.increment
  // which bypassed leveling entirely.
  Future<bool> defeatBoss(int zoneId) async {
    const int bossXp = 200;
    const int bossGold = 100;

    try {
      final userRef = _db.collection('users').doc(userId);

      await _db.runTransaction((t) async {
        final snap = await t.get(userRef);
        if (!snap.exists) throw Exception("User not found");

        final d = snap.data() as Map<String, dynamic>;
        int lvl = d['level'] ?? 1;
        int curXp = d['xp'] ?? 0;
        int curGold = d['gold'] ?? 0;
        int curZone = d['currentZone'] ?? 1;

        int newXp = curXp + bossXp;
        int xpNeed = lvl * 100;

        // Apply level-up logic properly
        if (newXp >= xpNeed) {
          lvl++;
          newXp -= xpNeed;
        }

        t.update(userRef, {
          'level': lvl,
          'xp': newXp,
          'gold': curGold + bossGold,
          // Only advance zone if this is the current zone
          'currentZone': (zoneId >= curZone) ? zoneId + 1 : curZone,
        });
      });

      return true;
    } catch (e) {
      debugPrint("defeatBoss error: $e");
      return false;
    }
  }

  // --- SHOP LOGIC ---

  Future<bool> buyItem(int cost, String statType, int amount) async {
    final userRef = _db.collection('users').doc(userId);

    try {
      await _db.runTransaction((t) async {
        final snap = await t.get(userRef);
        if (!snap.exists) throw Exception("User not found");

        final data = snap.data() as Map<String, dynamic>;
        int currentGold = data['gold'] ?? 0;
        int currentStat = data[statType.toLowerCase()] ?? 0;

        if (currentGold < cost) throw Exception("Not enough gold!");

        t.update(userRef, {
          'gold': currentGold - cost,
          statType.toLowerCase(): currentStat + amount,
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

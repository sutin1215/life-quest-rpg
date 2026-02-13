import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // 1. DEFINING _db HERE MAKES IT VISIBLE TO THE WHOLE CLASS
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId = "hero_player_1";

  // --- STREAMS ---
  Stream<QuerySnapshot> getQuests() {
    return _db
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
    await _db.collection('quests').add({
      ...data,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addQuests(List<Map<String, dynamic>> quests) async {
    final batch = _db.batch();
    for (final quest in quests) {
      final newQuestRef = _db.collection('quests').doc();
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
    final questRef = _db.collection('quests').doc(questId);

    await _db.runTransaction((t) async {
      final snap = await t.get(userRef);
      if (!snap.exists) return; // Should exist if we initialized!

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
        statType.toLowerCase(): curStat + 1
      });
      t.update(questRef, {'isCompleted': true});
    });
  }

  Future<bool> defeatBoss(int zoneId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'currentZone': zoneId + 1,
        'gold': FieldValue.increment(100),
        'xp': FieldValue.increment(200),
      });
      return true;
    } catch (e) {
      // TODO: Add proper logging
      return false;
    }
  }

  // --- SHOP LOGIC ---
  Future<bool> buyItem(int cost, String statType, int amount) async {
    final userRef = _db.collection('users').doc(userId);

    try {
      await _db.runTransaction((t) async {
        final snap = await t.get(userRef);
        if (!snap.exists) {
          throw Exception("User not found");
        }

        final data = snap.data() as Map<String, dynamic>;
        int currentGold = data['gold'] ?? 0;
        int currentStat = data[statType.toLowerCase()] ?? 0;

        if (currentGold < cost) {
          throw Exception("Not enough gold!");
        }

        t.update(userRef, {
          'gold': currentGold - cost,
          statType.toLowerCase(): currentStat + amount,
        });
      });
      return true;
    } catch (e) {
      // TODO: Add proper logging
      return false;
    }
  }
}

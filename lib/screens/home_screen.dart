import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'world_map_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const QuestBoard(),
    const WorldMapScreen(),
    const ShopScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF2D2D2D),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Quests"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hero"),
        ],
      ),
    );
  }
}

// IMPROVEMENT #8: QuestBoard split into its own class (still in same file
// for minimal disruption — you can move it to quest_board.dart later).

class QuestBoard extends StatefulWidget {
  const QuestBoard({super.key});
  @override
  State<QuestBoard> createState() => _QuestBoardState();
}

class _QuestBoardState extends State<QuestBoard> {
  final db = DatabaseService();
  final ai = AiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text("QUEST BOARD",
            style: GoogleFonts.vt323(fontSize: 28, color: Colors.amber)),
        actions: [_buildGoldCounter()],
      ),
      body: Column(
        children: [
          _buildAttributeBar(),
          Expanded(child: _buildQuestList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () => _showAddQuestDialog(),
        child: const Icon(Icons.shield, color: Colors.black),
      ),
    );
  }

  Widget _buildGoldCounter() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        int gold = data?['gold'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text("$gold",
                style: GoogleFonts.vt323(fontSize: 24, color: Colors.white)),
          ]),
        );
      },
    );
  }

  Widget _buildAttributeBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        // FIX: Handle error state
        if (snap.hasError) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text("Could not load stats.",
                style: GoogleFonts.vt323(color: Colors.redAccent)),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox(height: 50);
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        final int lvl = d['level'] ?? 1;
        final int xp = d['xp'] ?? 0;
        final int xpNeeded = lvl * 100;

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _statText("STR", d['str'] ?? 0, Colors.redAccent),
                _statText("INT", d['int'] ?? 0, Colors.blueAccent),
                _statText("DEX", d['dex'] ?? 0, Colors.greenAccent),
                _statText("LVL", lvl, Colors.white),
              ]),
              const SizedBox(height: 8),
              // IMPROVEMENT #2: XP bar shows progress to next level
              Row(children: [
                Text("XP  ",
                    style:
                        GoogleFonts.vt323(color: Colors.amber, fontSize: 14)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (xp / xpNeeded).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade800,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text("$xp / $xpNeeded",
                    style:
                        GoogleFonts.vt323(color: Colors.white70, fontSize: 14)),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _statText(String label, int val, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.vt323(color: color, fontSize: 16)),
      Text("$val", style: GoogleFonts.vt323(color: Colors.white, fontSize: 22)),
    ]);
  }

  Widget _buildQuestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.getQuests(),
      builder: (context, snap) {
        // FIX: Handle error state
        if (snap.hasError) {
          return Center(
            child: Text("Failed to load quests.\nCheck your connection.",
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.vt323(color: Colors.redAccent, fontSize: 20)),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          // IMPROVEMENT #9: Shimmer-style loading placeholders
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 3,
            itemBuilder: (context, index) => _buildSkeletonCard(),
          );
        }

        // IMPROVEMENT #10: Empty state message
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text("No quests active, Adventurer!",
                    style:
                        GoogleFonts.vt323(fontSize: 24, color: Colors.white54)),
                const SizedBox(height: 8),
                Text("Tap the shield below to summon one.",
                    style:
                        GoogleFonts.vt323(fontSize: 18, color: Colors.white38)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: snap.data!.docs.map((doc) {
            final q = doc.data() as Map<String, dynamic>;
            return _buildQuestCard(doc, q);
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuestCard(QueryDocumentSnapshot doc, Map<String, dynamic> q) {
    Color statColor = Colors.white70;
    if (q['statType'] == 'STR') statColor = Colors.redAccent;
    if (q['statType'] == 'INT') statColor = Colors.blueAccent;
    if (q['statType'] == 'DEX') statColor = Colors.greenAccent;

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(q['title'] ?? 'Quest',
            style: GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q['description'] ?? '',
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.star, color: Colors.amber, size: 14),
              Text(" +${q['xp']} XP",
                  style: GoogleFonts.vt323(fontSize: 16, color: Colors.amber)),
              const SizedBox(width: 12),
              Icon(Icons.monetization_on, color: Colors.yellow, size: 14),
              Text(" +${q['gold']} G",
                  style: GoogleFonts.vt323(fontSize: 16, color: Colors.yellow)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statColor.withOpacity(0.5)),
                ),
                child: Text(q['statType'] ?? 'STR',
                    style: GoogleFonts.vt323(fontSize: 14, color: statColor)),
              ),
            ]),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black54),
          // IMPROVEMENT #11: Confirm before SLAY
          onPressed: () => _confirmSlay(doc, q),
          child: Text("SLAY", style: GoogleFonts.vt323(color: Colors.amber)),
        ),
      ),
    );
  }

  // IMPROVEMENT #11: Confirmation bottom sheet before completing a quest
  void _confirmSlay(QueryDocumentSnapshot doc, Map<String, dynamic> q) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("COMPLETE QUEST?",
                style: GoogleFonts.vt323(fontSize: 26, color: Colors.amber)),
            const SizedBox(height: 8),
            Text(q['title'] ?? '',
                style: GoogleFonts.vt323(fontSize: 22, color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                "Reward: +${q['xp']} XP  |  +${q['gold']} G  |  +1 ${q['statType']}",
                style: GoogleFonts.vt323(fontSize: 18, color: Colors.white60)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38)),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("CANCEL",
                      style: GoogleFonts.vt323(
                          fontSize: 18, color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () {
                    Navigator.pop(ctx);
                    db.completeQuest(doc.id, q['xp'] ?? 0, q['gold'] ?? 0,
                        q['statType'] ?? 'STR');
                    _showLevelUpCheck();
                  },
                  child: Text("SLAY IT!",
                      style:
                          GoogleFonts.vt323(fontSize: 18, color: Colors.black)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // IMPROVEMENT #4: Level-up notification
  // Checks user stats after quest completion and shows banner if leveled up
  void _showLevelUpCheck() async {
    final before = await db.getUserStats().first;
    final beforeData = before.data() as Map<String, dynamic>?;
    final beforeLvl = beforeData?['level'] ?? 1;

    // Wait for Firestore write to propagate
    await Future.delayed(const Duration(milliseconds: 800));

    final after = await db.getUserStats().first;
    final afterData = after.data() as Map<String, dynamic>?;
    final afterLvl = afterData?['level'] ?? 1;

    if (afterLvl > beforeLvl && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 60),
                const SizedBox(height: 12),
                Text("LEVEL UP!",
                    style:
                        GoogleFonts.vt323(fontSize: 48, color: Colors.amber)),
                Text("You are now Level $afterLvl!",
                    style:
                        GoogleFonts.vt323(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("ONWARD!",
                      style:
                          GoogleFonts.vt323(fontSize: 20, color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // IMPROVEMENT #9: Skeleton loading card
  Widget _buildSkeletonCard() {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuestDialog() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => _AddQuestDialog(
        ctrl: ctrl,
        ai: ai,
        db: db,
      ),
    );
  }
}

// IMPROVEMENT: Extracted AddQuestDialog as its own StatefulWidget to properly
// handle its own loading state and avoid the async-safety issue (FIX #5).
class _AddQuestDialog extends StatefulWidget {
  final TextEditingController ctrl;
  final AiService ai;
  final DatabaseService db;

  const _AddQuestDialog(
      {required this.ctrl, required this.ai, required this.db});

  @override
  State<_AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends State<_AddQuestDialog> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: Text("NEW QUEST",
          style: GoogleFonts.vt323(color: Colors.amber, fontSize: 28)),
      content: _isLoading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 8),
                    Text("Summoning quest...",
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: widget.ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "What must be done?",
                    hintStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () async {
              if (widget.ctrl.text.trim().isEmpty) {
                setState(() => _error = "Please describe your quest first!");
                return;
              }
              setState(() {
                _isLoading = true;
                _error = null;
              });
              try {
                // FIX #5: All async work is done inside this widget's own
                // state, so mounted check is valid and navigator is safe.
                final result = await widget.ai.generateQuest(widget.ctrl.text);
                await widget.db.addQuest(result);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _error = "Failed to generate quest. Try again.";
                  });
                }
              }
            },
            child: Text("SUMMON",
                style: GoogleFonts.vt323(color: Colors.amber, fontSize: 20)),
          ),
      ],
    );
  }
}

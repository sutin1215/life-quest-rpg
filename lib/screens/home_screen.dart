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
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.white))
            ]));
      },
    );
  }

  Widget _buildAttributeBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox(height: 50);
        }
        final d = snap.data!.data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(8)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statText("STR", d['str'] ?? 0, Colors.redAccent),
            _statText("INT", d['int'] ?? 0, Colors.blueAccent),
            _statText("DEX", d['dex'] ?? 0, Colors.greenAccent),
            _statText("LVL", d['level'] ?? 1, Colors.white)
          ]),
        );
      },
    );
  }

  Widget _statText(String label, int val, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.vt323(color: color, fontSize: 16)),
      Text("$val", style: GoogleFonts.vt323(color: Colors.white, fontSize: 22))
    ]);
  }

  Widget _buildQuestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.getQuests(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snap.data!.docs.map((doc) {
            final q = doc.data() as Map<String, dynamic>;
            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(q['title'] ?? 'Quest',
                    style:
                        GoogleFonts.vt323(fontSize: 20, color: Colors.white)),
                subtitle: Text("${q['description']}\n+${q['xp']} XP",
                    style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black54),
                    onPressed: () => db.completeQuest(doc.id, q['xp'] ?? 0,
                        q['gold'] ?? 0, q['statType'] ?? 'STR'),
                    child: Text("SLAY",
                        style: GoogleFonts.vt323(color: Colors.amber))),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddQuestDialog() {
    final ctrl = TextEditingController();
    bool isLoading = false;
    final navigator = Navigator.of(context); // Capture navigator

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                    backgroundColor: const Color(0xFF2D2D2D),
                    title: Text("NEW QUEST",
                        style: GoogleFonts.vt323(color: Colors.amber)),
                    content: isLoading
                        ? const SizedBox(
                            height: 50,
                            child: Center(child: CircularProgressIndicator()))
                        : TextField(
                            controller: ctrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                hintText: "What must be done?")),
                    actions: [
                      if (!isLoading)
                        TextButton(
                            onPressed: () async {
                              if (ctrl.text.isEmpty) return;
                              setState(() => isLoading = true);
                              final result = await ai.generateQuest(ctrl.text);
                              await db.addQuest(result);
                              navigator.pop();
                            },
                            child: Text("SUMMON",
                                style: GoogleFonts.vt323(color: Colors.amber)))
                    ])));
  }
}

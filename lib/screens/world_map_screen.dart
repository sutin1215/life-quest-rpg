import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    // HARDCODED GAME ZONES
    final List<Map<String, dynamic>> zones = [
      {
        "id": 1,
        "name": "Slime Forest",
        "boss": "Giant Slime",
        "reqLvl": 2,
        "img": "slime"
      },
      {
        "id": 2,
        "name": "Goblin Cave",
        "boss": "Goblin King",
        "reqLvl": 5,
        "img": "goblin"
      },
      {
        "id": 3,
        "name": "Haunted Keep",
        "boss": "Skeleton Lord",
        "reqLvl": 8,
        "img": "skeleton"
      },
      {
        "id": 4,
        "name": "Dragon Peak",
        "boss": "Red Dragon",
        "reqLvl": 12,
        "img": "dragon"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text("WORLD MAP",
            style: GoogleFonts.vt323(fontSize: 28, color: Colors.amber)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: db.getUserStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final user = snapshot.data!.data() as Map<String, dynamic>;
          final int currentZone = user['currentZone'] ?? 1;
          final int userLvl = user['level'] ?? 1;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              final int zoneId = zone['id'];

              // LOGIC: Is this zone locked, active, or conquered?
              bool isConquered = zoneId < currentZone;
              bool isLocked = zoneId > currentZone;
              bool isActive = zoneId == currentZone;

              return Card(
                color: isLocked
                    ? Colors.white10
                    : (isActive
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1)),
                margin: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "Zone Locked! Defeat previous boss first.")));
                      return;
                    }
                    if (isConquered) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("You have already conquered this land.")));
                      return;
                    }
                    // Show Boss Battle Dialog
                    _showBossDialog(context, zone, userLvl, db);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // ZONE ICON (Pixel Art)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isActive ? Colors.amber : Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black45,
                          ),
                          child: isLocked
                              ? const Icon(Icons.lock,
                                  color: Colors.grey, size: 40)
                              : Image.network(
                                  "https://api.dicebear.com/9.x/pixel-art/png?seed=${zone['boss']}",
                                  fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 20),

                        // ZONE INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(zone['name'],
                                  style: GoogleFonts.vt323(
                                      fontSize: 24, color: Colors.white)),
                              Text("Boss: ${zone['boss']}",
                                  style: GoogleFonts.vt323(
                                      fontSize: 18, color: Colors.grey)),
                              const SizedBox(height: 5),
                              if (isConquered)
                                Text("CONQUERED",
                                    style: GoogleFonts.vt323(
                                        fontSize: 18, color: Colors.green))
                              else if (isActive)
                                Text("RECOMMENDED LVL: ${zone['reqLvl']}",
                                    style: GoogleFonts.vt323(
                                        fontSize: 16, color: Colors.amber))
                              else
                                Text("LOCKED",
                                    style: GoogleFonts.vt323(
                                        fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showBossDialog(
      BuildContext context, Map zone, int userLvl, DatabaseService db) {
    bool canWin = userLvl >= zone['reqLvl'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text("BOSS BATTLE",
            style: GoogleFonts.vt323(fontSize: 28, color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
                "https://api.dicebear.com/9.x/pixel-art/png?seed=${zone['boss']}",
                height: 100),
            const SizedBox(height: 20),
            Text(zone['boss'],
                style: GoogleFonts.vt323(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              canWin
                  ? "You sense that you are strong enough to defeat this foe!"
                  : "DANGER! You are Level $userLvl. You need Level ${zone['reqLvl']} to survive.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FLEE"),
          ),
          if (canWin)
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await db.defeatBoss(zone['id']);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("VICTORY! The path forward opens...")));
              },
              child:
                  const Text("FIGHT!", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

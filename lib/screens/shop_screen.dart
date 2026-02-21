import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    final List<Map<String, dynamic>> items = [
      {
        "name": "Protein Shake",
        "cost": 50,
        "stat": "STR",
        "amt": 1,
        "desc": "+1 STR — Fuel the warrior within",
        "icon": Icons.fitness_center,
        "color": Colors.redAccent,
      },
      {
        "name": "Energy Drink",
        "cost": 50,
        "stat": "DEX",
        "amt": 1,
        "desc": "+1 DEX — Move like lightning",
        "icon": Icons.bolt,
        "color": Colors.greenAccent,
      },
      {
        "name": "Coding Manual",
        "cost": 50,
        "stat": "INT",
        "amt": 1,
        "desc": "+1 INT — Sharpen your mind",
        "icon": Icons.menu_book,
        "color": Colors.blueAccent,
      },
      {
        "name": "Golden Dumbbell",
        "cost": 200,
        "stat": "STR",
        "amt": 5,
        "desc": "+5 STR — For the truly mighty",
        "icon": Icons.fitness_center,
        "color": Colors.redAccent,
      },
      {
        "name": "Neural Link",
        "cost": 200,
        "stat": "INT",
        "amt": 5,
        "desc": "+5 INT — Unlock hidden knowledge",
        "icon": Icons.psychology,
        "color": Colors.blueAccent,
      },
      {
        "name": "Jet Boots",
        "cost": 200,
        "stat": "DEX",
        "amt": 5,
        "desc": "+5 DEX — Run faster than fate",
        "icon": Icons.directions_run,
        "color": Colors.greenAccent,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text("GOBLIN MARKET",
            style: GoogleFonts.vt323(fontSize: 28, color: Colors.amber)),
        actions: [_buildGoldCounter(db)],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildShopItem(context, db, item);
        },
      ),
    );
  }

  Widget _buildShopItem(
      BuildContext context, DatabaseService db, Map<String, dynamic> item) {
    final Color statColor = item['color'] as Color;

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // IMPROVEMENT: Use icon instead of DiceBear network image for shop
            // items, avoiding unnecessary network calls
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: statColor.withOpacity(0.15),
                border: Border.all(color: statColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item['icon'] as IconData, color: statColor, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] as String,
                      style:
                          GoogleFonts.vt323(fontSize: 22, color: Colors.white)),
                  Text(item['desc'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 14),
                    Text(" ${item['cost']} Gold",
                        style: GoogleFonts.vt323(
                            fontSize: 18, color: Colors.amber)),
                  ]),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _handlePurchase(context, db, item),
              child: Text("BUY",
                  style: GoogleFonts.vt323(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(
      BuildContext context, DatabaseService db, Map item) async {
    bool success = await db.buyItem(
        item['cost'] as int, item['stat'] as String, item['amt'] as int);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${item['name']} purchased! ${item['desc']}",
            style: GoogleFonts.vt323(fontSize: 18)),
        backgroundColor: Colors.green[800],
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Not enough Gold, Adventurer!",
            style: GoogleFonts.vt323(fontSize: 18)),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Widget _buildGoldCounter(DatabaseService db) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        // FIX: Handle error state
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.error_outline, color: Colors.redAccent),
          );
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        int gold = data?['gold'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
            child: Row(children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text("$gold G",
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.amber)),
            ]),
          ),
        );
      },
    );
  }
}

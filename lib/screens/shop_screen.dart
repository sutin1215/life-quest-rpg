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
        "desc": "+1 STR"
      },
      {
        "name": "Energy Drink",
        "cost": 50,
        "stat": "DEX",
        "amt": 1,
        "desc": "+1 DEX"
      },
      {
        "name": "Coding Manual",
        "cost": 50,
        "stat": "INT",
        "amt": 1,
        "desc": "+1 INT"
      },
      {
        "name": "Golden Dumbbell",
        "cost": 200,
        "stat": "STR",
        "amt": 5,
        "desc": "+5 STR"
      },
      {
        "name": "Neural Link",
        "cost": 200,
        "stat": "INT",
        "amt": 5,
        "desc": "+5 INT"
      },
      {
        "name": "Jet Boots",
        "cost": 200,
        "stat": "DEX",
        "amt": 5,
        "desc": "+5 DEX"
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
          return Card(
            color: Colors.white10,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        color: Colors.black45,
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8)),
                    child: Image.network(
                        "https://api.dicebear.com/9.x/pixel-art/png?seed=${item['name']}",
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'],
                            style: GoogleFonts.vt323(
                                fontSize: 22, color: Colors.white)),
                        Text(item['desc'],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text("${item['cost']} Gold",
                            style: GoogleFonts.vt323(
                                fontSize: 18, color: Colors.amber)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800]),
                    onPressed: () => _handlePurchase(context, db, item),
                    child: Text("BUY",
                        style: GoogleFonts.vt323(
                            fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePurchase(
      BuildContext context, DatabaseService db, Map item) async {
    bool success = await db.buyItem(item['cost'], item['stat'], item['amt']);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Purchased ${item['name']}!"),
          backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Not enough Gold!"), backgroundColor: Colors.red));
    }
  }

  Widget _buildGoldCounter(DatabaseService db) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        int gold = data?['gold'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(
              child: Text("$gold G",
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.amber))),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: StreamBuilder<DocumentSnapshot>(
        stream: db.getUserStats(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          // 2. Data Parsing
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String className = data['className'] ?? 'Unknown Hero';
          final String story =
              data['story'] ?? 'Your legend is yet to be written...';

          // GENERATE PIXEL AVATAR (DiceBear API)
          final String pixelAvatarUrl =
              "https://api.dicebear.com/9.x/pixel-art/png?seed=$className";

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("HERO AWAKENED",
                      style:
                          GoogleFonts.vt323(fontSize: 40, color: Colors.amber)),

                  const SizedBox(height: 30),

                  // AVATAR
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 4),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black54,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 20)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        pixelAvatarUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amber));
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person,
                                size: 80, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CLASS NAME
                  Text(className.toUpperCase(),
                      style:
                          GoogleFonts.vt323(fontSize: 32, color: Colors.white)),

                  const SizedBox(height: 10),

                  // STATS ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge(
                          "STR", data['str'] ?? 0, Colors.redAccent),
                      const SizedBox(width: 15),
                      _buildStatBadge(
                          "INT", data['int'] ?? 0, Colors.blueAccent),
                      const SizedBox(width: 15),
                      _buildStatBadge(
                          "DEX", data['dex'] ?? 0, Colors.greenAccent),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ORIGIN STORY
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ORIGIN STORY",
                                style: GoogleFonts.vt323(
                                    fontSize: 22, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              story,
                              style: GoogleFonts.vt323(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CONTINUE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()));
                      },
                      child: Text("BEGIN JOURNEY",
                          style: GoogleFonts.vt323(
                              fontSize: 24, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.vt323(color: color, fontSize: 18)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text("$value",
              style: GoogleFonts.vt323(fontSize: 22, color: Colors.white)),
        ),
      ],
    );
  }
}

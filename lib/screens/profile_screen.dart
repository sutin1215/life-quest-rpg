import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseService();
  final _ai = AiService();
  bool _isLoading = false;

  Future<void> _generateQuestsAndBegin(Map<String, dynamic> userData) async {
    setState(() => _isLoading = true);

    final bio = userData['bio'] ?? '';
    final mainQuest = userData['mainQuest'] ?? 'Achieve my goals';

    // FIX #7: addQuests now guards against duplicates internally
    final quests = await _ai.generateStarterQuests(bio, mainQuest);
    await _db.addQuests(quests);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.getUserStats(),
        builder: (context, snapshot) {
          // FIX: Handle error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text("Could not load hero data.",
                        style: GoogleFonts.vt323(
                            fontSize: 24, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Text("Check your connection and restart.",
                        style: GoogleFonts.vt323(
                            fontSize: 18, color: Colors.white54),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String className = data['className'] ?? 'Unknown Hero';
          final String story =
              data['story'] ?? 'Your legend is yet to be written...';
          final String pixelAvatarUrl =
              "https://api.dicebear.com/9.x/pixel-art/png?seed=$className";

          // Determine if this is the reveal screen (coming from character
          // creation) or the in-game profile tab.
          // If quests exist, we are in-game; show a profile card instead.
          final bool isRevealMode = data['currentZone'] == null ||
              data['currentZone'] == 1 &&
                  (data['level'] == null || data['level'] == 1);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    isRevealMode ? "HERO AWAKENED" : "HERO PROFILE",
                    style: GoogleFonts.vt323(fontSize: 40, color: Colors.amber),
                  ),
                  const SizedBox(height: 30),

                  // Avatar
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 4),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black54,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.amber.withAlpha(77), blurRadius: 20),
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

                  Text(className.toUpperCase(),
                      style:
                          GoogleFonts.vt323(fontSize: 32, color: Colors.white)),
                  const SizedBox(height: 4),

                  // IMPROVEMENT: Show level in profile
                  Text("Level ${data['level'] ?? 1}",
                      style:
                          GoogleFonts.vt323(fontSize: 22, color: Colors.amber)),
                  const SizedBox(height: 10),

                  // Stats row
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
                  const SizedBox(height: 20),

                  // XP Bar
                  _buildXpBar(data),
                  const SizedBox(height: 20),

                  // Main Quest reminder
                  if (data['mainQuest'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("MAIN QUEST",
                              style: GoogleFonts.vt323(
                                  fontSize: 18, color: Colors.amber)),
                          Text(data['mainQuest'],
                              style: GoogleFonts.vt323(
                                  fontSize: 18,
                                  color: Colors.white,
                                  height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Origin Story
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
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
                              fontSize: 20, color: Colors.white, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Only show "BEGIN JOURNEY" on the reveal screen
                  if (isRevealMode)
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amber))
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () => _generateQuestsAndBegin(data),
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

  Widget _buildXpBar(Map<String, dynamic> data) {
    final int lvl = data['level'] ?? 1;
    final int xp = data['xp'] ?? 0;
    final int xpNeeded = lvl * 100;
    final double progress = (xp / xpNeeded).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("XP",
              style: GoogleFonts.vt323(color: Colors.amber, fontSize: 16)),
          Text("$xp / $xpNeeded",
              style: GoogleFonts.vt323(color: Colors.white54, fontSize: 16)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.vt323(color: color, fontSize: 18)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
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

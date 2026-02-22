import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../theme/rpg_theme.dart';
import '../widgets/glowing_stat_badge.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  final _ai = AiService();
  bool _isLoading = false;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _shimmer = Tween(begin: 0.3, end: 1.0).animate(_shimmerCtrl);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateQuestsAndBegin(Map<String, dynamic> userData) async {
    setState(() => _isLoading = true);
    final bio = userData['bio'] ?? '';
    final mainQuest = userData['mainQuest'] ?? 'Achieve my goals';
    final quests = await _ai.generateStarterQuests(bio, mainQuest);
    await _db.addQuests(quests);
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RpgTheme.backgroundDark,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.getUserStats(),
        builder: (context, snapshot) {
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
                    Text('Could not load hero data.',
                        style: GoogleFonts.vt323(
                            fontSize: 24, color: Colors.redAccent)),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: CircularProgressIndicator(color: RpgTheme.goldPrimary));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String className = data['className'] ?? 'Unknown Hero';
          final String story =
              data['story'] ?? 'Your legend is yet to be written...';
          final String avatarUrl =
              'https://api.dicebear.com/9.x/pixel-art/png?seed=$className';

          final bool isRevealMode = data['currentZone'] == null ||
              (data['currentZone'] == 1 &&
                  (data['level'] == null || data['level'] == 1));

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Header
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) => Text(
                      isRevealMode ? 'HERO AWAKENED' : 'HERO PROFILE',
                      style: GoogleFonts.vt323(
                        fontSize: 38,
                        color: RpgTheme.goldPrimary,
                        shadows: [
                          Shadow(
                            blurRadius: 16,
                            color: RpgTheme.goldPrimary
                                .withValues(alpha: _shimmer.value),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avatar with decorative border
                  _buildAvatar(avatarUrl),

                  const SizedBox(height: 16),

                  // Class name
                  Text(className.toUpperCase(),
                      style: GoogleFonts.vt323(
                          fontSize: 32, color: RpgTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Level ${data['level'] ?? 1}',
                      style: GoogleFonts.vt323(
                          fontSize: 22, color: RpgTheme.goldPrimary)),

                  const SizedBox(height: 16),

                  // IMPROVEMENT #8: Glowing animated stat badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlowingStatBadge(
                          label: 'STR',
                          value: data['str'] ?? 0,
                          color: RpgTheme.strColor),
                      const SizedBox(width: 12),
                      GlowingStatBadge(
                          label: 'INT',
                          value: data['int'] ?? 0,
                          color: RpgTheme.intColor),
                      const SizedBox(width: 12),
                      GlowingStatBadge(
                          label: 'DEX',
                          value: data['dex'] ?? 0,
                          color: RpgTheme.dexColor),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // XP Bar
                  _buildXpBar(data),
                  const SizedBox(height: 20),

                  // Main Quest card
                  if (data['mainQuest'] != null) ...[
                    _buildInfoCard(
                      title: 'MAIN QUEST',
                      content: data['mainQuest'],
                      accentColor: RpgTheme.goldPrimary,
                      icon: Icons.flag,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Origin Story
                  _buildInfoCard(
                    title: 'ORIGIN STORY',
                    content: story,
                    accentColor: RpgTheme.textMuted,
                    icon: Icons.auto_stories,
                  ),

                  const SizedBox(height: 24),

                  if (isRevealMode)
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? Column(
                              children: [
                                const CircularProgressIndicator(
                                    color: RpgTheme.goldPrimary),
                                const SizedBox(height: 12),
                                Text('The Fate Weaver prepares your quests...',
                                    style: GoogleFonts.vt323(
                                        fontSize: 18,
                                        color: RpgTheme.textMuted)),
                              ],
                            )
                          : GestureDetector(
                              onTap: () => _generateQuestsAndBegin(data),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      RpgTheme.goldPrimary,
                                      Color(0xFFE8A838)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: RpgTheme.goldPrimary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 16,
                                        spreadRadius: 2),
                                  ],
                                ),
                                child: Text('BEGIN JOURNEY',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.vt323(
                                        fontSize: 26,
                                        color: Colors.black,
                                        letterSpacing: 2)),
                              ),
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

  Widget _buildAvatar(String url) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: RpgTheme.goldPrimary.withValues(alpha: _shimmer.value),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  RpgTheme.goldPrimary.withValues(alpha: _shimmer.value * 0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                  child:
                      CircularProgressIndicator(color: RpgTheme.goldPrimary));
            },
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person, size: 80, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildXpBar(Map<String, dynamic> data) {
    final int lvl = data['level'] ?? 1;
    final int xp = data['xp'] ?? 0;
    final int xpNeeded = lvl * 100;
    final double progress = (xp / xpNeeded).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: RpgTheme.parchmentDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('EXPERIENCE',
                style: GoogleFonts.vt323(
                    color: RpgTheme.goldPrimary, fontSize: 16)),
            Text('$xp / $xpNeeded XP',
                style:
                    GoogleFonts.vt323(color: RpgTheme.textMuted, fontSize: 15)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black45,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(RpgTheme.goldPrimary),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: RpgTheme.cardDecoration(borderColor: accentColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: accentColor, size: 16),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.vt323(
                    fontSize: 18, color: accentColor, letterSpacing: 1)),
          ]),
          const SizedBox(height: 8),
          Text(content,
              style: GoogleFonts.vt323(
                  fontSize: 19, color: RpgTheme.textPrimary, height: 1.4)),
        ],
      ),
    );
  }
}

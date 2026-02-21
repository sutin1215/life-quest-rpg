import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../theme/rpg_theme.dart';
import '../widgets/glowing_stat_badge.dart';
import '../widgets/floating_reward.dart';
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
      backgroundColor: RpgTheme.backgroundDark,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: RpgTheme.backgroundMid,
          border: Border(
              top: BorderSide(color: RpgTheme.goldPrimary.withOpacity(0.3))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: RpgTheme.goldPrimary,
          unselectedItemColor: RpgTheme.textMuted,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt), label: 'Quests'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hero'),
          ],
        ),
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
      backgroundColor: RpgTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: RpgTheme.backgroundMid,
        elevation: 0,
        title: Text('QUEST BOARD',
            style: GoogleFonts.vt323(
                fontSize: 30,
                color: RpgTheme.goldPrimary,
                shadows: [
                  const Shadow(blurRadius: 8, color: RpgTheme.goldPrimary)
                ])),
        actions: [_buildGoldCounter()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: RpgTheme.goldPrimary.withOpacity(0.3)),
        ),
      ),
      body: Column(
        children: [
          _buildAttributeBar(),
          Expanded(child: _buildQuestList()),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: RpgTheme.goldPrimary.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: RpgTheme.goldPrimary,
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showAddQuestDialog();
          },
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        ),
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
            const Icon(Icons.monetization_on,
                color: RpgTheme.goldLight, size: 18),
            const SizedBox(width: 4),
            Text('$gold',
                style:
                    GoogleFonts.vt323(fontSize: 24, color: RpgTheme.goldLight)),
          ]),
        );
      },
    );
  }

  Widget _buildAttributeBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: RpgTheme.cardDecoration(borderColor: Colors.redAccent),
            child: Text('Could not load stats.',
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
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          padding: const EdgeInsets.all(14),
          decoration: RpgTheme.parchmentDecoration(),
          child: Column(
            children: [
              // IMPROVEMENT #8/#12: Glowing animated stat badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GlowingStatBadge(
                      label: 'STR',
                      value: d['str'] ?? 0,
                      color: RpgTheme.strColor),
                  GlowingStatBadge(
                      label: 'INT',
                      value: d['int'] ?? 0,
                      color: RpgTheme.intColor),
                  GlowingStatBadge(
                      label: 'DEX',
                      value: d['dex'] ?? 0,
                      color: RpgTheme.dexColor),
                  // Level badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: RpgTheme.glowDecoration(RpgTheme.goldPrimary),
                    child: Column(
                      children: [
                        Text('LVL',
                            style: GoogleFonts.vt323(
                                color: RpgTheme.goldPrimary,
                                fontSize: 16,
                                letterSpacing: 1.5)),
                        Text('$lvl',
                            style: GoogleFonts.vt323(
                                color: Colors.white, fontSize: 26)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // XP bar
              Row(children: [
                Text('XP  ',
                    style: GoogleFonts.vt323(
                        color: RpgTheme.goldPrimary, fontSize: 14)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (xp / xpNeeded).clamp(0.0, 1.0),
                      backgroundColor: Colors.black45,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(RpgTheme.goldPrimary),
                      minHeight: 9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$xp / $xpNeeded',
                    style: GoogleFonts.vt323(
                        color: RpgTheme.textMuted, fontSize: 13)),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.getQuests(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Failed to load quests.\nCheck your connection.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.vt323(color: Colors.redAccent, fontSize: 20)),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 3,
            itemBuilder: (_, __) => _buildSkeletonCard(),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_fix_high,
                    size: 64, color: RpgTheme.goldPrimary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No quests active, Adventurer!',
                    style: GoogleFonts.vt323(
                        fontSize: 24, color: RpgTheme.textMuted)),
                const SizedBox(height: 8),
                Text('Tap + below to summon one.',
                    style: GoogleFonts.vt323(
                        fontSize: 18,
                        color: RpgTheme.textMuted.withOpacity(0.6))),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
          children: snap.data!.docs.map((doc) {
            final q = doc.data() as Map<String, dynamic>;
            return _buildQuestCard(doc, q);
          }).toList(),
        );
      },
    );
  }

  // IMPROVEMENT #14: Parchment scroll-style quest card
  Widget _buildQuestCard(QueryDocumentSnapshot doc, Map<String, dynamic> q) {
    Color statColor = RpgTheme.strColor;
    IconData statIcon = Icons.fitness_center;
    if (q['statType'] == 'INT') {
      statColor = RpgTheme.intColor;
      statIcon = Icons.menu_book;
    } else if (q['statType'] == 'DEX') {
      statColor = RpgTheme.dexColor;
      statIcon = Icons.bolt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1409), Color(0xFF130E04)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: statColor.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1),
        ],
      ),
      child: Stack(
        children: [
          // Wax seal icon top-right (IMPROVEMENT #14)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statColor.withOpacity(0.15),
                border: Border.all(color: statColor.withOpacity(0.5)),
              ),
              child: Icon(statIcon, color: statColor, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 50, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['title'] ?? 'Quest',
                    style: GoogleFonts.vt323(
                        fontSize: 22, color: RpgTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(q['description'] ?? '',
                    style: GoogleFonts.vt323(
                        fontSize: 16, color: RpgTheme.textMuted, height: 1.3)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _rewardChip(
                        Icons.star, '+${q['xp']} XP', Colors.lightBlueAccent),
                    const SizedBox(width: 8),
                    _rewardChip(
                        Icons.monetization_on, '+${q['gold']} G', Colors.amber),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statColor.withOpacity(0.5)),
                      ),
                      child: Text('+1 ${q['statType']}',
                          style: GoogleFonts.vt323(
                              fontSize: 14, color: statColor)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _confirmSlay(doc, q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              RpgTheme.bloodRed,
                              RpgTheme.bloodRed.withOpacity(0.7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                                color: RpgTheme.bloodRed.withOpacity(0.3),
                                blurRadius: 6),
                          ],
                        ),
                        child: Text('SLAY',
                            style: GoogleFonts.vt323(
                                fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardChip(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 3),
      Text(text, style: GoogleFonts.vt323(fontSize: 15, color: color)),
    ]);
  }

  void _confirmSlay(QueryDocumentSnapshot doc, Map<String, dynamic> q) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: RpgTheme.backgroundMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: RpgTheme.goldPrimary, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('COMPLETE QUEST?',
                style: GoogleFonts.vt323(
                    fontSize: 28, color: RpgTheme.goldPrimary)),
            const SizedBox(height: 8),
            Text(q['title'] ?? '',
                style: GoogleFonts.vt323(
                    fontSize: 22, color: RpgTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(
                'Reward: +${q['xp']} XP  |  +${q['gold']} G  |  +1 ${q['statType']}',
                style:
                    GoogleFonts.vt323(fontSize: 18, color: RpgTheme.textMuted)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: RpgTheme.textMuted),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL',
                      style: GoogleFonts.vt323(
                          fontSize: 18, color: RpgTheme.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpgTheme.goldPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    HapticFeedback.heavyImpact();
                    // IMPROVEMENT #4: Show floating XP reward
                    FloatingRewardOverlay.show(
                      context,
                      xp: q['xp'] ?? 0,
                      gold: q['gold'] ?? 0,
                    );
                    db.completeQuest(doc.id, q['xp'] ?? 0, q['gold'] ?? 0,
                        q['statType'] ?? 'STR');
                    _showLevelUpCheck();
                  },
                  child: Text('SLAY IT!',
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

  void _showLevelUpCheck() async {
    final before = await db.getUserStats().first;
    final beforeData = before.data() as Map<String, dynamic>?;
    final beforeLvl = beforeData?['level'] ?? 1;

    await Future.delayed(const Duration(milliseconds: 900));

    final after = await db.getUserStats().first;
    final afterData = after.data() as Map<String, dynamic>?;
    final afterLvl = afterData?['level'] ?? 1;

    if (afterLvl > beforeLvl && mounted) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: RpgTheme.backgroundMid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: RpgTheme.goldPrimary, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                const BoxShadow(
                    color: RpgTheme.goldPrimary,
                    blurRadius: 30,
                    spreadRadius: -5)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome,
                    color: RpgTheme.goldPrimary, size: 64),
                const SizedBox(height: 12),
                Text('LEVEL UP!',
                    style: GoogleFonts.vt323(
                        fontSize: 52,
                        color: RpgTheme.goldPrimary,
                        shadows: [
                          const Shadow(
                              blurRadius: 20, color: RpgTheme.goldPrimary)
                        ])),
                Text('You are now Level $afterLvl!',
                    style: GoogleFonts.vt323(
                        fontSize: 26, color: RpgTheme.textPrimary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: RpgTheme.goldPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12)),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('ONWARD!',
                      style:
                          GoogleFonts.vt323(fontSize: 22, color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: RpgTheme.parchmentDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 18,
              width: 200,
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  void _showAddQuestDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _AddQuestDialog(ctrl: ctrl, ai: ai, db: db),
    );
  }
}

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
      backgroundColor: RpgTheme.backgroundMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: RpgTheme.goldPrimary, width: 1),
      ),
      title: Text('NEW QUEST',
          style: GoogleFonts.vt323(color: RpgTheme.goldPrimary, fontSize: 30)),
      content: _isLoading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: RpgTheme.goldPrimary),
                    SizedBox(height: 8),
                    Text('The Guildmaster ponders...',
                        style: TextStyle(color: RpgTheme.textMuted)),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: widget.ctrl,
                  style: const TextStyle(color: RpgTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'What must be done?',
                    hintStyle: const TextStyle(color: RpgTheme.textMuted),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: RpgTheme.goldPrimary.withOpacity(0.3))),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: RpgTheme.goldPrimary)),
                    filled: true,
                    fillColor: RpgTheme.backgroundCard,
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
                setState(() => _error = 'Describe your quest first!');
                return;
              }
              setState(() {
                _isLoading = true;
                _error = null;
              });
              try {
                final result = await widget.ai.generateQuest(widget.ctrl.text);
                await widget.db.addQuest(result);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _error = 'Failed to generate quest. Try again.';
                  });
                }
              }
            },
            child: Text('SUMMON',
                style: GoogleFonts.vt323(
                    color: RpgTheme.goldPrimary, fontSize: 22)),
          ),
      ],
    );
  }
}

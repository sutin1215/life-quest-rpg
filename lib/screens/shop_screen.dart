import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../theme/rpg_theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    final List<Map<String, dynamic>> items = [
      {
        'name': 'Protein Shake',
        'cost': 50,
        'stat': 'STR',
        'amt': 1,
        'desc': '+1 STR — Fuel the warrior within',
        'icon': Icons.fitness_center,
        'color': RpgTheme.strColor,
        'flavour': 'Brewed from mountain giant milk',
      },
      {
        'name': 'Energy Drink',
        'cost': 50,
        'stat': 'DEX',
        'amt': 1,
        'desc': '+1 DEX — Move like lightning',
        'icon': Icons.bolt,
        'color': RpgTheme.dexColor,
        'flavour': 'Distilled from storm clouds',
      },
      {
        'name': 'Coding Manual',
        'cost': 50,
        'stat': 'INT',
        'amt': 1,
        'desc': '+1 INT — Sharpen your mind',
        'icon': Icons.menu_book,
        'color': RpgTheme.intColor,
        'flavour': 'Written by the Arcane Council',
      },
      {
        'name': 'Golden Dumbbell',
        'cost': 200,
        'stat': 'STR',
        'amt': 5,
        'desc': '+5 STR — For the truly mighty',
        'icon': Icons.fitness_center,
        'color': RpgTheme.strColor,
        'flavour': 'Forged in the fires of Mount Grim',
      },
      {
        'name': 'Neural Link',
        'cost': 200,
        'stat': 'INT',
        'amt': 5,
        'desc': '+5 INT — Unlock hidden knowledge',
        'icon': Icons.psychology,
        'color': RpgTheme.intColor,
        'flavour': 'Banned in three kingdoms',
      },
      {
        'name': 'Jet Boots',
        'cost': 200,
        'stat': 'DEX',
        'amt': 5,
        'desc': '+5 DEX — Run faster than fate',
        'icon': Icons.directions_run,
        'color': RpgTheme.dexColor,
        'flavour': 'Enchanted by the Wind Sorcerer',
      },
    ];

    return Scaffold(
      backgroundColor: RpgTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: RpgTheme.backgroundMid,
        elevation: 0,
        title: Text('GOBLIN MARKET',
            style: GoogleFonts.vt323(
                fontSize: 30,
                color: RpgTheme.goldPrimary,
                shadows: [
                  const Shadow(blurRadius: 8, color: RpgTheme.goldPrimary)
                ])),
        actions: [_buildGoldCounter(db)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: RpgTheme.goldPrimary.withValues(alpha: 0.3)),
        ),
      ),
      body: Column(
        children: [
          // Shop keeper banner
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: RpgTheme.parchmentDecoration(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: RpgTheme.goldPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: RpgTheme.goldPrimary.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.storefront,
                      color: RpgTheme.goldPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"Welcome, hero. Fine wares for the discerning adventurer."',
                    style: GoogleFonts.vt323(
                        fontSize: 16, color: RpgTheme.textMuted, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                // Section header for premium items
                if (index == 3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Container(
                              height: 1,
                              width: 40,
                              color:
                                  RpgTheme.goldPrimary.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Text('RARE ITEMS',
                              style: GoogleFonts.vt323(
                                  fontSize: 16,
                                  color: RpgTheme.goldPrimary,
                                  letterSpacing: 2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                                height: 1,
                                color: RpgTheme.goldPrimary
                                    .withValues(alpha: 0.4)),
                          ),
                        ]),
                      ),
                      _buildShopItem(context, db, items[index]),
                    ],
                  );
                }
                return _buildShopItem(context, db, items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(
      BuildContext context, DatabaseService db, Map<String, dynamic> item) {
    final Color statColor = item['color'] as Color;
    final bool isRare = (item['amt'] as int) > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RpgTheme.backgroundCard,
            isRare
                ? statColor.withValues(alpha: 0.08)
                : RpgTheme.backgroundCard,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statColor.withValues(alpha: isRare ? 0.5 : 0.25),
          width: isRare ? 1.5 : 1,
        ),
        boxShadow: isRare
            ? [
                BoxShadow(
                    color: statColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Item icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statColor.withValues(alpha: 0.12),
                border: Border.all(color: statColor.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(item['icon'] as IconData,
                        color: statColor, size: 30),
                  ),
                  if (isRare)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(Icons.auto_awesome,
                          color: RpgTheme.goldPrimary, size: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(item['name'] as String,
                        style: GoogleFonts.vt323(
                            fontSize: 20, color: RpgTheme.textPrimary)),
                    if (isRare) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: RpgTheme.goldPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color:
                                  RpgTheme.goldPrimary.withValues(alpha: 0.5)),
                        ),
                        child: Text('RARE',
                            style: GoogleFonts.vt323(
                                fontSize: 11, color: RpgTheme.goldPrimary)),
                      ),
                    ],
                  ]),
                  Text(item['flavour'] as String,
                      style: GoogleFonts.vt323(
                          fontSize: 14,
                          color: RpgTheme.textMuted,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: statColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(item['desc'] as String,
                          style: GoogleFonts.vt323(
                              fontSize: 14, color: statColor)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Buy button
            GestureDetector(
              onTap: () => _handlePurchase(context, db, item),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      RpgTheme.forestGreen,
                      RpgTheme.forestGreen.withValues(alpha: 0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                        color: RpgTheme.forestGreen.withValues(alpha: 0.3),
                        blurRadius: 6)
                  ],
                ),
                child: Column(
                  children: [
                    Text('BUY',
                        style: GoogleFonts.vt323(
                            fontSize: 18, color: Colors.white)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: RpgTheme.goldLight, size: 12),
                        Text(' ${item['cost']}',
                            style: GoogleFonts.vt323(
                                fontSize: 14, color: RpgTheme.goldLight)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(
      BuildContext context, DatabaseService db, Map item) async {
    HapticFeedback.mediumImpact();
    // Capture messenger before async gap to satisfy BuildContext lint
    final messenger = ScaffoldMessenger.of(context);
    bool success = await db.buyItem(
        item['cost'] as int, item['stat'] as String, item['amt'] as int);
    if (!context.mounted) return;
    if (success) {
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration:
              RpgTheme.cardDecoration(borderColor: RpgTheme.forestGreen),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Text('${item['name']} acquired! ${item['desc']}',
                style: GoogleFonts.vt323(
                    fontSize: 17, color: RpgTheme.textPrimary)),
          ]),
        ),
        duration: const Duration(seconds: 2),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: RpgTheme.cardDecoration(borderColor: RpgTheme.bloodRed),
          child: Row(children: [
            const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text('Not enough Gold, Adventurer!',
                style: GoogleFonts.vt323(
                    fontSize: 17, color: RpgTheme.textPrimary)),
          ]),
        ),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Widget _buildGoldCounter(DatabaseService db) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.getUserStats(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.error_outline, color: Colors.redAccent),
          );
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        int gold = data?['gold'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(children: [
            const Icon(Icons.monetization_on,
                color: RpgTheme.goldLight, size: 18),
            const SizedBox(width: 4),
            Text('$gold G',
                style:
                    GoogleFonts.vt323(fontSize: 24, color: RpgTheme.goldLight)),
          ]),
        );
      },
    );
  }
}

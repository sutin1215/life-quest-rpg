class Quest {
  final String id;
  final String title;
  final String description;
  final int xp;
  final int gold;
  final String statType; // STR, INT, or DEX
  final bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.xp,
    required this.gold,
    required this.statType,
    required this.isCompleted,
  });
}

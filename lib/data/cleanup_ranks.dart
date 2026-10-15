import 'dart:ui';

class CleanupRank {
  const CleanupRank(this.name, this.required, this.color);
  final String name;
  final int required;
  final Color color;
}

const cleanupRanks = [
  CleanupRank('Rookie', 0, Color(0xFF739580)),
  CleanupRank('Bronze', 100, Color(0xFFB7855E)),
  CleanupRank('Silver', 500, Color(0xFF8A9BA8)),
  CleanupRank('Gold', 1500, Color(0xFFD5A447)),
  CleanupRank('Platinum', 4000, Color(0xFF5CA7A1)),
  CleanupRank('Diamond', 10000, Color(0xFF7797D0)),
  CleanupRank('City Legend', 25000, Color(0xFFA481C1)),
];

int cleanupRankIndex(int collected) {
  for (var i = cleanupRanks.length - 1; i >= 0; i--) {
    if (collected >= cleanupRanks[i].required) return i;
  }
  return 0;
}

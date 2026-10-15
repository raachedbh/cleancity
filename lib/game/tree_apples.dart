import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';
import '../state/game_state.dart';
import 'navigation.dart';

class TreeApple {
  TreeApple(this.position, this.tree);
  final Offset position, tree;
  double age = 0;
  Offset get drawnPosition => age >= .7
      ? position
      : Offset.lerp(
          tree - const Offset(0, 100),
          position,
          (age / .7).clamp(0, 1),
        )!;
}

class TreeApples {
  TreeApples(this.state, this.navigation, this.random);
  final GameState state;
  final CityNavigation navigation;
  final Random random;
  final List<TreeApple> apples = [];
  final Map<Offset, double> _treeCooldowns = {};
  double untilAttempt = 4, boostSeconds = 0;
  double get speedMultiplier => boostSeconds > 0 ? 1.35 : 1;

  bool drop({bool preview = false}) {
    if (preview && !state.testMode || apples.length >= 6) return false;
    final area = districts[state.district];
    final trees =
        area.layout.trees
            .where(
              (t) =>
                  (preview || (_treeCooldowns[t.position] ?? 0) <= 0) &&
                  (t.position - state.position).distance < 850,
            )
            .toList()
          ..shuffle(random);
    for (final tree in trees) {
      for (var i = 0; i < 12; i++) {
        final angle = i * pi / 6;
        final p = tree.position + Offset(cos(angle), sin(angle)) * 58;
        if (!area.canStand(p, clearance: 20) ||
            apples.any((a) => (a.position - p).distance < 80) ||
            navigation.route(state.position, p).isEmpty) {
          continue;
        }
        apples.add(TreeApple(p, tree.position));
        _treeCooldowns[tree.position] = 60;
        return true;
      }
    }
    return false;
  }

  void update(double dt) {
    if (!dt.isFinite || dt <= 0 || !state.introduced) return;
    boostSeconds = max(0, boostSeconds - dt);
    for (final tree in _treeCooldowns.keys.toList()) {
      _treeCooldowns[tree] = max(0, _treeCooldowns[tree]! - dt);
    }
    for (final apple in apples) {
      apple.age += dt;
    }
    apples.removeWhere((a) => a.age >= 65);
    untilAttempt -= dt;
    if (untilAttempt <= 0) {
      untilAttempt = 4 + random.nextDouble() * 3;
      if (random.nextDouble() < .4) drop();
    }
  }

  bool eatAt(Offset player) {
    final apple = apples
        .where(
          (a) =>
              a.age >= .7 &&
              (a.position - player).distance <= 24 &&
              navigation.visible(player, a.position),
        )
        .firstOrNull;
    if (apple == null) return false;
    apples.remove(apple);
    boostSeconds = 5; // Refresh duration; never stack speed indefinitely.
    return true;
  }

  static void draw(Canvas c, TreeApple apple) {
    final p = apple.drawnPosition;
    c.drawOval(
      Rect.fromCenter(center: apple.position, width: 29, height: 12),
      Paint()..color = const Color(0x34385735),
    );
    c.save();
    c.translate(p.dx, p.dy - 8);
    c.drawCircle(Offset.zero, 19, Paint()..color = const Color(0x335CDC8A));
    final shape = Path()
      ..moveTo(0, -9)
      ..cubicTo(-17, -17, -19, 12, -5, 13)
      ..quadraticBezierTo(0, 10, 5, 13)
      ..cubicTo(19, 12, 17, -17, 0, -9)
      ..close();
    c.drawPath(shape, Paint()..color = const Color(0xFFE66048));
    c.drawPath(
      shape,
      Paint()
        ..color = const Color(0xFF773C2D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    c.drawLine(
      const Offset(0, -8),
      const Offset(2, -17),
      Paint()
        ..color = const Color(0xFF654835)
        ..strokeWidth = 3,
    );
    c.drawOval(
      const Rect.fromLTWH(2, -18, 10, 5),
      Paint()..color = const Color(0xFF489E5F),
    );
    c.drawOval(
      const Rect.fromLTWH(-9, -5, 4, 7),
      Paint()..color = const Color(0xFFFFC49A),
    );
    c.restore();
  }
}

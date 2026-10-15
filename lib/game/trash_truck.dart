import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';
import '../state/game_state.dart';
import 'navigation.dart';
import 'world_art.dart';

class TrashTruck {
  TrashTruck(this.position, this.route, this.heading, this.duration);
  Offset position;
  final List<Offset> route;
  final double duration;
  double heading, age = 0, fade = 0, untilDrop = 1;
  int drops = 0;
  static const radius = 64.0;
}

/// Picks an actual street and a travel direction. It never uses pedestrian
/// shortcuts through courtyards; every segment has clearance for the vehicle.
class TrashTruckEncounter {
  TrashTruckEncounter(this.state, this.navigation, this.random, this.onToss);
  final GameState state;
  final CityNavigation navigation;
  final Random random;
  final void Function(Litter, Offset) onToss;
  TrashTruck? actor;
  District get area => districts[state.district];
  Rect? get navigationObstacle => actor == null
      ? null
      : Rect.fromCircle(
          center: actor!.position,
          radius: TrashTruck.radius + 14,
        );

  bool spawn({bool preview = false, Iterable<Offset> pedestrians = const []}) {
    if (actor != null || !state.introduced || preview && !state.testMode) {
      return false;
    }
    if (state.cleanupTarget -
            state.removed[state.district].length -
            state.streetLitter[state.district].length <
        5) {
      return false;
    }
    final candidates = <({Offset position, List<Offset> route})>[];
    for (final street in area.layout.streets.where((s) => s.width >= 90)) {
      final points = street.points;
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1], b = points[i], delta = b - a;
        final length = delta.distance;
        if (length < 1) continue;
        final steps = max(1, (length / 160).ceil());
        for (var step = 0; step < steps; step++) {
          final p = Offset.lerp(a, b, (step + .5) / steps)!;
          final distance = (p - state.position).distance;
          if (distance < 240 || distance > 900) continue;
          final side =
              Offset(-delta.dy, delta.dx) /
              length *
              min(22.0, street.width / 2 - 40);
          for (final direction in [-1, 1]) {
            final spawn = p + side * direction.toDouble();
            final route = direction == 1
                ? [p, ...points.skip(i)]
                : [p, ...points.take(i).toList().reversed];
            if ((points.first - points.last).distance < 5) {
              route.addAll(
                direction == 1
                    ? points.skip(1).take(i - 1)
                    : points.skip(i).toList().reversed.skip(1),
              );
            }
            candidates.add((position: spawn, route: route));
          }
        }
      }
    }
    candidates.shuffle(random);
    for (final candidate in candidates.take(60)) {
      if (!area.canStand(
            candidate.position,
            clearance: TrashTruck.radius + 2,
          ) ||
          pedestrians.any((p) => (p - candidate.position).distance < 85) ||
          navigation.route(state.position, candidate.position).isEmpty) {
        continue;
      }
      final path = <Offset>[];
      var previous = candidate.position, length = 0.0;
      for (final p in candidate.route) {
        final distance = (p - previous).distance;
        final steps = max(1, (distance / 32).ceil());
        if (!List.generate(
          steps + 1,
          (i) => Offset.lerp(previous, p, i / steps)!,
        ).every(
          (point) => area.canStand(point, clearance: TrashTruck.radius + 2),
        )) {
          break;
        }
        path.add(p);
        length += distance;
        previous = p;
      }
      if (length < 650) continue;
      final heading = path.length > 1
          ? path[1] - path[0]
          : path.first - candidate.position;
      actor = TrashTruck(
        candidate.position,
        path,
        atan2(heading.dy, heading.dx),
        28 + random.nextDouble() * 12,
      );
      state.truckWaitMs = (300 + random.nextDouble() * 120) * 1000;
      state.alertCity('Trash truck nearby');
      unawaited(state.save());
      return true;
    }
    return false;
  }

  bool blocksMovement(Offset from, Offset to, {double clearance = 12}) {
    final truck = actor;
    if (truck == null) return false;
    final radius = TrashTruck.radius + clearance;
    // Let an actor already touching the boundary move away from it.
    if ((from - truck.position).distance < radius &&
        (to - truck.position).distance > (from - truck.position).distance) {
      return false;
    }
    final delta = to - from;
    final t = delta.distanceSquared == 0
        ? 0.0
        : (((truck.position.dx - from.dx) * delta.dx +
                      (truck.position.dy - from.dy) * delta.dy) /
                  delta.distanceSquared)
              .clamp(0.0, 1.0);
    return (from + delta * t - truck.position).distance < radius;
  }

  void update(
    double dt, {
    Iterable<Offset> pedestrians = const [],
    bool allowSpawn = true,
  }) {
    if (!dt.isFinite || dt <= 0 || !state.introduced) return;
    final t = actor;
    if (t == null) {
      if (!allowSpawn) return;
      state.truckWaitMs = max(0, state.truckWaitMs - dt * 1000);
      if (state.truckWaitMs <= 0 && !spawn(pedestrians: pedestrians)) {
        state.truckWaitMs = 45000;
      }
      return;
    }
    t.age += dt;
    if (t.fade > 0) {
      t.fade += dt;
      if (t.fade >= 1) actor = null;
      return;
    }
    if (t.age >= t.duration || t.route.isEmpty) {
      t.fade = .01;
      return;
    }
    final delta = t.route.first - t.position;
    if (delta.distance < 3) {
      t.route.removeAt(0);
      return;
    }
    final next =
        t.position + delta / delta.distance * min(delta.distance, dt * 95);
    // Yield to the player and pedestrians. Never push or drive through them.
    if ((next - state.position).distance < TrashTruck.radius + 18 ||
        pedestrians.any((p) => (p - next).distance < TrashTruck.radius + 16)) {
      return;
    }
    if (!area.canStand(next, clearance: TrashTruck.radius)) {
      t.fade = .01;
      return;
    }
    t.position = next;
    final angle = atan2(delta.dy, delta.dx) - t.heading;
    t.heading += atan2(sin(angle), cos(angle)) * min(1, dt * 9);
    t.untilDrop -= dt;
    if (t.untilDrop <= 0 && t.drops < 20) {
      t.untilDrop = 1.1 + random.nextDouble() * .5;
      final behind = t.position - delta / delta.distance * 83;
      final item = state.dropLitter(behind, fromTruck: true);
      if (item != null) {
        t.drops++;
        onToss(
          item,
          t.position - delta / delta.distance * 47 - const Offset(0, 28),
        );
      }
    }
  }

  static void draw(Canvas canvas, TrashTruck t) {
    final alpha = t.fade > 0
        ? (1 - t.fade).clamp(0.0, 1.0)
        : min(1.0, t.age * 2);
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: t.position + const Offset(8, 9),
        width: 128,
        height: 70,
      ),
      Paint()..color = const Color(0x38303E35),
    );
    canvas.save();
    canvas.translate(t.position.dx, t.position.dy);
    canvas.rotate(t.heading);
    void box(Rect r, Color color, {double radius = 4}) {
      final shape = RRect.fromRectAndRadius(r, Radius.circular(radius));
      canvas.drawRRect(shape, Paint()..color = color);
      canvas.drawRRect(
        shape,
        Paint()
          ..color = const Color(0xFF263E39)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (final x in [-30.0, 30.0]) {
      for (final y in [-32.0, 24.0]) {
        box(Rect.fromLTWH(x - 10, y, 20, 11), const Color(0xFF293238));
        canvas.drawLine(
          Offset(x - 5, y + 4),
          Offset(x + 5, y + 4),
          Paint()
            ..color = const Color(0xFF899395)
            ..strokeWidth = 2,
        );
      }
    }
    box(const Rect.fromLTWH(-53, -28, 104, 56), const Color(0xFF2E6552));
    box(const Rect.fromLTWH(-49, -32, 70, 53), const Color(0xFF65A477));
    box(
      const Rect.fromLTWH(22, -29, 28, 54),
      const Color(0xFFF0BA56),
      radius: 8,
    );
    box(
      const Rect.fromLTWH(36, -22, 10, 38),
      const Color(0xFF91CBD0),
      radius: 3,
    );
    canvas.drawLine(
      const Offset(-46, 13),
      const Offset(18, 13),
      Paint()
        ..color = const Color(0xFFAFD0A5)
        ..strokeWidth = 4,
    );
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(-15, -6);
      canvas.rotate(i * pi * 2 / 3);
      canvas.drawPath(
        Path()
          ..moveTo(-4, -12)
          ..lineTo(9, -12)
          ..lineTo(9, -17)
          ..lineTo(17, -9)
          ..lineTo(8, -3)
          ..lineTo(9, -8)
          ..lineTo(-4, -8)
          ..close(),
        Paint()..color = const Color(0xFFF4F1D8),
      );
      canvas.restore();
    }
    for (final y in [-21.0, 16.0]) {
      box(Rect.fromLTWH(48, y, 5, 7), const Color(0xFFFFF0AD), radius: 1);
      box(Rect.fromLTWH(-55, y, 5, 7), const Color(0xFFC95542), radius: 1);
    }
    canvas.drawCircle(
      const Offset(27, -3),
      4,
      Paint()
        ..color = sin(t.age * 8) > 0
            ? const Color(0xFFFFDE72)
            : const Color(0xFFDD9545),
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: t.position - const Offset(0, 63),
          width: 120,
          height: 27,
        ),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xE6284C3E),
    );
    WorldArt.label(
      canvas,
      'Trash Truck',
      t.position - const Offset(0, 76),
      17,
      const Color(0xFFF5F1DC),
    );
    canvas.restore();
  }
}

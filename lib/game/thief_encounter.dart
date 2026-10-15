import '../data/album.dart';
import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';
import '../state/game_state.dart';
import 'navigation.dart';
import 'walk_cycle.dart';

class ThiefActor {
  ThiefActor(this.position);
  Offset position;
  final route = <Offset>[];
  final gait = WalkCycle();
  int facing = 0, drops = 0;
  bool running = false, caught = false;
  double age = 0, runTime = 0, escapeAfter = 24, fade = 0;
  double untilDrop = .3, untilRoute = 0, gesture = 0;
}

/// A short, optional street encounter. Menus pause it with the world.
/// Leaving a city ends the encounter; its saved cooldown and litter remain.
class ThiefEncounter {
  ThiefEncounter(this.state, this.navigation, this.random, this.onToss);
  final GameState state;
  final CityNavigation navigation;
  final Random random;
  final void Function(Litter item, Offset from) onToss;
  ThiefActor? actor;
  District get area => districts[state.district];

  bool spawn({bool preview = false}) {
    if (actor != null) return false;
    if (preview && !state.testMode) return false;
    if (!preview &&
        state.cleanupTarget -
                state.removed[state.district].length -
                state.streetLitter[state.district].length <
            5) {
      return false;
    }
    final candidates = <Offset>[];
    for (var i = 0; i < 16; i++) {
      final angle = i * pi / 8;
      final distance = preview ? 310.0 : 450 + random.nextDouble() * 500;
      final p = navigation.nearestWalkable(
        state.position + Offset(cos(angle), sin(angle)) * distance,
      );
      if ((p - state.position).distance < 280 ||
          area.stations.any((s) => (s - p).distance < 170)) {
        continue;
      }
      if (navigation.route(state.position, p).isNotEmpty) candidates.add(p);
    }
    if (candidates.isEmpty) return false;
    actor = ThiefActor(candidates[random.nextInt(candidates.length)]);
    state.scheduleNextThief(240 + random.nextDouble() * 120);
    state.alertCity('Thief in the city');
    return true;
  }

  void update(double dt, {bool allowSpawn = true}) {
    if (!dt.isFinite || dt <= 0 || !state.introduced) return;
    final t = actor;
    if (t == null) {
      if (!allowSpawn) return;
      state.thiefWaitMs = max(0, state.thiefWaitMs - dt * 1000);
      if (state.thiefWaitMs <= 0 && !spawn()) state.scheduleNextThief(45);
      return;
    }
    t.age += dt;
    t.gesture = max(0, t.gesture - dt);
    if (t.fade > 0) {
      t.fade += dt;
      if (t.fade >= 1.2) {
        actor = null;
        if (!t.caught) state.events.add('The thief got away');
      }
      return;
    }
    if (!t.running) {
      if ((state.position - t.position).distance < 260 &&
          navigation.visible(state.position, t.position)) {
        t.running = true;
        t.escapeAfter = 18 + random.nextDouble() * 14;
        state.events.add('Follow the litter trail!');
      } else {
        if (t.age > 90) t.fade = .01;
        return;
      }
    }
    if (t.running &&
        t.runTime >= .6 &&
        (state.position - t.position).distance <= 44 &&
        navigation.visible(state.position, t.position)) {
      t.caught = true;
      t.fade = .01;
      t.gait.stop();
      final loot = <({ValuableKind kind, Offset position})>[];
      final count = 2 + random.nextInt(3);
      for (var i = 0; i < count; i++) {
        final angle = i * pi * 2 / count + random.nextDouble() * .4;
        final p = navigation.nearestWalkable(
          t.position + Offset(cos(angle), sin(angle)) * 56,
        );
        final location =
            navigation.visible(t.position, p) && (p - t.position).distance < 130
            ? p
            : t.position;
        loot.add((
          kind: ValuableKind.values[random.nextInt(ValuableKind.values.length)],
          position: location,
        ));
      }
      state.rewardCaughtThief(valuables: loot);
      return;
    }
    t.runTime += dt;
    if (t.runTime >= t.escapeAfter) {
      t.fade = .01;
      return;
    }
    t.untilRoute -= dt;
    if (t.route.isEmpty || t.untilRoute <= 0) _chooseRoute(t);
    if (t.route.isNotEmpty) {
      final delta = t.route.first - t.position;
      if (delta.distance < 4) {
        t.route.removeAt(0);
        t.gait.update(0, dt);
      } else {
        final next =
            t.position + delta / delta.distance * min(delta.distance, dt * 185);
        if (area.canStand(next) && navigation.visible(t.position, next)) {
          t.gait.update((next - t.position).distance, dt, strideLength: 80);
          t.position = next;
          t.facing = facingFor(delta, t.facing);
        } else {
          t.route.clear();
        }
      }
    }
    t.untilDrop -= dt;
    if (t.untilDrop <= 0 && t.drops < 16) {
      t.untilDrop = 1.1 + random.nextDouble() * .7;
      final item = state.dropLitter(t.position, fromThief: true);
      if (item != null) {
        t.drops++;
        t.gesture = .5;
        onToss(item, t.position + const Offset(12, -52));
      }
    }
  }

  void _chooseRoute(ThiefActor t) {
    t.untilRoute = 2;
    final candidates = <Offset>[];
    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6 + random.nextDouble() * .3;
      final p = navigation.nearestWalkable(
        t.position +
            Offset(cos(angle), sin(angle)) * (300 + random.nextDouble() * 250),
      );
      if ((p - t.position).distance > 140) candidates.add(p);
    }
    candidates.sort(
      (a, b) => (b - state.position).distanceSquared.compareTo(
        (a - state.position).distanceSquared,
      ),
    );
    for (final p in candidates) {
      final route = navigation.route(t.position, p);
      if (route.isEmpty) continue;
      t.route
        ..clear()
        ..addAll(route);
      return;
    }
  }
}

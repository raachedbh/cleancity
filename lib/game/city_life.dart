import 'walk_cycle.dart';
import 'thief_encounter.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/catalog.dart';
import '../state/game_state.dart';
import 'navigation.dart';
import 'people_art.dart';
import 'trash_truck.dart';
import 'tree_apples.dart';

class Pedestrian {
  Pedestrian(this.id, this.position, this.wait);
  final int id;
  Offset position;
  final List<Offset> route = [];
  int nextNeighborhood = 0;
  final List<Offset> recentStops = [];
  double wait, animation = 0, gesture = 0;
  int facing = 0;
  bool walking = false;
  double speed = 0;
  double untilLitter = 0;
  final gait = WalkCycle();
}

class LitterToss {
  LitterToss(this.item, this.from);
  final Litter item;
  final Offset from;
  double elapsed = 0;
  double get progress => (elapsed / .65).clamp(0, 1);
  Offset get position =>
      Offset.lerp(from, item.position, progress)! -
      Offset(0, sin(progress * pi) * 27);
}

/// Active play only: no offline litter generation; each round has a finite quota.
class CityLife {
  CityLife(this.state, this.navigation)
    : area = districts[state.district],
      random = Random(
        830 + state.district * 29 + state.cycles[state.district],
      ) {
    thief = ThiefEncounter(state, navigation, random, (item, from) {
      tosses.add(LitterToss(item, from));
    });
    truck = TrashTruckEncounter(
      state,
      navigation,
      Random(571 + state.district * 47 + state.cycles[state.district]),
      (item, from) => tosses.add(LitterToss(item, from)),
    );
    apples = TreeApples(
      state,
      navigation,
      Random(271 + state.district * 61 + state.cycles[state.district]),
    );
    groundRandom = Random(
      921 + state.district * 53 + state.cycles[state.district],
    );
    stops = area.pedestrianStops
        .where((p) => area.canStand(p, clearance: 18))
        .toList();
    neighborhoods = List.generate(
      4,
      (zone) => stops.where((p) => _neighborhood(p) == zone).toList(),
    );
    final count = min(24, min(stops.length, area.blocks.length * 2));
    // Farthest-point placement keeps every part of the city populated at load.
    final remaining = [...stops];
    var spawn = remaining.reduce(
      (a, b) =>
          (a - area.start).distanceSquared < (b - area.start).distanceSquared
          ? a
          : b,
    );
    final separation = <Offset, double>{
      for (final stop in remaining) stop: double.infinity,
    };
    for (var i = 0; i < count; i++) {
      people.add(
        Pedestrian(i, spawn, random.nextDouble() * 3)
          ..nextNeighborhood = (_neighborhood(spawn) + (i.isEven ? 1 : 3)) % 4,
      );
      remaining.remove(spawn);
      for (final stop in remaining) {
        separation[stop] = min(
          separation[stop]!,
          (stop - spawn).distanceSquared,
        );
      }
      if (remaining.isNotEmpty) {
        spawn = remaining.reduce(
          (a, b) => separation[a]! > separation[b]! ? a : b,
        );
      }
    }
  }
  final GameState state;
  final CityNavigation navigation;
  final District area;
  final Random random;
  late final List<Offset> stops;
  late final List<List<Offset>> neighborhoods;
  final List<Pedestrian> people = [];
  final List<LitterToss> tosses = [];
  late final ThiefEncounter thief;
  late final TrashTruckEncounter truck;
  late final TreeApples apples;
  late final Random groundRandom;
  double _untilDrop = 7;
  double _untilGround = 18;
  bool inFlight(String id) => tosses.any((t) => t.item.id == id);

  int _neighborhood(Offset p) {
    final right = p.dx >= area.worldSize.width / 2;
    final bottom = p.dy >= area.worldSize.height / 2;
    return bottom ? (right ? 2 : 3) : (right ? 1 : 0);
  }

  void _chooseDestination(Pedestrian p) {
    // Tour all four neighborhoods, in both directions, instead of choosing
    // repeatedly from the four closest corners of the same block.
    final minimumTrip = min(area.worldSize.width, area.worldSize.height) * .2;
    for (var attempt = 0; attempt < 4; attempt++) {
      final zone = p.nextNeighborhood;
      p.nextNeighborhood = (zone + (p.id.isEven ? 1 : 3)) % 4;
      final candidates =
          neighborhoods[zone]
              .where(
                (s) =>
                    !p.recentStops.contains(s) &&
                    (s - p.position).distance > minimumTrip,
              )
              .toList()
            ..shuffle(random);
      for (final destination in candidates.take(3)) {
        final route = navigation.route(
          p.position,
          destination,
          temporaryObstacle: truck.navigationObstacle,
        );
        if (route.isEmpty) continue;
        p.route.addAll(route);
        p.recentStops.add(destination);
        if (p.recentStops.length > 4) p.recentStops.removeAt(0);
        return;
      }
    }
  }

  void update(double dt) {
    truck.update(
      dt,
      pedestrians: people.map((p) => p.position),
      allowSpawn: thief.actor == null,
    );
    apples.update(dt);
    thief.update(dt, allowSpawn: truck.actor == null);
    _untilGround -= dt;
    if (state.introduced && _untilGround <= 0) {
      _untilGround = 18 + groundRandom.nextDouble() * 8;
      spawnGroundLitter();
    }
    for (final toss in tosses) {
      toss.elapsed += dt;
    }
    tosses.removeWhere((t) => t.progress >= 1);
    for (final p in people) {
      p.animation += dt;
      p.gesture = max(0, p.gesture - dt);
      p.untilLitter = max(0, p.untilLitter - dt);
      p.wait -= dt;
      p.walking = false;
      if (p.wait > 0 || p.gesture > 0) {
        p.speed = 0;
        p.gait.update(0, dt);
        continue;
      }
      if (p.route.isEmpty) {
        _chooseDestination(p);
        if (p.route.isEmpty) {
          p.wait = 1;
          continue;
        }
      }
      final delta = p.route.first - p.position;
      if (delta.distance < 3) {
        p.gait.update(0, dt);
        p.route.removeAt(0);
        if (p.route.isEmpty) p.wait = .7 + random.nextDouble() * 2.4;
        continue;
      }
      final cruiseSpeed = 55 + p.id % 4 * 7;
      final approach = p.route.length == 1
          ? (delta.distance / 24).clamp(.18, 1.0)
          : 1.0;
      p.speed += (cruiseSpeed * approach - p.speed) * (1 - exp(-dt * 8));
      final next =
          p.position +
          delta / delta.distance * min(delta.distance, p.speed * dt);
      if (!area.canStand(next)) {
        p.route.clear();
        p.wait = .5;
        continue;
      }
      if (truck.blocksMovement(p.position, next)) {
        final detour = navigation.route(
          p.position,
          p.route.last,
          temporaryObstacle: truck.navigationObstacle,
        );
        p.route
          ..clear()
          ..addAll(detour);
        p.wait = .3;
        p.speed = 0;
        p.gait.update(0, dt);
        continue;
      }
      final traveled = (next - p.position).distance;
      p.position = next;
      p.walking = traveled > .02;
      p.gait.update(traveled, dt, strideLength: 65);
      p.facing = facingFor(delta, p.facing);
    }
    _untilDrop -= dt;
    if (!state.introduced || _untilDrop > 0) return;
    _untilDrop = 7 + random.nextDouble() * 3;
    // Spread occasional throws across the city instead of surrounding the player.
    final candidates =
        people
            .where(
              (p) =>
                  p.untilLitter <= 0 &&
                  p.gesture == 0 &&
                  (p.position - state.position).distance > 80,
            )
            .toList()
          ..shuffle(random);
    for (final p in candidates) {
      final landing =
          p.position +
          Offset(
            (p.id.isEven ? 1 : -1) * (24 + random.nextDouble() * 18),
            12 + random.nextDouble() * 12,
          );
      if (!navigation.visible(p.position, landing)) continue;
      if (state.streetLitter[state.district]
              .where((i) => (i.position - landing).distance < 180)
              .length >=
          3) {
        continue;
      }
      final item = state.dropLitter(landing);
      if (item == null) continue;
      p.facing = landing.dx >= p.position.dx ? 1 : 3;
      p.gesture = .85;
      p.untilLitter = 45 + random.nextDouble() * 30;
      tosses.add(
        LitterToss(
          item,
          PeopleArt.throwingHand(p.id, p.position, p.facing, p.gait),
        ),
      );
      break;
    }
  }

  /// Replenish reachable ground near the player during active play only.
  /// The same saved capacity/quota rules apply as to pedestrian throws.
  int spawnGroundLitter() {
    if (!state.introduced || state.bag.length >= state.capacity) return 0;
    final active = state.streetLitter[state.district];
    if (active.length >= area.streetLitterLimit ||
        active.length + state.removed[state.district].length >=
            state.cleanupTarget) {
      return 0;
    }
    var added = 0;
    for (var attempt = 0; attempt < 36 && added < 1; attempt++) {
      final angle = groundRandom.nextDouble() * pi * 2;
      final distance = 180 + groundRandom.nextDouble() * 440;
      final p = state.position + Offset(cos(angle), sin(angle)) * distance;
      if (!area.canStand(p, clearance: 20) ||
          truck.blocksMovement(p, p) ||
          state.streetLitter[state.district]
                  .where((i) => (i.position - p).distance < 200)
                  .length >=
              3 ||
          navigation.route(state.position, p).isEmpty) {
        continue;
      }
      if (state.dropLitter(p) != null) added++;
    }
    return added;
  }

  static void drawPerson(Canvas c, Pedestrian p, bool night) => PeopleArt.draw(
    c,
    id: p.id,
    position: p.position,
    facing: p.facing,
    walking: p.walking,
    time: p.animation,
    throwing: p.gesture > 0,
    night: night,
    gait: p.gait,
  );
}

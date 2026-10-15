import 'dart:ui';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'buildings and full silhouettes stay clear of every road and pavement',
    () {
      for (final d in districts) {
        final l = d.layout;
        expect(
          l.buildings.length,
          greaterThanOrEqualTo([8, 10, 10, 14, 20, 16][d.id]),
          reason: d.name,
        );
        expect(
          l.buildings.values.map((b) => b.kind).toSet().length,
          greaterThanOrEqualTo(4),
          reason: d.name,
        );
        for (final e in l.buildingEnvelopes.entries) {
          for (final street in l.streets) {
            final reserved = e.value.inflate(street.width / 2 + 26);
            for (var i = 1; i < street.points.length; i++) {
              expect(
                segmentHitsRect(
                  street.points[i - 1],
                  street.points[i],
                  reserved,
                ),
                isFalse,
                reason: '${d.name} building ${e.key} intersects road',
              );
            }
          }
          for (final other in l.buildingEnvelopes.entries) {
            if (e.key >= other.key) continue;
            expect(
              e.value.overlaps(other.value),
              isFalse,
              reason: '${d.name} building silhouettes overlap',
            );
          }
        }
        final oldSize = Size(d.columns * 520 + 260, d.rows * 420 + 280);
        expect(
          d.worldSize.width * d.worldSize.height,
          greaterThan(oldSize.width * oldSize.height * 2),
        );
      }
    },
  );

  test('district boundaries reject corners and taps route inside the city', () {
    for (final d in districts) {
      final nav = CityNavigation(d);
      for (final p in [
        d.walkable.topLeft,
        d.walkable.bottomRight,
        d.walkable.bottomLeft,
      ]) {
        expect(d.canStand(p), isFalse);
        final destination = nav.nearestWalkable(p);
        expect(d.canStand(destination), isTrue, reason: d.name);
        final route = nav.route(d.start, p);
        expect(route, isNotEmpty, reason: d.name);
        var from = d.start;
        for (final to in route) {
          for (var t = 0.0; t <= 1; t += .04) {
            expect(
              d.canStand(Offset.lerp(from, to, t)!),
              isTrue,
              reason: d.name,
            );
          }
          from = to;
        }
      }
    }
  });

  test(
    'every city spawn, review location and recycling approach is accessible',
    () {
      for (final d in districts) {
        final nav = CityNavigation(d);
        expect(d.canStand(d.start), isTrue, reason: d.name);
        for (final p in [
          d.layout.reviewPoint,
          ...d.stations.map((p) => p + const Offset(0, 65)),
        ]) {
          expect(d.canStand(p), isTrue, reason: '${d.name}: $p');
          var from = d.start;
          final route = nav.route(from, p);
          expect(route, isNotEmpty, reason: d.name);
          for (final to in route) {
            expect(nav.visible(from, to), isTrue, reason: d.name);
            from = to;
          }
          expect((from - p).distance, lessThan(.1));
        }
      }
    },
  );

  test(
    'Kyoto water blocks straight movement and routes cross the real bridges',
    () {
      final d = districts[4], nav = CityNavigation(d);
      final water = d.layout.canal!;
      for (var i = 1; i < d.layout.bridges.length; i++) {
        final y = (d.layout.bridges[i - 1] + d.layout.bridges[i]) / 2;
        expect(d.canStand(Offset(water.center.dx, y)), isFalse);
        final a = Offset(water.left - 55, y), b = Offset(water.right + 55, y);
        expect(nav.visible(a, b), isFalse);
        final route = nav.route(a, b);
        expect(route, isNotEmpty);
        var from = a;
        for (final to in route) {
          for (var t = 0.0; t <= 1; t += .025) {
            expect(d.canStand(Offset.lerp(from, to, t)!), isTrue);
          }
          from = to;
        }
        expect(from, b);
      }
      for (final y in d.layout.bridges) {
        expect(
          nav.visible(Offset(water.left - 35, y), Offset(water.right + 35, y)),
          isTrue,
        );
      }
    },
  );

  test(
    'v7 geometry migration preserves progress, IDs, materials and jobs across water and buildings',
    () async {
      final store = MemoryStore(), time = DateTime.utc(2026, 10, 10, 12);
      final old = GameState(MemoryStore(), now: () => time)
        ..coins = 18400
        ..gems = 43
        ..xp = 3300;
      old.unlockedMaps.addAll([1, 2, 3, 4]);
      old.ownedOutfits.addAll([1, 2, 6]);
      old.collect(old.streetLitter[0].first);
      old.position = districts[0].station + const Offset(0, 65);
      old.startRecycling();
      old.collect(old.streetLitter[0].first);
      old.travel(4);
      final data = old.toJson()
        ..['version'] = 7
        ..['position'] = [1440, 755];
      final streets = data['streetLitter'] as List;
      for (var city = 0; city < streets.length; city++) {
        final entries = streets[city] as List;
        final blocked = city == 4
            ? const Offset(1440, 755)
            : districts[city].blocks.first.center;
        final item = entries.first as List;
        item[1] = blocked.dx;
        item[2] = blocked.dy;
      }
      store.value = jsonEncode(data);
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.coins, old.coins);
      expect(loaded.gems, old.gems);
      expect(loaded.xp, old.xp);
      expect(loaded.bag, old.bag);
      expect(loaded.unlockedMaps, old.unlockedMaps);
      expect(loaded.ownedOutfits, old.ownedOutfits);
      expect(loaded.totalCollected, old.totalCollected);
      expect(loaded.jobs[0]!.coins, old.jobs[0]!.coins);
      expect(loaded.removed, old.removed);
      expect(districts[4].canStand(loaded.position), isTrue);
      for (final d in districts) {
        expect(
          loaded.streetLitter[d.id].map((i) => (i.id, i.kind)),
          containsAll(old.streetLitter[d.id].map((i) => (i.id, i.kind))),
        );
        for (final item in loaded.streetLitter[d.id]) {
          expect(d.canStand(item.position, clearance: 20), isTrue);
          expect(loaded.removed[d.id], isNot(contains(item.id)));
        }
      }
      await loaded.flush();
      final saved = loaded.toJson()['streetLitter'];
      final again = GameState(store, now: () => time);
      await again.load();
      expect(again.toJson()['version'], 17);
      expect(again.toJson()['streetLitter'], saved);
      await again.flush();
      await old.flush();
      old.dispose();
      loaded.dispose();
      again.dispose();
    },
  );
}

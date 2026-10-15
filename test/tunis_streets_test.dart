import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/city_life.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'ground spawns near the player, stays reachable and respects saved limits',
    () async {
      for (final area in districts) {
        final state = GameState(MemoryStore());
        state.unlockedMaps.add(area.id);
        state.travel(area.id);
        final nav = CityNavigation(area),
            life = CityLife(state, CityNavigation(area));
        expect(life.spawnGroundLitter(), 0);
        state.introduced = true;
        final before = state.streetLitter[area.id].map((i) => i.id).toSet();
        expect(life.spawnGroundLitter(), 1, reason: area.name);
        for (final item in state.streetLitter[area.id].where(
          (i) => !before.contains(i.id),
        )) {
          expect(
            (item.position - state.position).distance,
            inInclusiveRange(180, 620),
          );
          expect(nav.route(state.position, item.position), isNotEmpty);
          expect(area.canStand(item.position, clearance: 20), isTrue);
          expect(
            area.stations.every((s) => (s - item.position).distance >= 105),
            isTrue,
          );
        }
        state.bag = List.generate(
          state.capacity,
          (_) => (kind: 0, district: area.id),
        );
        final countWhenFull = state.streetLitter[area.id].length;
        expect(life.spawnGroundLitter(), 0);
        expect(state.streetLitter[area.id].length, countWhenFull);
        state.bag.clear();
        for (var i = 0; i < 60; i++) {
          life.spawnGroundLitter();
        }
        expect(
          state.streetLitter[area.id].length,
          lessThanOrEqualTo(area.streetLitterLimit),
        );
        state.streetLitter[area.id].clear();
        state.removed[area.id] = {
          for (var i = 0; i < area.litterCount; i++) '${area.id}:0:$i',
        };
        expect(life.spawnGroundLitter(), 0);
        await state.flush();
        state.dispose();
      }
    },
  );

  test(
    'Tunis bench rows and interview crew leave the central walkway and station routes clear',
    () {
      final area = districts[2],
          plan = area.layout,
          nav = CityNavigation(districts[2]);
      final benches = plan.props.where((p) => p.kind == 2).toList();
      expect(benches.length, greaterThanOrEqualTo(12));
      expect(benches.map((p) => p.position.dy).toSet(), {1325.0, 1460.0});
      for (final bench in benches) {
        expect(plan.plaza!.contains(bench.position), isTrue);
        expect(
          plan.roadHits(
            Rect.fromCenter(center: bench.position, width: 66, height: 28),
          ),
          isFalse,
        );
        expect(area.canStand(bench.position), isFalse);
      }
      expect(
        nav.visible(const Offset(950, 1390), const Offset(2250, 1390)),
        isTrue,
      );
      expect(plan.interviewSpots.length, 3);
      for (final spot in plan.interviewSpots) {
        expect(area.canStand(spot), isFalse);
        expect(
          plan.roadHits(Rect.fromCircle(center: spot, radius: 20)),
          isFalse,
        );
        expect(nav.route(area.start, spot + const Offset(0, 70)), isNotEmpty);
      }
      for (final station in area.stations) {
        expect(
          nav.route(
            plan.interviewAnchor! + const Offset(0, 100),
            station + const Offset(0, 80),
          ),
          isNotEmpty,
        );
      }
    },
  );

  test(
    'v12 items covered by new benches relocate without losing rewards or progress',
    () async {
      final old = GameState(MemoryStore()), store = MemoryStore();
      final bench = districts[2].layout.props.firstWhere((p) => p.kind == 2);
      final item = old.streetLitter[2].first;
      old.streetLitter[2][0] = Litter(
        item.id,
        bench.position,
        item.kind,
        2,
        truckDroppedAt: 123456,
      );
      old.coins = 431;
      store.value = jsonEncode(old.toJson()..['version'] = 12);
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.coins, 431);
      final moved = loaded.streetLitter[2].firstWhere((i) => i.id == item.id);
      expect(moved.truckDroppedAt, 123456);
      expect(moved.kind, item.kind);
      expect(districts[2].canStand(moved.position, clearance: 20), isTrue);
      expect(moved.position, isNot(bench.position));
      final saved = loaded.toJson()['streetLitter'];
      final reopened = GameState(store);
      await reopened.load();
      expect(reopened.toJson()['streetLitter'], saved);
      await loaded.flush();
      await reopened.flush();
      old.dispose();
      loaded.dispose();
      reopened.dispose();
    },
  );
}

import 'dart:math';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/game/city_life.dart';
import 'package:greenhaven/game/trash_truck.dart';
import 'package:greenhaven/game/tree_apples.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'pedestrians detour around the truck without gridlocking its litter trail',
    () async {
      for (final district in districts) {
        final state = GameState(MemoryStore())..introduced = true;
        state.unlockedMaps.add(district.id);
        state.travel(district.id);
        final life = CityLife(state, CityNavigation(district));
        expect(
          life.truck.spawn(pedestrians: life.people.map((p) => p.position)),
          isTrue,
        );
        final truck = life.truck.actor!;
        for (var frame = 0; frame < 880 && life.truck.actor != null; frame++) {
          life.update(.05);
          for (final person in life.people) {
            expect(
              (person.position - truck.position).distance,
              greaterThanOrEqualTo(TrashTruck.radius + 11.9),
              reason: district.name,
            );
          }
        }
        expect(truck.drops, greaterThanOrEqualTo(2), reason: district.name);
        await state.flush();
        state.dispose();
      }
    },
  );
  test(
    'trucks spawn near the player on all six cities, stay clear and leave collectible trails',
    () async {
      for (final district in districts) {
        for (final seed in [3, 17, 81]) {
          final state = GameState(MemoryStore())..introduced = true;
          state.unlockedMaps.add(district.id);
          state.travel(district.id);
          final nav = CityNavigation(district);
          final dropped = <Litter>[];
          final event = TrashTruckEncounter(
            state,
            nav,
            Random(seed),
            (item, _) => dropped.add(item),
          );
          expect(event.spawn(), isTrue, reason: '${district.name} seed $seed');
          final truck = event.actor!;
          expect(
            (truck.position - state.position).distance,
            inInclusiveRange(210, 930),
          );
          expect(
            event.blocksMovement(
              truck.position + const Offset(-150, 0),
              truck.position + const Offset(150, 0),
            ),
            isTrue,
          );
          final positions = <Offset>{truck.position};
          for (var frame = 0; frame < 860 && event.actor != null; frame++) {
            event.update(.05);
            positions.add(truck.position);
            expect(
              district.canStand(truck.position, clearance: TrashTruck.radius),
              isTrue,
            );
            expect(
              (truck.position - state.position).distance,
              greaterThanOrEqualTo(TrashTruck.radius + 18),
            );
          }
          expect(event.actor, isNull);
          expect(positions.length, greaterThan(50));
          expect(
            dropped.length,
            inInclusiveRange(1, 20),
            reason: district.name,
          );
          for (final item in dropped) {
            expect(item.truckDroppedAt, isNotNull);
            expect(nav.route(district.start, item.position), isNotEmpty);
          }
          await state.flush();
          state.dispose();
        }
      }
    },
  );

  test(
    'truck yields to player and cannot spawn during onboarding or exhaust cleanup quota',
    () async {
      final state = GameState(MemoryStore());
      final event = TrashTruckEncounter(
        state,
        CityNavigation(districts[0]),
        Random(4),
        (_, _) {},
      );
      event.update(200);
      expect(event.actor, isNull);
      expect(event.spawn(), isFalse);
      state.introduced = true;
      expect(event.spawn(preview: true), isFalse);
      expect(event.spawn(), isTrue);
      final truck = event.actor!;
      while ((truck.route.first - truck.position).distance < 3) {
        truck.route.removeAt(0);
      }
      final direction =
          (truck.route.first - truck.position) /
          (truck.route.first - truck.position).distance;
      state.position = truck.position + direction * (TrashTruck.radius + 18);
      final before = truck.position;
      for (var i = 0; i < 10; i++) {
        event.update(.05);
      }
      expect(truck.position, before);
      state.position = districts[0].start;
      state.streetLitter[0].clear();
      state.removed[0].addAll(
        List.generate(districts[0].litterCount, (i) => '0:0:$i'),
      );
      event.actor = null;
      expect(event.spawn(), isFalse);
      expect(state.dropLitter(before, fromTruck: true), isNull);
      await state.flush();
      state.dispose();
    },
  );

  test(
    'fresh truck bonuses decay, persist across reload and pay once only after a successful pickup',
    () async {
      var time = DateTime.utc(2026, 10, 12, 12);
      final store = MemoryStore();
      final state = GameState(store, now: () => time);
      final position = state.streetLitter[0].first.position;
      state.streetLitter[0].clear();
      final fresh = state.dropLitter(position, fromTruck: true)!;
      expect(fresh.truckBonus(state.nowMs), 8);
      state.bag.addAll(
        List.generate(state.capacity, (_) => (kind: 0, district: 0)),
      );
      expect(state.collect(fresh), isFalse);
      expect(state.coins, 0);
      state.bag.clear();
      state.truckWaitMs = 181234;
      await state.save();
      await state.flush();
      time = time.add(const Duration(seconds: 12));
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      final old = loaded.streetLitter[0].single;
      expect(old.truckBonus(loaded.nowMs), 5);
      expect(loaded.truckWaitMs, 181234);
      expect(loaded.collect(old), isTrue);
      expect(loaded.coins, 5);
      expect(loaded.collect(old), isFalse);
      expect(loaded.coins, 5);
      final next = loaded.dropLitter(position, fromTruck: true)!;
      time = time.add(const Duration(seconds: 60));
      expect(loaded.collect(next), isTrue);
      expect(loaded.coins, 6);
      final ordinary = loaded.dropLitter(position)!;
      expect(loaded.collect(ordinary), isTrue);
      expect(loaded.coins, 6);
      await loaded.flush();
      final reopened = GameState(store, now: () => time);
      await reopened.load();
      expect(reopened.coins, 6);
      expect(reopened.playerRewardSequence, 0);
      expect(reopened.streetLitter[0], isEmpty);
      await reopened.flush();
      state.dispose();
      loaded.dispose();
      reopened.dispose();
    },
  );

  test(
    'v10 saves retain streets, wallets and collected IDs without inventing truck bonuses',
    () async {
      final old = GameState(MemoryStore());
      old.collect(old.streetLitter[0].first);
      old.coins = 438;
      final save = old.toJson()..['version'] = 10;
      save.remove('truckWaitMs');
      save['streetLitter'] = old.streetLitter
          .map(
            (items) => items
                .map((i) => [i.id, i.position.dx, i.position.dy, i.kind.index])
                .toList(),
          )
          .toList();
      final loaded = GameState(MemoryStore()..value = jsonEncode(save));
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.coins, 438);
      expect(loaded.removed[0], old.removed[0]);
      expect(loaded.streetLitter[0].length, districts[0].initialLitterCount);
      expect(
        loaded.streetLitter[0].map((i) => i.id),
        containsAll(old.streetLitter[0].map((i) => i.id)),
      );
      expect(
        loaded.streetLitter
            .expand((i) => i)
            .every((i) => i.truckDroppedAt == null),
        isTrue,
      );
      await old.flush();
      await loaded.flush();
      old.dispose();
      loaded.dispose();
    },
  );

  test(
    'apples fall on reachable ground, require stepping on them, refresh a bounded boost and expire',
    () async {
      for (final district in districts) {
        final state = GameState(MemoryStore())..introduced = true;
        state.unlockedMaps.add(district.id);
        state.travel(district.id);
        final nav = CityNavigation(district);
        final drops = TreeApples(state, nav, Random(7));
        expect(drops.drop(), isTrue, reason: district.name);
        final apple = drops.apples.single;
        expect(nav.route(state.position, apple.position), isNotEmpty);
        expect(drops.eatAt(apple.position), isFalse); // Still falling.
        drops.update(.8);
        expect(drops.eatAt(apple.position + const Offset(30, 0)), isFalse);
        state.bag.addAll(
          List.generate(
            state.capacity,
            (_) => (kind: 0, district: district.id),
          ),
        );
        expect(drops.eatAt(apple.position), isTrue); // No bag space required.
        expect(drops.speedMultiplier, 1.35);
        expect(drops.eatAt(apple.position), isFalse);
        drops.untilAttempt = 100;
        expect(drops.boostSeconds, 5);
        drops.update(3);
        expect(drops.boostSeconds, 2);
        drops.apples.add(TreeApple(apple.position, apple.tree));
        drops.update(.8);
        expect(drops.eatAt(drops.apples.first.position), isTrue);
        expect(drops.boostSeconds, 5);
        expect(drops.speedMultiplier, 1.35);
        drops.update(4.9);
        expect(drops.speedMultiplier, 1.35);
        drops.update(.1);
        expect(drops.speedMultiplier, 1);
        drops.update(60);
        expect(drops.drop(), isTrue);
        drops.untilAttempt = 100;
        drops.update(65);
        expect(drops.apples, isEmpty);
        await state.flush();
        state.dispose();
      }
    },
  );
}

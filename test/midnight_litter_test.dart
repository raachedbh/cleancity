import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  late DateTime time;
  late MemoryStore store;
  late GameState state;
  setUp(() {
    time = DateTime(2026, 10, 15, 23, 59, 59);
    store = MemoryStore();
    state = GameState(store, now: () => time)..introduced = true;
  });
  tearDown(() async {
    await state.flush();
    state.dispose();
  });

  test(
    'local midnight adds 20 once to unlocked maps and survives reopening',
    () async {
      state.unlockedMaps.add(2);
      state.coins = 431;
      state.gems = 9;
      final picked = state.streetLitter[0].first;
      state.collect(picked);
      final before = state.streetLitter.map((items) => items.length).toList();
      final liveList = state.streetLitter[0];
      state.tick();
      expect(state.streetLitter.map((items) => items.length), before);
      time = DateTime(2026, 10, 16);
      state.tick();
      for (final area in districts) {
        expect(
          state.streetLitter[area.id].length,
          before[area.id] + (state.isUnlocked(area.id) ? 20 : 0),
        );
      }
      expect(identical(liveList, state.streetLitter[0]), isTrue);
      expect(state.streetLitter[0].any((i) => i.id == picked.id), isFalse);
      expect(state.coins, 431);
      expect(state.gems, 9);
      expect(state.totalCollected, 1);
      expect(state.bag.length, 1);
      final snapshot = jsonEncode(state.toJson()['streetLitter']);
      state.tick();
      expect(jsonEncode(state.toJson()['streetLitter']), snapshot);
      await state.flush();
      final reopened = GameState(store, now: () => time);
      await reopened.load();
      expect(reopened.recoveredSave, isFalse);
      expect(jsonEncode(reopened.toJson()['streetLitter']), snapshot);
      expect(reopened.lastLitterDay, state.lastLitterDay);
      await reopened.flush();
      reopened.dispose();
    },
  );

  test(
    'offline nights accumulate only to each map limit, without replaying a full night',
    () async {
      state.unlockedMaps.addAll(districts.map((d) => d.id));
      await state.save();
      time = DateTime(2026, 10, 19, 12);
      final reopened = GameState(store, now: () => time);
      await reopened.load();
      expect(reopened.recoveredSave, isFalse);
      for (final area in districts) {
        expect(
          reopened.streetLitter[area.id].length,
          min(area.initialLitterCount + 80, area.maximumLitterCount),
        );
      }
      final picked = reopened.streetLitter[0].first;
      reopened.collect(picked);
      time = DateTime(
        2026,
        10,
        18,
        12,
      ); // Clock rollback cannot repeat a refill.
      reopened.tick();
      expect(reopened.streetLitter[0].length, 39);
      time = DateTime(2026, 10, 19, 23, 59);
      reopened.tick();
      expect(reopened.streetLitter[0].length, 39);
      await reopened.flush();
      final again = GameState(store, now: () => time);
      await again.load();
      expect(again.streetLitter[0].length, 39);
      time = DateTime(2026, 10, 20);
      again.tick();
      expect(again.streetLitter[0].length, 40);
      expect(again.streetLitter[0].any((i) => i.id == picked.id), isFalse);
      await again.flush();
      again.dispose();
      reopened.dispose();
    },
  );

  test('all sources obey the same hard cap and larger maps hold more', () {
    expect(districts.map((d) => d.maximumLitterCount), [
      40,
      70,
      80,
      110,
      120,
      150,
    ]);
    for (final area in districts) {
      state.unlockedMaps.add(area.id);
      state.travel(area.id);
      final candidates = createLitter(area.id, 0);
      state.streetLitter[area.id] = candidates
          .take(area.streetLitterLimit)
          .toList();
      expect(
        state.dropLitter(candidates[area.streetLitterLimit].position),
        isNull,
      );
      var truck = false;
      for (final candidate in candidates.skip(area.streetLitterLimit)) {
        final item = state.dropLitter(
          candidate.position,
          fromTruck: truck,
          fromThief: !truck,
        );
        if (state.streetLitter[area.id].length == area.maximumLitterCount) {
          final freePosition = candidates[area.maximumLitterCount].position;
          expect(state.dropLitter(freePosition, fromTruck: true), isNull);
          expect(state.dropLitter(freePosition, fromThief: true), isNull);
          break;
        }
        expect(item, isNotNull);
        truck = !truck;
      }
      expect(state.streetLitter[area.id].length, area.maximumLitterCount);
    }
    time = DateTime(2026, 10, 16);
    state.tick();
    for (final area in districts) {
      expect(state.streetLitter[area.id].length, area.maximumLitterCount);
    }
  });

  test(
    'nightly positions vary, remain reachable and leave stations clear in all cities',
    () {
      state.unlockedMaps.addAll(districts.map((d) => d.id));
      for (final items in state.streetLitter) {
        items.clear();
      }
      time = DateTime(2026, 10, 16);
      state.tick();
      final first = state.streetLitter
          .map((items) => items.map((i) => i.position).toSet())
          .toList();
      for (final area in districts) {
        final items = state.streetLitter[area.id], nav = CityNavigation(area);
        expect(items.length, 20);
        expect(items.map((i) => i.id).toSet().length, 20);
        for (final item in items) {
          expect(area.canStand(item.position, clearance: 20), isTrue);
          expect(
            nav.route(area.start, item.position),
            isNotEmpty,
            reason: area.name,
          );
          expect(
            area.stations.every((p) => (p - item.position).distance >= 105),
            isTrue,
          );
          expect(item.truckDroppedAt, isNull);
        }
        items.clear();
      }
      time = DateTime(2026, 10, 17);
      state.tick();
      for (final area in districts) {
        expect(state.streetLitter[area.id].length, 20);
        expect(
          state.streetLitter[area.id].any(
            (i) => !first[area.id].contains(i.position),
          ),
          isTrue,
        );
      }
    },
  );

  test(
    'midnight respects remaining quota and starts a completed round without losing inventory',
    () {
      state.streetLitter[0].clear();
      state.removed[0] = {for (var i = 0; i < 598; i++) '0:0:$i'};
      state.totalCollected = 598;
      state.coins = 538;
      state.bag.add((kind: 0, district: 0));
      state.jobs[0] = RecyclingJob(
        0,
        [(kind: 1, district: 0)],
        3,
        state.nowMs,
        time.add(const Duration(days: 10)).millisecondsSinceEpoch,
      );
      time = DateTime(2026, 10, 16);
      state.tick();
      expect(state.streetLitter[0].map((i) => i.id), ['0:0:598', '0:0:599']);
      for (final item in state.streetLitter[0].toList()) {
        state.collect(item);
      }
      final liveList = state.streetLitter[0];
      time = DateTime(2026, 10, 17);
      state.tick();
      expect(identical(liveList, state.streetLitter[0]), isTrue);
      expect(state.cycles[0], 1);
      expect(state.streetLitter[0].length, 20);
      expect(
        state.streetLitter[0].every((i) => i.id.startsWith('0:1:')),
        isTrue,
      );
      expect(state.bag.length, 3);
      expect(state.jobs[0]!.coins, 3);
      expect(state.coins, 538);
      expect(state.totalCollected, 600);
    },
  );

  for (final version in [16, 17]) {
    test(
      'v$version dense saves migrate safely and start counting nights today',
      () async {
        state.unlockedMaps.addAll(districts.map((d) => d.id));
        state.coins = 731;
        state.gems = 17;
        state.darkMode = false;
        for (final area in districts) {
          state.streetLitter[area.id] = createLitter(
            area.id,
            0,
            count: 101 + area.id * 15,
          );
        }
        state.collect(state.streetLitter[0].first);
        final original = state.streetLitter[0].first;
        state.streetLitter[0][0] = Litter(
          original.id,
          original.position,
          original.kind,
          0,
          truckDroppedAt: state.nowMs - 1000,
        );
        state.streetLitter[4] = state.streetLitter[4].take(5).toList();
        final raw = state.toJson()..['version'] = version;
        raw.remove('lastLitterDay');
        store.value = jsonEncode(raw);
        time = DateTime(2026, 11, 20, 12);
        final migrated = GameState(store, now: () => time);
        await migrated.load();
        expect(migrated.recoveredSave, isFalse);
        expect(migrated.coins, 731);
        expect(migrated.gems, 17);
        expect(migrated.darkMode, isFalse);
        expect(migrated.bag, state.bag);
        expect(migrated.removed, state.removed);
        expect(migrated.totalCollected, 1);
        for (final area in districts) {
          expect(
            migrated.streetLitter[area.id].length,
            area.id == 4 ? 5 : area.maximumLitterCount,
          );
        }
        expect(
          migrated.streetLitter[0].first.truckDroppedAt,
          state.streetLitter[0].first.truckDroppedAt,
        );
        expect(migrated.lastLitterDay, migrated.localLitterDay);
        await migrated.flush();
        final again = GameState(store, now: () => time);
        await again.load();
        expect(again.recoveredSave, isFalse);
        expect(
          again.toJson()['streetLitter'],
          migrated.toJson()['streetLitter'],
        );
        expect(again.toJson()['version'], 18);
        await again.flush();
        again.dispose();
        migrated.dispose();
      },
    );
  }
}

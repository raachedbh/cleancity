import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/city_life.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'v11 top-up preserves progress and truck drops and only happens once',
    () async {
      final store = MemoryStore(), old = GameState(MemoryStore());
      old.coins = 431;
      old.gems = 9;
      old.collect(old.streetLitter[0].first);
      for (final area in districts) {
        old.streetLitter[area.id] = old.streetLitter[area.id].take(17).toList();
      }
      final original = old.streetLitter[0].first;
      old.streetLitter[0][0] = Litter(
        original.id,
        original.position,
        original.kind,
        0,
        truckDroppedAt: old.nowMs - 8000,
      );
      // Unfinished rounds expand; completed cities remain complete.
      old.removed[4] = {for (var i = 0; i < 120 + 4 * 45 - 3; i++) '4:0:$i'};
      old.streetLitter[4].clear();
      old.removed[5] = {for (var i = 0; i < 120 + 5 * 45; i++) '5:0:$i'};
      old.streetLitter[5].clear();
      final previous = old.streetLitter.map((items) => [...items]).toList();
      store.value = jsonEncode(old.toJson()..['version'] = 11);
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.coins, 431);
      expect(loaded.gems, 9);
      expect(loaded.bag, old.bag);
      expect(loaded.removed, old.removed);
      for (final area in districts) {
        final items = loaded.streetLitter[area.id];
        expect(items.length, area.id == 5 ? 0 : area.initialLitterCount);
        expect(
          items.map((i) => (i.id, i.position, i.kind, i.truckDroppedAt)),
          containsAll(
            previous[area.id].map(
              (i) => (i.id, i.position, i.kind, i.truckDroppedAt),
            ),
          ),
        );
        expect(items.map((i) => i.id).toSet().length, items.length);
        final nav = CityNavigation(area);
        for (final item in items) {
          expect(loaded.removed[area.id], isNot(contains(item.id)));
          expect(nav.route(area.start, item.position), isNotEmpty);
        }
      }
      loaded.collect(loaded.streetLitter[0].first);
      await loaded.flush();
      final saved = loaded.toJson()['streetLitter'];
      final reopened = GameState(store);
      await reopened.load();
      expect(reopened.toJson()['streetLitter'], saved);
      expect(reopened.removed, loaded.removed);
      await old.flush();
      await reopened.flush();
      old.dispose();
      loaded.dispose();
      reopened.dispose();
    },
  );

  test('v4 update tops up streets once, preserving collected IDs', () async {
    final store = MemoryStore(), old = GameState(MemoryStore());
    final picked = old.streetLitter[0].first;
    old.collect(picked);
    for (var id = 0; id < districts.length; id++) {
      old.streetLitter[id] = old.streetLitter[id].take(17).toList();
    }
    store.value = jsonEncode(old.toJson()..['version'] = 4);
    final loaded = GameState(store);
    await loaded.load();
    expect(loaded.recoveredSave, isFalse);
    expect(loaded.streetLitter[0].length, districts[0].initialLitterCount);
    expect(loaded.removed[0], contains(picked.id));
    expect(loaded.streetLitter[0].any((i) => i.id == picked.id), isFalse);
    loaded.collect(loaded.streetLitter[0].first);
    await loaded.flush();
    final reopened = GameState(store);
    await reopened.load();
    expect(
      reopened.streetLitter[0].length,
      districts[0].initialLitterCount - 1,
    );
    expect(reopened.totalCollected, 2);
    await reopened.flush();
    await old.flush();
    old.dispose();
    loaded.dispose();
    reopened.dispose();
  });
  test(
    'streets open with more litter, capped drops persist, pickups never respawn',
    () async {
      final store = MemoryStore(), state = GameState(MemoryStore());
      final s = GameState(store);
      expect(s.streetLitter[0].length, districts[0].initialLitterCount);
      expect(s.streetLitter[0].length, districts[0].maximumLitterCount ~/ 2);
      final picked = s.streetLitter[0].first;
      expect(
        s.dropLitter(picked.position),
        isNull,
      ); // spacing prevents duplicates
      expect(s.collect(picked), isTrue);
      expect(s.dropLitter(districts[0].blocks.first.center), isNull);
      expect(s.dropLitter(districts[0].station), isNull);
      final dropped = s.dropLitter(picked.position);
      expect(dropped, isNotNull);
      expect(dropped!.id, isNot(picked.id));
      expect(s.dropLitter(picked.position), isNull);
      expect(s.streetLitter[0].length, districts[0].initialLitterCount);
      expect(s.collect(dropped), isTrue);
      await s.flush();
      final loaded = GameState(store);
      await loaded.load();
      expect(
        loaded.streetLitter[0].length,
        districts[0].initialLitterCount - 1,
      );
      expect(
        loaded.streetLitter[0].any(
          (i) => i.id == picked.id || i.id == dropped.id,
        ),
        isFalse,
      );
      expect(loaded.removed[0], containsAll([picked.id, dropped.id]));
      expect(loaded.collect(dropped), isFalse);
      await loaded.flush();
      loaded.dispose();
      s.dispose();
      state.dispose();
    },
  );

  test(
    'v2 upgrade keeps progress and old batch value, migrates to denser streets',
    () async {
      final store = MemoryStore();
      final time = DateTime.utc(2026, 10, 8, 12);
      final previous = GameState(store, now: () => time);
      final save = previous.toJson()
        ..['version'] = 2
        ..['coins'] = 431
        ..['gems'] = 9
        ..['xp'] = 240
        ..['upgrades'] = [1, 0, 0, 0, 0]
        ..['removed'] = [
          for (var d = 0; d < districts.length; d++)
            d == 0 ? [for (var i = 0; i < 60; i++) '0:0:$i'] : <String>[],
        ]
        ..['bag'] = [
          [0, 0],
          [2, 1],
        ]
        ..['jobs'] = [
          {
            'district': 0,
            'items': [
              [2, 0],
            ],
            'coins': 5,
            'startedAt': time.millisecondsSinceEpoch - 15000,
            'readyAt': time.millisecondsSinceEpoch,
          },
        ];
      save.remove('streetLitter');
      store.value = jsonEncode(save);
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.coins, 436); // preserve the old 5-coin pending batch
      expect(loaded.gems, 9);
      expect(loaded.capacity, 24);
      expect(loaded.bag.length, 2);
      expect(loaded.removed[0].length, 60);
      expect(loaded.streetLitter[0].length, districts[0].initialLitterCount);
      expect(
        loaded.streetLitter[0].any((i) => loaded.removed[0].contains(i.id)),
        isFalse,
      );
      expect(
        loaded.valueOf([
          (kind: 0, district: 0),
          (kind: 1, district: 0),
          (kind: 2, district: 0),
        ]),
        9,
      );
      loaded.tick();
      expect(loaded.coins, 436);
      await loaded.flush();
      loaded.dispose();
      previous.dispose();
    },
  );

  test(
    'pedestrians stay reachable and animate finite, spaced, valid litter drops',
    () async {
      for (final district in districts) {
        final s = GameState(MemoryStore())
          ..introduced = true
          ..thiefWaitMs = 300000
          ..truckWaitMs = 300000;
        s.unlockedMaps.add(district.id);
        s.travel(district.id);
        // Free a little space without changing the cleanup quota.
        for (final item in s.streetLitter[district.id].take(12).toList()) {
          s.collect(item);
        }
        final nav = CityNavigation(district),
            life = CityLife(s, CityNavigation(district));
        final starts = life.people.map((p) => p.position).toList();
        final originalIds = s.streetLitter[district.id]
            .map((i) => i.id)
            .toSet();
        var seenToss = false;
        for (var frame = 0; frame < 2400; frame++) {
          life.update(.05);
          seenToss |= life.tosses.isNotEmpty;
          if (frame == 599) {
            expect(
              s.streetLitter[district.id].length - originalIds.length,
              inInclusiveRange(1, 5),
              reason:
                  '${district.name}: only occasional drops in the first 30 seconds',
            );
          }
          for (final person in life.people) {
            expect(
              district.canStand(person.position),
              isTrue,
              reason: district.name,
            );
          }
        }
        expect(seenToss, isTrue, reason: district.name);
        expect(
          life.people.asMap().entries.any(
            (p) => (p.value.position - starts[p.key]).distance > 20,
          ),
          isTrue,
        );
        expect(
          s.streetLitter[district.id].length - originalIds.length,
          inInclusiveRange(3, 22),
        );
        expect(
          s.streetLitter[district.id].map((i) => i.id).toSet().length,
          s.streetLitter[district.id].length,
        );
        for (final item in s.streetLitter[district.id].where(
          (i) => !originalIds.contains(i.id),
        )) {
          expect(district.canStand(item.position, clearance: 20), isTrue);
          expect(nav.route(district.start, item.position), isNotEmpty);
          expect(
            district.stations.every((p) => (p - item.position).distance >= 105),
            isTrue,
          );
        }
        await s.flush();
        s.dispose();
      }
    },
  );

  test('cleanup quota prevents any further pedestrian emissions', () async {
    final s = GameState(MemoryStore());
    s.streetLitter[0].clear();
    s.removed[0].addAll([
      for (var i = 0; i < districts[0].litterCount; i++) '0:0:$i',
    ]);
    expect(s.dropLitter(const Offset(600, 400)), isNull);
    s.position = districts[0].station + const Offset(0, 80);
    expect(s.nextCleanup(), isTrue);
    expect(s.streetLitter[0].length, districts[0].initialLitterCount);
    expect(s.streetLitter[0].every((i) => i.id.startsWith('0:1:')), isTrue);
    await s.flush();
    s.dispose();
  });
}

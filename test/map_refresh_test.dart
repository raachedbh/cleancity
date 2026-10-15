import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/data/city_layout.dart';
import 'package:greenhaven/game/mini_map.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/game/thief_encounter.dart';
import 'package:greenhaven/game/trash_truck.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test('road caps, joins and texture footprints have no square gaps', () {
    const street = CityStreet(
      [Offset(100, 100), Offset(300, 100), Offset(300, 300)],
      100,
      StreetSurface.stone,
    );
    final surface = street.footprint(),
        pavement = street.footprint(extraWidth: 52);
    for (final p in [
      const Offset(60, 100),
      const Offset(330, 70),
      const Offset(300, 340),
      const Offset(220, 100),
    ]) {
      expect(surface.contains(p), isTrue);
      expect(pavement.contains(p), isTrue);
    }
    expect(surface.contains(const Offset(40, 100)), isFalse);
    expect(pavement.contains(const Offset(40, 100)), isTrue);
  });

  test('Tunis promenade stays outside the clock roundabout', () {
    final plan = districts[2].layout;
    final road = plan.streets.first.footprint();
    final overlap = Path.combine(PathOperation.intersect, road, plan.plazaPath);
    expect(overlap.computeMetrics().isEmpty, isTrue);
    final lucca = districts[1].layout;
    expect(lucca.plazaPath.contains(lucca.streets[4].points.last), isTrue);
    expect(lucca.plazaPath.contains(lucca.streets[5].points.first), isTrue);
    final midnight = districts[5].layout;
    expect(
      midnight.plazaPath.contains(midnight.streets.last.points.first),
      isTrue,
    );
    expect(
      midnight.streets.first.distanceTo(midnight.streets.last.points.last),
      lessThan(2),
    );
  });

  test(
    'minimap keeps proportions, groups dots and removes collected trash',
    () {
      final projection = MiniMapProjection(
        const Size(4000, 2000),
        const Size(96, 76),
      );
      expect(projection.bounds.width / projection.bounds.height, 2);
      final normal = Litter(
        '0:0:0',
        const Offset(1000, 1000),
        MaterialKind.bottle,
        0,
      );
      final truck = Litter(
        '0:0:1',
        const Offset(1001, 1001),
        MaterialKind.bottle,
        0,
        truckDroppedAt: 100,
      );
      final far = Litter(
        '0:0:2',
        const Offset(3000, 1000),
        MaterialKind.bottle,
        0,
      );
      final litter = [normal, truck, far];
      expect(projection.litterMarkers(litter).length, 2);
      expect(projection.litterMarkers(litter).where((m) => m.truck).length, 1);
      litter.remove(far);
      expect(projection.litterMarkers(litter).length, 1);
      litter.clear();
      expect(projection.litterMarkers(litter), isEmpty);
    },
  );

  test(
    'v13 migration expands unfinished streets once and preserves finished rounds',
    () async {
      final old = GameState(MemoryStore())
        ..coins = 731
        ..gems = 17;
      old.streetLitter[0] = old.streetLitter[0].take(90).toList();
      old.collect(old.streetLitter[0].first);
      old.removed[1] = {for (var i = 0; i < 165; i++) '1:0:$i'};
      old.streetLitter[1].clear();
      final raw = old.toJson()
        ..['version'] = 13
        ..['cityEventWaitMs'] = 420000
        ..['thiefWaitMs'] = 300000
        ..['truckWaitMs'] = 300000;
      raw.remove('cleanupTargets');
      final store = MemoryStore()..value = jsonEncode(raw);
      final state = GameState(store);
      await state.load();
      expect(state.recoveredSave, isFalse);
      expect(state.coins, 731);
      expect(state.gems, 17);
      expect(state.bag, old.bag);
      expect(state.removed, old.removed);
      expect(state.cleanupTarget, 600);
      expect(state.streetLitter[0].length, districts[0].initialLitterCount);
      expect(state.cleanupTargets[1], 165);
      expect(state.streetLitter[1], isEmpty);
      expect(state.cityEventWaitMs, 360000);
      expect(state.thiefWaitMs, 300000);
      expect(state.truckWaitMs, 300000);
      state.collect(state.streetLitter[0].first);
      await state.flush();
      final reopened = GameState(store);
      await reopened.load();
      expect(
        reopened.streetLitter[0].length,
        districts[0].initialLitterCount - 1,
      );
      expect(reopened.cleanupTargets[1], 165);
      reopened.unlockedMaps.add(1);
      reopened.travel(1);
      reopened.bag.clear();
      reopened.position = districts[1].station + const Offset(0, 80);
      expect(reopened.nextCleanup(), isTrue);
      expect(reopened.cleanupTarget, districts[1].litterCount);
      await old.flush();
      await reopened.flush();
      old.dispose();
      state.dispose();
      reopened.dispose();
    },
  );

  test(
    'populated streets allow automatic events beyond the old allocation limit',
    () async {
      final state = GameState(MemoryStore())..introduced = true;
      final navigation = CityNavigation(districts[0]);
      final thief = ThiefEncounter(state, navigation, Random(7), (_, _) {});
      final truck = TrashTruckEncounter(
        state,
        navigation,
        Random(8),
        (_, _) {},
      );
      expect(state.streetLitter[0].length, districts[0].initialLitterCount);
      thief.update(149);
      truck.update(209);
      expect(thief.actor, isNull);
      expect(truck.actor, isNull);
      thief.update(1);
      truck.update(1);
      expect(thief.actor, isNotNull);
      expect(truck.actor, isNotNull);
      expect(state.thiefWaitMs, inInclusiveRange(240000, 360000));
      expect(state.truckWaitMs, inInclusiveRange(300000, 420000));
      await state.flush();
      state.dispose();
    },
  );
  test(
    'cleared rounds replenish during play without losing inventory or paying twice',
    () async {
      final store = MemoryStore(), state = GameState(MemoryStore());
      state.cleanupTargets[0] = 120;
      state.streetLitter[0].clear();
      state.removed[0] = {for (var i = 0; i < 120; i++) '0:0:$i'};
      state.totalCollected = 120;
      state.bag.add((kind: 1, district: 0));
      state.jobs[0] = RecyclingJob(
        0,
        [(kind: 0, district: 0)],
        2,
        state.nowMs,
        state.nowMs + 15000,
      );
      state.coins = 537;
      expect(
        state.replenishClearedStreets(),
        isFalse,
      ); // Not before onboarding.
      state.introduced = true;
      expect(state.replenishClearedStreets(), isTrue);
      expect(state.cycles[0], 1);
      expect(state.streetLitter[0].length, districts[0].initialLitterCount);
      expect(
        state.streetLitter[0].every((i) => i.id.startsWith('0:1:')),
        isTrue,
      );
      expect(state.bag.single, (kind: 1, district: 0));
      expect(state.jobs[0]!.coins, 2);
      expect(state.coins, 537);
      expect(state.totalCollected, 120);
      expect(state.replenishClearedStreets(), isFalse);
      state.collect(state.streetLitter[0].first);
      store.value = jsonEncode(state.toJson());
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.cycles[0], 1);
      expect(
        loaded.streetLitter[0].length,
        districts[0].initialLitterCount - 1,
      );
      expect(loaded.replenishClearedStreets(), isFalse);
      await state.flush();
      await loaded.flush();
      state.dispose();
      loaded.dispose();
    },
  );
  for (final version in [14, 15]) {
    test(
      'dense v$version saves thin out once without resetting wallets or collected progress',
      () async {
        final store = MemoryStore(), old = GameState(MemoryStore());
        for (final area in districts) {
          old.streetLitter[area.id] = createLitter(
            area.id,
            0,
            count: version == 14 ? 280 + area.id * 100 : 170 + area.id * 60,
          );
        }
        old.coins = 431;
        old.gems = 9;
        old.collect(old.streetLitter[0].first);
        final item = old.streetLitter[0].first;
        old.streetLitter[0][0] = Litter(
          item.id,
          item.position,
          item.kind,
          0,
          truckDroppedAt: old.nowMs - 3000,
        );
        store.value = jsonEncode(old.toJson()..['version'] = version);
        final loaded = GameState(store);
        await loaded.load();
        expect(loaded.recoveredSave, isFalse);
        expect(loaded.coins, 431);
        expect(loaded.gems, 9);
        expect(loaded.bag, old.bag);
        expect(loaded.removed, old.removed);
        expect(loaded.totalCollected, old.totalCollected);
        for (final area in districts) {
          final active = loaded.streetLitter[area.id];
          expect(active.length, area.initialLitterCount);
          expect(active.map((i) => i.id).toSet().length, active.length);
        }
        final retained = loaded.streetLitter[0].firstWhere(
          (i) => i.id == item.id,
        );
        expect(
          retained.truckDroppedAt,
          old.streetLitter[0].first.truckDroppedAt,
        );
        final retired = old.streetLitter[0].firstWhere(
          (i) => !loaded.streetLitter[0].any((j) => j.id == i.id),
        );
        expect(loaded.collect(retired), isFalse);
        loaded.collect(loaded.streetLitter[0].last);
        await loaded.flush();
        final reopened = GameState(store);
        await reopened.load();
        expect(
          reopened.streetLitter[0].length,
          districts[0].initialLitterCount - 1,
        );
        expect(reopened.removed, loaded.removed);
        await old.flush();
        await reopened.flush();
        old.dispose();
        loaded.dispose();
        reopened.dispose();
      },
    );
  }
}

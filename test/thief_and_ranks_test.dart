import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/data/cleanup_ranks.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/game/thief_encounter.dart';
import 'package:greenhaven/state/bootstrap.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'thief waits for line of sight, flees on every map, drops reachable litter and escapes',
    () async {
      final durations = <double>{};
      for (final d in districts) {
        final s = GameState(MemoryStore())..introduced = true;
        s.unlockedMaps.add(d.id);
        s.travel(d.id);
        final nav = CityNavigation(d), emitted = <Litter>[];
        final encounter = ThiefEncounter(
          s,
          nav,
          Random(d.id + 17),
          (i, _) => emitted.add(i),
        );
        expect(encounter.spawn(), isTrue, reason: d.name);
        final thief = encounter.actor!;
        encounter.update(.05);
        expect(thief.running, isFalse);
        s.position = thief.position;
        encounter.update(.05);
        expect(thief.running, isTrue);
        durations.add(thief.escapeAfter);
        final start = thief.position;
        for (var i = 0; i < 700 && encounter.actor != null; i++) {
          encounter.update(.05);
          expect(d.canStand(thief.position), isTrue, reason: d.name);
        }
        expect(encounter.actor, isNull);
        expect((thief.position - start).distance, greaterThan(100));
        expect(emitted.length, inInclusiveRange(5, 16), reason: d.name);
        for (final litter in emitted) {
          expect(nav.route(d.start, litter.position), isNotEmpty);
          expect(d.canStand(litter.position, clearance: 20), isTrue);
        }
        expect(s.totalCollected, 0); // Throwing alone never earns rank.
        expect(s.events, contains('The thief got away'));
        await s.flush();
        s.dispose();
      }
      expect(durations.length, greaterThan(1));
    },
  );

  test(
    'thief uses reserved capacity and its trail and cooldown survive reloading',
    () async {
      final store = MemoryStore(),
          s = GameState(MemoryStore())..introduced = true;
      final d = districts[0];
      s.streetLitter[0] = createLitter(0, 0).take(d.streetLitterLimit).toList();
      final nav = CityNavigation(d), dropped = <Litter>[];
      final encounter = ThiefEncounter(
        s,
        nav,
        Random(55),
        (i, _) => dropped.add(i),
      );
      expect(encounter.spawn(), isTrue);
      s.position = encounter.actor!.position;
      for (var i = 0; i < 700 && encounter.actor != null; i++) {
        encounter.update(.05);
      }
      expect(dropped, isNotEmpty);
      expect(s.streetLitter[0].length, greaterThan(d.streetLitterLimit));
      expect(s.streetLitter[0].length, lessThanOrEqualTo(d.maximumLitterCount));
      expect(s.dropLitter(dropped.first.position), isNull);
      await s.flush();
      store.value = (s.store as MemoryStore).value;
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(
        loaded.streetLitter[0].map((i) => i.id),
        s.streetLitter[0].map((i) => i.id),
      );
      expect(loaded.thiefWaitMs, s.thiefWaitMs);
      loaded.tick();
      expect(loaded.thiefWaitMs, s.thiefWaitMs); // No offline spawning.
      await loaded.flush();
      s.dispose();
      loaded.dispose();
    },
  );

  test(
    'no thief before onboarding, no test preview in regular game, finite cleanup quota',
    () async {
      final s = GameState(MemoryStore());
      final e = ThiefEncounter(
        s,
        CityNavigation(districts[0]),
        Random(2),
        (_, _) {},
      );
      e.update(100);
      expect(e.actor, isNull);
      expect(e.spawn(preview: true), isFalse);
      s.introduced = true;
      s.streetLitter[0].clear();
      s.removed[0].addAll([for (var i = 0; i < s.cleanupTarget; i++) '0:0:$i']);
      expect(e.spawn(), isFalse);
      expect(s.dropLitter(districts[0].start, fromThief: true), isNull);
      await s.flush();
      s.dispose();
    },
  );

  test(
    'ranks advance on unique collected litter and survive renewal and restart',
    () async {
      final store = MemoryStore(), s = GameState(MemoryStore());
      for (var i = 1; i < cleanupRanks.length; i++) {
        expect(cleanupRankIndex(cleanupRanks[i].required - 1), i - 1);
        expect(cleanupRankIndex(cleanupRanks[i].required), i);
      }
      s.totalCollected = 99;
      final item = s.streetLitter[0].first;
      expect(s.collect(item), isTrue);
      expect(cleanupRankIndex(s.totalCollected), 1);
      expect(s.events.where((e) => e == 'New rank: Bronze!').length, 1);
      expect(s.collect(item), isFalse);
      expect(s.totalCollected, 100);
      s.bag.clear();
      s.streetLitter[0].clear();
      s.removed[0].addAll([for (var i = 0; i < s.cleanupTarget; i++) '0:0:$i']);
      s.position = districts[0].station + const Offset(0, 80);
      expect(s.nextCleanup(), isTrue);
      expect(s.totalCollected, 100);
      await s.flush();
      store.value = (s.store as MemoryStore).value;
      final loaded = GameState(store);
      await loaded.load();
      expect(cleanupRankIndex(loaded.totalCollected), 1);
      loaded.unlockTestContent();
      expect(
        loaded.totalCollected,
        100,
      ); // Unlocking gear does not fake a score.
      await loaded.flush();
      s.dispose();
      loaded.dispose();
    },
  );

  test(
    'a fresh regular install starts with only starter content and no test controls',
    () async {
      final s = await loadGameState(
        testBuild: false,
        normalStore: MemoryStore(),
      );
      expect(s.testMode, isFalse);
      expect(s.unlockedMaps, {0});
      expect(s.ownedOutfits, {0});
      expect(s.level, 1);
      expect(s.coins, 0);
      expect(s.gems, 0);
      expect(s.totalCollected, 0);
      expect(s.upgrades.every((u) => u == 0), isTrue);
      await s.flush();
      s.dispose();
    },
  );
}

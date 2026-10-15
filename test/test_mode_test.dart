import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/state/bootstrap.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'test build unlocks all content in a separate persistent save',
    () async {
      final normal = MemoryStore(), sandbox = MemoryStore();
      final original = GameState(normal)
        ..coins = 417
        ..gems = 3;
      original.collect(original.streetLitter[0].first);
      await original.save();
      final untouched = normal.value;
      final test = await loadGameState(
        testBuild: true,
        normalStore: normal,
        testStore: sandbox,
      );
      expect(test.testMode, isTrue);
      expect(test.level, 100);
      expect(test.coins, 1000000);
      expect(test.gems, 10000);
      expect(test.bag.length, 1);
      expect(test.upgrades.every((v) => v == maxUpgradeLevel), isTrue);
      expect(test.projects.every((v) => v == 3), isTrue);
      for (final d in districts) {
        expect(test.travel(d.id), isTrue);
      }
      for (final o in outfits) {
        expect(test.equipOutfit(outfits.indexOf(o)), isTrue);
      }
      expect(test.activateMagnet(), isTrue);
      test.refillTestSupplies();
      expect(test.magnetCooldown, 0);
      test.setTestGear(false);
      expect(test.capacity, 16);
      expect(test.processingSeconds, 15);
      test.setTestGear(true);
      expect(test.capacity, 64);
      expect(test.processingSeconds, 3);
      await test.flush();
      expect(normal.value, untouched);
      final reopened = await loadGameState(
        testBuild: true,
        normalStore: normal,
        testStore: sandbox,
      );
      expect(reopened.district, 5);
      expect(reopened.outfit, outfits.length - 1);
      expect(reopened.testMode, isTrue);
      expect(reopened.isUnlocked(5), isTrue);
      final regular = await loadGameState(
        testBuild: false,
        normalStore: normal,
        testStore: sandbox,
      );
      expect(regular.testMode, isFalse);
      expect(regular.coins, 417);
      expect(regular.gems, 3);
      expect(regular.level, 1);
      expect(regular.isUnlocked(5), isFalse);
      regular.unlockMap(5);
      regular.refillTestSupplies();
      regular.setTestGear(true);
      expect(regular.coins, 417);
      expect(regular.capacity, 16);
      await regular.flush();
      await reopened.flush();
      original.dispose();
      test.dispose();
      reopened.dispose();
      regular.dispose();
    },
  );

  test(
    'v3 streets are retained on update without losing collected progress or resetting currency',
    () async {
      final store = MemoryStore();
      final old = GameState(store);
      final data = old.toJson()
        ..['version'] = 3
        ..['coins'] = 881
        ..['gems'] = 12
        ..['streetLitter'] = [
          for (final d in districts)
            createLitter(d.id, 0)
                .take(d.id == 0 ? 36 : 48)
                .map((i) => [i.id, i.position.dx, i.position.dy, i.kind.index])
                .toList(),
        ];
      store.value = jsonEncode(data);
      final state = GameState(store);
      await state.load();
      expect(state.recoveredSave, isFalse);
      expect(state.coins, 881);
      expect(state.gems, 12);
      expect(state.totalCollected, 0);
      expect(state.removed[0], isEmpty);
      for (final d in districts) {
        expect(state.streetLitter[d.id].length, d.initialLitterCount);
      }
      expect(state.streetLitter[0].length, districts[0].initialLitterCount);
      final usedIds = state.streetLitter[0].map((i) => i.id).toSet();
      state.collect(state.streetLitter[0].first);
      final emitted = state.dropLitter(createLitter(0, 0).first.position);
      expect(emitted, isNotNull);
      expect(
        usedIds,
        isNot(contains(emitted!.id)),
      ); // New unique item, never a previously collected ID.
      await state.flush();
      final reload = GameState(store);
      await reload.load();
      expect(reload.streetLitter[0].length, districts[0].initialLitterCount);
      expect(reload.totalCollected, 1);
      expect(reload.coins, 881);
      await reload.flush();
      old.dispose();
      state.dispose();
      reload.dispose();
    },
  );
}

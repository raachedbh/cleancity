import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/data/city_events.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  late GameState s;
  late MemoryStore store;
  late DateTime time;
  setUp(() {
    store = MemoryStore();
    time = DateTime.utc(2026, 10, 9);
    s = GameState(store, now: () => time)..introduced = true;
  });
  tearDown(() async {
    await s.flush();
    s.dispose();
  });
  void collect(int count) {
    for (final item in s.streetLitter[s.district].take(count).toList()) {
      expect(s.collect(item), isTrue);
    }
  }

  void recycle() {
    s.position = districts[s.district].station + const Offset(0, 80);
    expect(s.startRecycling(), isTrue);
  }

  void finish() {
    time = time.add(const Duration(seconds: 20));
    s.tick();
  }

  test(
    'offers use active play time; invitations and progress never expire',
    () async {
      s.introduced = false;
      s.advanceCityEvents(50);
      expect(s.cityEvent, isNull);
      s.introduced = true;
      s.advanceCityEvents(119);
      time = time.add(const Duration(days: 90));
      s.tick();
      expect(s.cityEvent, isNull);
      expect(s.cityEventWaitMs, 1000);
      s.advanceCityEvents(1);
      expect(s.cityEvent!.joined, isFalse);
      collect(1);
      expect(s.cityEvent!.progress, 0);
      expect(s.joinCityEvent(), isTrue);
      expect(s.joinCityEvent(), isFalse);
      collect(3);
      time = time.add(const Duration(days: 365));
      s.tick();
      s.advanceCityEvents(100000);
      expect(s.cityEvent!.progress, 3);
      await s.save();
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.cityEvent!.progress, 3);
      expect(loaded.cityEvent!.joined, isTrue);
      await loaded.flush();
      loaded.dispose();
    },
  );
  test('joining and collecting are bound to the host city', () {
    s.advanceCityEvents(120);
    s.unlockedMaps.add(1);
    s.travel(1);
    expect(s.joinCityEvent(), isFalse);
    s.travel(0);
    expect(s.joinCityEvent(), isTrue);
    collect(2);
    final previousItem = s.streetLitter[0].first;
    s.travel(1);
    collect(2);
    expect(s.cityEvent!.progress, 2);
    expect(s.collect(previousItem), isFalse);
    s.travel(0);
    expect(s.collect(previousItem), isTrue);
    expect(s.collect(previousItem), isFalse);
    expect(s.cityEvent!.progress, 3);
  });
  test('event rewards are explicit, paid once and survive restart', () async {
    s.xp = xpForLevel(100);
    s.advanceCityEvents(120);
    s.joinCityEvent();
    expect(s.claimCityEvent(), isFalse);
    collect(13);
    expect(s.cityEvent!.progress, 12);
    expect(s.cityEvent!.ready, isTrue);
    final before = s.coins, xp = s.xp;
    expect(s.claimCityEvent(), isTrue);
    expect(s.coins, before + cityEvents[0].coins);
    expect(s.xp, xp + cityEvents[0].xp);
    expect(s.claimCityEvent(), isFalse);
    expect(s.completedCityEvents, 1);
    await s.flush();
    final loaded = GameState(store, now: () => time);
    await loaded.load();
    expect(loaded.cityEvent, isNull);
    expect(loaded.claimCityEvent(), isFalse);
    expect(loaded.completedCityEvents, 1);
    expect(loaded.cityEventWaitMs, 360000);
    loaded.advanceCityEvents(359);
    expect(loaded.cityEvent, isNull);
    loaded.advanceCityEvents(1);
    expect(loaded.cityEvent!.type, 1);
    expect(loaded.cityEvent!.id, 2);
    await loaded.flush();
    loaded.dispose();
  });
  test('bottle hunt only counts bottles and skipping has no cost', () {
    s.cityEventSequence = 1;
    s.advanceCityEvents(120);
    s.joinCityEvent();
    var bottles = 0;
    for (final item in s.streetLitter[0].take(16).toList()) {
      s.collect(item);
      if (item.kind == MaterialKind.bottle) bottles++;
    }
    expect(
      s.cityEvent!.progress,
      bottles.clamp(0, s.cityEvent!.definition.target),
    );
    final coins = s.coins, xp = s.xp;
    s.leaveCityEvent();
    expect(s.coins, coins);
    expect(s.xp, xp);
    expect(s.completedCityEvents, 0);
    expect(s.cityEvent, isNull);
    s.advanceCityEvents(420);
    expect(s.cityEvent!.type, 2);
  });
  test('recycling rally excludes batches started before joining', () {
    s.cityEventSequence = 2;
    s.advanceCityEvents(120);
    collect(8);
    recycle();
    expect(s.jobs[0]!.cityEventId, isNull);
    s.joinCityEvent();
    finish();
    expect(s.cityEvent!.progress, 0);
    collect(8);
    recycle();
    expect(s.jobs[0]!.cityEventId, s.cityEvent!.id);
    finish();
    expect(s.cityEvent!.progress, 8);
    s.tick();
    expect(s.cityEvent!.progress, 8);
  });
  test('offline recycling credits only host-city items, once', () async {
    s.upgrades[0] = maxUpgradeLevel;
    s.upgrades[4] = maxUpgradeLevel;
    s.cityEventSequence = 2;
    s.advanceCityEvents(120);
    s.joinCityEvent();
    collect(20);
    s.unlockedMaps.add(1);
    s.travel(1);
    collect(4);
    s.travel(0);
    recycle();
    await s.flush();
    time = time.add(const Duration(days: 3));
    final loaded = GameState(store, now: () => time);
    await loaded.load();
    expect(loaded.cityEvent!.progress, 20);
    expect(loaded.cityEvent!.ready, isTrue);
    expect(loaded.totalRecycled, 24);
    loaded.tick();
    expect(loaded.cityEvent!.progress, 20);
    expect(loaded.claimCityEvent(), isTrue);
    await loaded.flush();
    loaded.dispose();
  });
  test('abandoned batch cannot credit a new event of the same kind', () {
    s.cityEventSequence = 2;
    s.advanceCityEvents(120);
    s.joinCityEvent();
    collect(8);
    recycle();
    final oldId = s.cityEvent!.id;
    s.leaveCityEvent();
    s.cityEventSequence = 5;
    s.advanceCityEvents(420);
    s.joinCityEvent();
    expect(s.cityEvent!.id, isNot(oldId));
    finish();
    expect(s.cityEvent!.progress, 0);
  });
  test('test event preview is restricted to the test build', () {
    s.offerTestCityEvent();
    expect(s.cityEvent, isNull);
    s.unlockTestContent();
    s.offerTestCityEvent();
    expect(s.cityEvent!.type, 0);
    s.offerTestCityEvent();
    expect(s.cityEvent!.type, 1);
  });
  test('invalid optional event does not discard a valid save', () async {
    s.coins = 491;
    store.value = jsonEncode(s.toJson()..['cityEvent'] = {'id': 8, 'type': 99});
    final loaded = GameState(store, now: () => time);
    await loaded.load();
    expect(loaded.recoveredSave, isFalse);
    expect(loaded.coins, 491);
    expect(loaded.cityEvent, isNull);
    await loaded.flush();
    loaded.dispose();
  });
  test('new outfits use advertised currency and ownership persists', () async {
    s.coins = 100000;
    s.gems = 150;
    for (var id = 6; id < outfits.length; id++) {
      final beforeCoins = s.coins, beforeGems = s.gems;
      expect(s.equipOutfit(id), isTrue);
      expect(s.coins, beforeCoins - outfits[id].price);
      expect(s.gems, beforeGems - outfits[id].gems);
      final once = (s.coins, s.gems);
      expect(s.equipOutfit(id), isTrue);
      expect((s.coins, s.gems), once);
    }
    await s.flush();
    final loaded = GameState(store, now: () => time);
    await loaded.load();
    expect(loaded.outfit, 11);
    expect(loaded.ownedOutfits, containsAll([0, 6, 7, 8, 9, 10, 11]));
    await loaded.flush();
    loaded.dispose();
  });
}

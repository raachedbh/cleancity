import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/game/navigation.dart';

class MemoryStore implements SaveStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    if (fail) throw StateError('disk unavailable');
    value = next;
  }
}

void main() {
  late MemoryStore store;
  late GameState s;
  late DateTime time;
  setUp(() {
    store = MemoryStore();
    time = DateTime.utc(2026, 10, 8, 12);
    s = GameState(store, now: () => time);
  });
  tearDown(() async {
    await s.flush();
    s.dispose();
  });
  void advance(Duration d) {
    time = time.add(d);
    s.tick();
  }

  void fill([int count = 16]) {
    for (var n = 0; n < count; n++) {
      if (s.bag.length >= s.capacity) break;
      if (s.streetLitter[s.district].isEmpty) {
        for (final point in createLitter(s.district, s.cycles[s.district])) {
          if (s.dropLitter(point.position) != null) break;
        }
      }
      s.collect(s.streetLitter[s.district].first);
    }
  }

  void atStation() {
    s.position = districts[s.district].station + const Offset(0, 80);
  }

  test(
    'automatic pickups are unique and a full bag leaves remaining litter',
    () {
      final litter = createLitter(0, 0);
      expect(s.collect(litter.first), isTrue);
      expect(s.collect(litter.first), isFalse);
      fill(30);
      expect(s.bag.length, 16);
      expect(s.totalCollected, 16);
      expect(s.collect(litter[16]), isFalse);
      expect(s.removed[0].contains(litter[16].id), isFalse);
    },
  );
  test('recycling takes 15 seconds, frees bag space, pays exactly once', () {
    fill();
    final value = s.bagValue;
    s.position = const Offset(900, 950);
    expect(s.startRecycling(), isFalse);
    atStation();
    expect(s.startRecycling(), isTrue);
    expect(s.bag, isEmpty);
    expect(s.coins, 0);
    expect(s.totalRecycled, 0);
    fill(1);
    expect(s.startRecycling(), isFalse);
    advance(const Duration(seconds: 14));
    expect(s.coins, 0);
    advance(const Duration(seconds: 1));
    expect(s.coins, value);
    expect(s.totalRecycled, 16);
    expect(s.recycledByDistrict[0], 16);
    s.tick();
    expect(s.coins, value);
    expect(s.bag.length, 1);
  });
  test(
    'offline jobs survive restart and preserve their locked payout',
    () async {
      fill(8);
      atStation();
      final value = s.batchValue;
      s.startRecycling();
      await s.flush();
      time = time.add(const Duration(minutes: 2));
      final restored = GameState(store, now: () => time);
      await restored.load();
      expect(restored.jobs, isEmpty);
      expect(restored.coins, value);
      expect(restored.totalRecycled, 8);
      restored.tick();
      await restored.flush();
      final again = GameState(store, now: () => time);
      await again.load();
      expect(again.coins, value);
      expect(again.totalRecycled, 8);
      restored.dispose();
      await again.flush();
      again.dispose();
    },
  );
  test(
    'batch capacity leaves excess inventory and speed upgrades only affect new batches',
    () {
      s.upgrades[0] = 2;
      fill(30);
      atStation();
      s.startRecycling();
      expect(s.bag.length, 14);
      expect(s.jobs[0]!.items.length, 16);
      s.upgrades[3] = 6;
      expect(s.processingSeconds, 3);
      advance(const Duration(seconds: 3));
      expect(s.jobs, isNotEmpty);
      advance(const Duration(seconds: 12));
      expect(s.totalRecycled, 16);
      s.startRecycling();
      advance(const Duration(seconds: 3));
      expect(s.totalRecycled, 30);
    },
  );
  test('mixed city bags pay based on origin and credit each city once', () {
    fill(2);
    s.unlockedMaps.add(1);
    s.travel(1);
    fill(3);
    final expected = s.valueOf(s.bag);
    atStation();
    s.startRecycling();
    s.travel(0);
    advance(const Duration(seconds: 15));
    expect(s.coins, expected);
    expect(s.recycledByDistrict.take(2), [2, 3]);
    expect(s.totalRecycled, 5);
  });
  test(
    'level rewards and level 5 magnet unlock persist without duplicate awards',
    () async {
      s.xp = xpForLevel(5) - 1;
      fill(1);
      expect(s.level, 5);
      expect(s.coins, 95);
      expect(s.magnetUnlocked, isTrue);
      await s.flush();
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.coins, 95);
      expect(loaded.level, 5);
      await loaded.flush();
      loaded.dispose();
    },
  );
  test('level 10 receives both the five-level and ten-level bonuses', () {
    s.xp = xpForLevel(10) - 1;
    fill(1);
    expect(s.coins, 430);
    expect(s.level, 10);
  });
  test(
    'magnet lasts 15 seconds then recharges for 90, including after restart',
    () async {
      expect(s.activateMagnet(), isFalse);
      s.xp = xpForLevel(5);
      expect(s.activateMagnet(), isTrue);
      expect(s.pickupRadius, greaterThan(180));
      expect(s.activateMagnet(), isFalse);
      advance(const Duration(seconds: 14));
      expect(s.magnetActive, isTrue);
      advance(const Duration(seconds: 1));
      expect(s.magnetActive, isFalse);
      expect(s.magnetCooldown, 90);
      await s.save();
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.activateMagnet(), isFalse);
      time = time.add(const Duration(seconds: 90));
      expect(loaded.activateMagnet(), isTrue);
      await loaded.flush();
      loaded.dispose();
    },
  );
  test(
    'gear and outfits enforce prices, maximum levels and separate currencies',
    () {
      expect(outfits[1].price, 1000);
      expect(s.buyUpgrade(Upgrade.bag), isFalse);
      s.coins = 1350;
      expect(s.buyUpgrade(Upgrade.bag), isTrue);
      expect(s.capacity, 24);
      expect(s.equipOutfit(1), isTrue);
      expect(s.coins, 0);
      expect(s.equipOutfit(0), isTrue);
      expect(s.equipOutfit(1), isTrue);
      expect(s.coins, 0);
      s.coins = 100000;
      expect(s.equipOutfit(4), isFalse);
      s.gems = 35;
      expect(s.equipOutfit(4), isTrue);
      expect(s.gems, 0);
      expect(s.coins, 100000);
      s.upgrades[0] = maxUpgradeLevel;
      expect(s.buyUpgrade(Upgrade.bag), isFalse);
    },
  );
  test(
    'coin maps require both level and price; their bonus is awarded once',
    () {
      expect(s.travel(1), isFalse);
      s.coins = 4500;
      expect(s.unlockMap(1), isFalse);
      s.xp = xpForLevel(10);
      s.coins = 4499;
      expect(s.unlockMap(1), isFalse);
      s.coins = 4500;
      expect(s.unlockMap(1), isTrue);
      expect(s.coins, 350);
      expect(s.unlockMap(1), isFalse);
      expect(s.coins, 350);
      expect(s.travel(1), isTrue);
      expect(s.position, districts[1].start);
    },
  );
  test(
    'premium map is gems only and includes the skin and unlock bonus once',
    () {
      s.coins = 1000000;
      s.xp = xpForLevel(100);
      s.gems = 79;
      expect(s.unlockMap(5), isFalse);
      s.gems = 80;
      expect(s.unlockMap(5), isTrue);
      expect(s.gems, 0);
      expect(s.coins, 1001200);
      expect(s.ownedOutfits, contains(4));
      expect(s.unlockMap(5), isFalse);
      expect(s.coins, 1001200);
      s.unlockedMaps.remove(4);
      s.coins = 65000;
      expect(s.unlockMap(4), isTrue);
      expect(s.ownedOutfits, contains(5));
    },
  );
  test(
    'daily check-in is idempotent, day 7 grants 5 gems and day 8 cycles',
    () async {
      for (var day = 1; day <= 7; day++) {
        expect(s.checkIn(), isTrue);
        expect(s.dailyStreak, day);
        expect(s.checkIn(), isFalse);
        if (day < 7) time = time.add(const Duration(days: 1));
      }
      expect(s.gems, 5);
      expect(s.coins, dailyCoins.reduce((a, b) => a + b));
      await s.flush();
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.checkIn(), isFalse);
      expect(loaded.gems, 5);
      time = time.add(const Duration(days: 1));
      expect(loaded.checkIn(), isTrue);
      expect(loaded.dailyStreak, 1);
      await loaded.flush();
      loaded.dispose();
    },
  );
  test(
    'missed day resets streak without removing currency; clock rollback cannot re-claim',
    () {
      s.checkIn();
      time = time.add(const Duration(days: 1));
      s.tick();
      s.checkIn();
      final earned = s.coins;
      time = time.add(const Duration(days: 2));
      s.tick();
      s.checkIn();
      expect(s.dailyStreak, 1);
      expect(s.coins, earned + 25);
      time = time.subtract(const Duration(days: 1));
      s.tick();
      expect(s.checkIn(), isFalse);
      expect(s.coins, earned + 25);
    },
  );
  test(
    'daily weekly monthly counters and claims reset independently at UTC boundaries',
    () {
      time = DateTime.utc(2026, 10, 11, 23, 59, 59);
      s.tick();
      for (final p in GoalPeriod.values) {
        s.goals[p]!.collected = 1500;
      }
      final daily = missions[0], weekly = missions[2];
      expect(s.claim(daily), isTrue);
      expect(s.claim(daily), isFalse);
      expect(s.claim(weekly), isTrue);
      advance(const Duration(seconds: 1)); // Monday, new day and week
      expect(s.progress(daily), 0);
      expect(s.progress(weekly), 0);
      expect(s.progress(missions[4]), 1500);
      expect(s.isClaimed(daily), isFalse);
      time = DateTime.utc(2026, 11, 1);
      s.tick();
      expect(s.progress(missions[4]), 0);
    },
  );
  test(
    'only difficult challenge completions award the configured 1 or 2 gems',
    () {
      s.tick();
      expect(s.claim(missions[3]), isFalse);
      s.goals[GoalPeriod.weekly]!.recycled = 2200;
      expect(s.claim(missions[3]), isTrue);
      expect(s.gems, 1);
      expect(s.claim(missions[3]), isFalse);
      s.goals[GoalPeriod.monthly]!.recycled = 12000;
      expect(s.claim(missions[5]), isTrue);
      expect(s.gems, 3);
    },
  );
  test(
    'offline recycling uses completion date, not return date, for calendar goals',
    () async {
      time = DateTime.utc(2026, 10, 8, 23, 59, 40);
      fill(2);
      atStation();
      s.startRecycling();
      await s.flush();
      time = DateTime.utc(2026, 10, 9, 1);
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.totalRecycled, 2);
      expect(loaded.progress(missions[1]), 0);
      expect(loaded.progress(missions[3]), 2);
      expect(loaded.progress(missions[5]), 2);
      await loaded.flush();
      loaded.dispose();
    },
  );
  test(
    'restoration stays separate from map unlocks and requires work plus coins',
    () {
      s.coins = 10000;
      expect(s.restore(), isFalse);
      s.recycledByDistrict[0] = 1200;
      expect(s.restore(), isTrue);
      expect(s.restore(), isTrue);
      expect(s.restore(), isTrue);
      expect(s.restore(), isFalse);
      expect(s.isUnlocked(1), isFalse);
    },
  );
  test('cleanup renews only after finishing and processing every item', () {
    atStation();
    for (final item in createLitter(0, 0)) {
      if (s.bag.length == s.capacity) {
        s.startRecycling();
        advance(const Duration(seconds: 15));
      }
      final active = s.streetLitter[0]
          .where((v) => v.id == item.id)
          .firstOrNull;
      final next = active ?? s.dropLitter(item.position);
      expect(next, isNotNull);
      expect(s.collect(next!), isTrue);
    }
    expect(s.nextCleanup(), isFalse);
    s.startRecycling();
    expect(s.nextCleanup(), isFalse);
    advance(const Duration(seconds: 15));
    expect(s.nextCleanup(), isTrue);
    expect(s.cycles[0], 1);
    expect(s.removed[0], isEmpty);
    expect(s.collect(createLitter(0, 0).first), isFalse);
    expect(s.collect(createLitter(0, 1).first), isTrue);
  });
  test(
    'legacy save migration keeps currency, outfits, upgrades, inventory and unlocked maps',
    () async {
      store.value = jsonEncode({
        'version': 1,
        'coins': 2345,
        'district': 2,
        'outfit': 3,
        'upgrades': [2, 1, 3],
        'projects': [3, 0, 0],
        'cycles': [2, 1, 0],
        'recycledByDistrict': [70, 12, 0],
        'removed': [
          ['0:2:0'],
          [],
          [],
        ],
        'bag': [
          [0, 1],
          [2, 2],
        ],
        'ownedOutfits': [0, 1, 3],
        'claimedMissions': ['first_steps'],
        'totalCollected': 99,
        'totalRecycled': 82,
        'totalEarned': 3900,
        'position': [800, 695],
        'introduced': true,
        'sound': false,
        'haptics': false,
      });
      await s.load();
      expect(s.recoveredSave, isFalse);
      expect(s.coins, 2345);
      expect(s.gems, 0);
      expect(s.xp, 345);
      expect(s.district, 2);
      expect(s.isUnlocked(1), isTrue);
      expect(s.isUnlocked(2), isTrue);
      expect(s.outfit, 3);
      expect(s.bag.length, 2);
      expect(s.upgrades, [2, 1, 3, 0, 0]);
      expect(s.position, districts[2].start);
      expect(s.removed[0], isEmpty);
      expect(s.projects.length, 6);
      expect(s.projects.first, 3);
      expect(jsonDecode(store.value!)['version'], 18);
    },
  );
  test(
    'current saves preserve paid-with-earned-gems unlocks, goals, timers and equipment',
    () async {
      s.gems = 100;
      s.unlockMap(5);
      s.equipOutfit(4);
      s.travel(5);
      fill(4);
      atStation();
      s.startRecycling();
      s.checkIn();
      s.tick();
      await s.save();
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.toJson(), s.toJson());
      expect(loaded.recoveredSave, isFalse);
      await loaded.flush();
      loaded.dispose();
    },
  );
  test(
    'failed saves can recover and malformed saves never partially apply',
    () async {
      store.fail = true;
      s.setSound(false);
      await s.flush();
      expect(s.saveFailed, isTrue);
      store.fail = false;
      s.setHaptics(false);
      await s.flush();
      expect(s.saveFailed, isFalse);
      store.value = '{"version":2,"coins":900,"bag":"invalid"}';
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.recoveredSave, isTrue);
      expect(loaded.coins, 0);
      expect(loaded.bag, isEmpty);
      loaded.dispose();
    },
  );
  test(
    'every item across six expanding maps has an unobstructed route from spawn',
    () {
      var lastArea = 0.0;
      for (final d in districts) {
        expect(d.worldSize.width * d.worldSize.height, greaterThan(lastArea));
        lastArea = d.worldSize.width * d.worldSize.height;
        final nav = CityNavigation(d), litter = createLitter(d.id, 0);
        expect(litter.length, d.litterCount);
        expect(litter.map((v) => v.id).toSet().length, d.litterCount);
        for (final item in litter) {
          expect(d.canStand(item.position), isTrue);
          expect(
            d.stations.every((p) => (item.position - p).distance >= 105),
            isTrue,
          );
          final route = nav.route(d.start, item.position);
          expect(route, isNotEmpty, reason: '${d.name} ${item.id}');
          expect((route.last - item.position).distance, lessThan(.1));
          var from = d.start;
          for (final to in route) {
            expect(nav.visible(from, to), isTrue);
            from = to;
          }
        }
      }
    },
  );
}

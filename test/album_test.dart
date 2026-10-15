import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/album.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/city_life.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/game/thief_encounter.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'police lots stay off roads and buildings; entrances reachable in all cities',
    () {
      for (final d in districts) {
        final layout = d.layout, nav = CityNavigation(d);
        expect(
          layout.roadHits(layout.policeBounds, setback: 26),
          isFalse,
          reason: d.name,
        );
        expect(
          layout.buildingEnvelopes.values.any(
            (r) => r.overlaps(layout.policeBounds),
          ),
          isFalse,
        );
        expect(d.canStand(layout.police), isFalse);
        expect(d.canStand(layout.policeEntrance), isTrue);
        final route = nav.route(d.start, layout.policeEntrance);
        expect(route, isNotEmpty, reason: d.name);
        expect((route.last - layout.policeEntrance).distance, lessThan(30));
        var from = d.start;
        for (final to in route) {
          expect(nav.visible(from, to), isTrue);
          from = to;
        }
      }
    },
  );

  test(
    'caught thieves drop random reachable valuables once in every city',
    () async {
      final kinds = <ValuableKind>{}, counts = <int>{};
      for (final d in districts) {
        final s = GameState(MemoryStore())
          ..introduced = true
          ..district = d.id
          ..position = d.start;
        final nav = CityNavigation(d),
            thief = ThiefEncounter(
              s,
              CityNavigation(d),
              Random(d.id + 71),
              (_, _) {},
            );
        thief.actor = ThiefActor(s.position)
          ..running = true
          ..runTime = 1;
        thief.update(.05);
        expect(s.album.drops.length, inInclusiveRange(2, 4));
        expect(s.album.totalFound, 0);
        counts.add(s.album.drops.length);
        for (final drop in s.album.drops) {
          kinds.add(drop.kind);
          expect(d.canStand(drop.position), isTrue);
          expect(nav.visible(d.start, drop.position), isTrue);
          expect(drop.district, d.id);
        }
        final count = s.album.drops.length;
        thief.update(.05);
        expect(s.album.drops.length, count);
        expect(s.thievesCaught, 1);
        await s.flush();
        s.dispose();
      }
      expect(kinds.length, 4);
      expect(counts.length, greaterThan(1));
    },
  );

  test(
    'pickups persist across travel and reload; full bags do not block them; police pays once',
    () async {
      final store = MemoryStore(),
          s = GameState(MemoryStore())..introduced = true;
      s.rewardCaughtThief(
        valuables: [
          for (final k in ValuableKind.values) (kind: k, position: s.position),
        ],
      );
      s.bag.addAll(List.filled(s.capacity, (kind: 0, district: 0)));
      final first = s.album.drops.first;
      s.position += const Offset(150, 0);
      expect(s.collectValuable(first.id), isFalse);
      s.position = first.position;
      expect(s.collectValuable(first.id), isTrue);
      expect(s.collectValuable(first.id), isFalse);
      expect(s.album.totalFound, 1);
      expect(s.bag.length, s.capacity);
      s.unlockedMaps.add(1);
      s.travel(1);
      expect(s.collectValuable(s.album.drops.first.id), isFalse);
      store.value = jsonEncode(s.toJson());
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.album.totalFound, 1);
      expect(loaded.album.drops.length, 3);
      expect(loaded.returnValuables(), 0);
      loaded.travel(0);
      for (final drop in loaded.album.drops.toList()) {
        loaded.position = drop.position;
        expect(loaded.collectValuable(drop.id), isTrue);
      }
      expect(loaded.album.carried, 4);
      loaded.position = districts[0].layout.policeEntrance;
      final before = loaded.coins;
      expect(loaded.returnValuables(), 18);
      expect(loaded.coins, before + 18);
      expect(loaded.returnValuables(), 0);
      expect(loaded.album.totalFound, 4);
      expect(loaded.album.totalReturned, 4);
      expect(loaded.album.carried, 0);
      await loaded.flush();
      final again = GameState(store);
      await again.load();
      expect(again.album.totalFound, 4);
      expect(again.album.totalReturned, 4);
      expect(again.album.drops, isEmpty);
      expect(again.returnValuables(), 0);
      expect(again.coins, before + 18);
      await s.flush();
      await again.flush();
      s.dispose();
      loaded.dispose();
      again.dispose();
    },
  );

  test(
    'legacy totals earn souvenirs, clock changes do not, and rewards never replay',
    () async {
      final old = GameState(MemoryStore())
        ..coins = 719
        ..totalRecycled = 100000
        ..totalCollected = 105000
        ..thievesCaught = 10;
      final raw = old.toJson()
        ..['version'] = 16
        ..remove('album')
        ..['thiefWaitMs'] = 1000
        ..['truckWaitMs'] = 1000
        ..['cityEventWaitMs'] = 1000;
      // Previously valid litter is now under the new kiosk. Preserve IDs/metadata.
      final streets = raw['streetLitter'] as List;
      final item = streets[0][0] as List;
      item[1] = districts[0].layout.police.dx;
      item[2] = districts[0].layout.police.dy;
      final store = MemoryStore()..value = jsonEncode(raw);
      final s = GameState(store);
      await s.load();
      expect(s.recoveredSave, isFalse);
      expect(s.coins, 719);
      expect(
        s.album.earned,
        containsAll(['recycled100000', 'thieves10', 'collected25000']),
      );
      expect(s.album.totalFound, 0);
      expect(s.album.carried, 0);
      expect(districts[0].canStand(s.streetLitter[0].first.position), isTrue);
      expect(s.streetLitter[0].first.id, item[0]);
      expect(s.thiefWaitMs, 150000);
      expect(s.truckWaitMs, 210000);
      expect(s.cityEventWaitMs, 120000);
      await s.flush();
      final again = GameState(store, now: () => DateTime.utc(2035));
      await again.load();
      expect(again.album.earned, s.album.earned);
      expect(again.coins, 719);
      expect(again.thiefWaitMs, 150000);
      expect(again.events.where((e) => e.contains('souvenir')), isEmpty);
      await again.flush();
      old.dispose();
      s.dispose();
      again.dispose();
    },
  );

  test(
    '100,000 recycling milestone unlocks on completed batch, not collection',
    () async {
      var time = DateTime.utc(2026);
      final s = GameState(MemoryStore(), now: () => time)
        ..introduced = true
        ..totalRecycled = 99999;
      s.collect(s.streetLitter[0].first);
      expect(s.album.earned, isNot(contains('recycled100000')));
      s.position = districts[0].station + const Offset(0, 80);
      s.startRecycling();
      time = time.add(const Duration(seconds: 16));
      s.tick();
      expect(s.totalRecycled, 100000);
      expect(s.album.earned, contains('recycled100000'));
      s.tick();
      expect(s.album.earned.where((id) => id == 'recycled100000').length, 1);
      await s.flush();
      s.dispose();
    },
  );

  test(
    'street encounters pause the other countdown and announce their city',
    () async {
      final s = GameState(MemoryStore())
        ..introduced = true
        ..thiefWaitMs = 0
        ..truckWaitMs = 0;
      final life = CityLife(s, CityNavigation(districts[0]));
      life.update(.05);
      expect(life.truck.actor, isNotNull);
      expect(life.thief.actor, isNull);
      expect(s.thiefWaitMs, 0);
      expect(s.cityAlerts.single.text, 'Trash truck nearby');
      life.truck.actor = null;
      s.truckWaitMs = 300000;
      life.update(.05);
      expect(life.thief.actor, isNotNull);
      expect(s.cityAlerts.last, (district: 0, text: 'Thief in the city'));
      final cooldown = s.truckWaitMs;
      life.update(.05);
      expect(s.truckWaitMs, cooldown);
      await s.flush();
      s.dispose();
    },
  );
}

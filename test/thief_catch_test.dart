import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/game/thief_encounter.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'catch pays 25 coins once, preserves cooldown and survives saving',
    () async {
      final store = MemoryStore(),
          s = GameState(MemoryStore())..introduced = true;
      final e = ThiefEncounter(
        s,
        CityNavigation(districts[0]),
        Random(7),
        (_, _) {},
      );
      expect(e.spawn(), isTrue);
      final t = e.actor!;
      s.position = t.position;
      e.update(.05);
      expect(
        t.caught,
        isFalse,
      ); // Time to start fleeing before a catch is possible.
      for (var i = 0; i < 20; i++) {
        e.update(.05);
      }
      final before = s.coins, cooldown = s.thiefWaitMs;
      s.position = t.position;
      e.update(.05);
      expect(t.caught, isTrue);
      expect(s.coins, before + 25);
      expect(s.thievesCaught, 1);
      expect(s.playerRewardText, 'Caught! +25 coins');
      for (var i = 0; i < 30; i++) {
        e.update(.05);
      }
      expect(e.actor, isNull);
      expect(s.coins, before + 25);
      expect(s.events, isNot(contains('The thief got away')));
      expect(s.thiefWaitMs, lessThanOrEqualTo(cooldown));
      await s.flush();
      store.value = (s.store as MemoryStore).value;
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.coins, before + 25);
      expect(loaded.thievesCaught, 1);
      expect(loaded.playerRewardSequence, 0); // A reload cannot replay payment.
      await loaded.flush();
      s.dispose();
      loaded.dispose();
    },
  );

  test(
    'catch cannot reach through a building corner or reward an escaped thief',
    () async {
      final d = districts[0], s = GameState(MemoryStore())..introduced = true;
      final nav = CityNavigation(d),
          e = ThiefEncounter(s, CityNavigation(d), Random(3), (_, _) {});
      final wall = d.blocks[d.layout.buildings.keys.first];
      s.position = Offset(wall.left - 15, wall.top + 10);
      final t = ThiefActor(Offset(wall.left + 10, wall.top - 15))
        ..running = true
        ..runTime = 1;
      e.actor = t;
      expect((t.position - s.position).distance, lessThan(44));
      expect(nav.visible(s.position, t.position), isFalse);
      e.update(.05);
      expect(t.caught, isFalse);
      expect(s.coins, 0);
      t.fade = .1;
      s.position = t.position;
      e.update(.05);
      expect(t.caught, isFalse);
      expect(s.coins, 0);
      await s.flush();
      s.dispose();
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greenhaven/main.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/trash_truck.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/ui/game_screen.dart';

class EventStore implements SaveStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    value = next;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'truck collision, timed pickups, apples and joystick auto-walk on Android',
    (tester) async {
      var time = DateTime.utc(2026, 10, 12, 12);
      final state = GameState(EventStore(), now: () => time)
        ..introduced = true
        ..sound = false
        ..haptics = false
        ..thiefWaitMs = 300000
        ..truckWaitMs = 300000;
      state.unlockTestContent();
      // Reproduce the installed phone's fully cleared legacy map with a bag
      // still awaiting recycling: the next active frame must restore supply.
      state.cleanupTargets[0] = 120;
      state.removed[0] = {for (var i = 0; i < 120; i++) '0:0:$i'};
      state.streetLitter[0].clear();
      state.bag.add((kind: 0, district: 0));
      await tester.pumpWidget(CleanCityApp(state: state));
      final screen = tester.state<GameScreenState>(find.byType(GameScreen));
      final game = screen.game;
      Future<void> frames([int count = 12]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }

      Future<void> until(bool Function() ready, {int limit = 200}) async {
        for (var i = 0; i < limit && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(ready(), isTrue);
      }

      await until(() => game.sceneReady.value);
      await frames();
      expect(state.cycles[0], 1);
      expect(state.streetLitter[0], isNotEmpty);
      expect(state.bag, contains((kind: 0, district: 0)));
      await binding.convertFlutterSurfaceToImage();
      Future<void> capture(String name) async {
        await frames();
        await tester.runAsync(() => binding.takeScreenshot(name));
      }

      await tester.tap(find.byKey(const ValueKey('settings-button')));
      await frames();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('test-truck')),
        180,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 30,
      );
      await frames();
      await tester.tap(find.byKey(const ValueKey('test-truck')));
      await frames();
      final encounter = game.life!.truck;
      final truck = encounter.actor!;
      final originalRoute = [...truck.route];
      truck.route
        ..clear()
        ..add(truck.position + const Offset(-300, 0));
      state.position = truck.position + const Offset(-82, 0);
      game.startAutoMove(const Offset(1, 0));
      await until(() => !game.autoMoving);
      expect(
        (state.position - truck.position).distance,
        greaterThanOrEqualTo(TrashTruck.radius + 12),
      );
      await capture('truck-solid');
      truck.route
        ..clear()
        ..addAll(originalRoute);
      state.position = districts[0].start;
      await until(() => truck.drops >= 2);
      final first = state.streetLitter[0].firstWhere(
        (i) => i.truckDroppedAt != null,
      );
      state.position = game.navigation!.nearestWalkable(
        first.position + const Offset(0, 130),
      );
      await capture('truck-trail');
      state.bag.clear();
      final before = state.coins;
      state.position = first.position;
      await until(() => state.removed[0].contains(first.id));
      expect(state.coins, greaterThanOrEqualTo(before + 8));
      await capture('truck-pickup-bonus');
      encounter.actor = null;
      state.truckWaitMs = 300000;
      time = time.add(const Duration(seconds: 32));
      final oldDrops = state.streetLitter[0]
          .where((i) => i.truckDroppedAt != null)
          .toList();
      if (oldDrops.isNotEmpty) {
        expect(oldDrops.first.truckBonus(state.nowMs), 1);
      }

      state.position = districts[0].start;
      final apples = game.life!.apples;
      apples.apples.clear();
      expect(apples.drop(preview: true), isTrue);
      final apple = apples.apples.first;
      state.position = game.navigation!.nearestWalkable(
        apple.position + const Offset(0, 80),
      );
      await capture('fallen-apple');
      state.position = apple.position;
      await until(() => apples.boostSeconds > 0);
      expect(apples.speedMultiplier, 1.35);
      expect(apples.boostSeconds, lessThanOrEqualTo(5));
      await capture('apple-speed-boost');
      await until(() => apples.boostSeconds == 0, limit: 60);
      expect(apples.speedMultiplier, 1);

      // Use a straight, open road for the actual double-tap gesture.
      state.position = const Offset(740, 1250);
      game.clearInput();
      await frames();
      final beforeWalk = state.position;
      final center = tester.getCenter(
        find.byKey(const ValueKey('movement-joystick')),
      );
      await tester.tapAt(center + const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(center + const Offset(40, 0));
      await tester.pump();
      expect(screen.joystick.autoMoving, isTrue);
      expect(game.autoMoving, isTrue);
      await frames();
      expect(state.position.dx, greaterThan(beforeWalk.dx + 30));
      await capture('joystick-auto-walk');
      await tester.tapAt(const Offset(210, 380));
      await frames();
      expect(screen.joystick.autoMoving, isFalse);
      expect(game.input, Offset.zero);
      await tester.tapAt(center + const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(center + const Offset(0, -40));
      await tester.tap(find.byKey(const ValueKey('nav-gear')));
      await frames();
      expect(game.autoMoving, isFalse);
      expect(screen.joystick.autoMoving, isFalse);
      Navigator.of(tester.element(find.byType(GameScreen))).pop();
      await frames();
      expect(state.travel(2), isTrue);
      final tunis = districts[2];
      state.position = tunis.layout.interviewAnchor! + const Offset(0, 100);
      await game.loadDistrict();
      await until(() => game.sceneReady.value);
      await capture('tunis-interview-live');
      expect(tunis.layout.interviewSpots.length, 3);
      game.walkTo(tunis.layout.interviewAnchor! + const Offset(140, 80));
      await until(() => game.target == null);
      expect(tunis.canStand(state.position), isTrue);
      await capture('tunis-interview-walking');
      state.position = game.navigation!.nearestWalkable(
        const Offset(1800, 1510),
      );
      await frames(30);
      await capture('tunis-bench-rows');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await state.flush();
      state.dispose();
    },
  );
}

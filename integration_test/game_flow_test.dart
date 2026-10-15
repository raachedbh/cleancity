import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greenhaven/main.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/ui/game_screen.dart';

class DeviceTestStore implements SaveStore {
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
    'CleanCity: full-screen streets, recycling timer, progression, shop and six maps',
    (tester) async {
      final store = DeviceTestStore();
      var time = DateTime.utc(2026, 10, 8, 12);
      final state = GameState(store, now: () => time)
        ..sound = false
        ..haptics = false
        ..thiefWaitMs = 300000
        ..truckWaitMs = 300000;
      // Isolated QA fixture. Production starts with zero coins and zero gems.
      state.coins = 150000;
      state.gems = 100;
      state.xp = xpForLevel(40);
      await tester.pumpWidget(CleanCityApp(state: state));
      Future<void> until(bool Function() condition, {int frames = 180}) async {
        for (var i = 0; i < frames && !condition(); i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(condition(), isTrue);
      }

      Future<void> uiFrames() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }

      Future<void> reveal(Finder finder, {double step = 180}) async {
        await tester.scrollUntilVisible(
          finder,
          step,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 40,
        );
        await uiFrames();
      }

      await uiFrames();
      final screen = tester.state<GameScreenState>(find.byType(GameScreen));
      await until(() => screen.game.sceneReady.value);
      await uiFrames();
      await reveal(find.byKey(const ValueKey('start-game')));
      await uiFrames();
      await tester.tap(find.byKey(const ValueKey('start-game')));
      await uiFrames();
      expect(state.introduced, isTrue);
      await until(() => screen.foreground && !screen.game.paused);
      expect(state.dailyStreak, 1);
      final world = tester.getSize(find.byKey(const ValueKey('game-world')));
      if (!screen.mounted) fail('Game screen was unexpectedly removed');
      final viewport = MediaQuery.sizeOf(screen.context);
      expect(world.width, viewport.width);
      expect(world.height, viewport.height);
      expect(
        screen.game.paused,
        isFalse,
        reason: 'Closing onboarding resumes the game',
      );

      final x = state.position.dx,
          stick = tester.getCenter(
            find.byKey(const ValueKey('movement-joystick')),
          );
      final gesture = await tester.startGesture(stick);
      await gesture.moveTo(stick + const Offset(30, 0));
      await tester.pump();
      expect(
        screen.game.input.dx,
        greaterThan(0),
        reason: 'Joystick drag reaches the game',
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      expect(state.position.dx, greaterThan(x + 15));
      screen.game.clearInput();
      final beforeTap = state.position;
      const touchPoint = Offset(230, 330);
      await tester.tapAt(touchPoint);
      await uiFrames();
      expect(screen.game.target, isNull);
      expect((state.position - beforeTap).distance, lessThan(.1));
      final floating = await tester.startGesture(touchPoint);
      await tester.pump();
      expect(
        tester.getCenter(find.byKey(const ValueKey('movement-joystick'))),
        touchPoint,
      );
      await floating.moveTo(touchPoint + const Offset(0, -28));
      await tester.pump();
      expect(screen.game.input.dy, lessThan(0));
      await floating.up();
      await uiFrames();
      expect(screen.game.input, Offset.zero);

      for (final item in state.streetLitter[0].toList()) {
        if (state.bag.length == state.capacity) break;
        if (state.removed[0].contains(item.id)) continue;
        state.position = item.position;
        await until(() => state.removed[0].contains(item.id), frames: 40);
      }
      expect(state.bag.length, 16);
      state.position = districts[0].station + const Offset(0, 80);
      await until(() => screen.game.nearStation.value);
      final before = state.coins;
      await tester.tap(find.byKey(const ValueKey('station-action')));
      await uiFrames();
      expect(screen.panelOpen, isFalse);
      expect(screen.game.playerStatusText, contains('15s'));
      expect(
        screen.game.playerStatusText,
        contains('+${state.jobs[0]!.coins} coins'),
      );
      expect(screen.game.paused, isFalse);
      expect(state.bag, isEmpty);
      expect(state.coins, before);
      expect(state.jobs[0], isNotNull);
      time = time.add(const Duration(seconds: 15));
      state.tick();
      await uiFrames();
      expect(state.coins, greaterThan(before));
      expect(state.totalRecycled, 16);

      await tester.tap(find.byKey(const ValueKey('magnet-action')));
      await uiFrames();
      expect(state.magnetActive, isTrue);
      time = time.add(const Duration(seconds: 15));
      state.tick();
      await uiFrames();
      expect(state.magnetActive, isFalse);

      Future<void> close() async {
        await tester.tap(find.byTooltip('Close').last);
        await uiFrames();
      }

      await tester.tap(find.byKey(const ValueKey('nav-gear')));
      await uiFrames();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(screen.game.paused, isTrue);
      await tester.tap(find.byKey(const ValueKey('upgrade-bag')));
      await uiFrames();
      expect(state.capacity, 24);
      await close();
      expect(screen.game.paused, isFalse);

      await tester.tap(find.byKey(const ValueKey('nav-style')));
      await uiFrames();
      await reveal(find.byKey(const ValueKey('outfit-1')));
      await uiFrames();
      await tester.tap(find.byKey(const ValueKey('outfit-1')));
      await uiFrames();
      expect(state.outfit, 1);
      await close();

      await tester.tap(find.byKey(const ValueKey('nav-goals')));
      await uiFrames();
      await tester.tap(find.text('Weekly'));
      await uiFrames();
      expect(find.text('The weekly champion'), findsOneWidget);
      await tester.tap(find.text('Monthly'));
      await uiFrames();
      expect(find.text('The extraordinary effort'), findsOneWidget);
      await close();

      await tester.tap(find.byKey(const ValueKey('nav-town')));
      await uiFrames();
      await reveal(find.byKey(const ValueKey('unlock-1')));
      await uiFrames();
      await tester.tap(find.byKey(const ValueKey('unlock-1')));
      await uiFrames();
      expect(state.isUnlocked(1), isTrue);
      await reveal(find.byKey(const ValueKey('travel-1')));
      await uiFrames();
      await tester.tap(find.byKey(const ValueKey('travel-1')));
      await until(
        () =>
            state.district == 1 &&
            screen.game.sceneReady.value &&
            !screen.panelOpen,
      );
      await uiFrames();
      await until(() => screen.notice == null, frames: 80);
      await uiFrames();
      expect(find.text('Porto Sole'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-shop')));
      await uiFrames();
      final buy = tester.widget<FilledButton>(
        find.byKey(const ValueKey('buy-gems')),
      );
      expect(buy.onPressed, isNull);
      await reveal(find.byKey(const ValueKey('shop-spooky')));
      await uiFrames();
      await tester.tap(find.byKey(const ValueKey('shop-spooky')));
      await uiFrames();
      expect(find.text('Use 80 gems'), findsOneWidget);
      await tester.tap(find.text('Use 80 gems'));
      await uiFrames();
      expect(state.gems, 20);
      expect(state.isUnlocked(5), isTrue);
      expect(state.ownedOutfits, contains(4));
      await close();

      // Render every district with its actual assets, geometry and camera.
      for (final id in [0, 1, 2, 3, 4, 5]) {
        if (!state.isUnlocked(id)) {
          expect(state.unlockMap(id), isTrue);
        }
        state.travel(id);
        await screen.game.loadDistrict();
        state.position = districts[id].start;
        if (id == 5) state.equipOutfit(4);
        for (var frame = 0; frame < 15; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(screen.game.sceneReady.value, isTrue);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Rendering ${districts[id].name}',
        );
      }

      await binding.convertFlutterSurfaceToImage();
      await uiFrames();
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          await binding.takeScreenshot(name);
        });
      }

      state.events.clear();
      screen.noticeTimer?.cancel();
      screen.notice = null;
      await uiFrames();
      await capture('cleancity-night');
      state.travel(2);
      await screen.game.loadDistrict();
      state.position = const Offset(1440, 965);
      await uiFrames();
      await capture('cleancity-tunis');
      state.travel(0);
      state.equipOutfit(0);
      await screen.game.loadDistrict();
      state.position = districts[state.district].layout.reviewPoint;
      await uiFrames();
      await capture('cleancity-streets');
      unawaited(screen.openPanel('daily'));
      await uiFrames();
      await capture('cleancity-daily');
      await close();
      unawaited(screen.openPanel('town'));
      await uiFrames();
      await capture('cleancity-maps');
      await close();
      unawaited(screen.openPanel('shop'));
      await uiFrames();
      await capture('cleancity-shop');
      await close();

      // The unlocked build must expose every city and skin without a purchase.
      state.unlockTestContent();
      expect(state.testMode, isTrue);
      expect(state.level, 100);
      expect(state.upgrades.every((v) => v == maxUpgradeLevel), isTrue);
      for (final d in districts) {
        expect(state.isUnlocked(d.id), isTrue);
        state.travel(d.id);
        await screen.game.loadDistrict();
        state.position = districts[state.district].layout.reviewPoint;
        state.events.clear();
        screen.noticeTimer?.cancel();
        screen.notice = null;
        await uiFrames();
        await capture('test-city-${d.id}');
        expect(tester.takeException(), isNull);
      }
      for (var id = 0; id < outfits.length; id++) {
        expect(state.equipOutfit(id), isTrue);
      }
      await tester.tap(find.byKey(const ValueKey('nav-style')));
      await uiFrames();
      for (var id = 6; id < outfits.length; id++) {
        await reveal(find.byKey(ValueKey('outfit-$id')));
        await tester.tap(find.byKey(ValueKey('outfit-$id')));
        await uiFrames();
        expect(state.outfit, id);
        await capture('new-outfit-$id');
        expect(tester.takeException(), isNull);
      }
      await close();
      state.equipOutfit(6);
      state.travel(0);
      await screen.game.loadDistrict();
      state.position = districts[state.district].layout.reviewPoint;
      await uiFrames();
      await capture('transparent-streets');
      final header = tester.widget<Container>(
        find.byKey(const ValueKey('top-hud')),
      );
      expect((header.decoration! as BoxDecoration).color!.a, closeTo(.38, .01));
      expect(
        tester.getSize(find.byKey(const ValueKey('top-hud'))).height,
        lessThan(105),
      );
      // Use a fresh city; the onboarding cleanup already collected most of Willow Lane.
      state.travel(2);
      await screen.game.loadDistrict();
      state.position = districts[state.district].layout.reviewPoint;
      unawaited(screen.openPanel('settings'));
      await uiFrames();
      await capture('test-settings');
      await tester.tap(find.byKey(const ValueKey('theme-dark')));
      await uiFrames();
      expect(state.darkMode, isTrue);
      expect(
        Theme.of(
          tester.element(find.byKey(const ValueKey('appearance-setting'))),
        ).brightness,
        Brightness.dark,
      );
      expect(
        Theme.of(tester.element(find.byType(GameScreen))).brightness,
        Brightness.dark,
      );
      await capture('settings-dark');
      await tester.tap(find.byKey(const ValueKey('theme-light')));
      await uiFrames();
      expect(state.darkMode, isFalse);
      expect(
        Theme.of(
          tester.element(find.byKey(const ValueKey('appearance-setting'))),
        ).brightness,
        Brightness.light,
      );
      await capture('settings-light');
      await reveal(find.byKey(const ValueKey('hud-opacity')));
      final slider = find.byKey(const ValueKey('hud-opacity'));
      final sliderRect = tester.getRect(slider);
      await tester.tapAt(
        Offset(sliderRect.left + sliderRect.width * .17, sliderRect.center.dy),
      );
      await uiFrames();
      expect(state.hudOpacity, lessThan(.38));
      await capture('bar-visibility');
      await reveal(find.byKey(const ValueKey('test-event')));
      // Start with the collection activity regardless of when an automatic offer appeared.
      state.cityEventSequence = 0;
      await tester.tap(find.byKey(const ValueKey('test-event')));
      await uiFrames();
      expect(state.cityEvent!.type, 0);
      await reveal(find.byKey(const ValueKey('test-gear-toggle')));
      await tester.tap(find.byKey(const ValueKey('test-gear-toggle')));
      await uiFrames();
      expect(state.capacity, 16);
      await tester.tap(find.byKey(const ValueKey('test-gear-toggle')));
      await uiFrames();
      expect(state.capacity, 64);
      expect(state.activateMagnet(), isTrue);
      await reveal(find.byKey(const ValueKey('test-refill')), step: -180);
      await tester.tap(find.byKey(const ValueKey('test-refill')));
      await uiFrames();
      expect(state.magnetCooldown, 0);
      expect(state.coins, greaterThanOrEqualTo(1000000));
      await close();

      await tester.tap(find.byKey(const ValueKey('action-events')));
      await uiFrames();
      await capture('event-invitation');
      expect(find.byKey(const ValueKey('event-join')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('event-join')));
      await uiFrames();
      expect(state.cityEvent!.joined, isTrue);
      // Exercise the real world automatic pickup path until the objective is ready.
      for (final item in state.streetLitter[state.district].toList()) {
        if (state.cityEvent!.ready) break;
        state.position = item.position;
        await until(
          () => state.removed[state.district].contains(item.id),
          frames: 40,
        );
      }
      expect(state.cityEvent!.ready, isTrue);
      await tester.tap(find.byKey(const ValueKey('action-events')));
      await uiFrames();
      await capture('event-reward');
      final eventCoins = state.coins;
      await tester.tap(find.byKey(const ValueKey('event-claim')));
      await uiFrames();
      expect(state.cityEvent, isNull);
      expect(state.coins, eventCoins + 140);
      expect(state.completedCityEvents, 1);
      expect(find.byKey(const ValueKey('event-claim')), findsNothing);
      await close();

      // Every layout is selected through Settings, then exercised while playing.
      state.travel(2);
      await screen.game.loadDistrict();
      for (final position in JoystickPosition.values) {
        await tester.tap(find.byKey(const ValueKey('settings-button')));
        await uiFrames();
        await tester.tap(find.byKey(ValueKey('joystick-${position.name}')));
        await uiFrames();
        expect(state.joystickPosition, position);
        if (position == JoystickPosition.right) {
          await tester.tap(find.byKey(const ValueKey('theme-dark')));
          await uiFrames();
        }
        await close();
        expect(screen.game.paused, isFalse);
        final stickRect = tester.getRect(
          find.byKey(const ValueKey('movement-joystick')),
        );
        final magnetRect = tester.getRect(
          find.byKey(const ValueKey('magnet-action')),
        );
        final stationRect = tester.getRect(
          find.byKey(const ValueKey('station-action')),
        );
        expect(stickRect.overlaps(magnetRect), isFalse);
        expect(stickRect.overlaps(stationRect), isFalse);
        expect(stickRect.left, greaterThanOrEqualTo(0));
        expect(stickRect.right, lessThanOrEqualTo(viewport.width));
        if (position == JoystickPosition.center) {
          expect(stickRect.center.dx, closeTo(viewport.width / 2, 1));
        } else if (position == JoystickPosition.left) {
          expect(stickRect.center.dx, lessThan(viewport.width / 3));
        } else {
          expect(stickRect.center.dx, greaterThan(viewport.width * 2 / 3));
        }
        final city = districts[state.district];
        final walkStart = city.layout.safe(
          city.start + const Offset(0, 100),
          clearance: 90,
        );
        state.position = walkStart;
        screen.game.clearInput();
        await uiFrames();
        final walk = await tester.startGesture(stickRect.center);
        await walk.moveTo(stickRect.center + const Offset(27, 0));
        await uiFrames();
        expect(screen.game.input.dx, greaterThan(0));
        expect(state.position.dx, greaterThan(walkStart.dx + 5));
        await walk.up();
        await uiFrames();
        expect(screen.game.input, Offset.zero);
        expect(screen.game.gait.blend, lessThan(.02));
        if (position == JoystickPosition.right) {
          final wall = city.obstacles.firstWhere(
            (r) =>
                city.canStand(Offset(r.left - 25, r.center.dy)) &&
                city.canStand(Offset(r.left - 60, r.center.dy)),
          );
          state.position = Offset(wall.left - 25, wall.center.dy);
          screen.game.clearInput();
          final blocked = await tester.startGesture(stickRect.center);
          await blocked.moveTo(stickRect.center + const Offset(30, 0));
          await uiFrames();
          final plantedPhase = screen.game.gait.phase;
          await uiFrames();
          expect(state.position.dx, lessThan(wall.left - 11));
          expect(screen.game.gait.phase, closeTo(plantedPhase, .001));
          expect(screen.game.gait.blend, lessThan(.02));
          await blocked.up();
        }
        state.position = districts[state.district].layout.reviewPoint;
        screen.noticeTimer?.cancel();
        screen.notice = null;
        await uiFrames();
        await capture('controls-${position.name}');
        expect(tester.takeException(), isNull);
      }
      // Menus, not just Settings, use the selected dark palette.
      for (final page in [
        'town',
        'gear',
        'style',
        'goals',
        'shop',
        'daily',
        'levels',
        'projects',
        'events',
        'ranking',
      ]) {
        unawaited(screen.openPanel(page));
        await uiFrames();
        expect(
          Theme.of(tester.element(find.byTooltip('Close'))).brightness,
          Brightness.dark,
        );
        await capture('dark-$page');
        expect(tester.takeException(), isNull);
        await close();
      }
      await tester.tap(find.byKey(const ValueKey('hide-hud')));
      await uiFrames();
      expect(state.hudVisible, isFalse);
      expect(find.byKey(const ValueKey('top-hud')), findsNothing);
      expect(find.byKey(const ValueKey('show-hud')), findsOneWidget);
      screen.showNotice('Bag full');
      await uiFrames();
      expect(find.text('Bag full'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Bag full')).dy, lessThan(90));
      await capture('hud-hidden');
      await tester.tap(find.byKey(const ValueKey('settings-button')));
      await uiFrames();
      expect(find.byKey(const ValueKey('appearance-setting')), findsOneWidget);
      await close();
      await tester.tap(find.byKey(const ValueKey('show-hud')));
      await uiFrames();
      expect(state.hudVisible, isTrue);
      expect(find.byKey(const ValueKey('top-hud')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hide-hud')));
      await uiFrames();

      // Exercise the new encounter through the actual test-build controls.
      state.travel(0);
      await screen.game.loadDistrict();
      state.bag.clear();
      state.totalCollected = 99;
      expect(state.collect(state.streetLitter[0].first), isTrue);
      await tester.tap(find.byKey(const ValueKey('action-ranking')));
      await uiFrames();
      expect(find.text('BRONZE'), findsOneWidget);
      await capture('ranking-bronze');
      await close();
      unawaited(screen.openPanel('settings'));
      await uiFrames();
      await reveal(find.byKey(const ValueKey('test-thief')));
      await tester.tap(find.byKey(const ValueKey('test-thief')));
      await uiFrames();
      final encounter = screen.game.life!.thief;
      expect(encounter.actor, isNotNull);
      final thief = encounter.actor!;
      expect(thief.running, isFalse);
      state.position = thief.position;
      await until(() => thief.running);
      await uiFrames();
      expect(thief.drops, greaterThan(0));
      await capture('thief-running');
      await until(() => thief.runTime > .7);
      final beforeCatch = state.coins;
      state.position = thief.position;
      await until(() => thief.caught);
      expect(state.coins, beforeCatch + GameState.thiefCatchReward);
      await capture('thief-caught');
      await until(() => encounter.actor == null);
      expect(state.coins, beforeCatch + GameState.thiefCatchReward);

      state.bag.clear();
      state.collect(state.streetLitter[0].first);
      state.position = districts[0].station + const Offset(0, 80);
      await until(() => screen.game.nearStation.value);
      await tester.tap(find.byKey(const ValueKey('station-action')));
      await uiFrames();
      expect(screen.panelOpen, isFalse);
      await until(() => screen.game.playerStatusText?.startsWith('3s') == true);
      final expectedRecycled =
          state.totalRecycled + state.jobs[0]!.items.length;
      await capture('recycling-above-player');
      final touch = Offset(viewport.width * .72, viewport.height * .52);
      final freeStick = await tester.startGesture(touch);
      await freeStick.moveTo(touch + const Offset(28, 0));
      await uiFrames();
      expect(
        tester.getCenter(find.byKey(const ValueKey('movement-joystick'))),
        touch,
      );
      await capture('floating-joystick');
      await freeStick.up();
      time = time.add(const Duration(seconds: 4));
      state.tick();
      await uiFrames();
      await capture('recycling-paid');
      expect(state.jobs, isEmpty);
      expect(tester.takeException(), isNull);

      await state.save();
      final loaded = GameState(store, now: () => time);
      await loaded.load();
      expect(loaded.gems, 10000);
      expect(loaded.isUnlocked(5), isTrue);
      expect(loaded.ownedOutfits.contains(4), isTrue);
      expect(loaded.capacity, 64);
      expect(loaded.totalRecycled, expectedRecycled);
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.darkMode, isTrue);
      expect(loaded.joystickPosition, JoystickPosition.right);
      expect(loaded.hudVisible, isFalse);
      expect(loaded.hudOpacity, state.hudOpacity);
      expect(loaded.completedCityEvents, 1);
      expect(loaded.ownedOutfits.length, 12);
      expect(tester.takeException(), isNull);
      await loaded.flush();
      loaded.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await state.flush();
      state.dispose();
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greenhaven/main.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/ui/game_screen.dart';
import 'street_events_test.dart' show EventStore;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'album recovery, police navigation, returns and souvenirs on Android',
    (tester) async {
      final store = EventStore();
      final state = GameState(store)
        ..introduced = true
        ..sound = false
        ..haptics = false;
      state.unlockTestContent();
      await tester.pumpWidget(CleanCityApp(state: state));
      final screen = tester.state<GameScreenState>(find.byType(GameScreen)),
          game = screen.game;
      Future<void> frames([int n = 10]) async {
        for (var i = 0; i < n; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }

      for (var i = 0; i < 200 && !game.sceneReady.value; i++) {
        await frames(1);
      }
      expect(game.sceneReady.value, isTrue);
      await binding.convertFlutterSurfaceToImage();
      Future<void> capture(String name) async {
        // Flame must render a new frame after manual simulation or map travel.
        // Menus keep the world paused, just as in the actual app.
        final renderWorld = !screen.panelOpen;
        if (renderWorld) game.resumeEngine();
        await frames(20);
        await tester.runAsync(() => binding.takeScreenshot(name));
        if (renderWorld) game.pauseEngine();
        expect(tester.takeException(), isNull);
      }

      // Let the attendance notice finish so the city alert gets its full display.
      await frames(50);
      expect(game.life!.thief.spawn(preview: true), isTrue);
      await frames(17);
      expect(screen.notice, 'Thief in the city');
      await capture('thief-city-alert');
      game.pauseEngine();
      final thief = game.life!.thief.actor!;
      state.position = thief.position;
      thief.running = true;
      thief.runTime = 1;
      game.life!.thief.update(.05);
      expect(thief.caught, isTrue);
      expect(state.album.drops.length, inInclusiveRange(2, 4));
      state.position = game.navigation!.nearestWalkable(
        thief.position + const Offset(0, 180),
      );
      await capture('thief-valuables');
      final count = state.album.drops.length;
      state.bag.clear();
      state.bag.addAll(List.filled(state.capacity, (kind: 0, district: 0)));
      for (final drop in state.album.drops.toList()) {
        state.position = drop.position;
        game.update(.05);
      }
      expect(state.album.carried, count);
      expect(state.album.totalFound, count);
      await frames(16);
      await tester.tap(find.byKey(const ValueKey('action-album')));
      await capture('album-rewards');
      expect(find.text('$count to return'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('album-return')));
      await frames(3);
      game.pauseEngine();
      expect(game.target, isNotNull);
      for (var i = 0; i < 3000 && !state.nearPolice; i++) {
        game.update(.05);
      }
      expect(state.nearPolice, isTrue);
      game.clearInput();
      await frames(16);
      await capture('police-return');
      final before = state.coins, reward = state.album.returnReward;
      await tester.tap(find.byKey(const ValueKey('police-action')));
      game.update(.05);
      await frames(16);
      expect(state.album.carried, 0);
      expect(state.album.totalReturned, count);
      expect(state.coins, before + reward);
      expect(find.byKey(const ValueKey('police-action')), findsNothing);
      await capture('police-reward');
      await state.flush();
      final loaded = GameState(store);
      await loaded.load();
      expect(loaded.recoveredSave, isFalse);
      expect(loaded.album.totalFound, count);
      expect(loaded.album.totalReturned, count);
      await loaded.flush();
      loaded.dispose();
      // Exercise rendering and UI state for the long-term milestone.
      state.totalRecycled = 100000;
      state.setDarkMode(true);
      await tester.tap(find.byKey(const ValueKey('action-album')));
      await frames();
      await tester.tap(find.text('Progress'));
      await capture('album-progress-dark');
      await tester.scrollUntilVisible(
        find.text('Golden city'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await capture('album-golden-city');
      await tester.tap(find.byTooltip('Close'));
      await frames();
      state.setDarkMode(false);
      for (final city in districts) {
        state.travel(city.id);
        await game.loadDistrict();
        state.position = city.layout.policeEntrance;
        game.pauseEngine();
        for (var i = 0; i < 80; i++) {
          game.update(.05);
        }
        await capture('police-city-${city.id}');
      }
      await state.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      await state.flush();
      state.dispose();
    },
  );
}

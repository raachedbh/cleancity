import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greenhaven/main.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/ui/game_screen.dart';
import 'package:greenhaven/ui/quick_start_guide.dart';
import 'street_events_test.dart' show EventStore;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'dark first launch and every guide dismissal persist on Android',
    (tester) async {
      Future<void> frames([int count = 10]) async {
        for (var i = 0; i < count; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }

      await binding.convertFlutterSurfaceToImage();
      for (final exit in ['start', 'close', 'back', 'outside', 'swipe']) {
        final store = EventStore();
        final state = GameState(store)
          ..sound = false
          ..haptics = false;
        await tester.pumpWidget(CleanCityApp(state: state));
        await frames();
        final screen = tester.state<GameScreenState>(find.byType(GameScreen));
        for (var i = 0; i < 250 && !screen.game.sceneReady.value; i++) {
          await frames(1);
        }
        expect(screen.game.sceneReady.value, isTrue);
        expect(find.text('Quick start'), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(QuickStartGuide))).brightness,
          Brightness.dark,
        );
        expect(state.introduced, isFalse);
        if (exit == 'start') {
          await tester.runAsync(
            () => binding.takeScreenshot('quick-start-dark'),
          );
          await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
          await frames(3);
          await tester.tap(find.byKey(const ValueKey('start-game')));
        } else if (exit == 'close') {
          await tester.tap(find.byTooltip('Close'));
        } else if (exit == 'back') {
          await binding.handlePopRoute();
        } else if (exit == 'outside') {
          final top = tester.getTopLeft(find.byType(QuickStartGuide)).dy;
          await tester.tapAt(Offset(12, top - 8));
        } else {
          await tester.fling(
            find.text('Quick start'),
            const Offset(0, 650),
            1800,
          );
        }
        await frames();
        expect(find.byType(QuickStartGuide), findsNothing, reason: exit);
        expect(state.introduced, isTrue, reason: exit);
        expect(screen.panelOpen, isFalse, reason: exit);
        expect(tester.takeException(), isNull);
        if (exit == 'start') {
          await tester.runAsync(() => binding.takeScreenshot('dark-home'));
        }
        await state.flush();
        await tester.pumpWidget(const SizedBox.shrink());
        await frames(2);
        final reopened = GameState(store);
        await reopened.load();
        expect(reopened.introduced, isTrue, reason: exit);
        expect(reopened.darkMode, isTrue);
        // Reopen after each dismissal: the persisted guide must stay closed.
        await tester.pumpWidget(CleanCityApp(state: reopened));
        await frames();
        expect(find.byType(QuickStartGuide), findsNothing, reason: exit);
        expect(
          tester.state<GameScreenState>(find.byType(GameScreen)).panelOpen,
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await frames(2);
        await reopened.flush();
        reopened.dispose();
        state.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

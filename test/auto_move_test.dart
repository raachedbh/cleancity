import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/ui/joystick.dart';

void main() {
  test(
    'double edge taps latch all directions; a new touch, cancel or reset stops auto-walk',
    () {
      var direction = Offset.zero, ms = 0, id = 0;
      final input = JoystickInput((d) => direction = d);
      const center = Offset(100, 100);
      void tap(Offset at, {int gap = 100}) {
        ms += gap;
        input.begin(
          ++id,
          at,
          padCenter: center,
          timeStamp: Duration(milliseconds: ms),
        );
        ms += 40;
        input.end(id, timeStamp: Duration(milliseconds: ms));
      }

      for (final edge in [
        const Offset(40, 0),
        const Offset(-40, 0),
        const Offset(0, 40),
        const Offset(0, -40),
        const Offset(28, 28),
      ]) {
        input.reset();
        tap(center + edge);
        expect(input.autoMoving, isFalse);
        expect(direction, Offset.zero);
        tap(center + edge);
        expect(input.autoMoving, isTrue);
        expect((direction - edge / edge.distance).distance, lessThan(.001));
        expect(input.pointer, isNull); // Continues after lifting the finger.
        tap(const Offset(250, 200));
        expect(input.autoMoving, isFalse);
        expect(direction, Offset.zero);
      }
      tap(center + const Offset(40, 0));
      tap(center + const Offset(40, 0), gap: 600);
      expect(input.autoMoving, isFalse);
      input.reset();
      tap(center + const Offset(40, 0));
      tap(center + const Offset(0, 40));
      expect(
        input.autoMoving,
        isFalse,
      ); // Different directions are not a double tap.
      input.reset();
      tap(const Offset(250, 200));
      tap(const Offset(250, 200));
      expect(input.autoMoving, isFalse); // Ordinary map taps never auto-walk.
      input.reset();
      tap(center + const Offset(40, 0));
      input.begin(++id, center + const Offset(40, 0), padCenter: center);
      input.cancel(id);
      expect(input.autoMoving, isFalse);
      input.dispose();
    },
  );

  testWidgets(
    'visible joystick edge double-tap starts auto-walk and map touch stops it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var direction = Offset.zero, autoCalls = 0;
      final input = JoystickInput(
        (d) => direction = d,
        onAutoMove: (d) {
          direction = d;
          autoCalls++;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingMovementJoystick(
              input: input,
              position: JoystickPosition.left,
              enabled: true,
              onFocus: () {},
              child: const ColoredBox(color: Colors.green),
            ),
          ),
        ),
      );
      final center = tester.getCenter(
        find.byKey(const ValueKey('movement-joystick')),
      );
      await tester.tapAt(center + const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(center + const Offset(40, 0));
      await tester.pump();
      expect(autoCalls, 1);
      expect(direction, const Offset(1, 0));
      expect(input.autoMoving, isTrue);
      expect(find.byIcon(Icons.double_arrow_rounded), findsOneWidget);
      await tester.tapAt(const Offset(240, 340));
      await tester.pump();
      expect(direction, Offset.zero);
      expect(input.autoMoving, isFalse);
      await tester.pumpWidget(const SizedBox());
      input.dispose();
    },
  );
}

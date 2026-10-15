import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/state/game_state.dart';
import 'package:greenhaven/ui/joystick.dart';

void main() {
  testWidgets(
    'touch relocates joystick, drag steers, second finger cannot hijack, cancel stops',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var direction = Offset.zero, pressed = 0;
      final input = JoystickInput((d) => direction = d);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingMovementJoystick(
                  input: input,
                  position: JoystickPosition.left,
                  enabled: true,
                  onFocus: () {},
                  child: const ColoredBox(color: Colors.green),
                ),
                Positioned(
                  top: 30,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: () => pressed++,
                    child: const Text('Menu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      expect(pressed, 1);
      expect(input.origin, isNull);
      const point = Offset(220, 330);
      final first = await tester.startGesture(point, pointer: 1);
      await tester.pump();
      expect(
        tester.getCenter(find.byKey(const ValueKey('movement-joystick'))),
        point,
      );
      expect(direction, Offset.zero); // A tap is not a walking destination.
      await first.moveTo(point + const Offset(90, 0));
      expect(direction, const Offset(1, 0));
      final second = await tester.startGesture(
        const Offset(140, 440),
        pointer: 2,
      );
      await second.moveBy(const Offset(0, -60));
      await second.up();
      expect(direction, const Offset(1, 0));
      expect(input.origin, point);
      await first.cancel();
      expect(direction, Offset.zero);
      expect(input.origin, isNull);
      final edge = await tester.startGesture(const Offset(2, 420), pointer: 3);
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const ValueKey('movement-joystick'))).left,
        0,
      );
      await edge.moveBy(const Offset(0, 24));
      expect(direction.dy, greaterThan(0));
      input.reset(); // Opening a menu/backgrounding cancels the held finger.
      await edge.moveBy(const Offset(20, 0));
      expect(direction, Offset.zero);
      await edge.up();
      await tester.pumpWidget(const SizedBox());
      input.dispose();
    },
  );
}

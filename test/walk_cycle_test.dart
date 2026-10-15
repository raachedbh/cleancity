import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/game/walk_cycle.dart';

void main() {
  test(
    'cadence follows distance independently of frame rate and stops at obstacles',
    () {
      final fastFrames = WalkCycle(), slowFrames = WalkCycle();
      for (var i = 0; i < 120; i++) {
        fastFrames.update(1, 1 / 120);
      }
      for (var i = 0; i < 30; i++) {
        slowFrames.update(4, 1 / 30);
      }
      expect(fastFrames.phase, closeTo(slowFrames.phase, .000001));
      final phase = fastFrames.phase;
      for (var i = 0; i < 120; i++) {
        fastFrames.update(0, 1 / 60);
      }
      expect(fastFrames.phase, phase);
      expect(fastFrames.blend, 0);
      expect(fastFrames.foot(0).lift, 0);
    },
  );
  test('steps alternate with a grounded support foot', () {
    final gait = WalkCycle()..blend = 1;
    for (var i = 0; i < 240; i++) {
      gait.phase = i / 240 * pi * 2;
      final left = gait.foot(0), right = gait.foot(1);
      expect(left.lift, inInclusiveRange(0, 7));
      expect(right.lift, inInclusiveRange(0, 7));
      expect(left.lift == 0 || right.lift == 0, isTrue);
    }
  });
  test('diagonal turns retain facing until a deliberate axis change', () {
    expect(facingFor(const Offset(1, 1.05), 1), 1);
    expect(facingFor(const Offset(1.05, 1), 0), 0);
    expect(facingFor(const Offset(1, 2), 1), 0);
    expect(facingFor(const Offset(-2, 1), 0), 3);
    expect(facingFor(Offset.zero, 3), 3);
  });
}

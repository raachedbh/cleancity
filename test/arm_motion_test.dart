import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/game/arm_motion.dart';
import 'package:greenhaven/game/walk_cycle.dart';

void main() {
  test('arm joints remain connected through a stride, including its wrap', () {
    for (final side in [false, true]) {
      for (final direction in [-1.0, 1.0]) {
        for (var arm = 0; arm < 2; arm++) {
          ArmPose? previous;
          for (var frame = 0; frame <= 240; frame++) {
            final gait = WalkCycle()
              ..phase = frame / 240 * 2 * pi
              ..blend = 1;
            final pose = ArmPose.walk(
              gait,
              arm,
              side: side,
              direction: direction,
            );
            expect((pose.elbow - pose.shoulder).distance, closeTo(15.5, .001));
            expect((pose.hand - pose.elbow).distance, closeTo(15, .001));
            if (previous != null) {
              expect((pose.hand - previous.hand).distance, lessThan(.6));
            }
            previous = pose;
          }
          final start = ArmPose.walk(
            WalkCycle()..blend = 1,
            arm,
            side: side,
            direction: direction,
          );
          expect((previous!.hand - start.hand).distance, lessThan(.001));
        }
      }
    }
  });
  test('both walking arms swing and settle when movement stops', () {
    final gait = WalkCycle()..blend = 1;
    for (var arm = 0; arm < 2; arm++) {
      final xs = <double>[];
      for (var frame = 0; frame < 60; frame++) {
        gait.phase = frame / 60 * 2 * pi;
        xs.add(ArmPose.walk(gait, arm, side: true).hand.dx);
      }
      expect(xs.reduce(max) - xs.reduce(min), greaterThan(25));
    }
    for (var frame = 0; frame < 120; frame++) {
      gait.update(0, 1 / 60);
    }
    final stopped = ArmPose.walk(gait, 0, side: true);
    gait.phase += pi;
    final otherPhase = ArmPose.walk(gait, 0, side: true);
    expect((stopped.hand - otherPhase.hand).distance, lessThan(.01));
  });
}

import 'dart:math';
import 'dart:ui';

/// A distance-driven gait: feet slow with the actor and stop at obstacles.
class WalkCycle {
  double phase = 0, blend = 0;
  void update(double distance, double dt, {double strideLength = 76}) {
    if (dt <= 0) return;
    if (distance > 0) {
      phase = (phase + distance / strideLength * pi * 2) % (pi * 2);
    }
    final target = (distance / dt / 55).clamp(0.0, 1.0);
    blend += (target - blend) * (1 - exp(-dt * 14));
    if (blend < .002) blend = 0;
  }

  void stop() => blend = 0;
  double get bob => (1 - cos(phase * 2)) * .65 * blend;
  double get armSwing => sin(phase) * blend;

  /// 60% stance with a planted sole, then a lifted return step.
  ({double travel, double lift}) foot(int leg) {
    final t = ((phase / (2 * pi) + leg * .5) % 1);
    if (t < .6) return (travel: (1 - t / .6 * 2) * blend, lift: 0);
    final swing = (t - .6) / .4;
    return (
      travel: -cos(swing * pi) * blend,
      lift: sin(swing * pi) * 7 * blend,
    );
  }
}

/// Two-bone joint placement, with fixed limb lengths and a stable bend direction.
Offset kneeBetween(
  Offset hip,
  Offset foot,
  double upper,
  double lower,
  double bend,
) {
  final delta = foot - hip;
  final length = delta.distance.clamp(.001, upper + lower - .001);
  final direction = delta.distance > .001
      ? delta / delta.distance
      : const Offset(0, 1);
  final along =
      (upper * upper - lower * lower + length * length) / (2 * length);
  final across = sqrt(max(0, upper * upper - along * along));
  return hip +
      direction * along +
      Offset(-direction.dy, direction.dx) * across * bend;
}

/// Hysteresis prevents rapid left/front flicker around a diagonal direction.
int facingFor(Offset movement, int previous) {
  if (movement.distanceSquared < .01) return previous;
  final x = movement.dx.abs(), y = movement.dy.abs();
  final wasSide = previous == 1 || previous == 3;
  if (x > y * (wasSide ? .8 : 1.2)) return movement.dx < 0 ? 3 : 1;
  return movement.dy < 0 ? 2 : 0;
}

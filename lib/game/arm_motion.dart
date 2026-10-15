import 'dart:math';
import 'dart:ui';
import 'walk_cycle.dart';

/// Forward joint rotation keeps upper/forearm lengths stable through a stride.
/// Elbow and wrist lag the shoulder instead of pulling a rigid arm sideways.
class ArmPose {
  const ArmPose(this.shoulder, this.elbow, this.hand);
  final Offset shoulder, elbow, hand;
  static ArmPose walk(
    WalkCycle gait,
    int index, {
    required bool side,
    double shoulderWidth = 14,
    double direction = 1,
    double time = 0,
  }) {
    final sign = index == 0 ? -1.0 : 1.0;
    final phase = gait.phase + index * pi;
    final swing = sin(phase - .18) * gait.blend;
    final breath = sin(time * 1.6 + index * .5) * .012 * (1 - gait.blend);
    final shoulder = Offset(
      side ? sign * 4 : sign * shoulderWidth,
      -61 + sin(phase) * .5 * gait.blend,
    );
    final angle = (side ? .46 * swing : sign * .075 + .11 * swing) + breath;
    final flex = side
        ? .13 + .14 * gait.blend * (1 + sin(phase - .52))
        : sign * (.09 + .045 * gait.blend * (1 + sin(phase - .4)));
    final elbow = shoulder + Offset(sin(angle) * 15.5, cos(angle) * 15.5);
    final hand = elbow + Offset(sin(angle + flex) * 15, cos(angle + flex) * 15);
    return ArmPose(
      Offset(shoulder.dx * direction, shoulder.dy),
      Offset(elbow.dx * direction, elbow.dy),
      Offset(hand.dx * direction, hand.dy),
    );
  }
}

class ArmArt {
  static void draw(
    Canvas c,
    ArmPose pose, {
    required Color cloth,
    required Color skin,
    bool longSleeve = false,
    bool far = false,
    Color? cuff,
  }) {
    const ink = Color(0xFF393A34);
    Color dim(Color color) => far ? Color.lerp(color, ink, .13)! : color;
    void stroke(Path p, Color color, double width) {
      for (final layer in [(ink, width + 1.45), (dim(color), width)]) {
        c.drawPath(
          p,
          Paint()
            ..color = layer.$1
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer.$2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    final upper = pose.elbow - pose.shoulder, lower = pose.hand - pose.elbow;
    final p = Path()
      ..moveTo(pose.shoulder.dx, pose.shoulder.dy)
      ..lineTo(pose.elbow.dx, pose.elbow.dy)
      ..lineTo(pose.hand.dx, pose.hand.dy);
    stroke(p, longSleeve ? cloth : skin, longSleeve ? 7.7 : 6.3);
    if (!longSleeve) {
      final end = pose.shoulder + upper * .55;
      stroke(
        Path()
          ..moveTo(pose.shoulder.dx, pose.shoulder.dy)
          ..lineTo(end.dx, end.dy),
        cloth,
        9.2,
      );
    }
    if (cuff != null) {
      final at = pose.elbow + lower * .8,
          n = Offset(-lower.dy, lower.dx) / lower.distance * 3.5;
      c.drawLine(
        at - n,
        at + n,
        Paint()
          ..color = cuff
          ..strokeWidth = 2.6,
      );
    }
    c.save();
    c.translate(pose.hand.dx, pose.hand.dy);
    c.rotate(-atan2(lower.dx, lower.dy) * .7);
    // Tapered palm and tucked thumb; no rectangular sprite strip at the wrist.
    final hand = Path()
      ..moveTo(-2.6, -2)
      ..quadraticBezierTo(-4.1, 1, -3.1, 4.6)
      ..quadraticBezierTo(-1, 7, 2.5, 5.2)
      ..lineTo(3.4, 1.2)
      ..quadraticBezierTo(4.7, -.8, 2.5, -1.5)
      ..close();
    c.drawPath(hand, Paint()..color = dim(skin));
    c.drawPath(
      hand,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    c.drawLine(
      const Offset(1.7, .6),
      const Offset(1.2, 3.6),
      Paint()
        ..color = Color.lerp(skin, ink, .4)!
        ..strokeWidth = .65,
    );
    c.restore();
  }
}

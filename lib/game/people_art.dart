import 'dart:math';
import 'package:flutter/material.dart';
import 'walk_cycle.dart';
import 'arm_motion.dart';

enum InterviewRole { reporter, guest, camera }

/// Residents share the player's bold outline, expressive eyes and jointed limbs.
/// All limbs are drawn as continuous paths; sleeves cover the shoulder seam.
class PeopleArt {
  static double microphoneReach(double time) {
    final phase = time % 12;
    final t = phase < 4
        ? 0.0
        : phase < 5
        ? phase - 4
        : phase < 10.5
        ? 1.0
        : (12 - phase) / 1.5;
    return t * t * (3 - 2 * t);
  }

  static Offset? interviewHand(InterviewRole? role, int arm, double time) =>
      switch (role) {
        InterviewRole.reporter when arm == 1 => Offset.lerp(
          const Offset(13, -59),
          const Offset(31, -65),
          microphoneReach(time),
        )!,
        InterviewRole.guest when arm == 1 => Offset(
          20 + sin(time * 2.2) * 3,
          -47 - (4 + sin(time * 2.2) * 4) * microphoneReach(time),
        ),
        InterviewRole.camera =>
          arm == 0 ? const Offset(13, -77) : const Offset(26, -71),
        _ => null,
      };
  static const scales = [1.0, .97, 1.01, 1.04, .96, 1.02, .99, .98];
  static Offset throwingHand(
    int id,
    Offset position,
    int facing,
    WalkCycle gait,
  ) =>
      position +
      Offset(facing == 3 ? -31 : 31, -54 - gait.bob) * scales[id % 8];
  static const ink = Color(0xFF383B35);
  static Color shade(Color c, double a) =>
      Color.lerp(c, a < 0 ? Colors.black : Colors.white, a.abs())!;
  static void line(Canvas c, Offset a, Offset b, Color color, double w) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
  static void path(Canvas c, Path p, Color color, {double edge = 1.35}) {
    c.drawPath(p, Paint()..color = color);
    if (edge > 0) {
      c.drawPath(
        p,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  static void oval(Canvas c, Rect r, Color color, {double edge = 1.1}) {
    c.drawOval(r, Paint()..color = color);
    if (edge > 0) {
      c.drawOval(
        r,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge,
      );
    }
  }

  static void draw(
    Canvas c, {
    required int id,
    required Offset position,
    required int facing,
    required bool walking,
    required double time,
    required bool throwing,
    required bool night,
    WalkCycle? gait,
    bool thief = false,
    InterviewRole? interviewRole,
  }) {
    final style = id % 8, side = facing == 1 || facing == 3, back = facing == 2;
    final skin = const [
      Color(0xFFDBA16B),
      Color(0xFFB97D54),
      Color(0xFFEBC091),
      Color(0xFF8C5E41),
      Color(0xFFF0C7A0),
      Color(0xFFC89060),
      Color(0xFFA8734C),
      Color(0xFFE6B58A),
    ][style];
    final shirt = thief
        ? const Color(0xFF3D4350)
        : const [
            Color(0xFF5F8CAB),
            Color(0xFFCC7763),
            Color(0xFF5F9176),
            Color(0xFFCEA85E),
            Color(0xFFAA82B2),
            Color(0xFF598C91),
            Color(0xFFCA8870),
            Color(0xFF89956C),
          ][style];
    final hair = const [
      Color(0xFF65412B),
      Color(0xFF362B26),
      Color(0xFFBB8548),
      Color(0xFF262D2A),
      Color(0xFF97572F),
      Color(0xFF47362C),
      Color(0xFF302F2A),
      Color(0xFFB8B9B0),
    ][style];
    final motion =
        gait ??
        (WalkCycle()
          ..phase = time * 7
          ..blend = walking ? 1 : 0);
    final bob = motion.bob;
    c.save();
    c.translate(position.dx, position.dy);
    c.scale(scales[style]);
    oval(
      c,
      const Rect.fromLTWH(-18, -2, 38, 10),
      const Color(0x30343C31),
      edge: 0,
    );
    if (facing == 3) c.scale(-1, 1);
    void bonePath(Path p, Color color, double w) {
      for (final layer in [(ink, w + 1.7), (color, w)]) {
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

    final pants = style.isEven
        ? const Color(0xFF596B77)
        : const Color(0xFF676A59);
    for (var leg = 0; leg < 2; leg++) {
      final step = motion.foot(leg),
          home = side ? (leg == 0 ? -3.5 : 3.5) : (leg == 0 ? -7.0 : 7.0);
      final hip = Offset(home, -34 - bob),
          foot = Offset(
            home + (side ? step.travel * 13 : step.travel * 1.4),
            -3 - step.lift + (side ? 0 : step.travel * 3),
          );
      final knee = side
          ? kneeBetween(hip, foot, 15.5, 16, -1)
          : Offset.lerp(hip, foot, .48)! +
                Offset((leg == 0 ? -1 : 1) * step.lift * .15, 0);
      bonePath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..lineTo(knee.dx, knee.dy)
          ..lineTo(foot.dx, foot.dy),
        leg == 0 ? shade(pants, -.1) : pants,
        8.4,
      );
      final shoe = Path()
        ..moveTo(foot.dx - 4, foot.dy - 3)
        ..quadraticBezierTo(foot.dx + 3, foot.dy - 5, foot.dx + 7, foot.dy)
        ..lineTo(foot.dx + 8, foot.dy + 3)
        ..lineTo(foot.dx - 5, foot.dy + 3)
        ..close();
      path(c, shoe, const Color(0xFFECE4CE), edge: 1.2);
      line(
        c,
        foot + const Offset(-4, 3),
        foot + const Offset(7, 3),
        const Color(0xFF969583),
        1,
      );
    }
    c.translate(0, -bob);
    final bw = side ? 10.5 : (style == 2 || style == 5 ? 15.0 : 13.0);
    void arm(int index) {
      final a = index == 0 ? -1.0 : 1.0;
      final shoulder = Offset(side ? a * 4 : a * bw, -60);
      final walk = ArmPose.walk(
        motion,
        index,
        side: side,
        shoulderWidth: bw,
        time: time,
      );
      final heldHand = interviewHand(interviewRole, index, time);
      final hand =
          heldHand ??
          (throwing && index == 1
              ? Offset(side ? 31 : bw + 24, -54)
              : walk.hand);
      final elbow = heldHand != null || throwing && index == 1
          ? kneeBetween(shoulder, hand, 16, 17, 1)
          : walk.elbow;
      ArmArt.draw(
        c,
        ArmPose(
          throwing || heldHand != null ? shoulder : walk.shoulder,
          elbow,
          hand,
        ),
        cloth: shirt,
        skin: skin,
        far: side && index == 0,
      );
    }

    arm(0);
    if (!side) arm(1);
    final body = Path()
      ..moveTo(-7, -68)
      ..quadraticBezierTo(-bw - 3, -66, -bw - 2, -54)
      ..lineTo(-bw, -31)
      ..quadraticBezierTo(0, -27, bw, -31)
      ..lineTo(bw + 2, -54)
      ..quadraticBezierTo(bw + 2, -65, 7, -68)
      ..close();
    path(c, body, shirt);
    path(
      c,
      Path()
        ..moveTo(bw - 3, -57)
        ..lineTo(bw, -31)
        ..quadraticBezierTo(4, -28, 0, -30)
        ..lineTo(5, -35)
        ..lineTo(6, -60)
        ..close(),
      shade(shirt, -.1),
      edge: 0,
    );
    if (!back && (style == 0 || style == 5)) {
      line(
        c,
        const Offset(0, -62),
        const Offset(0, -31),
        shade(shirt, -.28),
        1,
      );
      for (var y = -54.0; y < -32; y += 8) {
        oval(
          c,
          Rect.fromCircle(center: Offset(1, y), radius: .8),
          const Color(0xFFE6DCBB),
          edge: 0,
        );
      }
      line(c, const Offset(6, -51), Offset(bw - 3, -51), shade(shirt, -.35), 1);
    } else if (style == 3 || style == 6) {
      for (var y = -52.0; y < -34; y += 8) {
        line(c, Offset(-bw + 2, y), Offset(bw - 2, y), shade(shirt, .28), 2.2);
      }
    }
    if (!back) {
      path(
        c,
        Path()
          ..moveTo(-7, -67)
          ..quadraticBezierTo(0, -57, 7, -67)
          ..lineTo(5, -70)
          ..lineTo(-5, -70)
          ..close(),
        skin,
        edge: 1.1,
      );
      line(
        c,
        const Offset(-7, -67),
        const Offset(-3, -60),
        shade(shirt, .28),
        2,
      );
      line(c, const Offset(7, -67), const Offset(3, -60), shade(shirt, .28), 2);
    }
    if (style == 1 || style == 4) {
      line(
        c,
        const Offset(-9, -64),
        const Offset(11, -32),
        const Color(0xFF68553D),
        2.6,
      );
      path(
        c,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(7, -38, 13, 16),
            const Radius.circular(3),
          ),
        ),
        const Color(0xFFAF9167),
      );
      line(
        c,
        const Offset(9, -33),
        const Offset(17, -33),
        const Color(0xFF72573B),
        1,
      );
    }
    if (side) arm(1);
    if (style == 7) {
      line(
        c,
        const Offset(-8, -66),
        const Offset(8, -66),
        const Color(0xFFB67463),
        4,
      );
      line(
        c,
        const Offset(6, -64),
        const Offset(9, -49),
        const Color(0xFFB67463),
        4,
      );
    }
    c.save();
    c.translate(0, -84);
    if (interviewRole != null) c.rotate(sin(time * 1.8) * .025);
    final talking = interviewRole == InterviewRole.reporter
        ? 1 - microphoneReach(time)
        : interviewRole == InterviewRole.guest
        ? microphoneReach(time)
        : 0.0;
    head(
      c,
      style,
      skin,
      hair,
      back,
      side,
      speaking: talking * (.5 + sin(time * 12) * .5),
    );
    if (thief) {
      // Knit cap, eye mask and pale shirt stripes identify the event actor.
      path(
        c,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-15, -21, 30, 13),
            const Radius.circular(6),
          ),
        ),
        const Color(0xFF292C35),
      );
      if (!back) {
        path(
          c,
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(side ? 0 : -14, -5, side ? 17 : 28, 10),
              const Radius.circular(4),
            ),
          ),
          const Color(0xFF30333C),
        );
        for (final x in (side ? [10.0] : [-6.0, 6.0])) {
          oval(
            c,
            Rect.fromCenter(center: Offset(x, 0), width: 7, height: 5),
            const Color(0xFFF7F3DC),
            edge: 0,
          );
          oval(
            c,
            Rect.fromCircle(center: Offset(x + 1, 0), radius: 1.6),
            ink,
            edge: 0,
          );
        }
      }
    }
    c.restore();
    if (interviewRole == InterviewRole.reporter) {
      final hand = interviewHand(interviewRole, 1, time)!;
      final reach = microphoneReach(time);
      final tip = hand + Offset(4 + reach * 11, -14 + reach * 5);
      line(c, hand + const Offset(0, 3), tip, ink, 4);
      path(
        c,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.lerp(hand, tip, .52)!,
              width: 9,
              height: 8,
            ),
            const Radius.circular(1.5),
          ),
        ),
        const Color(0xFFBC4057),
        edge: .8,
      );
      oval(
        c,
        Rect.fromCenter(center: tip, width: 9, height: 11),
        const Color(0xFF454950),
      );
      line(
        c,
        tip + const Offset(-2, -3),
        tip + const Offset(2, -3),
        const Color(0xFF858C91),
        1,
      );
    } else if (interviewRole == InterviewRole.camera) {
      // Shoulder camera with a viewfinder, grip, lens and recording light.
      path(
        c,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(1, -91, 30, 20),
            const Radius.circular(3),
          ),
        ),
        const Color(0xFF343D46),
      );
      path(
        c,
        Path()..addRect(const Rect.fromLTWH(28, -87, 12, 14)),
        const Color(0xFF202832),
      );
      line(
        c,
        const Offset(40, -86),
        const Offset(40, -75),
        const Color(0xFF6AA4A7),
        3,
      );
      line(c, const Offset(7, -92), const Offset(10, -97), ink, 3);
      line(c, const Offset(10, -97), const Offset(24, -97), ink, 3);
      line(c, const Offset(1, -86), const Offset(-5, -86), ink, 4);
      path(
        c,
        Path()..addRect(const Rect.fromLTWH(9, -87, 13, 9)),
        const Color(0xFF5C747D),
        edge: .7,
      );
      oval(
        c,
        const Rect.fromLTWH(24, -91, 3, 3),
        const Color(0xFFEB6362),
        edge: 0,
      );
      oval(c, const Rect.fromLTWH(22, -75, 8, 6), skin, edge: .7);
    }
    if (thief) {
      for (final y in [-57.0, -48.0, -39.0]) {
        line(
          c,
          Offset(-bw + 2, y),
          Offset(bw - 2, y),
          const Color(0xFFE0DED1),
          3,
        );
      }
      oval(c, const Rect.fromLTWH(-26, -54, 15, 28), const Color(0xFFAA8B68));
    }
    c.restore();
  }

  static void head(
    Canvas c,
    int style,
    Color skin,
    Color hair,
    bool back,
    bool side, {
    double speaking = 0,
  }) {
    final w = [14.0, 13.0, 15.0, 14.0, 13.0, 15.0, 13.5, 14.0][style];
    final long = style == 1 || style == 4;
    if (long) {
      path(
        c,
        Path()
          ..moveTo(-w, -9)
          ..cubicTo(-w - 8, 0, -w - 5, 21, -9, 22)
          ..quadraticBezierTo(6, 24, w + 4, 18)
          ..lineTo(w + 2, -10)
          ..close(),
        hair,
      );
    }
    if (style == 6) {
      oval(
        c,
        Rect.fromCircle(center: Offset(side ? -9 : 7, -16), radius: 7),
        hair,
      );
    }
    if (back) {
      oval(c, Rect.fromLTWH(-w, -17, w * 2, 34), style == 2 ? skin : hair);
      if (style == 2 || style == 7) {
        path(
          c,
          Path()
            ..moveTo(-w, -8)
            ..lineTo(-w + 5, -3)
            ..lineTo(-w + 5, 12)
            ..lineTo(-w, 8)
            ..close(),
          hair,
          edge: .6,
        );
        path(
          c,
          Path()
            ..moveTo(w, -8)
            ..lineTo(w - 5, -3)
            ..lineTo(w - 5, 12)
            ..lineTo(w, 8)
            ..close(),
          hair,
          edge: .6,
        );
      }
      if (style == 3) cap(c, w);
      line(c, const Offset(-5, -11), const Offset(-2, 9), shade(hair, .14), 1);
      return;
    }
    if (!side) {
      oval(
        c,
        Rect.fromCenter(center: Offset(-w, 1), width: 6, height: 9),
        skin,
        edge: 1,
      );
      oval(
        c,
        Rect.fromCenter(center: Offset(w, 1), width: 6, height: 9),
        skin,
        edge: 1,
      );
    }
    final face = side
        ? (Path()
            ..moveTo(-w + 2, -13)
            ..quadraticBezierTo(9, -20, 13, -8)
            ..lineTo(13, -1)
            ..quadraticBezierTo(23, 3, 14, 5)
            ..lineTo(13, 13)
            ..quadraticBezierTo(5, 21, -7, 14)
            ..quadraticBezierTo(-w - 2, 8, -w + 2, -13)
            ..close())
        : (Path()
            ..moveTo(-w, -8)
            ..quadraticBezierTo(-w, -18, 0, -18)
            ..quadraticBezierTo(w, -18, w, -7)
            ..lineTo(w, 5)
            ..quadraticBezierTo(w - 1, 17, 2, 18)
            ..quadraticBezierTo(-w + 1, 17, -w, 5)
            ..close());
    path(c, face, skin, edge: 1.45);
    if (side) oval(c, const Rect.fromLTWH(-13, -2, 7, 10), skin, edge: 1);
    final cheeks = side
        ? [const Offset(9, 8)]
        : [const Offset(-10, 8), const Offset(10, 8)];
    for (final p in cheeks) {
      oval(
        c,
        Rect.fromCenter(center: p, width: 5, height: 3),
        shade(skin, .14),
        edge: 0,
      );
    }
    void eye(double x) {
      oval(
        c,
        Rect.fromCenter(
          center: Offset(x, -2),
          width: side ? 8.8 : 8.2,
          height: 10.2,
        ),
        const Color(0xFFFFFBEF),
        edge: 1,
      );
      oval(
        c,
        Rect.fromCenter(
          center: Offset(x + (side ? 1.6 : .7), -1.4),
          width: 3.3,
          height: 4.8,
        ),
        ink,
        edge: 0,
      );
      c.drawCircle(
        Offset(x + (side ? 1.4 : .5), -2.5),
        .7,
        Paint()..color = Colors.white,
      );
      line(c, Offset(x - 3.1, -9), Offset(x + 3, -9.6), hair, 1.65);
    }

    if (side) {
      eye(8);
    } else {
      eye(-5.2);
      eye(5.2);
    }
    if (!side) {
      final nose = Path()
        ..moveTo(.2, 1)
        ..quadraticBezierTo(-2, 5, .5, 6)
        ..lineTo(3, 5);
      c.drawPath(
        nose,
        Paint()
          ..color = shade(skin, -.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
    final mouth = Path()
      ..moveTo(side ? 6 : -4, 11)
      ..quadraticBezierTo(side ? 10 : 1, 14, side ? 13 : 6, 10);
    c.drawPath(
      mouth,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..strokeCap = StrokeCap.round,
    );
    if (speaking > .15) {
      oval(
        c,
        Rect.fromCenter(
          center: Offset(side ? 10 : 1, 11.5),
          width: 5.5,
          height: 1.5 + speaking * 3.5,
        ),
        const Color(0xFF72483E),
        edge: .65,
      );
    }
    // Hair silhouettes, not a recolored cap, make the eight faces distinguishable.
    switch (style) {
      case 0:
        path(
          c,
          Path()
            ..moveTo(-w, 4)
            ..lineTo(-w - 2, -8)
            ..lineTo(-10, -16)
            ..lineTo(-6, -22)
            ..lineTo(-1, -18)
            ..lineTo(7, -22)
            ..lineTo(14, -14)
            ..quadraticBezierTo(10, -8, 1, -9)
            ..lineTo(-6, -6)
            ..lineTo(-9, -8)
            ..lineTo(-9, 2)
            ..close(),
          hair,
        );
      case 1 || 4:
        path(
          c,
          Path()
            ..moveTo(-w, 8)
            ..quadraticBezierTo(-w - 6, -16, -1, -19)
            ..quadraticBezierTo(12, -21, w + 2, -6)
            ..quadraticBezierTo(7, -6, 3, -12)
            ..quadraticBezierTo(-3, -2, -10, 0)
            ..lineTo(-10, 12)
            ..close(),
          hair,
        );
        line(
          c,
          const Offset(-8, -13),
          const Offset(-12, -3),
          shade(hair, .2),
          1.2,
        );
      case 2:
        path(
          c,
          Path()
            ..moveTo(-w, 2)
            ..lineTo(-w, -11)
            ..quadraticBezierTo(-9, -20, 3, -18)
            ..quadraticBezierTo(11, -18, 14, -11)
            ..quadraticBezierTo(4, -15, -5, -9)
            ..lineTo(-10, -4)
            ..lineTo(-10, 2)
            ..close(),
          hair,
        );
      case 3:
        cap(c, w);
      case 5:
        for (var i = 0; i < 6; i++) {
          oval(
            c,
            Rect.fromCircle(
              center: Offset(-12 + i * 4.8, -13 - sin(i * pi / 5) * 4),
              radius: 5.5,
            ),
            hair,
            edge: .9,
          );
        }
        path(
          c,
          Path()
            ..moveTo(-9, 9)
            ..quadraticBezierTo(0, 18, 11, 9)
            ..lineTo(9, 16)
            ..quadraticBezierTo(1, 22, -8, 15)
            ..close(),
          hair,
          edge: .7,
        );
      case 6:
        path(
          c,
          Path()
            ..moveTo(-w, 4)
            ..quadraticBezierTo(-18, -15, -4, -18)
            ..quadraticBezierTo(13, -22, 14, -8)
            ..quadraticBezierTo(3, -10, -4, -10)
            ..lineTo(-9, -4)
            ..lineTo(-10, 3)
            ..close(),
          hair,
        );
      default:
        path(
          c,
          Path()
            ..moveTo(-w, 3)
            ..lineTo(-w, -10)
            ..quadraticBezierTo(-10, -18, -3, -16)
            ..quadraticBezierTo(8, -22, 14, -9)
            ..lineTo(10, -8)
            ..quadraticBezierTo(0, -13, -9, -6)
            ..lineTo(-10, 3)
            ..close(),
          hair,
        );
    }
    if (style == 2 || style == 7) {
      for (final x in side ? [8.0] : [-5.2, 5.2]) {
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, -2), width: 10, height: 11),
          const Radius.circular(3),
        );
        c.drawRRect(
          r,
          Paint()
            ..color = const Color(0xFF535D57)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      if (!side) line(c, const Offset(-.5, -2), const Offset(.5, -2), ink, 1);
      if (side) line(c, const Offset(-8, -3), const Offset(3, -3), ink, 1.1);
    }
    if (long) {
      oval(
        c,
        Rect.fromCircle(center: Offset(side ? -10 : w, 7), radius: 1.7),
        const Color(0xFFE5C674),
        edge: .5,
      );
    }
  }

  static void cap(Canvas c, double w) {
    path(
      c,
      Path()
        ..moveTo(-w - 1, -8)
        ..quadraticBezierTo(-w - 1, -23, 0, -22)
        ..quadraticBezierTo(w, -23, w + 1, -8)
        ..close(),
      const Color(0xFF4D7271),
    );
    path(
      c,
      Path()
        ..moveTo(-3, -9)
        ..quadraticBezierTo(11, -12, 21, -7)
        ..lineTo(18, -4)
        ..quadraticBezierTo(6, -7, -3, -6)
        ..close(),
      const Color(0xFF688E89),
    );
  }
}

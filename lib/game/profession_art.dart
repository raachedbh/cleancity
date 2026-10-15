import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'walk_cycle.dart';
import 'arm_motion.dart';

/// Original vector costumes, using the existing four-direction hero's face.
/// Public-domain outfit references are documented in docs/OUTFIT_SOURCES_V6.md.
class ProfessionArt {
  static void draw(
    Canvas c, {
    required ui.Image atlas,
    required Rect source,
    required int outfit,
    required int facing,
    required Offset position,
    required WalkCycle gait,
    required double time,
    required double lean,
  }) {
    const ink = Color(0xFF343B40), skin = Color(0xFFDEA15F);
    const white = Color(0xFFF4F3E8), teal = Color(0xFF429D99);
    const gold = Color(0xFFD7B46B), red = Color(0xFFB8493B);
    final id = outfit - 6;
    final side = facing == 1 || facing == 3, back = facing == 2 || facing == 1;
    final sign = facing == 3 ? -1.0 : 1.0;
    final bob = gait.bob + sin(time * 1.9) * .22 * (1 - gait.blend);
    final cloth = const [
      Color(0xFFCFAB69),
      Color(0xFF745284),
      white,
      white,
      Color(0xFFE1E9EB),
      Color(0xFF41647A),
    ][id];
    final pants = const [
      Color(0xFF5A5146),
      Color(0xFF45414E),
      Color(0xFF388C8A),
      Color(0xFF515C63),
      Color(0xFFDEE6E8),
      Color(0xFF41647A),
    ][id];
    final radius = side ? 12.0 : 15.0;
    void shape(Path path, Color color, [double stroke = 1.2]) {
      c.drawPath(path, Paint()..color = color);
      c.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void line(Offset a, Offset b, Color color, double width) {
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    void box(Rect rect, Color color, [double curve = 2]) {
      final r = RRect.fromRectAndRadius(rect, Radius.circular(curve));
      c.drawRRect(r, Paint()..color = color);
      c.drawRRect(
        r,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    void oval(Rect rect, Color color, [bool stroke = true]) {
      c.drawOval(rect, Paint()..color = color);
      if (stroke) {
        c.drawOval(
          rect,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
    }

    void limb(List<Offset> points, Color color, double width) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      for (final (color, w) in [(ink, width + 1.6), (color, width)]) {
        c.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = w
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    c.save();
    c.translate(position.dx, position.dy);
    oval(const Rect.fromLTWH(-19, -3, 38, 11), const Color(0x34343C31), false);
    for (var i = 0; i < 2; i++) {
      final f = gait.foot(i), x = (i == 0 ? -1 : 1) * (side ? 4.0 : 8.0);
      final hip = Offset(x, -34 - bob);
      final foot = Offset(
        x + (side ? f.travel * 14 * sign : f.travel * 1.5),
        -3 - f.lift + (side ? 0 : f.travel * 3.2),
      );
      final knee = side
          ? kneeBetween(hip, foot, 15.5, 16, -sign)
          : Offset.lerp(hip, foot, .48)!;
      limb(
        [hip, knee, foot - const Offset(0, 2)],
        i == 0 && side ? Color.lerp(pants, Colors.black, .15)! : pants,
        9,
      );
      if (id == 0) {
        line(
          Offset.lerp(knee, foot, .45)! - const Offset(3.5, 0),
          Offset.lerp(knee, foot, .45)! + const Offset(3.5, 0),
          gold,
          3,
        );
      }
      c.save();
      c.translate(foot.dx, foot.dy);
      c.rotate(side ? -f.travel * .09 * sign : f.travel * .035);
      final toe = side ? sign * 2.5 : (i == 0 ? -1.0 : 1.0);
      box(
        Rect.fromLTWH(-6.5 + toe, -5, 14, 8),
        id == 4 ? white : const Color(0xFF41494D),
        2.4,
      );
      line(
        Offset(-5 + toe, 1.5),
        Offset(6 + toe, 1.5),
        id == 4 ? const Color(0xFF8DA3B0) : const Color(0xFF758084),
        1.2,
      );
      c.restore();
    }
    c.save();
    c.translate(lean * 1.8 + sin(gait.phase) * .35 * gait.blend, -bob);
    c.rotate(lean * .025);
    // Packs sit behind shoulders and are visible when turning around.
    if (id == 4) {
      box(
        Rect.fromLTWH(side ? -sign * 19 - 7 : -17, -66, side ? 14 : 34, 34),
        const Color(0xFFA9BEC8),
        5,
      );
      if (back) {
        for (final x in [-9.0, 3.0]) {
          box(Rect.fromLTWH(x, -63, 7, 28), white, 3);
        }
      }
    }
    void arm(int index) {
      final pose = ArmPose.walk(
        gait,
        index,
        side: side,
        shoulderWidth: radius,
        direction: sign,
        time: time,
      );
      ArmArt.draw(
        c,
        pose,
        cloth: cloth,
        skin: id == 0
            ? const Color(0xFF51534B)
            : id == 4
            ? white
            : skin,
        longSleeve: true,
        far: side && index == 0,
        cuff: id == 0
            ? const Color(0xFFE4DC83)
            : id == 4
            ? const Color(0xFF7898B1)
            : null,
      );
    }

    arm(0);
    if (!side) arm(1);
    final longCoat = id == 1 || id == 2;
    final bottom = longCoat ? -18.0 : -30.0;
    final body = Path()
      ..moveTo(-8, -67)
      ..lineTo(8, -67)
      ..lineTo(radius + 2, -60)
      ..lineTo(radius + (longCoat ? 3 : 0), bottom)
      ..quadraticBezierTo(0, bottom + 3, -radius - (longCoat ? 3 : 0), bottom)
      ..lineTo(-radius - 2, -60)
      ..close();
    shape(body, cloth);
    // A shaded side panel gives the otherwise flat costume volume.
    c.save();
    c.clipPath(body);
    c.drawRect(
      Rect.fromLTWH(radius - 5, -70, 10, 58),
      Paint()..color = ink.withValues(alpha: .13),
    );
    c.restore();
    if (!back) {
      final center = side ? sign * 4 : 0.0;
      c.save();
      c.translate(center, 0);
      if (id == 0) {
        for (final y in [-54.0, -39.0]) {
          line(
            Offset(-radius + 2, y),
            Offset(radius - 3, y),
            const Color(0xFFE6E398),
            4.5,
          );
          line(Offset(-radius + 2, y), Offset(radius - 3, y), white, 1.1);
        }
        line(const Offset(0, -65), const Offset(0, -31), ink, 1);
        box(const Rect.fromLTWH(-11, -52, 7, 8), cloth, 1);
      } else if (id == 1) {
        shape(
          Path()
            ..moveTo(-7, -66)
            ..lineTo(0, -51)
            ..lineTo(7, -66)
            ..lineTo(4, -37)
            ..lineTo(-4, -37)
            ..close(),
          const Color(0xFFDBBD86),
        );
        line(const Offset(-12, -33), const Offset(12, -33), ink, 4);
        box(const Rect.fromLTWH(-3, -36, 6, 6), gold, 1);
        for (var n = 0; n < 2; n++) {
          final x = n == 0 ? -9.0 : 8.0;
          box(
            Rect.fromLTWH(x - 2, -31, 4, 9),
            n == 0 ? teal : const Color(0xFFC88FC1),
          );
          line(Offset(x - 1, -32), Offset(x + 1, -32), gold, 2.5);
        }
        line(const Offset(0, -27), const Offset(0, -18), ink, .8);
      } else if (id == 2) {
        shape(
          Path()
            ..moveTo(-7, -66)
            ..lineTo(7, -66)
            ..lineTo(5, -33)
            ..lineTo(-5, -33)
            ..close(),
          teal,
          .6,
        );
        for (final sign in [-1.0, 1.0]) {
          shape(
            Path()
              ..moveTo(sign * 7, -67)
              ..lineTo(sign * 11, -56)
              ..lineTo(sign * 7, -54)
              ..lineTo(sign * 9, -50)
              ..lineTo(sign * 3, -37)
              ..close(),
            white,
            .6,
          );
        }
        final tube = Path()
          ..moveTo(-6, -63)
          ..cubicTo(-10, -44, 8, -45, 6, -63);
        c.drawPath(
          tube,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        oval(const Rect.fromLTWH(2, -48, 4, 4), const Color(0xFFB0C3CB));
        box(const Rect.fromLTWH(8, -54, 5, 7), const Color(0xFFA2D8DB), .5);
        line(const Offset(-12, -29), const Offset(-7, -29), ink, .6);
      } else if (id == 3) {
        shape(
          Path()
            ..moveTo(-7, -66)
            ..lineTo(0, -61)
            ..lineTo(7, -66)
            ..lineTo(3, -56)
            ..lineTo(0, -58)
            ..lineTo(-3, -56)
            ..close(),
          red,
          .7,
        );
        for (final y in [-53.0, -46.0, -39.0]) {
          for (final x in [-4.0, 4.0]) {
            oval(
              Rect.fromCenter(center: Offset(x, y), width: 2, height: 2),
              ink,
              false,
            );
          }
        }
        line(
          const Offset(-11, -32),
          const Offset(11, -32),
          const Color(0xFFCBD3D1),
          1,
        );
      } else if (id == 4) {
        box(const Rect.fromLTWH(-9, -57, 18, 16), const Color(0xFF91ADB9));
        box(const Rect.fromLTWH(-6, -54, 12, 6), const Color(0xFF3C6579), 1);
        for (var n = 0; n < 3; n++) {
          oval(
            Rect.fromLTWH(-5 + n * 4, -45, 2, 2),
            n == 0 ? red : gold,
            false,
          );
        }
        line(
          const Offset(-12, -33),
          const Offset(12, -33),
          const Color(0xFF849FAB),
          3,
        );
      } else {
        for (final x in [-8.0, 8.0]) {
          line(Offset(x, -64), Offset(x, -47), const Color(0xFF98B8BB), 3.2);
          oval(Rect.fromLTWH(x - 1, -48, 2, 2), gold, false);
        }
        box(const Rect.fromLTWH(-7, -52, 14, 10), const Color(0xFF34576C), 1);
        line(
          const Offset(-13, -34),
          const Offset(13, -34),
          const Color(0xFF986B49),
          4,
        );
        line(
          const Offset(9, -45),
          const Offset(9, -27),
          const Color(0xFFC8D6D7),
          2,
        );
        line(
          const Offset(7, -44),
          const Offset(7, -41),
          const Color(0xFFC8D6D7),
          2,
        );
        line(
          const Offset(11, -44),
          const Offset(11, -41),
          const Color(0xFFC8D6D7),
          2,
        );
      }
      c.restore();
    } else if (id == 0) {
      for (final y in [-54.0, -39.0]) {
        line(
          Offset(-radius + 1, y),
          Offset(radius - 1, y),
          const Color(0xFFE6E398),
          4,
        );
      }
    } else if (id == 5) {
      line(
        const Offset(-9, -63),
        const Offset(8, -42),
        const Color(0xFF98B8BB),
        3,
      );
      line(
        const Offset(9, -63),
        const Offset(-8, -42),
        const Color(0xFF98B8BB),
        3,
      );
    } else if (longCoat) {
      line(
        const Offset(0, -60),
        Offset(0, bottom),
        Color.lerp(cloth, ink, .28)!,
        .9,
      );
    }
    if (id == 4 && back) {
      box(const Rect.fromLTWH(-12, -60, 24, 27), const Color(0xFFA9BEC8), 4);
      box(const Rect.fromLTWH(-7, -56, 14, 14), white, 2);
    }
    if (side) arm(1);
    // Only the head region of the hero atlas is used; no old shirt shows through.
    box(const Rect.fromLTWH(-4, -71, 8, 8), skin, 2);
    final w = 104 * source.width / source.height;
    c.drawImageRect(
      atlas,
      Rect.fromLTWH(source.left, source.top, source.width, source.height * .37),
      Rect.fromLTWH(-w / 2, -104, w, 104 * .37),
      Paint()..filterQuality = FilterQuality.medium,
    );
    if (id == 0) {
      shape(
        Path()
          ..moveTo(-16, -93)
          ..quadraticBezierTo(-17, -111, 0, -112)
          ..quadraticBezierTo(18, -112, 18, -93)
          ..close(),
        red,
      );
      box(const Rect.fromLTWH(-20, -96, 41, 5), const Color(0xFF9C3933), 2);
      if (!back) {
        final x = side ? sign * 7 : 0.0;
        shape(
          Path()
            ..moveTo(x - 4, -106)
            ..lineTo(x + 4, -106)
            ..lineTo(x + 3, -99)
            ..lineTo(x, -97)
            ..lineTo(x - 3, -99)
            ..close(),
          gold,
          .8,
        );
      }
    } else if (id == 1) {
      // Brass goggles rest above the eyes, leaving the expression visible.
      line(
        const Offset(-16, -95),
        const Offset(16, -95),
        const Color(0xFF6D493C),
        4,
      );
      if (!back) {
        for (final x in side ? [sign * 7] : [-7.0, 7.0]) {
          oval(
            Rect.fromCenter(center: Offset(x, -95), width: 11, height: 8),
            gold,
          );
          oval(
            Rect.fromCenter(center: Offset(x, -95), width: 7, height: 4),
            teal,
            false,
          );
          line(Offset(x - 2, -96), Offset(x, -96), white, 1);
        }
      }
    } else if (id == 2) {
      // A teal medical cap and a small silver headlight (no protected emblem).
      shape(
        Path()
          ..moveTo(-16, -95)
          ..lineTo(-15, -102)
          ..quadraticBezierTo(0, -110, 16, -101)
          ..lineTo(17, -95)
          ..close(),
        teal,
      );
      if (!back) {
        oval(
          Rect.fromCenter(
            center: Offset(side ? sign * 8 : 0, -98),
            width: 5,
            height: 5,
          ),
          const Color(0xFFDCE7E9),
        );
      }
    } else if (id == 3) {
      shape(
        Path()
          ..moveTo(-14, -99)
          ..lineTo(-16, -108)
          ..cubicTo(-24, -115, -15, -123, -8, -118)
          ..cubicTo(-5, -127, 8, -127, 11, -118)
          ..cubicTo(21, -122, 25, -111, 17, -108)
          ..lineTo(14, -99)
          ..close(),
        white,
      );
      box(const Rect.fromLTWH(-15, -102, 30, 7), white, 1);
      line(
        const Offset(-7, -111),
        const Offset(-6, -103),
        const Color(0xFFBFCAC8),
        1,
      );
      line(
        const Offset(7, -112),
        const Offset(6, -103),
        const Color(0xFFBFCAC8),
        1,
      );
    } else if (id == 4) {
      final helmet = Rect.fromLTWH(-24, -113, 48, 47);
      oval(helmet, const Color(0x367CBCD7), false);
      c.drawOval(
        helmet,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );
      c.drawOval(
        helmet,
        Paint()
          ..color = white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8,
      );
      c.drawArc(
        helmet.deflate(5),
        pi * 1.1,
        .58,
        false,
        Paint()
          ..color = const Color(0xBAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3
          ..strokeCap = StrokeCap.round,
      );
      box(const Rect.fromLTWH(-13, -71, 26, 6), const Color(0xFFB6CCD4), 2);
    } else {
      shape(
        Path()
          ..moveTo(-16, -96)
          ..quadraticBezierTo(-18, -109, 0, -109)
          ..quadraticBezierTo(17, -109, 16, -96)
          ..close(),
        const Color(0xFFBC8754),
      );
      box(
        Rect.fromLTWH(
          side ? (sign > 0 ? -3 : -23) : -17,
          -98,
          side ? 26 : 34,
          4,
        ),
        const Color(0xFF8F633F),
        2,
      );
      if (!back) {
        box(Rect.fromLTWH(side ? sign * 7 - 3 : -4, -105, 7, 5), gold, 1);
      }
    }
    c.restore();
    c.restore();
  }
}

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'walk_cycle.dart';
import 'profession_art.dart';
import 'arm_motion.dart';

/// Original atlas faces over a fully articulated, code-drawn body.
class PlayerArt {
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
    if (outfit >= 6) {
      ProfessionArt.draw(
        c,
        atlas: atlas,
        source: source,
        outfit: outfit,
        facing: facing,
        position: position,
        gait: gait,
        time: time,
        lean: lean,
      );
      return;
    }
    const h = 104.0;
    final w = h * source.width / source.height;
    final side = facing == 1 || facing == 3;
    final sign = facing == 3 ? -1.0 : 1.0;
    final bob = gait.bob + sin(time * 1.9) * .22 * (1 - gait.blend);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    const outline = Color(0xFF383632);
    final pants = const [
      Color(0xFFC4B68F),
      Color(0xFF235071),
      Color(0xFF414241),
      Color(0xFF234C6B),
      Color(0xFF393137),
      Color(0xFF40525A),
    ][outfit];
    final shoes = outfit == 3
        ? const Color(0xFFCA742E)
        : outfit == 1
        ? const Color(0xFF424543)
        : outfit >= 4
        ? const Color(0xFF463A32)
        : const Color(0xFFF4F1E6);
    c.save();
    c.translate(position.dx, position.dy);
    c.drawOval(
      const Rect.fromLTWH(-19, -3, 38, 11),
      Paint()..color = const Color(0x34343C31),
    );
    void bone(Offset from, Offset to, Color color, double width) {
      c.drawLine(
        from,
        to,
        Paint()
          ..color = outline
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width + 1.5,
      );
      c.drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width,
      );
    }

    void leg(int index) {
      final f = gait.foot(index);
      final baseX = side
          ? (index == 0 ? -4.0 : 4.0)
          : (index == 0 ? -8.0 : 8.0);
      final hip = Offset(baseX, -34 - bob);
      final foot = Offset(
        baseX + (side ? f.travel * 14 * sign : f.travel * 1.5),
        -3 - f.lift + (side ? 0 : f.travel * 3.2),
      );
      final knee = side
          ? kneeBetween(hip, foot, 15.5, 16, -sign)
          : Offset.lerp(hip, foot, .48)! +
                Offset((index == 0 ? -1 : 1) * f.lift * .16, 0);
      final color = index == 0 && side
          ? Color.lerp(pants, Colors.black, .13)!
          : pants;
      final limbPath = Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy - 2);
      final width = outfit >= 4 ? 8.5 : 9.5;
      c.drawPath(
        limbPath,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width + 1.5,
      );
      c.drawPath(
        limbPath,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width,
      );
      c.save();
      c.translate(foot.dx, foot.dy);
      c.rotate(side ? f.travel * -.09 * sign : f.travel * .035);
      final toe = side ? sign * 2.5 : (index == 0 ? -1.0 : 1.0);
      final shoe = RRect.fromRectAndRadius(
        Rect.fromLTWH(-6.5 + toe, -3, 14, 6),
        const Radius.circular(2.5),
      );
      c.drawRRect(shoe, Paint()..color = shoes);
      c.drawRRect(
        shoe,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      bone(
        Offset(-5 + toe, 2),
        Offset(6 + toe, 2),
        outfit >= 4 ? const Color(0xFF302C29) : const Color(0xFFDDDCD4),
        1.4,
      );
      if (outfit >= 4) {
        c.drawRect(
          Rect.fromLTWH(toe - 3, -3, 5, 3),
          Paint()
            ..color = const Color(0xFFBF9D53)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
      } else {
        bone(
          Offset(toe - 2, -1.5),
          Offset(toe + 3, -1.5),
          const Color(0xFFDADBD4),
          .7,
        );
      }
      c.restore();
    }

    leg(0);
    leg(1);
    c.save();
    c.translate(lean * 1.8 + sin(gait.phase) * .35 * gait.blend, -bob);
    c.rotate(lean * .025);
    final back = facing == 1 || facing == 2;
    final radius = side ? 11.0 : 15.0;
    final cloth = const [
      Color(0xFF167A7D),
      Color(0xFFF1EEE6),
      Color(0xFF9982C3),
      Color(0xFF204A6C),
      Color(0xFF842C42),
      Color(0xFF245A66),
    ][outfit];
    final skin = outfit < 4 ? const Color(0xFFDEA15F) : const Color(0xFFE6AE78);
    void shape(Path p, Color color, [double width = 1.25]) {
      c.drawPath(p, Paint()..color = color);
      c.drawPath(
        p,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (outfit >= 4) {
      final sway = sin(gait.phase - .55) * 3 * gait.blend;
      final cape = Path()
        ..moveTo(-radius, -66)
        ..lineTo(radius, -66)
        ..cubicTo(
          radius + 8,
          -53,
          radius + 11 + sway,
          -25,
          radius + 12 + sway,
          -12,
        )
        ..quadraticBezierTo(0, -18, -radius - 12 + sway, -12)
        ..cubicTo(-radius - 9 + sway, -33, -radius - 6, -55, -radius, -66)
        ..close();
      shape(
        cape,
        outfit == 4 ? const Color(0xFF3D2949) : const Color(0xFF327684),
      );
      c.drawPath(
        Path()
          ..moveTo(-radius, -58)
          ..quadraticBezierTo(-radius - 2 + sway, -31, -radius - 9 + sway, -15),
        Paint()
          ..color = (outfit == 4
              ? const Color(0xFF9C3456)
              : const Color(0xFFDCB465))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8,
      );
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
        cloth: outfit == 4 ? const Color(0xFFF0E0C5) : cloth,
        skin: outfit == 5 ? const Color(0xFF624B35) : skin,
        longSleeve: outfit >= 2,
        far: side && index == 0,
        cuff: outfit >= 4 ? const Color(0xFFD6B779) : null,
      );
    }

    arm(0);
    if (!side) arm(1);
    final bottom = outfit == 5 ? -19.0 : -31.0;
    final torso = Path()
      ..moveTo(-7, -69)
      ..quadraticBezierTo(-radius - 2, -67, -radius - 2, -58)
      ..lineTo(-radius, bottom)
      ..quadraticBezierTo(0, bottom + 3, radius, bottom)
      ..lineTo(radius + 2, -58)
      ..quadraticBezierTo(radius + 2, -67, 7, -69)
      ..close();
    shape(torso, cloth);
    c.save();
    c.clipPath(torso);
    c.drawRect(
      Rect.fromLTWH(radius - 4, -68, 8, 52),
      Paint()..color = outline.withValues(alpha: .14),
    );
    c.restore();
    if (outfit == 1) {
      for (final a in [-1.0, 1.0]) {
        shape(
          Path()
            ..moveTo(a * 6, -68)
            ..lineTo(a * (radius + 1), -61)
            ..lineTo(a * radius, -31)
            ..lineTo(a * 3, -31)
            ..lineTo(a * 3, -55)
            ..close(),
          const Color(0xFFF1A223),
        );
      }
      for (final y in [-47.0, -39.0]) {
        bone(
          Offset(-radius + 1, y),
          Offset(radius - 1, y),
          const Color(0xFFDDE68C),
          3,
        );
      }
    } else if (outfit == 2) {
      shape(
        Path()
          ..moveTo(-9, -68)
          ..quadraticBezierTo(0, -59, 9, -68)
          ..quadraticBezierTo(0, -76, -9, -68),
        const Color(0xFFAD96D0),
      );
      if (!back) {
        bone(
          const Offset(-4, -63),
          const Offset(-4, -51),
          const Color(0xFFD3C5E9),
          .9,
        );
        bone(
          const Offset(4, -63),
          const Offset(4, -52),
          const Color(0xFFD3C5E9),
          .9,
        );
        shape(
          Path()
            ..moveTo(-7, -44)
            ..lineTo(7, -44)
            ..lineTo(10, -34)
            ..lineTo(-10, -34)
            ..close(),
          Color.lerp(cloth, Colors.black, .07)!,
          .7,
        );
      }
    } else if (outfit == 3) {
      bone(
        Offset(-radius, -34),
        Offset(radius, -34),
        const Color(0xFF192F42),
        3,
      );
      if (!back) {
        bone(
          const Offset(0, -65),
          const Offset(0, -35),
          const Color(0xFF4A6B7D),
          1,
        );
        for (final x in [-8.0, 8.0]) {
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x - 4, -56, 8, 8),
                const Radius.circular(1),
              ),
            ),
            cloth,
            .8,
          );
        }
      }
    } else if (outfit == 4) {
      if (!back) {
        shape(
          Path()
            ..moveTo(-6, -68)
            ..lineTo(6, -68)
            ..lineTo(0, -54)
            ..close(),
          const Color(0xFFF0E0C5),
        );
        for (final y in [-51.0, -43.0, -35.0]) {
          c.drawCircle(
            Offset(1, y),
            1.3,
            Paint()..color = const Color(0xFFE7BC60),
          );
        }
      }
      shape(
        Path()
          ..moveTo(-8, -66)
          ..lineTo(-17, -77)
          ..lineTo(-11, -59)
          ..close(),
        const Color(0xFF54253F),
      );
      shape(
        Path()
          ..moveTo(8, -66)
          ..lineTo(17, -77)
          ..lineTo(11, -59)
          ..close(),
        const Color(0xFF54253F),
      );
    } else if (outfit == 5) {
      for (final a in [-1.0, 1.0]) {
        bone(
          Offset(a * 12, -58),
          Offset(a * radius, -20),
          const Color(0xFFD6B779),
          1.8,
        );
      }
      bone(
        Offset(-radius, -36),
        Offset(radius, -36),
        const Color(0xFF79533C),
        4,
      );
      shape(
        Path()..addRect(const Rect.fromLTWH(-3, -39, 6, 6)),
        const Color(0xFFD6B779),
        .8,
      );
      bone(
        const Offset(-10, -68),
        const Offset(11, -66),
        const Color(0xFF378A91),
        5,
      );
      if (!back) {
        bone(
          const Offset(6, -64),
          Offset(9 + sin(gait.phase - .5) * gait.blend, -52),
          const Color(0xFF378A91),
          5,
        );
      }
    }
    if (side) arm(1);
    // Only the head is sampled. There are no static atlas arms or torso remnants.
    final headPart = outfit < 4 ? .35 : .325;
    c.drawImageRect(
      atlas,
      Rect.fromLTWH(
        source.left,
        source.top,
        source.width,
        source.height * headPart,
      ),
      Rect.fromLTWH(-w / 2, -h, w, h * headPart),
      paint,
    );
    c.restore();
    c.restore();
  }
}

import 'dart:ui';
import '../data/album.dart';
import 'world_art.dart';

/// Shared, resolution-independent artwork for the street and collection cards.
class AlbumArt {
  static const ink = Color(0xFF344759), gold = Color(0xFFF5C560);
  static void valuable(
    Canvas c,
    ValuableKind kind,
    Offset p, {
    double scale = 1,
  }) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    void shape(Path path, Color color) {
      c.drawPath(path, Paint()..color = color);
      c.drawPath(path, outline);
    }

    void box(Rect r, Color color, [double radius = 5]) {
      final rounded = RRect.fromRectAndRadius(r, Radius.circular(radius));
      c.drawRRect(rounded, Paint()..color = color);
      c.drawRRect(rounded, outline);
    }

    switch (kind) {
      case ValuableKind.jewelry:
        c.drawOval(
          const Rect.fromLTWH(-18, -22, 36, 36),
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        shape(
          Path()..addPolygon(const [
            Offset(0, 2),
            Offset(11, 10),
            Offset(0, 25),
            Offset(-11, 10),
          ], true),
          const Color(0xFFE98795),
        );
        c.drawLine(
          const Offset(-7, 10),
          const Offset(7, 10),
          Paint()
            ..color = const Color(0xFFFFE0DA)
            ..strokeWidth = 2,
        );
      case ValuableKind.wallet:
        box(const Rect.fromLTWH(-25, -17, 50, 36), const Color(0xFFC98F62));
        c.drawLine(
          const Offset(-21, -10),
          const Offset(20, -10),
          Paint()
            ..color = const Color(0xFFEFCCA2)
            ..strokeWidth = 2,
        );
        box(const Rect.fromLTWH(5, -6, 23, 15), const Color(0xFF986B55), 3);
        c.drawCircle(const Offset(13, 1), 2.5, Paint()..color = gold);
      case ValuableKind.handbag:
        c.drawOval(
          const Rect.fromLTWH(-12, -27, 24, 33),
          outline..strokeWidth = 4,
        );
        outline.strokeWidth = 2.5;
        shape(
          Path()..addPolygon(const [
            Offset(-21, -10),
            Offset(21, -10),
            Offset(27, 24),
            Offset(-27, 24),
          ], true),
          const Color(0xFFB498D2),
        );
        c.drawLine(
          const Offset(-18, -3),
          const Offset(18, -3),
          Paint()
            ..color = const Color(0xFFDAD0ED)
            ..strokeWidth = 2,
        );
        box(const Rect.fromLTWH(-5, -8, 10, 10), gold, 2);
      case ValuableKind.watch:
        box(const Rect.fromLTWH(-10, -30, 20, 60), const Color(0xFF729EB7), 5);
        c.drawCircle(Offset.zero, 18, Paint()..color = gold);
        c.drawCircle(Offset.zero, 18, outline);
        c.drawCircle(Offset.zero, 13, Paint()..color = const Color(0xFFFCF7E8));
        c.drawLine(Offset.zero, const Offset(0, -9), outline);
        c.drawLine(Offset.zero, const Offset(7, 3), outline);
    }
    c.restore();
  }

  static void badge(Canvas c, Offset p, double size) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(size / 20);
    final path = Path()
      ..moveTo(-9, -10)
      ..lineTo(9, -10)
      ..lineTo(9, 2)
      ..quadraticBezierTo(9, 9, 0, 13)
      ..quadraticBezierTo(-9, 9, -9, 2)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFF486DA8));
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF9E2A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawCircle(const Offset(0, -1), 3, Paint()..color = gold);
    c.restore();
  }

  static void police(Canvas c, Offset p, int city) {
    c.save();
    c.translate(p.dx, p.dy);
    final wall = const [
      Color(0xFFE5E7D4),
      Color(0xFFF0D6B0),
      Color(0xFFF4E4C8),
      Color(0xFFE5DCD1),
      Color(0xFFE4DBC7),
      Color(0xFFBBB6C9),
    ][city];
    void rect(Rect r, Color color, [double radius = 0]) {
      final path = RRect.fromRectAndRadius(r, Radius.circular(radius));
      c.drawRRect(path, Paint()..color = color);
      c.drawRRect(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    c.drawPath(
      Path()..addPolygon(const [
        Offset(-80, -25),
        Offset(86, -28),
        Offset(120, 22),
        Offset(-50, 27),
      ], true),
      Paint()..color = const Color(0x260D2837),
    );
    rect(const Rect.fromLTWH(-85, -35, 170, 50), const Color(0xFFC4C7C1), 3);
    rect(const Rect.fromLTWH(-80, -86, 160, 91), wall, 3);
    rect(const Rect.fromLTWH(-87, -100, 174, 19), const Color(0xFF385D86), 4);
    rect(const Rect.fromLTWH(-80, -66, 160, 23), const Color(0xFF486DA8));
    WorldArt.label(
      c,
      'POLICE',
      const Offset(0, -65),
      16,
      const Color(0xFFFFFFFF),
    );
    rect(const Rect.fromLTWH(-17, -36, 34, 41), const Color(0xFF547E95), 3);
    c.drawCircle(const Offset(10, -13), 2.5, Paint()..color = gold);
    for (final x in [-62.0, 32.0]) {
      rect(Rect.fromLTWH(x, -32, 30, 25), const Color(0xFF96C3D3), 2);
      c.drawLine(
        Offset(x + 15, -31),
        Offset(x + 15, -8),
        Paint()
          ..color = const Color(0xFFF4F1DB)
          ..strokeWidth = 3,
      );
    }
    badge(c, const Offset(0, -103), 25);
    c.restore();
  }
}

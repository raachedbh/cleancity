import 'dart:math';
import 'dart:ui';

/// Original vector interpretation of the user's Tour de l'Horloge photograph.
class TunisClock {
  static const height = 590.0;
  static void draw(Canvas c, Rect ground) {
    c.save();
    c.translate(ground.center.dx, ground.center.dy + 30);
    void poly(List<Offset> p, Color color) {
      final path = Path()..addPolygon(p, true);
      c.drawPath(path, Paint()..color = color);
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF574A37)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    void line(Offset a, Offset b, Color color, double width) => c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    c.drawOval(
      const Rect.fromLTWH(-155, -70, 330, 155),
      Paint()..color = const Color(0xFF8D968D),
    );
    c.drawOval(
      const Rect.fromLTWH(-152, -79, 322, 151),
      Paint()..color = const Color(0xFFCFCEC0),
    );
    c.drawOval(
      const Rect.fromLTWH(-138, -70, 294, 130),
      Paint()..color = const Color(0xFF7FA9AB),
    );
    for (var i = 0; i < 4; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(9, -5),
          width: 270 - i * 35.0,
          height: 115 - i * 15.0,
        ),
        Paint()
          ..color = const Color(0x448ED3CD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    poly([
      const Offset(-55, 6),
      const Offset(58, 6),
      const Offset(77, -12),
      const Offset(-32, -12),
    ], const Color(0xFFD5C8A9));
    poly([
      const Offset(-55, 6),
      const Offset(58, 6),
      const Offset(49, -90),
      const Offset(-47, -90),
    ], const Color(0xFFB7A37A));
    poly([
      const Offset(58, 6),
      const Offset(77, -12),
      const Offset(66, -104),
      const Offset(49, -90),
    ], const Color(0xFF88724F));
    final body = Path()
      ..addPolygon([
        const Offset(-48, -84),
        const Offset(49, -84),
        const Offset(29, -493),
        const Offset(-31, -493),
      ], true);
    c.drawPath(body, Paint()..color = const Color(0xFF9B7850));
    poly([
      const Offset(49, -84),
      const Offset(66, -104),
      const Offset(46, -504),
      const Offset(29, -493),
    ], const Color(0xFF70513B));
    c.save();
    c.clipPath(body);
    // Perforated bronze panels and rosettes, visible at street-view scale.
    for (var y = -477.0; y < -88; y += 8) {
      for (var x = -46.0; x < 49; x += 8) {
        c.drawCircle(
          Offset(x + (y.toInt() % 16 == 0 ? 4 : 0), y),
          1.25,
          Paint()..color = const Color(0xFF574733),
        );
      }
    }
    for (var y = -470.0; y < -100; y += 42) {
      for (final x in [-21.0, 20.0]) {
        final p = Offset(x, y);
        for (var i = 0; i < 8; i++) {
          final d = Offset(cos(i * pi / 4), sin(i * pi / 4));
          line(p + d * 4, p + d * 12, const Color(0xFFC2A277), 1.2);
        }
        c.drawCircle(p, 5, Paint()..color = const Color(0xFF715138));
      }
    }
    for (var y = -120.0; y > -490; y -= 84) {
      line(Offset(-49, y), Offset(49, y), const Color(0xFFCFB48A), 1.6);
    }
    line(
      const Offset(0, -88),
      const Offset(0, -493),
      const Color(0xFFCFB48A),
      1.4,
    );
    c.restore();
    line(
      const Offset(-48, -84),
      const Offset(-31, -493),
      const Color(0xFFCCAB76),
      2.2,
    );
    line(
      const Offset(49, -84),
      const Offset(29, -493),
      const Color(0xFF654C35),
      2.2,
    );
    poly([
      const Offset(-41, -490),
      const Offset(39, -490),
      const Offset(39, -565),
      const Offset(-41, -565),
    ], const Color(0xFFC9B995));
    poly([
      const Offset(39, -490),
      const Offset(56, -506),
      const Offset(56, -577),
      const Offset(39, -565),
    ], const Color(0xFF93764D));
    const face = Offset(-1, -528);
    c.drawCircle(face, 33, Paint()..color = const Color(0xFFEEE6C8));
    for (final radius in [33.0, 28.0]) {
      c.drawCircle(
        face,
        radius,
        Paint()
          ..color = const Color(0xFF4B4230)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    for (var i = 0; i < 12; i++) {
      final d = Offset(sin(i * pi / 6), -cos(i * pi / 6));
      line(face + d * 24, face + d * 29, const Color(0xFF453D30), 2.5);
      c.drawCircle(
        face + d * 34,
        1.8,
        Paint()..color = const Color(0xFF5D4935),
      );
    }
    line(face, face + const Offset(20, 10), const Color(0xFF383A32), 3);
    line(face, face + const Offset(-11, -17), const Color(0xFF383A32), 4);
    c.drawCircle(face, 3.5, Paint()..color = const Color(0xFF383A32));
    // The shallow second face makes the clock a tower rather than a flat sign.
    c.drawOval(
      const Rect.fromLTWH(42, -562, 12, 47),
      Paint()..color = const Color(0xFFE3D7B6),
    );
    line(
      const Offset(48, -540),
      const Offset(48, -553),
      const Color(0xFF584832),
      1.5,
    );
    line(
      const Offset(48, -540),
      const Offset(53, -535),
      const Color(0xFF584832),
      1.5,
    );
    poly([
      const Offset(-45, -568),
      const Offset(42, -568),
      const Offset(9, -height),
    ], const Color(0xFFA5824C));
    poly([
      const Offset(42, -568),
      const Offset(58, -579),
      const Offset(9, -height),
    ], const Color(0xFF775735));
    line(
      const Offset(9, -height),
      const Offset(9, -height - 14),
      const Color(0xFF746245),
      2,
    );
    for (final x in [-49.0, 49.0]) {
      line(Offset(x, -247), Offset(x, -267), const Color(0xFF594732), 2);
      c.drawCircle(
        Offset(x, -267),
        3,
        Paint()..color = const Color(0xFF8B7049),
      );
    }
    // Fountain jets around the base, kept inside the island's footprint.
    for (final spec in [
      (-118.0, 4.0, 88.0),
      (-86.0, 39.0, 58.0),
      (103.0, 31.0, 103.0),
      (136.0, -5.0, 73.0),
      (-6.0, 52.0, 52.0),
    ]) {
      final p = Offset(spec.$1, spec.$2);
      for (var spray = -2; spray <= 2; spray++) {
        final path = Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(
            p.dx + spray * 6,
            p.dy - spec.$3,
            p.dx + spray * 13,
            p.dy - 3,
          );
        c.drawPath(
          path,
          Paint()
            ..color = const Color(0x669FE4DF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7,
        );
      }
      line(p, p - Offset(0, spec.$3 * .76), const Color(0xBBDEF7EE), 2.8);
      c.drawOval(
        Rect.fromCenter(center: p, width: 27, height: 10),
        Paint()..color = const Color(0x66D0F3E9),
      );
    }
    c.restore();
  }
}

import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';
import '../data/city_layout.dart';

/// Extruded street frontages: roofs and walls share the actual ground polygon.
class UrbanArchitecture {
  static Color tint(Color c, double a) => Color.lerp(
    c,
    a < 0 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    a.abs(),
  )!;
  static void poly(Canvas c, List<Offset> p, Color color, {double stroke = 1}) {
    final path = Path()..addPolygon(p, true);
    c.drawPath(path, Paint()..color = color);
    if (stroke > 0) {
      c.drawPath(
        path,
        Paint()
          ..color = tint(color, -.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  static void line(Canvas c, Offset a, Offset b, Color color, double w) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
  static double height(int city, int i) => switch (city) {
    0 => 125 + (i % 3) * 22.0,
    1 => 155 + (i % 4) * 15.0,
    2 => 170 + (i % 3) * 26.0,
    3 => 220 + (i % 3) * 16.0,
    4 => 112 + (i % 3) * 19.0,
    _ => 165 + (i % 4) * 18.0,
  };
  static void paint(Canvas c, District d, List<Offset> points, int index) {
    final profile =
        d.layout.buildings[index] ??
        CityBuilding(BuildingKind.townhouse, height(d.id, index), index);
    final h = profile.height, lift = Offset(-16, -h);
    final kind = profile.kind;
    final walls = <Color>[
      const Color(0xFFDDD2B6),
      const Color(0xFFDCB77D),
      const Color(0xFFE5DDC6),
      const Color(0xFFD4C7AF),
      const Color(0xFFB3A38C),
      const Color(0xFF787785),
    ];
    final base = d.id == 1
        ? const [
            Color(0xFFDCB77D),
            Color(0xFFD2A58A),
            Color(0xFFE2CE9F),
            Color(0xFFCB9B78),
            Color(0xFFD4C5A5),
          ][index % 5]
        : walls[d.id];
    final variantColor = switch (kind) {
      BuildingKind.cafe => Color.lerp(base, const Color(0xFFCA9B7E), .38)!,
      BuildingKind.workshop => Color.lerp(base, const Color(0xFF9A8273), .55)!,
      BuildingKind.villa => Color.lerp(base, const Color(0xFF96AEAB), .45)!,
      BuildingKind.civic => tint(base, .18),
      _ => base,
    };
    final color = tint(variantColor, (profile.variant % 5 - 2) * .045);
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length], edge = b - a;
      if (edge.dx * lift.dy - edge.dy * lift.dx <= 0) continue;
      final shade = tint(color, edge.dy.abs() > edge.dx.abs() ? -.19 : 0);
      poly(c, [a, b, b + lift, a + lift], shade, stroke: 1.3);
      _facade(c, a, b, lift, shade, d.id, index + i, profile);
    }
    final roof = points.map((p) => p + lift).toList();
    final roofColor = const [
      Color(0xFF8B7670),
      Color(0xFFB97450),
      Color(0xFFC9C4B6),
      Color(0xFF697078),
      Color(0xFF5D6767),
      Color(0xFF505467),
    ][d.id];
    poly(c, roof, tint(roofColor, (index % 3 - 1) * .07), stroke: 2);
    final roofPath = Path()..addPolygon(roof, true),
        bounds = roofPath.getBounds();
    c.save();
    c.clipPath(roofPath);
    if (d.id == 2 ||
        kind == BuildingKind.apartment ||
        kind == BuildingKind.cafe) {
      // Flat Mediterranean roofs, parapet and small roof terraces.
      c.drawPath(
        roofPath,
        Paint()
          ..color = tint(roofColor, .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
      for (var y = bounds.top + 12; y < bounds.bottom; y += 25) {
        line(
          c,
          Offset(bounds.left, y),
          Offset(bounds.right, y + 12),
          tint(roofColor, -.08),
          .8,
        );
      }
    } else {
      final spacing = d.id == 1 ? 8.0 : 12.0;
      for (var y = bounds.top - 10; y < bounds.bottom; y += spacing) {
        line(
          c,
          Offset(bounds.left, y),
          Offset(bounds.right, y + 20),
          tint(roofColor, -.2),
          1,
        );
        line(
          c,
          Offset(bounds.left, y + 2),
          Offset(bounds.right, y + 22),
          tint(roofColor, .16),
          .9,
        );
      }
      for (
        var x = bounds.left - 100;
        x < bounds.right + 100;
        x += d.id == 1 ? 13 : 23
      ) {
        line(
          c,
          Offset(x, bounds.top),
          Offset(x + 35, bounds.bottom),
          tint(roofColor, -.12),
          .8,
        );
      }
      // Hip ridge gives the roof volume without using a pasted house image.
      final midA = Offset.lerp(roof[0], roof[3], .5)!,
          midB = Offset.lerp(roof[1], roof[2], .5)!;
      poly(
        c,
        [
          roof[0],
          roof[1],
          midB + const Offset(0, -18),
          midA + const Offset(0, -18),
        ],
        tint(roofColor, .13).withValues(alpha: .48),
        stroke: 0,
      );
      line(
        c,
        midA + const Offset(0, -18),
        midB + const Offset(0, -18),
        tint(roofColor, -.3),
        4,
      );
      line(
        c,
        midA + const Offset(0, -20),
        midB + const Offset(0, -20),
        tint(roofColor, .35),
        1.3,
      );
    }
    c.restore();
    if (kind == BuildingKind.civic && d.id != 4) {
      final a = roof[3], b = roof[2], middle = Offset.lerp(a, b, .5)!;
      poly(
        c,
        [a, b, middle + const Offset(0, -45)],
        tint(color, .17),
        stroke: 2,
      );
      line(c, a, middle + const Offset(0, -45), tint(roofColor, -.2), 5);
      line(c, middle + const Offset(0, -45), b, tint(roofColor, -.2), 5);
      c.drawCircle(
        middle + const Offset(0, -15),
        9,
        Paint()..color = tint(color, -.3),
      );
    } else if (kind == BuildingKind.villa ||
        (kind == BuildingKind.townhouse && d.id == 5)) {
      final a = roof[3], b = roof[2], middle = Offset.lerp(a, b, .5)!;
      poly(
        c,
        [
          middle + const Offset(-34, 0),
          middle + const Offset(34, 0),
          middle + const Offset(0, -49),
        ],
        tint(color, .14),
        stroke: 2,
      );
      line(
        c,
        middle + const Offset(-38, 0),
        middle + const Offset(0, -51),
        tint(roofColor, -.3),
        5,
      );
      line(
        c,
        middle + const Offset(0, -51),
        middle + const Offset(38, 0),
        tint(roofColor, -.3),
        5,
      );
      c.drawCircle(
        middle + const Offset(0, -18),
        8,
        Paint()..color = const Color(0xFF547479),
      );
    } else if (kind == BuildingKind.workshop) {
      final a = roof[0], b = roof[1];
      for (var i = 0; i < 3; i++) {
        final q = Offset.lerp(a, b, (i + .5) / 3)!;
        poly(c, [
          q + const Offset(-17, 12),
          q + const Offset(17, 12),
          q + const Offset(12, -15),
          q + const Offset(-12, -15),
        ], const Color(0xFF89AAA9));
        line(
          c,
          q + const Offset(-13, -15),
          q + const Offset(13, -15),
          const Color(0xFF495F62),
          2,
        );
      }
    }
    if (d.id == 4) {
      // Machiya roofs overhang the wooden frontage with a tiled lower eave.
      for (var e = 0; e < points.length; e++) {
        final a = points[e], b = points[(e + 1) % points.length], v = b - a;
        if (v.dx * lift.dy - v.dy * lift.dx <= 0) continue;
        final ra = a + lift, rb = b + lift;
        line(
          c,
          ra + const Offset(-4, 7),
          rb + const Offset(6, 7),
          const Color(0xFF444E4D),
          9,
        );
        line(c, ra, rb, const Color(0xFF94A099), 2);
        final lowerA = a + lift * .47, lowerB = b + lift * .47;
        poly(c, [
          lowerA,
          lowerB,
          lowerB + const Offset(7, 13),
          lowerA + const Offset(-6, 13),
        ], const Color(0xFF626C68));
        line(
          c,
          lowerA + const Offset(-6, 13),
          lowerB + const Offset(7, 13),
          const Color(0xFF414D49),
          3,
        );
      }
    }
    if (d.id == 3 || d.id == 5) {
      // Slate dormers in Paris; steep pointed gables in the night district.
      final a = roof[3], b = roof[2];
      for (var i = 0; i < 2; i++) {
        final q = Offset.lerp(a, b, (i + 1) / 3)!;
        final peak = d.id == 5 ? 48.0 : 26.0;
        poly(c, [
          q + const Offset(-13, 0),
          q + const Offset(13, 0),
          q + Offset(10, -peak + 8),
          q + Offset(0, -peak),
          q + Offset(-10, -peak + 8),
        ], tint(color, -.1));
        poly(c, [
          q + Offset(-14, -peak + 7),
          q + Offset(0, -peak - 5),
          q + Offset(14, -peak + 7),
          q + Offset(0, -peak),
        ], tint(roofColor, -.2));
        poly(c, [
          q + const Offset(-5, -3),
          q + const Offset(5, -3),
          q + Offset(5, -peak + 10),
          q + Offset(-5, -peak + 10),
        ], d.id == 5 ? const Color(0xFFC6B379) : const Color(0xFF597579));
      }
    }
    // One small rooftop feature, varied by frontage and local architecture.
    final p = roof.reduce((a, b) => a + b) / roof.length.toDouble();
    if (d.id == 2 && index.isEven) {
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(6, 4), width: 33, height: 15),
        Paint()..color = const Color(0x30474640),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.dx - 10, p.dy - 22, 23, 27),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFFE7E3D5),
      );
      c.drawOval(
        Rect.fromCenter(
          center: p + const Offset(1, -21),
          width: 23,
          height: 10,
        ),
        Paint()..color = const Color(0xFFC3C9C2),
      );
    } else if (index % 3 == 0) {
      poly(c, [
        p + const Offset(-7, 0),
        p + const Offset(10, 0),
        p + const Offset(10, -29),
        p + const Offset(-7, -32),
      ], tint(color, -.12));
      poly(c, [
        p + const Offset(-10, -32),
        p + const Offset(11, -29),
        p + const Offset(17, -35),
        p + const Offset(-5, -39),
      ], tint(color, .18));
    }
  }

  static void _facade(
    Canvas c,
    Offset a,
    Offset b,
    Offset lift,
    Color wall,
    int city,
    int seed,
    CityBuilding profile,
  ) {
    final width = (b - a).distance, h = -lift.dy;
    Offset at(double x, double y) =>
        Offset.lerp(a, b, x / width)! + lift * (y / h);
    void panel(
      double x,
      double y,
      double w,
      double tall,
      Color color, {
      double stroke = 1,
    }) => poly(
      c,
      [at(x, y), at(x + w, y), at(x + w, y + tall), at(x, y + tall)],
      color,
      stroke: stroke,
    );
    void band(double y, double thick, Color color) =>
        panel(0, y, width, thick, color, stroke: 0);
    final dark = city == 5 ? const Color(0xFF45404E) : const Color(0xFF3D5759);
    final trim = tint(wall, .3);
    band(0, 8, tint(wall, -.22));
    band(h - 8, 8, trim);
    final kind = profile.kind;
    final floors = switch (kind) {
      BuildingKind.cafe || BuildingKind.market || BuildingKind.workshop => 1,
      BuildingKind.apartment => city == 4 ? 3 : 4,
      BuildingKind.civic => 3,
      _ => 2,
    };
    final floorHeight = (h - 14) / floors;
    final columns = max(
          1,
          (width / (kind == BuildingKind.apartment ? 58 : 76)).floor(),
        ),
        step = width / columns;
    // Each building use has its own ground floor, not just a different paint color.
    if (kind == BuildingKind.market) {
      final bays = max(2, (width / 70).floor());
      for (var i = 0; i < bays; i++) {
        final left = width * i / bays + 9,
            right = width * (i + 1) / bays - 9,
            mid = (left + right) / 2,
            top = h - 26;
        final path = Path()
          ..moveTo(at(left, 8).dx, at(left, 8).dy)
          ..lineTo(at(left, top - 22).dx, at(left, top - 22).dy)
          ..quadraticBezierTo(
            at(mid, top + 18).dx,
            at(mid, top + 18).dy,
            at(right, top - 22).dx,
            at(right, top - 22).dy,
          )
          ..lineTo(at(right, 8).dx, at(right, 8).dy)
          ..close();
        c.drawPath(path, Paint()..color = dark);
        c.drawPath(
          path,
          Paint()
            ..color = trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        panel(left + 3, 8, right - left - 6, 23, const Color(0xFF98845B));
        for (var fruit = 0; fruit < 5; fruit++) {
          c.drawCircle(
            at(left + 7 + fruit * (right - left - 14) / 4, 33),
            4,
            Paint()
              ..color = fruit.isEven
                  ? const Color(0xFF97A75D)
                  : const Color(0xFFD4A95B),
          );
        }
      }
      band(h - 19, 7, trim);
      return;
    }
    if (kind == BuildingKind.cafe || kind == BuildingKind.workshop) {
      panel(width * .09, 12, width * .82, h - 46, dark);
      if (kind == BuildingKind.cafe) {
        panel(width * .11, 15, width * .78, h - 55, const Color(0xFF7FA6A7));
        for (var x = width * .1; x < width * .91; x += width * .2) {
          line(c, at(x, 13), at(x, h - 35), trim, 4);
        }
        line(c, at(width * .1, 29), at(width * .9, 29), trim, 3);
        panel(
          width * .09,
          h - 31,
          width * .82,
          20,
          city == 1 ? const Color(0xFF955E4C) : const Color(0xFF466E66),
        );
        // Cafe sign: cup icon, deliberately minimal text.
        final cup = at(width * .5, h - 23);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: cup, width: 15, height: 9),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFECE2C8),
        );
        line(
          c,
          cup + const Offset(-10, 7),
          cup + const Offset(10, 7),
          const Color(0xFFECE2C8),
          2,
        );
      } else {
        panel(width * .1, 13, width * .8, h - 51, const Color(0xFF858B87));
        for (var yy = 18.0; yy < h - 40; yy += 8) {
          line(
            c,
            at(width * .1, yy),
            at(width * .9, yy),
            const Color(0xFF596663),
            1.5,
          );
        }
        panel(width * .37, h - 30, width * .26, 14, const Color(0xFFC3B899));
      }
      band(h - 8, 8, trim);
      return;
    }
    for (var floor = 0; floor < floors; floor++) {
      final y = floor * floorHeight + 12;
      if (city == 3 || city == 2 || city == 4) {
        band(
          floor * floorHeight + 5,
          city == 4 ? 5 : 3,
          city == 4 ? const Color(0xFF64574A) : trim,
        );
      }
      for (var col = 0; col < columns; col++) {
        final x = (col + .5) * step,
            minWidth = min(21.0, step * .48),
            wh = floorHeight * .61;
        if (city == 4) {
          final ww = step * .75;
          panel(x - ww / 2, y - 2, ww, wh + 3, const Color(0xFF574A3B));
          panel(x - ww / 2 + 3, y, ww - 6, wh - 2, const Color(0xFFD4CCAA));
          for (var slat = x - ww / 2 + 6; slat < x + ww / 2 - 3; slat += 6) {
            line(
              c,
              at(slat, y),
              at(slat, y + wh),
              const Color(0xFF776144),
              1.8,
            );
          }
          for (var cross = y + 8; cross < y + wh; cross += 9) {
            line(
              c,
              at(x - ww / 2 + 2, cross),
              at(x + ww / 2 - 2, cross),
              const Color(0xFF776144),
              1.3,
            );
          }
          if (floor == 0 && col == columns ~/ 2) {
            for (var flap = 0; flap < 3; flap++) {
              panel(
                x - ww / 2 + flap * ww / 3,
                y + wh * .4,
                ww / 3 - 1,
                wh * .55,
                const Color(0xFF3F6268),
              );
            }
            line(
              c,
              at(x - ww * .6, y + wh + 2),
              at(x + ww * .6, y + wh + 2),
              const Color(0xFF4C4338),
              3,
            );
          }
          continue;
        }
        if (floor == 0 && col == columns ~/ 2) {
          panel(x - minWidth / 2 - 3, 7, minWidth + 6, wh + 9, trim);
          panel(x - minWidth / 2, 7, minWidth, wh + 6, dark);
          if (city == 4) {
            for (var n = 1; n < 4; n++) {
              line(
                c,
                at(x - minWidth / 2 + minWidth * n / 4, 8),
                at(x - minWidth / 2 + minWidth * n / 4, wh + 12),
                const Color(0xFFA99773),
                1.7,
              );
            }
          } else {
            line(c, at(x, 8), at(x, wh + 12), tint(dark, .4), 1.2);
            c.drawCircle(
              at(x + minWidth * .28, 20),
              1.5,
              Paint()..color = const Color(0xFFD0BB76),
            );
          }
        } else {
          panel(x - minWidth / 2 - 3, y - 3, minWidth + 6, wh + 6, trim);
          panel(x - minWidth / 2, y, minWidth, wh, dark);
          panel(
            x - minWidth / 2 + 2,
            y + wh * .45,
            minWidth * .45,
            wh * .48,
            city == 5 ? const Color(0xFFBEAC69) : const Color(0xFF94B4B3),
            stroke: 0,
          );
          if (city == 5) {
            poly(c, [
              at(x - minWidth / 2 - 3, y + wh),
              at(x, y + wh + 13),
              at(x + minWidth / 2 + 3, y + wh),
            ], trim);
          }
          if (city == 5) {
            poly(
              c,
              [
                at(x - minWidth / 2, y + wh),
                at(x, y + wh + 8),
                at(x + minWidth / 2, y + wh),
              ],
              const Color(0xFFB6A66E),
              stroke: .7,
            );
          }
          line(c, at(x, y), at(x, y + wh), trim, 1.5);
          line(
            c,
            at(x - minWidth / 2, y + wh * .48),
            at(x + minWidth / 2, y + wh * .48),
            trim,
            1.3,
          );
          if (city == 1 || city == 0 || city == 2) {
            final shutter = city == 1
                ? const Color(0xFF647561)
                : city == 2
                ? const Color(0xFF4E7D86)
                : const Color(0xFF748679);
            panel(x - minWidth / 2 - 10, y, 7, wh, shutter);
            panel(x + minWidth / 2 + 3, y, 7, wh, shutter);
            for (var sy = y + 4; sy < y + wh; sy += 5) {
              line(
                c,
                at(x - minWidth / 2 - 9, sy),
                at(x - minWidth / 2 - 4, sy),
                tint(shutter, .25),
                .8,
              );
              line(
                c,
                at(x + minWidth / 2 + 4, sy),
                at(x + minWidth / 2 + 9, sy),
                tint(shutter, .25),
                .8,
              );
            }
          }
          if ((city == 3 || city == 2) && floor > 0) {
            panel(x - minWidth / 2 - 6, y - 4, minWidth + 12, 4, trim);
            line(
              c,
              at(x - minWidth / 2 - 5, y + 8),
              at(x + minWidth / 2 + 5, y + 8),
              dark,
              2,
            );
            for (
              var rail = -minWidth / 2 - 4;
              rail < minWidth / 2 + 5;
              rail += 5
            ) {
              line(c, at(x + rail, y - 1), at(x + rail, y + 8), dark, 1.1);
            }
          }
        }
      }
    }
    if (kind == BuildingKind.civic) {
      for (var i = 0; i < 5; i++) {
        final x = width * (.08 + i * .21);
        panel(x - 5, 6, 10, h * .43, trim);
        panel(x - 8, 6, 16, 6, tint(trim, -.12));
        panel(x - 8, h * .43, 16, 6, trim);
      }
      band(h * .43 + 7, 9, trim);
    }
    if ((city == 0 || city == 5) && kind == BuildingKind.townhouse) {
      for (final x in [width * .07, width * .5, width * .93]) {
        line(c, at(x, 6), at(x, h - 10), const Color(0xFF69584A), 5);
      }
      band(h * .51, 5, const Color(0xFF69584A));
      line(
        c,
        at(width * .08, h * .52),
        at(width * .48, h - 12),
        const Color(0xFF69584A),
        4,
      );
      line(
        c,
        at(width * .52, h - 12),
        at(width * .92, h * .52),
        const Color(0xFF69584A),
        4,
      );
    }
    if (city == 4) {
      for (var x = 3.0; x < width; x += step) {
        panel(x, 0, 4, h, const Color(0xFF665545));
      }
    }
    if (city == 4 && width > 70) {
      final p = at(width * .18, floorHeight * .6);
      line(
        c,
        p + const Offset(0, -19),
        p + const Offset(0, -29),
        const Color(0xFF514C41),
        2,
      );
      c.drawOval(
        Rect.fromCenter(center: p, width: 12, height: 22),
        Paint()..color = const Color(0xFFB3594B),
      );
      for (final y in [-6.0, 0.0, 6.0]) {
        line(
          c,
          p + Offset(-5, y),
          p + Offset(5, y),
          const Color(0xFF883D35),
          .8,
        );
      }
      line(
        c,
        p + const Offset(-4, -11),
        p + const Offset(4, -11),
        const Color(0xFF474F45),
        3,
      );
    }
    if (city != 4 && (seed % 3 == 0 || city == 1) && width > 80) {
      final x = width * .16, w = width * .68, y = floorHeight - 1;
      final colors = const [
        Color(0xFF677E67),
        Color(0xFF9C5948),
        Color(0xFF4C7C8C),
        Color(0xFF6F7A6B),
        Color(0xFF885D57),
        Color(0xFF70597E),
      ];
      for (var stripe = 0; stripe < 8; stripe++) {
        final l = x + w * stripe / 8, r = x + w * (stripe + 1) / 8;
        poly(
          c,
          [
            at(l, y + 8),
            at(r, y + 8),
            at(r, y) + const Offset(0, 10),
            at(l, y) + const Offset(0, 10),
          ],
          stripe.isEven ? colors[city] : const Color(0xFFE4DACA),
          stroke: .6,
        );
      }
      line(
        c,
        at(x, y) + const Offset(0, 10),
        at(x + w, y) + const Offset(0, 10),
        tint(colors[city], -.3),
        2,
      );
    }
  }
}

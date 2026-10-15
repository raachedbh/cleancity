import 'dart:math';
import 'package:flutter/material.dart';
import '../data/catalog.dart';

/// Facades are assembled from volumes, with stable, address-specific proportions.
/// The caller records the result once; no per-frame mesh or texture generation.
class CityArchitecture {
  static const ink = Color(0xFF49504B);
  static Color tint(Color c, double v) =>
      Color.lerp(c, v < 0 ? Colors.black : Colors.white, v.abs())!;
  static void shape(
    Canvas c,
    List<Offset> points,
    Color color, {
    double edge = 1.2,
  }) {
    final p = Path()..addPolygon(points, true);
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

  static void stroke(Canvas c, Offset a, Offset b, Color color, double width) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  static void box(
    Canvas c,
    Rect r,
    Color color, {
    double edge = 1,
    double radius = 0,
  }) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, Paint()..color = color);
    if (edge > 0) {
      c.drawRRect(
        rr,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge,
      );
    }
  }

  static void face(Canvas c, Rect r, Color color) {
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [tint(color, .08), tint(color, -.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(r),
    );
    c.drawRect(
      r,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  static void paint(Canvas c, District area, Rect lot, int address) {
    if (address == 0 || address == 2) {
      civicBlock(c, area, lot, address);
      return;
    }
    final random = Random(area.id * 7919 + address * 131 + 71);
    final scheme = [
      [0xFFE7D9BC, 0xFFB6CCC3, 0xFFC79883, 0xFFB4B8AD, 0xFFE1C6AD],
      [0xFFE6C495, 0xFFCE9F7D, 0xFFE9D6B1, 0xFFD4BBA0, 0xFFF0D8B5],
      [0xFFF0E9D9, 0xFFDDE3D9, 0xFFE8D8BD, 0xFFF4E7D0, 0xFFC9DAD8],
      [0xFFD9D0BA, 0xFFDCD5C8, 0xFFC7C6BC, 0xFFE4D6C0, 0xFFD5C7B8],
      [0xFFDBCFB6, 0xFFD2BDA4, 0xFFE3D7C1, 0xFFC9BAA3, 0xFFDCD4C9],
      [0xFF8B8396, 0xFF728586, 0xFF92808B, 0xFF7B7B94, 0xFF888D81],
    ][area.id];
    final arrangement = (address + area.id) % 4;
    final count = arrangement == 0
        ? 1
        : arrangement == 3
        ? 3
        : 2;
    final widths = count == 1
        ? [225.0]
        : count == 2
        ? [103.0 + random.nextInt(13), 101.0 + random.nextInt(12)]
        : [75.0, 80.0, 73.0];
    final placements =
        <
          ({
            Offset foot,
            double width,
            double height,
            int kind,
            Color wall,
            int seed,
          })
        >[];
    var x = lot.left + (count == 1 ? 27 : 7);
    for (var slot = 0; slot < count; slot++) {
      final seed = address * 11 + slot * 7 + area.id * 3;
      final kind = (address + slot * 2) % 4;
      final base = switch (area.id) {
        0 => 122.0,
        1 => 160.0,
        2 => 135.0,
        3 => 186.0,
        4 => 128.0,
        _ => 163.0,
      };
      final height =
          base +
          (kind == 1
              ? 31
              : kind == 2
              ? -20
              : 8) +
          random.nextInt(13);
      final foot = Offset(x, lot.bottom - 23 - random.nextInt(25));
      placements.add((
        foot: foot,
        width: widths[slot],
        height: height,
        kind: kind,
        wall: Color(scheme[(address * 2 + slot) % scheme.length]),
        seed: seed,
      ));
      // Each entrance has a path aligned to its real door, not a repeated image.
      final doorX = foot.dx + widths[slot] * (count == 1 ? .34 : .5);
      box(
        c,
        Rect.fromLTRB(doorX - 15, foot.dy, doorX + 15, lot.bottom + 10),
        area.night ? const Color(0xFF827B87) : const Color(0xFFDCD5C4),
        edge: 0,
      );
      for (var y = foot.dy + 8; y < lot.bottom + 10; y += 12) {
        stroke(
          c,
          Offset(doorX - 15, y),
          Offset(doorX + 15, y),
          const Color(0x33807765),
          .8,
        );
      }
      x += widths[slot] + (count == 2 ? 42 : 24);
    }
    placements.sort((a, b) => a.foot.dy.compareTo(b.foot.dy));
    for (final b in placements) {
      building(c, b.foot, b.width, b.height, b.wall, area.id, b.kind, b.seed);
    }
    // Different boundary details suit each city and never project into the road.
    if (area.id == 0 || area.id == 5) {
      for (var n = 0; n < 10; n++) {
        final px = lot.left + 7 + n * 30;
        if (placements.any(
          (b) =>
              (px - b.foot.dx - b.width * (count == 1 ? .34 : .5)).abs() < 24,
        )) {
          continue;
        }
        stroke(
          c,
          Offset(px, lot.bottom - 3),
          Offset(px, lot.bottom - 19),
          area.id == 5 ? ink : const Color(0xFFE7DFCC),
          area.id == 5 ? 2 : 4,
        );
        if (area.id == 5) {
          shape(
            c,
            [
              Offset(px - 3, lot.bottom - 19),
              Offset(px, lot.bottom - 25),
              Offset(px + 3, lot.bottom - 19),
            ],
            ink,
            edge: 0,
          );
        }
      }
    }
    for (final b in placements) {
      planter(c, b.foot + Offset(b.width - 8, 4), area.night, b.seed);
    }
  }

  static void building(
    Canvas c,
    Offset p,
    double w,
    double h,
    Color wall,
    int city,
    int kind,
    int seed,
  ) {
    final night = city == 5, wide = w > 180;
    final depth = Offset(wide ? 34 : 20, wide ? -51 : -34);
    final roof = [
      const Color(0xFF896F60),
      const Color(0xFFA96B4F),
      const Color(0xFFB9B6A7),
      const Color(0xFF5F6B76),
      const Color(0xFF536761),
      const Color(0xFF4B4C62),
    ][city];
    final trim = night ? const Color(0xFFB3A7AA) : const Color(0xFFF2E8D3);
    final accent = [
      const Color(0xFF526D65),
      const Color(0xFF536D58),
      const Color(0xFF3A7992),
      const Color(0xFF525D63),
      const Color(0xFF6F5441),
      const Color(0xFF5C4C67),
    ][city];
    c.save();
    c.translate(p.dx, p.dy);
    shape(
      c,
      [
        const Offset(-4, 5),
        Offset(w + 12, 5),
        Offset(w + depth.dx + 37, depth.dy - 7),
        Offset(w - 4, depth.dy - 28),
      ],
      const Color(0x30323E38),
      edge: 0,
    );
    final tr = Offset(w, -h);
    shape(c, [
      tr,
      tr + depth,
      Offset(w, 0) + depth,
      Offset(w, 0),
    ], tint(wall, -.24));
    face(c, Rect.fromLTWH(0, -h, w, h), wall);
    final floors = h > 175
        ? 3
        : h > 122
        ? 2
        : 1;
    // Masonry courses, plaster repairs and corner stones follow the facade.
    if (city == 0 && kind == 1 || city == 5 && kind == 2) {
      for (var y = -h + 8; y < -8; y += 9) {
        stroke(c, Offset(1, y), Offset(w - 1, y), tint(wall, .2), .8);
        for (var x = (y.toInt().isEven ? 7.0 : 16.0); x < w; x += 23) {
          stroke(c, Offset(x, y - 8), Offset(x, y), tint(wall, .15), .65);
        }
      }
    } else if (city == 3) {
      for (var y = -h + 14; y < -8; y += 16) {
        stroke(c, Offset(0, y), Offset(w, y), tint(wall, -.1), .7);
      }
    }
    if (city != 4) {
      for (var y = -h + 2; y < -9; y += 17) {
        box(c, Rect.fromLTWH(1, y, 7, 12), tint(wall, .12), edge: .2);
        box(c, Rect.fromLTWH(w - 8, y, 7, 12), tint(wall, .12), edge: .2);
      }
    } else {
      for (final x in [3.0, w * .5, w - 3]) {
        box(c, Rect.fromLTWH(x - 2, -h, 4, h), accent, edge: .7);
      }
      for (var y = -h + 5; y < -5; y += 10) {
        stroke(c, Offset(0, y), Offset(w, y), tint(wall, -.15), .7);
      }
    }
    box(c, Rect.fromLTWH(-2, -8, w + 4, 9), tint(wall, -.22), edge: .6);
    // Side windows are projected into the side plane and cannot float off it.
    for (var floor = 0; floor < floors; floor++) {
      final q = Offset(w + 5, -h + 24 + floor * (h - 40) / floors);
      final d = depth * .58;
      shape(
        c,
        [q, q + d, q + d + const Offset(0, 28), q + const Offset(0, 28)],
        night ? const Color(0xFFD7AF79) : const Color(0xFF728B92),
        edge: .9,
      );
      stroke(c, q + d * .5, q + d * .5 + const Offset(0, 28), trim, 1.7);
      stroke(
        c,
        q + const Offset(0, 13),
        q + d + const Offset(0, 13),
        trim,
        1.7,
      );
    }
    roofVolume(c, w, h, depth, roof, wall, trim, city, kind);
    final cols = wide
        ? 4
        : w < 87
        ? 2
        : 2;
    final shop =
        kind == 2 || city == 4 && kind.isEven || city == 3 && kind == 0;
    for (var floor = 0; floor < floors; floor++) {
      final y = -h + 18 + floor * (h - 43) / floors;
      final lower = floor == floors - 1;
      if (lower && shop) continue;
      for (var col = 0; col < cols; col++) {
        final ww = wide
            ? 27.0
            : w < 87
            ? 19.0
            : 23.0;
        final x = (col + .5) * w / cols - ww / 2;
        if (lower && (x + ww / 2 - w * (wide ? .34 : .5)).abs() < 24) continue;
        facadeWindow(
          c,
          Rect.fromLTWH(x, y, ww, min(37, (h - 43) / floors - 13)),
          trim,
          accent,
          city,
          seed + col + floor,
          balcony: !lower && (city == 1 || city == 3 || city == 2 && kind == 1),
        );
      }
      if (!lower) {
        cornice(c, w, y + min(40, (h - 43) / floors - 7), trim, depth);
      }
    }
    if (shop) {
      storefront(c, w, trim, accent, city, seed);
    } else {
      door(c, Offset(w * (wide ? .34 : .5), -7), city, accent, trim, seed);
      // Projecting bays, porches and a garage give houses distinct silhouettes.
      if (wide && city == 0 || city == 5 && kind == 0) {
        final bay = Rect.fromLTWH(w * .67, -80, w * .25, 71);
        shape(c, [
          bay.topLeft,
          bay.topLeft + const Offset(-9, 7),
          bay.bottomLeft + const Offset(-9, 7),
          bay.bottomLeft,
        ], tint(wall, -.08));
        face(c, bay.translate(-9, 7), tint(wall, .06));
        facadeWindow(
          c,
          Rect.fromLTWH(bay.left - 3, bay.top + 18, bay.width - 14, 32),
          trim,
          accent,
          city,
          seed,
          balcony: false,
        );
        shape(c, [
          bay.topLeft,
          bay.topRight,
          bay.topRight + const Offset(3, 9),
          bay.topLeft + const Offset(-12, 9),
        ], roof);
      } else if (wide && city == 4) {
        for (var x = 12.0; x < w; x += 13) {
          stroke(c, Offset(x, -60), Offset(x, -10), accent, 2);
        }
        box(
          c,
          Rect.fromLTWH(-8, -6, w + 15, 7),
          const Color(0xFF8D755D),
          edge: .8,
        );
      } else if (city == 0 && kind == 0) {
        final dx = w / 2;
        shape(c, [
          Offset(dx - 29, -60),
          Offset(dx + 27, -60),
          Offset(dx + 36, -47),
          Offset(dx - 30, -47),
        ], roof);
        for (final x in [dx - 26, dx + 28]) {
          box(c, Rect.fromLTWH(x, -46, 3.5, 43), trim, edge: .7);
        }
      }
    }
    // Address plate and a wall light make each entrance feel inhabited.
    box(c, Rect.fromLTWH(w * .5 + 20, -31, 11, 8), accent, radius: 1, edge: .4);
    lettering(c, '${12 + seed % 83}', Offset(w * .5 + 25.5, -30.5), 5.5, trim);
    final lamp = Offset(wide ? 18 : w - 12, -58);
    stroke(c, lamp, lamp + const Offset(0, -9), ink, 1.8);
    box(
      c,
      Rect.fromCenter(center: lamp, width: 6, height: 9),
      night ? const Color(0xFFFFD69A) : const Color(0xFFE4D3A3),
      radius: 1,
      edge: .8,
    );
    c.restore();
  }

  static void cornice(Canvas c, double w, double y, Color trim, Offset depth) {
    box(
      c,
      Rect.fromLTWH(-2, y + 2, w + 4, 4),
      const Color(0x273F4439),
      edge: 0,
    );
    box(c, Rect.fromLTWH(-3, y - 1, w + 6, 3), trim, edge: .6);
    stroke(c, Offset(w + 3, y), Offset(w + 3, y) + depth, tint(trim, -.2), 2.5);
  }

  static void roofVolume(
    Canvas c,
    double w,
    double h,
    Offset d,
    Color roof,
    Color wall,
    Color trim,
    int city,
    int kind,
  ) {
    final flat = city == 2 || city == 0 && kind == 3;
    final a = Offset(-6, -h), b = Offset(w + 6, -h);
    if (flat) {
      shape(c, [a, b, b + d, a + d], tint(wall, .1));
      box(c, Rect.fromLTWH(-5, -h - 8, w + 10, 10), trim, edge: .8);
      stroke(
        c,
        b - const Offset(0, 5),
        b + d - const Offset(0, 5),
        tint(trim, -.2),
        8,
      );
      if (city == 2 && kind == 0) {
        final dome = Rect.fromLTWH(w * .42, -h - 33, w * .35, 42);
        final path = Path()
          ..moveTo(dome.left, -h - 9)
          ..cubicTo(
            dome.left,
            dome.top,
            dome.right,
            dome.top,
            dome.right,
            -h - 9,
          )
          ..close();
        c.drawPath(path, Paint()..color = tint(wall, .17));
        c.drawPath(
          path,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = .9,
        );
        box(
          c,
          Rect.fromLTWH(dome.left - 2, -h - 11, dome.width + 4, 5),
          trim,
          edge: .5,
        );
      } else {
        for (var x = 10.0; x < w; x += 14) {
          stroke(
            c,
            Offset(x, -h - 8),
            Offset(x, -h - 23),
            tint(roof, -.2),
            1.2,
          );
        }
        stroke(
          c,
          Offset(8, -h - 23),
          Offset(w - 5, -h - 23),
          tint(roof, -.2),
          1.6,
        );
        planter(c, Offset(w * .7, -h - 9), false, kind);
      }
      return;
    }
    if (city == 3) {
      // Mansard: a steep lower slope, shallow upper roof and dormers.
      final topL = a + Offset(17, -40), topR = b + Offset(-17, -40);
      shape(c, [a, b, topR, topL], roof);
      shape(c, [b, b + d, topR + d, topR], tint(roof, -.2));
      shape(c, [topL, topR, topR + d, topL + d], tint(roof, .13));
      for (var y = -h - 5; y > -h - 38; y -= 7) {
        stroke(c, Offset(0, y), Offset(w, y), tint(roof, .18), .8);
      }
      for (final x in [w * .25, w * .75]) {
        face(c, Rect.fromLTWH(x - 10, -h - 31, 20, 27), trim);
        facadeWindow(
          c,
          Rect.fromLTWH(x - 6, -h - 25, 12, 19),
          trim,
          roof,
          city,
          0,
          balcony: false,
        );
        shape(c, [
          Offset(x - 13, -h - 31),
          Offset(x, -h - 43),
          Offset(x + 13, -h - 31),
        ], tint(roof, -.08));
      }
      cornice(c, w, -h + 3, trim, d);
      return;
    }
    if (city == 1 || city == 4 || kind == 1) {
      final rise = city == 4 ? 27.0 : 32.0;
      final ridgeL = a + Offset(w * .18, -rise),
          ridgeR = b + Offset(-w * .18, -rise);
      shape(c, [a, b, ridgeR, ridgeL], roof);
      shape(c, [b, b + d, ridgeR + d, ridgeR], tint(roof, -.24));
      shape(c, [ridgeL, ridgeR, ridgeR + d, ridgeL + d], tint(roof, .13));
      for (var j = 1; j < 5; j++) {
        final q = j / 5;
        stroke(
          c,
          Offset.lerp(a, ridgeL, q)!,
          Offset.lerp(b, ridgeR, q)!,
          tint(roof, -.17),
          1.3,
        );
      }
      for (var j = 1; j < w / 10; j++) {
        final q = j / (w / 10);
        stroke(
          c,
          Offset.lerp(a, b, q)!,
          Offset.lerp(ridgeL, ridgeR, q)!,
          tint(roof, .17),
          .8,
        );
      }
      stroke(c, a, b, tint(roof, -.32), 4);
      if (city == 4) {
        stroke(
          c,
          a - const Offset(7, 3),
          a + const Offset(7, 2),
          tint(roof, -.2),
          4,
        );
        stroke(
          c,
          b - const Offset(7, -2),
          b + const Offset(8, -3),
          tint(roof, -.2),
          4,
        );
        final y = -h * .51;
        shape(c, [
          Offset(-7, y - 9),
          Offset(w + 4, y - 9),
          Offset(w + 13, y + 4),
          Offset(-13, y + 4),
        ], roof);
        stroke(
          c,
          Offset(-13, y + 4),
          Offset(w + 13, y + 4),
          tint(roof, -.3),
          3,
        );
      }
    } else {
      final peak = Offset(
        w * (kind == 3 ? .64 : .48),
        -h - (city == 5 ? 60 : 41),
      );
      shape(c, [a, peak, b], tint(wall, .08));
      shape(c, [a, peak, peak + d, a + d], tint(roof, .16));
      shape(c, [peak, b, b + d, peak + d], roof);
      for (var j = 1; j < 7; j++) {
        final q = Offset.lerp(peak, b, j / 7)!;
        stroke(c, q, q + d, tint(roof, -.2), 1);
      }
      stroke(c, a, peak, trim, 2.5);
      stroke(c, peak, b, trim, 2.5);
      final attic = Offset(peak.dx, -h - 14);
      c.drawOval(
        Rect.fromCenter(center: attic, width: 16, height: city == 5 ? 23 : 16),
        Paint()..color = trim,
      );
      c.drawOval(
        Rect.fromCenter(center: attic, width: 11, height: city == 5 ? 18 : 11),
        Paint()
          ..color = city == 5
              ? const Color(0xFFE6BA7E)
              : const Color(0xFF71979E),
      );
      stroke(
        c,
        attic - const Offset(0, 6),
        attic + const Offset(0, 6),
        trim,
        1.4,
      );
    }
    final chimney = Offset(w * .75, -h - 32);
    face(
      c,
      Rect.fromLTWH(chimney.dx, chimney.dy - 20, 11, 25),
      tint(wall, -.13),
    );
    shape(c, [
      chimney + const Offset(11, -20),
      chimney + const Offset(17, -28),
      chimney + const Offset(17, -3),
      chimney + const Offset(11, 5),
    ], tint(wall, -.32));
    box(
      c,
      Rect.fromLTWH(chimney.dx - 2, chimney.dy - 23, 16, 4),
      trim,
      edge: .7,
    );
  }

  static void facadeWindow(
    Canvas c,
    Rect r,
    Color trim,
    Color accent,
    int city,
    int seed, {
    required bool balcony,
  }) {
    box(c, r.inflate(2.5), trim, edge: .6);
    box(c, r, tint(accent, -.2), edge: .8);
    final glass = r.deflate(2);
    c.drawRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          colors: city == 5
              ? [const Color(0xFFCEA978), const Color(0xFFF4D7A0)]
              : [const Color(0xFF66878E), const Color(0xFFA3B9B7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(glass),
    );
    shape(
      c,
      [glass.topLeft, glass.topRight, glass.bottomLeft],
      Colors.white.withValues(alpha: .12),
      edge: 0,
    );
    if (seed % 3 == 0 && city != 4) {
      shape(
        c,
        [
          glass.topLeft,
          glass.topLeft + Offset(glass.width * .35, 0),
          glass.bottomLeft + Offset(glass.width * .16, 0),
          glass.bottomLeft,
        ],
        trim.withValues(alpha: .7),
        edge: 0,
      );
    }
    stroke(
      c,
      Offset(r.center.dx, r.top),
      Offset(r.center.dx, r.bottom),
      trim,
      1.8,
    );
    stroke(
      c,
      Offset(r.left, r.top + r.height * .4),
      Offset(r.right, r.top + r.height * .4),
      trim,
      1.6,
    );
    if (city == 4) {
      for (var y = r.top + 6; y < r.bottom; y += 7) {
        stroke(c, Offset(r.left, y), Offset(r.right, y), accent, .9);
      }
    } else if (city == 1 || city == 2 || city == 0 && seed.isEven) {
      for (final x in [r.left - 8, r.right + 3]) {
        box(c, Rect.fromLTWH(x, r.top - 1, 5, r.height + 1), accent, edge: .5);
        for (var y = r.top + 4; y < r.bottom; y += 5) {
          stroke(c, Offset(x + 1, y), Offset(x + 4, y), tint(accent, .2), .7);
        }
      }
    }
    box(
      c,
      Rect.fromLTWH(r.left - 4, r.bottom + 1, r.width + 8, 3),
      tint(trim, -.15),
      edge: .5,
    );
    if (balcony) {
      final y = r.bottom + 5, x = r.left - 7, width = r.width + 14;
      shape(
        c,
        [
          Offset(x, y),
          Offset(x + width, y),
          Offset(x + width + 4, y + 5),
          Offset(x - 3, y + 5),
        ],
        trim,
        edge: .7,
      );
      for (var n = 0; n <= 6; n++) {
        stroke(
          c,
          Offset(x + n * width / 6, y - 12),
          Offset(x + n * width / 6, y + 4),
          ink,
          1,
        );
      }
      stroke(c, Offset(x - 1, y - 12), Offset(x + width + 1, y - 12), ink, 1.7);
      if (seed.isEven) planter(c, Offset(r.center.dx, y), city == 5, seed);
    }
  }

  static void door(
    Canvas c,
    Offset p,
    int city,
    Color color,
    Color trim,
    int seed,
  ) {
    final r = Rect.fromLTWH(p.dx - 12, p.dy - 48, 24, 48);
    box(c, r.inflate(3), trim, edge: .8, radius: city == 2 ? 13 : 1);
    box(c, r, color, radius: city == 2 ? 12 : 1, edge: 1);
    if (city == 2) {
      for (var n = 0; n < 4; n++) {
        c.drawCircle(
          Offset(r.left + 6, r.top + 18 + n * 7),
          1,
          Paint()..color = trim,
        );
        c.drawCircle(
          Offset(r.right - 6, r.top + 18 + n * 7),
          1,
          Paint()..color = trim,
        );
      }
      stroke(
        c,
        Offset(r.center.dx, r.top + 3),
        Offset(r.center.dx, r.bottom),
        tint(color, -.25),
        1.2,
      );
    } else {
      box(
        c,
        Rect.fromLTWH(r.left + 4, r.top + 5, 16, 15),
        city == 5 ? const Color(0xFFECC88A) : const Color(0xFF9CAFAB),
        edge: .7,
      );
      box(
        c,
        Rect.fromLTWH(r.left + 4, r.top + 25, 16, 17),
        tint(color, -.09),
        edge: .5,
      );
    }
    c.drawCircle(
      Offset(r.right - 4, r.bottom - 21),
      1.6,
      Paint()..color = const Color(0xFFD9BA7A),
    );
    box(
      c,
      Rect.fromLTWH(r.left - 5, r.bottom, 34, 4),
      tint(trim, -.2),
      edge: .7,
    );
    box(
      c,
      Rect.fromLTWH(r.left - 8, r.bottom + 4, 40, 4),
      tint(trim, -.3),
      edge: .7,
    );
  }

  static void storefront(
    Canvas c,
    double w,
    Color trim,
    Color accent,
    int city,
    int seed,
  ) {
    box(c, Rect.fromLTWH(10, -53, w - 20, 45), accent, edge: .9);
    final glass = Rect.fromLTWH(14, -49, w - 28, 38);
    face(
      c,
      glass,
      city == 5 ? const Color(0xFFD3AB80) : const Color(0xFF8DAEAF),
    );
    for (var j = 0; j < 3; j++) {
      box(
        c,
        Rect.fromLTWH(19 + j * (w - 39) / 3, -22, 8, 9),
        const Color(0xFFC9B285),
        edge: .6,
      );
    }
    stroke(c, Offset(w * .7, -50), Offset(w * .7, -8), trim, 3);
    box(
      c,
      Rect.fromLTWH(7, -75, w - 14, 16),
      tint(accent, -.09),
      radius: 1,
      edge: 1,
    );
    final names = [
      ['BAKERY', 'FLOWERS', 'CORNER SHOP'],
      ['CAFFÈ', 'PANETTERIA', 'GELATO'],
      ['CAFÉ', 'ARTISAN', 'MARCHÉ'],
      ['BOULANGERIE', 'LIBRAIRIE', 'BISTRO'],
      ['TEA HOUSE', 'PAPER & INK', 'KITCHEN'],
      ['APOTHECARY', 'ANTIQUES', 'BOOKS'],
    ][city];
    lettering(c, names[seed % 3], Offset(w / 2, -73), w < 87 ? 6 : 8, trim);
    if (city != 4) {
      for (var j = 0; j < 7; j++) {
        final x = 7 + j * (w - 14) / 7, rw = (w - 14) / 7;
        shape(
          c,
          [
            Offset(x, -57),
            Offset(x + rw, -57),
            Offset(x + rw + 2, -46),
            Offset(x - 2, -46),
          ],
          j.isEven ? accent : trim,
          edge: .25,
        );
      }
    } else {
      for (var j = 0; j < 3; j++) {
        box(
          c,
          Rect.fromLTWH(9 + j * (w - 18) / 3, -57, (w - 18) / 3 - 2, 17),
          const Color(0xFF586F7E),
          edge: .5,
        );
      }
      final p = Offset(w - 4, -64);
      stroke(c, p - const Offset(0, 10), p, accent, 2);
      box(
        c,
        Rect.fromCenter(center: p, width: 11, height: 17),
        const Color(0xFFE3AE74),
        radius: 5,
        edge: .7,
      );
      for (var y = -5.0; y < 8; y += 4) {
        stroke(
          c,
          p + Offset(-4, y),
          p + Offset(4, y),
          const Color(0xFFBF8060),
          .7,
        );
      }
    }
  }

  static void planter(Canvas c, Offset p, bool night, int seed) {
    box(
      c,
      Rect.fromCenter(center: p, width: 21, height: 9),
      night ? const Color(0xFF87737E) : const Color(0xFFAA785D),
      radius: 2,
      edge: .7,
    );
    for (var i = 0; i < 5; i++) {
      final q = p + Offset(-8 + i * 4, -7 - (i.isEven ? 2 : 0));
      c.drawCircle(
        q,
        4,
        Paint()
          ..color = night ? const Color(0xFF537063) : const Color(0xFF66895D),
      );
      if (i.isEven) {
        c.drawCircle(
          q - const Offset(0, 2),
          2,
          Paint()
            ..color = seed.isEven
                ? const Color(0xFFDBA2A4)
                : const Color(0xFFE0C37C),
        );
      }
    }
  }

  static void lettering(
    Canvas c,
    String text,
    Offset p,
    double size,
    Color color,
  ) {
    final t = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, p - Offset(t.width / 2, 0));
    t.dispose();
  }

  /// Each city also has public buildings with their own plan and silhouette.
  static void civicBlock(Canvas c, District area, Rect lot, int address) {
    c.save();
    c.translate(lot.left + 15, lot.bottom - 24);
    final alternate = address % 5 == 2;
    final stone = area.night
        ? const Color(0xFF8B8198)
        : const Color(0xFFE0D2B8);
    box(
      c,
      const Rect.fromLTWH(-6, -108, 283, 125),
      area.night ? const Color(0xFF6D6579) : const Color(0xFFD6CFBB),
      edge: .5,
      radius: 7,
    );
    for (var y = -96.0; y < 16; y += 18) {
      stroke(c, Offset(-3, y), Offset(275, y), tint(stone, -.12), .6);
    }
    if (area.id == 0) {
      if (alternate) {
        // Low community market with an attached, open-sided timber pavilion.
        building(
          c,
          const Offset(0, -15),
          138,
          117,
          const Color(0xFFD2BCA3),
          0,
          2,
          address,
        );
        pavilion(
          c,
          const Offset(188, 0),
          const Color(0xFF7E8D77),
          false,
          false,
        );
      } else {
        building(
          c,
          const Offset(0, -10),
          123,
          139,
          const Color(0xFFBAC9B8),
          0,
          0,
          address,
        );
        glasshouse(
          c,
          const Offset(151, 0),
          112,
          102,
          const Color(0xFF658775),
          false,
        );
      }
      lettering(
        c,
        alternate ? 'NEIGHBORHOOD MARKET' : 'COMMUNITY NURSERY',
        const Offset(135, 18),
        9,
        ink,
      );
    } else if (area.id == 1) {
      // A stone loggia and campanile give the Italian city a piazza skyline.
      final front = const Rect.fromLTWH(24, -124, 237, 107);
      volume(c, front, const Color(0xFFDAC09C), const Offset(20, -30));
      // The roof is drawn in its own facade coordinates.
      c.save();
      c.translate(24, -17);
      roofVolume(
        c,
        237,
        107,
        const Offset(20, -30),
        const Color(0xFFAC6F51),
        stone,
        stone,
        1,
        1,
      );
      c.restore();
      for (var i = 0; i < 4; i++) {
        final x = 43 + i * 53.0;
        arch(
          c,
          Rect.fromLTWH(x, -94, 33, 72),
          const Color(0xFF655A49),
          stone,
          5,
        );
        box(c, Rect.fromLTWH(x - 5, -27, 43, 6), tint(stone, -.14), edge: .5);
        if (i.isOdd) planter(c, Offset(x + 16, -23), false, i);
      }
      if (!alternate) {
        volume(
          c,
          const Rect.fromLTWH(0, -236, 57, 219),
          const Color(0xFFE3CCAB),
          const Offset(15, -24),
        );
        for (final y in [-225.0, -176.0, -113.0, -25.0]) {
          cornice(c, 57, y, stone, const Offset(15, -24));
        }
        arch(
          c,
          const Rect.fromLTWH(14, -219, 29, 42),
          const Color(0xFF665E4E),
          stone,
          3,
        );
        final bell = Path()
          ..moveTo(25, -211)
          ..quadraticBezierTo(16, -198, 20, -186)
          ..lineTo(39, -186)
          ..quadraticBezierTo(39, -198, 31, -211)
          ..close();
        pathFill(c, bell, const Color(0xFFA18D59));
        stroke(c, const Offset(29, -215), const Offset(29, -185), ink, 1.2);
        c.drawCircle(
          const Offset(29, -148),
          16,
          Paint()..color = const Color(0xFFF3E6C6),
        );
        stroke(c, const Offset(29, -148), const Offset(29, -160), ink, 1.6);
        stroke(c, const Offset(29, -148), const Offset(39, -143), ink, 1.6);
        shape(c, [
          const Offset(-7, -240),
          const Offset(28, -270),
          const Offset(68, -240),
        ], const Color(0xFFAD7358));
        shape(c, [
          const Offset(28, -270),
          const Offset(44, -291),
          const Offset(83, -263),
          const Offset(68, -240),
        ], const Color(0xFF8B5C46));
      } else {
        umbrella(c, const Offset(35, 5), const Color(0xFFBBA36A));
        umbrella(c, const Offset(166, 8), const Color(0xFF76917A));
      }
      lettering(
        c,
        alternate ? 'TRATTORIA DEL SOLE' : 'LOGGIA DELLA PIAZZA',
        const Offset(159, -119),
        9,
        ink,
      );
    } else if (area.id == 2) {
      // Original covered souk: horseshoe-like arches, blue tile and a roof dome.
      volume(
        c,
        const Rect.fromLTWH(0, -116, 252, 109),
        const Color(0xFFEAE0C9),
        const Offset(21, -34),
      );
      box(
        c,
        const Rect.fromLTWH(-5, -124, 262, 10),
        const Color(0xFFF1E9D8),
        edge: .8,
      );
      stroke(
        c,
        const Offset(257, -119),
        const Offset(278, -153),
        const Color(0xFFD1C8B4),
        8,
      );
      final roof = Path()
        ..moveTo(alternate ? 90 : 72, -125)
        ..cubicTo(88, -188, 177, -188, 191, -125)
        ..close();
      pathFill(c, roof, const Color(0xFFF2E6CC));
      box(c, const Rect.fromLTWH(69, -129, 125, 8), stone, edge: .8);
      for (var i = 0; i < 4; i++) {
        final x = 14 + i * 60.0;
        arch(
          c,
          Rect.fromLTWH(x, -98, 42, 85),
          const Color(0xFF498095),
          const Color(0xFFF3EBD6),
          6,
        );
        arch(
          c,
          Rect.fromLTWH(x + 8, -77, 26, 58),
          const Color(0xFF55726E),
          const Color(0xFFB7C9BB),
          1,
        );
        if (i != 2) {
          for (var j = 0; j < 4; j++) {
            box(
              c,
              Rect.fromLTWH(x + 2 + j * 10, -39, 10, 11),
              j.isEven ? const Color(0xFFBB956E) : const Color(0xFFE0C89C),
              edge: .3,
            );
            c.drawCircle(
              Offset(x + 7 + j * 10, -31),
              2.5,
              Paint()
                ..color = i.isEven
                    ? const Color(0xFFCA9E55)
                    : const Color(0xFF81965F),
            );
          }
        }
      }
      for (var x = 3.0; x < 252; x += 12) {
        shape(
          c,
          [
            Offset(x, -9),
            Offset(x + 5, -14),
            Offset(x + 10, -9),
            Offset(x + 5, -4),
          ],
          const Color(0xFF507D8C),
          edge: 0,
        );
      }
      lettering(
        c,
        alternate ? 'MAISON DES ARTISANS' : 'SOUK DES FLEURS',
        const Offset(126, -114),
        9,
        const Color(0xFF477486),
      );
      palm(c, const Offset(267, 8), .9);
      if (alternate) umbrella(c, const Offset(56, 7), const Color(0xFFB78962));
    } else if (area.id == 3) {
      if (!alternate) {
        glasshouse(
          c,
          const Offset(8, -1),
          248,
          149,
          const Color(0xFF526D65),
          false,
        );
        lettering(c, 'JARDIN D\u2019HIVER', const Offset(133, 18), 9, ink);
      } else {
        building(
          c,
          const Offset(18, -23),
          216,
          183,
          const Color(0xFFD2C8B5),
          3,
          2,
          address,
        );
        // A small wrought-iron garden entrance beside a pavement cafe terrace.
        umbrella(c, const Offset(51, 5), const Color(0xFF8D6E67));
        umbrella(c, const Offset(182, 5), const Color(0xFF8D6E67));
        for (final x in [2.0, 269.0]) {
          stroke(c, Offset(x, 10), Offset(x, -82), const Color(0xFF49685B), 3);
          c.drawCircle(
            Offset(x, -84),
            4,
            Paint()..color = const Color(0xFFE2C786),
          );
        }
      }
    } else if (area.id == 4) {
      if (alternate) {
        pavilion(
          c,
          const Offset(137, -10),
          const Color(0xFF526860),
          true,
          true,
        );
        for (var j = 0; j < 5; j++) {
          box(c, Rect.fromLTWH(108, -3 + j * 5.0, 54, 4), stone, edge: .4);
        }
      } else {
        // Three separate roof tiers and a raised timber platform, not a house reskin.
        for (var tier = 0; tier < 3; tier++) {
          final y = -10 - tier * 64.0,
              width = 172 - tier * 28.0,
              left = 138 - width / 2;
          volume(
            c,
            Rect.fromLTWH(left, y - 57, width, 57),
            const Color(0xFFB28A66),
            const Offset(18, -27),
          );
          for (var col = 0; col < 4; col++) {
            box(
              c,
              Rect.fromLTWH(
                left + 12 + col * (width - 24) / 4,
                y - 42,
                (width - 24) / 4 - 8,
                29,
              ),
              const Color(0xFFC6C7A5),
              edge: .6,
            );
          }
          for (final x in [left + 4, left + width - 4]) {
            box(
              c,
              Rect.fromLTWH(x, y - 57, 4, 57),
              const Color(0xFF795641),
              edge: .5,
            );
          }
          curvedRoof(
            c,
            Offset(138, y - 57),
            width + 36,
            const Color(0xFF4D6761),
          );
        }
        stroke(
          c,
          const Offset(138, -222),
          const Offset(138, -268),
          const Color(0xFFC3A461),
          2,
        );
        for (var y = -242.0; y > -261; y -= 5) {
          stroke(
            c,
            Offset(131, y),
            Offset(145, y),
            const Color(0xFFC3A461),
            1.7,
          );
        }
        box(
          c,
          const Rect.fromLTWH(37, -6, 203, 9),
          const Color(0xFF9F8668),
          edge: .9,
        );
        for (var j = 0; j < 3; j++) {
          box(
            c,
            Rect.fromLTWH(103 + j * 4.0, 3 + j * 4.0, 69 - j * 8.0, 4),
            stone,
            edge: .5,
          );
        }
      }
      // Compact torii silhouette at the edge of the courtyard.
      final ox = alternate ? 34.0 : 28.0;
      for (final x in [ox - 16, ox + 17]) {
        stroke(c, Offset(x, 9), Offset(x, -54), const Color(0xFFA7674E), 5);
      }
      stroke(
        c,
        Offset(ox - 23, -39),
        Offset(ox + 24, -39),
        const Color(0xFFA7674E),
        5,
      );
      final gate = Path()
        ..moveTo(ox - 30, -58)
        ..quadraticBezierTo(ox, -49, ox + 32, -58);
      c.drawPath(
        gate,
        Paint()
          ..color = const Color(0xFF66534A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
      lettering(
        c,
        alternate ? 'GARDEN PAVILION' : 'LANTERN SHRINE',
        const Offset(147, 19),
        9,
        ink,
      );
    } else {
      building(
        c,
        const Offset(0, -17),
        172,
        149,
        const Color(0xFF8B7C8B),
        5,
        alternate ? 2 : 0,
        address,
      );
      // Octagonal turret with a conical slate roof and tall lit windows.
      final faceRect = Rect.fromLTWH(183, -226, 61, 216);
      volume(c, faceRect, const Color(0xFF818395), const Offset(20, -23));
      shape(c, [
        const Offset(165, -211),
        const Offset(183, -226),
        const Offset(183, -10),
        const Offset(165, -24),
      ], const Color(0xFF6D7085));
      for (final y in [-198.0, -143.0, -83.0]) {
        arch(
          c,
          Rect.fromLTWH(197, y, 29, 39),
          const Color(0xFFDDBF89),
          const Color(0xFFADA2B0),
          3,
        );
        stroke(
          c,
          Offset(211, y + 4),
          Offset(211, y + 38),
          const Color(0xFF817388),
          1.8,
        );
      }
      shape(c, [
        const Offset(156, -211),
        const Offset(214, -283),
        const Offset(276, -237),
        const Offset(250, -211),
      ], const Color(0xFF4A4D66));
      shape(c, [
        const Offset(156, -211),
        const Offset(214, -283),
        const Offset(214, -211),
      ], const Color(0xFF676078));
      for (var i = 1; i < 5; i++) {
        stroke(
          c,
          Offset.lerp(const Offset(156, -211), const Offset(214, -283), i / 5)!,
          Offset.lerp(const Offset(250, -211), const Offset(214, -283), i / 5)!,
          const Color(0xFF81748E),
          .7,
        );
      }
      stroke(
        c,
        const Offset(214, -283),
        const Offset(214, -296),
        const Color(0xFFD5B27D),
        1.7,
      );
      c.drawCircle(
        const Offset(214, -299),
        4,
        Paint()..color = const Color(0xFFD5B27D),
      );
      for (final x in [7.0, 273.0]) {
        stroke(c, Offset(x, 10), Offset(x, -48), ink, 2.5);
        box(
          c,
          Rect.fromCenter(center: Offset(x, -50), width: 9, height: 15),
          const Color(0xFFE7BD7D),
          radius: 2,
          edge: .8,
        );
      }
      lettering(
        c,
        alternate ? 'THE CURIOSITY MUSEUM' : 'MOONWATCH MANOR',
        const Offset(137, 18),
        9,
        const Color(0xFFD8D0DF),
      );
    }
    c.restore();
  }

  static void pathFill(Canvas c, Path p, Color color) {
    c.drawPath(p, Paint()..color = color);
    c.drawPath(
      p,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  static void volume(Canvas c, Rect r, Color color, Offset d) {
    shape(c, [
      r.topRight,
      r.topRight + d,
      r.bottomRight + d,
      r.bottomRight,
    ], tint(color, -.24));
    face(c, r, color);
    shape(c, [
      r.topLeft,
      r.topRight,
      r.topRight + d,
      r.topLeft + d,
    ], tint(color, .08));
  }

  static void arch(Canvas c, Rect r, Color fill, Color trim, double rim) {
    Path archPath(Rect a) => Path()
      ..moveTo(a.left, a.bottom)
      ..lineTo(a.left, a.top + a.width * .5)
      ..cubicTo(a.left, a.top, a.right, a.top, a.right, a.top + a.width * .5)
      ..lineTo(a.right, a.bottom)
      ..close();
    pathFill(c, archPath(r.inflate(rim)), trim);
    pathFill(c, archPath(r), fill);
  }

  static void glasshouse(
    Canvas c,
    Offset p,
    double w,
    double h,
    Color frame,
    bool night,
  ) {
    c.save();
    c.translate(p.dx, p.dy);
    const d = Offset(23, -32);
    final r = Rect.fromLTWH(0, -h, w, h),
        glass = night ? const Color(0xFF9E91AE) : const Color(0xFF92B6B5);
    volume(c, r, glass, d);
    final rise = w * .21;
    shape(c, [
      r.topLeft,
      r.topRight,
      Offset(w * .73, -h - rise),
      Offset(w * .27, -h - rise),
    ], tint(glass, .18));
    shape(c, [
      r.topRight,
      r.topRight + d,
      Offset(w * .73, -h - rise) + d,
      Offset(w * .73, -h - rise),
    ], tint(glass, -.12));
    shape(c, [
      Offset(w * .27, -h - rise),
      Offset(w * .73, -h - rise),
      Offset(w * .73, -h - rise) + d,
      Offset(w * .27, -h - rise) + d,
    ], tint(glass, .3));
    for (var j = 0; j <= 8; j++) {
      final x = j * w / 8;
      stroke(c, Offset(x, 0), Offset(x, -h), frame, 2);
      stroke(
        c,
        Offset(x, -h),
        Offset(w * .27 + j * w * .46 / 8, -h - rise),
        frame,
        1.7,
      );
    }
    for (var y = -h; y < 0; y += 24) {
      stroke(c, Offset(0, y), Offset(w, y), frame, 2);
      stroke(c, Offset(w, y), Offset(w, y) + d, frame, 1.5);
    }
    for (var j = 1; j < 4; j++) {
      stroke(
        c,
        Offset(w * .27 * j / 4, -h - rise * j / 4),
        Offset(w - w * .27 * j / 4, -h - rise * j / 4),
        frame,
        1.5,
      );
    }
    // Plants visible behind the glazing.
    for (var i = 0; i < 5; i++) {
      final x = 18 + i * (w - 35) / 4;
      stroke(
        c,
        Offset(x, -8),
        Offset(x, -44 - i % 2 * 10),
        const Color(0xFF5F8068),
        2,
      );
      for (var j = 0; j < 3; j++) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x - 5, -20 - j * 10),
            width: 15,
            height: 5,
          ),
          Paint()..color = const Color(0xAA678F75),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x + 5, -26 - j * 10),
            width: 15,
            height: 5,
          ),
          Paint()..color = const Color(0xAA779F80),
        );
      }
    }
    box(c, Rect.fromLTWH(-4, -6, w + 8, 10), const Color(0xFFBDBDAA), edge: .7);
    box(
      c,
      Rect.fromLTWH(w / 2 - 17, -57, 34, 55),
      tint(glass, -.08),
      edge: 1.4,
    );
    stroke(c, Offset(w / 2, -55), Offset(w / 2, -3), frame, 2);
    stroke(c, Offset(w / 2 - 15, -32), Offset(w / 2 + 15, -32), frame, 1.6);
    shape(
      c,
      [Offset(4, -h + 6), Offset(w * .35, -h + 6), Offset(4, -h * .33)],
      const Color(0x33FFFFFF),
      edge: 0,
    );
    c.restore();
  }

  static void curvedRoof(Canvas c, Offset p, double w, Color color) {
    final a = p + Offset(-w / 2, 0), b = p + Offset(w / 2, 0);
    shape(c, [
      a,
      p + Offset(-w * .28, -27),
      p + Offset(w * .27, -27),
      b,
      b + const Offset(5, 6),
      a + const Offset(-5, 6),
    ], color);
    for (var j = 1; j < 5; j++) {
      stroke(
        c,
        Offset.lerp(a, p + Offset(-w * .28, -27), j / 5)!,
        Offset.lerp(b, p + Offset(w * .27, -27), j / 5)!,
        tint(color, .18),
        1.2,
      );
    }
    final curve = Path()
      ..moveTo(a.dx - 9, a.dy - 5)
      ..quadraticBezierTo(p.dx, p.dy + 10, b.dx + 9, b.dy - 5);
    c.drawPath(
      curve,
      Paint()
        ..color = tint(color, -.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  static void pavilion(
    Canvas c,
    Offset p,
    Color roof,
    bool japanese,
    bool wide,
  ) {
    c.save();
    c.translate(p.dx, p.dy);
    final w = wide ? 214.0 : 119.0;
    shape(c, [
      Offset(-w / 2, -8),
      Offset(w / 2, -8),
      Offset(w / 2 + 12, -23),
      Offset(-w / 2 + 12, -23),
    ], const Color(0xFFBAA486));
    for (final x in [-w / 2 + 9, w / 2 - 9]) {
      box(c, Rect.fromLTWH(x, -105, 5, 96), const Color(0xFF8C6E50), edge: .7);
      box(
        c,
        Rect.fromLTWH(x - 3, -14, 11, 9),
        const Color(0xFFD1C4AC),
        edge: .7,
      );
    }
    box(
      c,
      Rect.fromLTWH(-w / 2 + 12, -43, w - 24, 4),
      const Color(0xFF9B7D5C),
      edge: .5,
    );
    for (var x = -w / 2 + 18; x < w / 2 - 10; x += 15) {
      stroke(c, Offset(x, -42), Offset(x, -10), const Color(0xFF9B7D5C), 1.7);
    }
    curvedRoof(c, const Offset(0, -105), w + 24, roof);
    if (japanese) {
      for (final x in [-w / 3, w / 3]) {
        stroke(c, Offset(x, -101), Offset(x, -87), ink, 1.2);
        box(
          c,
          Rect.fromCenter(center: Offset(x, -80), width: 12, height: 20),
          const Color(0xFFE3B583),
          radius: 5,
          edge: .8,
        );
      }
    }
    c.restore();
  }

  static void umbrella(Canvas c, Offset p, Color color) {
    stroke(c, p, p - const Offset(0, 52), ink, 2);
    c.drawOval(
      Rect.fromCenter(center: p - const Offset(0, 13), width: 35, height: 13),
      Paint()..color = const Color(0xFFBAA37B),
    );
    for (final x in [-14.0, 14.0]) {
      stroke(c, p + Offset(x, -11), p + Offset(x + 2, 0), ink, 1.3);
    }
    shape(c, [
      p + const Offset(-37, -45),
      p + const Offset(0, -67),
      p + const Offset(39, -45),
      p + const Offset(27, -39),
      p + const Offset(0, -42),
      p + const Offset(-28, -39),
    ], color);
    stroke(
      c,
      p + const Offset(0, -67),
      p + const Offset(0, -42),
      tint(color, .18),
      1.2,
    );
  }

  static void palm(Canvas c, Offset p, double scale) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final trunk = Path()
      ..moveTo(-5, 0)
      ..quadraticBezierTo(8, -42, 2, -92)
      ..lineTo(8, -92)
      ..quadraticBezierTo(15, -41, 4, 0)
      ..close();
    pathFill(c, trunk, const Color(0xFFB59870));
    for (var j = 0; j < 7; j++) {
      final dx = (j - 3) * 12.0, dy = -82.0 - (3 - (j - 3).abs()) * 7;
      final leaf = Path()
        ..moveTo(5, -93)
        ..quadraticBezierTo(dx * .7, -121, dx, dy)
        ..quadraticBezierTo(dx * .4, -102, 5, -93)
        ..close();
      pathFill(
        c,
        leaf,
        j.isEven ? const Color(0xFF5E8264) : const Color(0xFF74966B),
      );
    }
    c.restore();
  }
}

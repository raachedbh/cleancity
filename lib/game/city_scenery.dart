import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';
import '../data/city_layout.dart';

/// Original, cached street geometry drawn from the same plan as navigation.
class CityScenery {
  static Color tint(Color c, double a) => Color.lerp(
    c,
    a < 0 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    a.abs(),
  )!;
  static void line(Canvas c, Offset a, Offset b, Color color, double w) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
  static void box(Canvas c, Rect r, Color color) =>
      c.drawRect(r, Paint()..color = color);
  static void shape(Canvas c, List<Offset> p, Color color) =>
      c.drawPath(Path()..addPolygon(p, true), Paint()..color = color);
  static const shadow = Color(0x28313E38);
  static Color terrain(District d) => const [
    Color(0xFF8EA97A),
    Color(0xFFA0AC84),
    Color(0xFFC0B48E),
    Color(0xFF899C79),
    Color(0xFF839C89),
    Color(0xFF373A48),
  ][d.id];
  static void ground(Canvas c, District d) {
    final plan = d.layout, w = d.worldSize.width, h = d.worldSize.height;
    box(c, Rect.fromLTWH(-400, -400, w + 800, h + 800), terrain(d));
    final pavement = const [
      Color(0xFFD9D0BB),
      Color(0xFFC7BFAE),
      Color(0xFFD5D0BD),
      Color(0xFFD3C7B1),
      Color(0xFFB5B7AB),
      Color(0xFF716C79),
    ][d.id];
    c.drawPath(
      plan.boundary,
      Paint()
        ..color = tint(pavement, -.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    c.save();
    c.clipPath(plan.boundary);
    box(c, d.walkable, pavement);
    // Courtyards and planted lots form the background; paving follows streets.
    box(
      c,
      d.walkable,
      Color.lerp(pavement, terrain(d), (d.id == 0 || d.id == 4) ? .45 : .2)!,
    );
    for (final park in plan.parks) {
      c.drawRRect(
        RRect.fromRectAndRadius(park, const Radius.circular(14)),
        Paint()
          ..color = d.night ? const Color(0xFF48554C) : const Color(0xFF93A87A),
      );
    }
    if (plan.garden case final Rect g) {
      c.drawRRect(
        RRect.fromRectAndRadius(g.inflate(9), const Radius.circular(18)),
        Paint()..color = const Color(0xFFEBDEBF),
      );
      c.save();
      c.clipRRect(RRect.fromRectAndRadius(g, const Radius.circular(14)));
      box(c, g, const Color(0xFF8B9E68));
      // Fine, directional lawn stripes in the formal square.
      for (var y = g.top; y < g.bottom; y += 38) {
        box(
          c,
          Rect.fromLTWH(g.left, y, g.width, min(19, g.bottom - y)),
          const Color(0x1671874E),
        );
      }
      c.restore();
    }
    // Delineated building plots and front aprons keep facades grounded in blocks.
    for (final entry in plan.buildingEnvelopes.entries) {
      final b = d.blocks[entry.key], plot = entry.value.inflate(7);
      c.drawRRect(
        RRect.fromRectAndRadius(plot, const Radius.circular(5)),
        Paint()
          ..color = Color.lerp(pavement, terrain(d), d.id == 0 ? .65 : .13)!,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(plot, const Radius.circular(5)),
        Paint()
          ..color = tint(pavement, -.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final apron = Rect.fromLTWH(b.left - 15, b.bottom - 3, b.width + 30, 42);
      tiles(c, apron, pavement, 34, 20, seed: entry.key);
    }
    // Union each layer before painting: no internal curb seams at junctions,
    // and the stone texture covers the same rounded footprint as its road.
    Path network(Iterable<CityStreet> streets, double extraWidth) {
      var result = Path();
      for (final street in streets) {
        result = Path.combine(
          PathOperation.union,
          result,
          street.footprint(extraWidth: extraWidth),
        );
      }
      return result;
    }

    final carriageway = network(plan.streets, 0);
    c.drawPath(network(plan.streets, 58), Paint()..color = tint(pavement, -.2));
    c.drawPath(network(plan.streets, 52), Paint()..color = pavement);
    c.drawPath(network(plan.streets, 14), Paint()..color = tint(pavement, .24));
    for (final surface in StreetSurface.values) {
      final roads = plan.streets.where((s) => s.surface == surface);
      if (roads.isEmpty) continue;
      final color = switch (surface) {
        StreetSurface.asphalt =>
          d.id == 2 ? const Color(0xFF818987) : const Color(0xFF858C89),
        StreetSurface.stone =>
          d.id == 1 ? const Color(0xFFAEA89C) : const Color(0xFF929C99),
        StreetSurface.granite => const Color(0xFFB7B6AD),
        StreetSurface.cobble => const Color(0xFF555665),
        StreetSurface.gravel => const Color(0xFFC2B59B),
      };
      final ribbon = network(roads, 0);
      c.drawPath(ribbon, Paint()..color = color);
      if (surface == StreetSurface.asphalt) continue;
      c.save();
      c.clipPath(ribbon);
      if (surface == StreetSurface.gravel) {
        final random = Random(d.id);
        for (var i = 0; i < 700; i++) {
          final q = Offset(random.nextDouble() * w, random.nextDouble() * h);
          c.drawCircle(q, 1, Paint()..color = tint(color, -.17));
        }
      } else {
        tiles(
          c,
          ribbon.getBounds().intersect(d.walkable),
          color,
          surface == StreetSurface.cobble ? 22 : 56,
          surface == StreetSurface.cobble ? 15 : 30,
          seed: d.id + 1,
        );
      }
      c.restore();
    }
    // Painted lines are confined to vehicle streets; piazzas have stone bands.
    for (final street in plan.streets.where((s) => s.marked)) {
      for (final metric in _path(street.points).computeMetrics()) {
        for (var t = 70.0; t < metric.length - 30; t += 100) {
          final center = metric.getTangentForOffset(t + 12)!.position;
          if (plan.streets.any(
            (other) =>
                !identical(other, street) &&
                other.distanceTo(center) < other.width / 2 + 28,
          )) {
            continue;
          }
          c.drawPath(
            metric.extractPath(t, min(t + 25, metric.length)),
            Paint()
              ..color = const Color(0x99EBE9D4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
      }
    }
    if (plan.plaza case final Rect plaza) {
      c.save();
      c.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(d.walkable),
          carriageway,
        ),
      );
      c.drawPath(
        plan.plazaPath,
        Paint()
          ..color = tint(pavement, .32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12,
      );
      c.restore();
      c.save();
      c.clipPath(plan.plazaPath);
      final stone = d.id == 2
          ? const Color(0xFFBFC1B6)
          : d.night
          ? const Color(0xFF696272)
          : const Color(0xFFB8B1A2);
      box(c, plaza, stone);
      tiles(
        c,
        plaza,
        stone,
        d.id == 2 ? 38 : 65,
        d.id == 2 ? 22 : 44,
        seed: 21,
      );
      if (d.id == 2) {
        for (final y in [plaza.top + 17, plaza.bottom - 17]) {
          line(
            c,
            Offset(plaza.left, y),
            Offset(plaza.right, y),
            const Color(0xFFE6E2CE),
            5,
          );
        }
        for (var x = plaza.left + 180; x < plaza.right; x += 175) {
          line(
            c,
            Offset(x, plaza.top),
            Offset(x, plaza.bottom),
            const Color(0xFFE1DFCC),
            3,
          );
        }
      } else {
        final center = plaza.center;
        for (final radius in [64.0, 112.0, 162.0]) {
          c.drawOval(
            Rect.fromCenter(
              center: center,
              width: radius * 2,
              height: radius * 1.25,
            ),
            Paint()
              ..color = tint(stone, .22)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5,
          );
        }
      }
      c.restore();
    }
    if (plan.canal case final Rect water) {
      box(c, water.inflate(8), const Color(0xFF777F76));
      box(c, water, const Color(0xFF719A92));
      box(
        c,
        Rect.fromLTWH(water.left, water.top, 19, water.height),
        const Color(0xFF587F78),
      );
      for (var y = water.top + 7; y < water.bottom; y += 21) {
        line(
          c,
          Offset(water.left + 4, y),
          Offset(water.left + 11, y),
          const Color(0xFFC7CEB8),
          2,
        );
        line(
          c,
          Offset(water.right - 6, y + 8),
          Offset(water.right + 4, y + 8),
          const Color(0xFFC7CEB8),
          2,
        );
        line(
          c,
          Offset(water.left + 32 + (y.toInt() % 4) * 8, y),
          Offset(water.left + 61 + (y.toInt() % 4) * 8, y),
          const Color(0x446DE3C2),
          1.8,
        );
      }
      for (final y in plan.bridges) {
        final bridge = Rect.fromLTRB(
          water.left - 14,
          y - 60,
          water.right + 14,
          y + 60,
        );
        box(c, bridge.shift(const Offset(8, 12)), shadow);
        box(c, bridge, const Color(0xFFA89A7D));
        for (var x = bridge.left + 4; x < bridge.right; x += 12) {
          line(
            c,
            Offset(x, bridge.top + 3),
            Offset(x, bridge.bottom - 3),
            const Color(0xFF7D7966),
            1.2,
          );
          line(
            c,
            Offset(x + 2, bridge.top + 3),
            Offset(x + 2, bridge.bottom - 3),
            const Color(0xFFC5B798),
            1,
          );
        }
        // Low parapets remain within the solid banks, leaving the bridge open.
        for (final by in [bridge.top + 1, bridge.bottom - 1]) {
          line(
            c,
            Offset(bridge.left, by),
            Offset(bridge.right, by),
            const Color(0xFF5B675F),
            4,
          );
          line(
            c,
            Offset(bridge.left, by - 2),
            Offset(bridge.right, by - 2),
            const Color(0xFFD6CDB5),
            2,
          );
        }
      }
    }
    for (var i = 0; i < d.blocks.length; i++) {
      final b = d.blocks[i];
      if (plan.footprints[i] case final List<Offset> footprint) {
        shape(
          c,
          footprint.map((p) => p + const Offset(65, 38)).toList(),
          shadow,
        );
        for (var e = 0; e < footprint.length; e++) {
          final a = footprint[e], b = footprint[(e + 1) % footprint.length];
          shape(c, [
            a,
            b,
            b + const Offset(65, 38),
            a + const Offset(65, 38),
          ], shadow);
        }
        shape(c, footprint, tint(pavement, -.18));
        continue;
      }
      // Footprint and cast shadow tie facades to the pavement in one light direction.
      if (!plan.gardenLots.contains(i)) {
        shape(c, [
          b.topLeft,
          b.topRight,
          b.topRight + const Offset(63, 36),
          b.bottomRight + const Offset(63, 36),
          b.bottomRight,
          b.bottomLeft,
        ], shadow);
      }
      box(c, b.inflate(5), tint(pavement, -.25));
      box(c, b.inflate(2), tint(pavement, .25));
      box(
        c,
        b,
        plan.gardenLots.contains(i) || d.id == 0
            ? terrain(d)
            : tint(pavement, -.05),
      );
    }
    for (final b in plan.planters) {
      if (plan.props.any((p) => (p.position - b.center).distance < 1)) continue;
      c.drawOval(
        b.shift(const Offset(7, 6)).inflate(2),
        Paint()..color = shadow,
      );
      box(c, b, const Color(0xFF817C68));
      box(c, b.deflate(3), const Color(0xFF645F4C));
      for (var x = b.left + 5; x < b.right - 2; x += 7) {
        line(
          c,
          Offset(x, b.bottom - 3),
          Offset(x + 3, b.top + 4),
          const Color(0xFF78915C),
          2,
        );
      }
    }
    c.restore();
  }

  static void streetProp(Canvas c, CityProp prop, bool night) {
    c.save();
    c.translate(prop.position.dx, prop.position.dy);
    c.drawOval(const Rect.fromLTWH(-24, -9, 76, 29), Paint()..color = shadow);
    if (prop.kind == 2) {
      // Slatted timber with curved metal arms; all benches share their footprint.
      for (final x in [-23.0, 23.0]) {
        line(c, Offset(x, 4), Offset(x, -20), const Color(0xFF485951), 4);
        line(c, Offset(x, 10), Offset(x, -3), const Color(0xFF485951), 4);
      }
      for (var y = -24.0; y < -10; y += 5) {
        line(c, Offset(-29, y), Offset(29, y), const Color(0xFFA48A62), 3.5);
      }
      for (var y = -6.0; y < 4; y += 4) {
        line(c, Offset(-30, y), Offset(30, y), const Color(0xFFB09A75), 3.5);
      }
      for (final x in [-29.0, 29.0]) {
        final arm = Path()
          ..moveTo(x, 1)
          ..lineTo(x, -11)
          ..quadraticBezierTo(x, -15, x + 4, -14)
          ..lineTo(x + 7, -10);
        c.drawPath(
          arm,
          Paint()
            ..color = const Color(0xFF3A514B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
      for (var y = -24.0; y < -10; y += 5) {
        line(
          c,
          Offset(-27, y - .8),
          Offset(27, y - .8),
          const Color(0xFFC9AF81),
          .7,
        );
      }
    } else if (prop.kind == 0) {
      for (final x in [-24.0, 24.0]) {
        box(c, Rect.fromLTWH(x - 7, -9, 14, 10), const Color(0xFF91745C));
        line(c, Offset(x, 0), Offset(x, 8), const Color(0xFF635F50), 2);
      }
      c.drawOval(
        const Rect.fromLTWH(-18, -18, 36, 19),
        Paint()..color = const Color(0xFFE0D0AF),
      );
      line(
        c,
        const Offset(0, 0),
        const Offset(0, -60),
        const Color(0xFF786D58),
        3,
      );
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4, b = (i + 1) * pi / 4;
        shape(c, [
          const Offset(0, -76),
          Offset(cos(a) * 40, -56 + sin(a) * 17),
          Offset(cos(b) * 40, -56 + sin(b) * 17),
        ], i.isEven ? const Color(0xFFAE7460) : const Color(0xFFE6D6B1));
      }
      c.drawCircle(
        const Offset(0, -76),
        2,
        Paint()..color = const Color(0xFF766347),
      );
    } else {
      box(c, const Rect.fromLTWH(-41, -27, 82, 31), const Color(0xFF9A7E5C));
      for (final x in [-39.0, 39.0]) {
        line(c, Offset(x, -4), Offset(x, -73), const Color(0xFF625E50), 3);
      }
      for (var i = 0; i < 8; i++) {
        shape(c, [
          Offset(-46 + i * 11.5, -77),
          Offset(-34.5 + i * 11.5, -77),
          Offset(-30.5 + i * 11.5, -51),
          Offset(-42 + i * 11.5, -51),
        ], i.isEven ? const Color(0xFF588478) : const Color(0xFFE2D8B9));
      }
      for (var i = 0; i < 12; i++) {
        c.drawCircle(
          Offset(-31 + (i % 6) * 12, -28 + (i ~/ 6) * 8),
          4,
          Paint()
            ..color = i % 3 == 0
                ? const Color(0xFFCEA46A)
                : const Color(0xFF77995E),
        );
      }
    }
    c.restore();
  }

  static Path _path(List<Offset> points) {
    final p = Path()..moveTo(points.first.dx, points.first.dy);
    for (final q in points.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    return p;
  }

  static void tiles(
    Canvas c,
    Rect r,
    Color color,
    double width,
    double height, {
    int seed = 0,
  }) {
    c.save();
    c.clipRect(r);
    final random = Random(seed);
    for (var y = r.top, row = 0.0; y < r.bottom; y += height, row++) {
      for (
        var x = r.left - (row.toInt().isEven ? 0 : width / 2);
        x < r.right;
        x += width
      ) {
        final tile = Rect.fromLTWH(x + .8, y + .7, width - 1.6, height - 1.4);
        box(c, tile, tint(color, (random.nextDouble() - .5) * .09));
        line(c, tile.topLeft, tile.topRight, tint(color, .12), .65);
        line(c, tile.bottomLeft, tile.bottomRight, tint(color, -.16), .65);
        line(c, tile.topLeft, tile.bottomLeft, tint(color, -.12), .65);
      }
    }
    c.restore();
  }

  static double treeScale(CityTree tree) =>
      tree.scale *
      switch (tree.kind) {
        TreeKind.willow || TreeKind.palm => 1.9,
        TreeKind.lemon => 1.5,
        _ => 1.75,
      };
  static void tree(Canvas c, CityTree tree, {bool night = false}) {
    c.save();
    c.translate(tree.position.dx, tree.position.dy);
    c.scale(treeScale(tree));
    final kind = tree.kind, r = Random(tree.seed + kind.index * 81);
    // Directional canopy shadow is stretched along the ground plane.
    c.save();
    c.translate(31, 13);
    c.skew(.45, 0);
    c.drawOval(
      const Rect.fromLTWH(-34, -16, 78, 35),
      Paint()..color = const Color(0x30313F35),
    );
    c.restore();
    const bark = Color(0xFF82735C);
    line(c, const Offset(0, 0), const Offset(-2, -59), tint(bark, -.2), 9);
    line(c, const Offset(-2, -2), const Offset(-4, -60), tint(bark, .17), 3);
    if (kind != TreeKind.palm && kind != TreeKind.cypress) {
      for (final branch in [
        const Offset(-25, -64),
        const Offset(27, -60),
        const Offset(-9, -85),
      ]) {
        line(c, const Offset(-2, -30), branch, bark, 4);
      }
    }
    final green = night
        ? const Color(0xFF415854)
        : switch (kind) {
            TreeKind.ficus => const Color(0xFF426A48),
            TreeKind.lemon => const Color(0xFF617E43),
            TreeKind.cherry => const Color(0xFFC78F98),
            TreeKind.willow => const Color(0xFF72956A),
            TreeKind.plane => const Color(0xFF81925B),
            TreeKind.pine || TreeKind.cypress => const Color(0xFF456A54),
            _ => const Color(0xFF62854E),
          };
    if (kind == TreeKind.bare) {
      for (final side in [-1.0, 1.0]) {
        line(c, const Offset(0, -50), Offset(side * 22, -90), bark, 4);
        line(c, Offset(side * 16, -79), Offset(side * 34, -91), bark, 2);
        line(c, Offset(side * 22, -90), Offset(side * 18, -110), bark, 2);
        line(c, const Offset(-1, -61), Offset(side * 10, -113), bark, 3);
      }
    } else if (kind == TreeKind.palm) {
      line(c, const Offset(0, 0), const Offset(6, -99), bark, 10);
      for (var y = -5.0; y > -95; y -= 9) {
        line(
          c,
          Offset(-3 + y * -.06, y),
          Offset(5 + y * -.06, y - 2),
          tint(bark, .25),
          2,
        );
      }
      for (var i = 0; i < 9; i++) {
        final angle = i * pi / 5,
            end = Offset(6 + cos(angle) * 51, -95 + sin(angle) * 25);
        final p = Path()
          ..moveTo(6, -99)
          ..quadraticBezierTo(end.dx, -135, end.dx, end.dy)
          ..quadraticBezierTo(end.dx * .55, -112, 6, -99);
        c.drawPath(p, Paint()..color = tint(green, i.isEven ? .13 : -.1));
        line(c, const Offset(6, -99), end, tint(green, .3), 1);
      }
    } else if (kind == TreeKind.cypress || kind == TreeKind.pine) {
      if (kind == TreeKind.cypress) {
        final p = Path()
          ..moveTo(0, -142)
          ..cubicTo(-15, -112, -24, -48, -14, -29)
          ..quadraticBezierTo(0, -18, 16, -32)
          ..cubicTo(27, -55, 11, -116, 0, -142);
        c.drawPath(p, Paint()..color = green);
        for (var i = 0; i < 42; i++) {
          final y = -32 - r.nextDouble() * 94;
          c.drawOval(
            Rect.fromCenter(
              center: Offset(-5 + r.nextDouble() * 10, y),
              width: 10,
              height: 17,
            ),
            Paint()..color = tint(green, r.nextDouble() * .16),
          );
        }
      } else {
        for (var tier = 0; tier < 4; tier++) {
          final y = -123 + tier * 25.0, width = 18 + tier * 9.0;
          shape(c, [
            Offset(0, y),
            Offset(width, y + 46),
            Offset(3, y + 39),
            Offset(-width, y + 46),
          ], tint(green, -.12 + tier * .045));
          shape(c, [
            Offset(0, y),
            Offset(-width, y + 46),
            Offset(-5, y + 36),
          ], tint(green, .13));
        }
      }
    } else {
      final ficus = kind == TreeKind.ficus;
      // Ficus is a pruned avenue crown; other species have branching silhouettes.
      final centers = ficus
          ? [
              const Offset(-23, -73),
              const Offset(20, -73),
              const Offset(-4, -88),
              const Offset(-2, -63),
            ]
          : [
              const Offset(-25, -64),
              const Offset(24, -69),
              const Offset(-4, -89),
              const Offset(0, -63),
            ];
      for (var i = 0; i < centers.length; i++) {
        final q = centers[i];
        c.drawOval(
          Rect.fromCenter(
            center: q,
            width: ficus ? 53 : 56,
            height: ficus ? 45 : 53,
          ),
          Paint()..color = tint(green, i == 2 ? .13 : -.08 + i * .025),
        );
      }
      for (var i = 0; i < 55; i++) {
        final angle = r.nextDouble() * pi * 2,
            rad = sqrt(r.nextDouble()),
            q = Offset(cos(angle) * 43 * rad, -78 + sin(angle) * 26 * rad);
        c.drawOval(
          Rect.fromCenter(
            center: q,
            width: 5 + r.nextDouble() * 9,
            height: 3 + r.nextDouble() * 5,
          ),
          Paint()
            ..color = tint(
              green,
              q.dx < 0
                  ? .13 + r.nextDouble() * .13
                  : -.04 + r.nextDouble() * .1,
            ),
        );
      }
      if (kind == TreeKind.willow) {
        for (var i = 0; i < 15; i++) {
          final x = -39 + i * 5.5, end = -20 + r.nextDouble() * 24;
          final p = Path()
            ..moveTo(x, -81)
            ..quadraticBezierTo(x + 8, -48, x + 2, end);
          c.drawPath(
            p,
            Paint()
              ..color = tint(green, i.isEven ? .13 : -.1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
          for (var y = -72.0; y < end; y += 9) {
            line(
              c,
              Offset(x + 4, y),
              Offset(x - 1, y + 5),
              tint(green, .18),
              2.5,
            );
          }
        }
      }
      if (kind == TreeKind.lemon || kind == TreeKind.cherry) {
        for (var i = 0; i < 13; i++) {
          final q = Offset(
            -28 + r.nextDouble() * 57,
            -96 + r.nextDouble() * 45,
          );
          c.drawOval(
            Rect.fromCenter(
              center: q,
              width: kind == TreeKind.lemon ? 5 : 4,
              height: kind == TreeKind.lemon ? 7 : 3,
            ),
            Paint()
              ..color = kind == TreeKind.lemon
                  ? const Color(0xFFECCD65)
                  : const Color(0xFFFFD5D8),
          );
        }
      }
    }
    c.restore();
  }

  static void lamp(Canvas c, Offset p, int city) {
    c.save();
    c.translate(p.dx, p.dy);
    line(c, const Offset(0, 0), const Offset(43, 21), shadow, 7);
    final metal = city == 5 ? const Color(0xFF494854) : const Color(0xFF405650);
    c.drawOval(const Rect.fromLTWH(-7, -3, 14, 6), Paint()..color = metal);
    line(c, Offset.zero, const Offset(0, -89), metal, 4);
    line(c, const Offset(-1, -8), const Offset(-1, -87), tint(metal, .28), 1);
    if (city == 4) {
      line(c, const Offset(0, -88), const Offset(16, -88), metal, 3);
      box(c, const Rect.fromLTWH(7, -87, 17, 22), const Color(0xFFE3BA7E));
      for (var y = -85.0; y < -66; y += 5) {
        line(c, Offset(7, y), Offset(24, y), const Color(0xFF967658), 1);
      }
      box(c, const Rect.fromLTWH(5, -90, 22, 4), metal);
    } else {
      final heads = city == 2 || city == 3 ? [-13.0, 13.0] : [0.0];
      for (final x in heads) {
        line(c, const Offset(0, -79), Offset(x, -87), metal, 2.5);
        final glass = Rect.fromLTWH(x - 6, -103, 12, 17);
        if (city == 5) {
          c.drawCircle(
            Offset(x, -94),
            17,
            Paint()..color = const Color(0x18FFDC96),
          );
        }
        box(c, glass, const Color(0xFFF2D6A1));
        line(c, glass.topLeft, glass.bottomLeft, metal, 1.5);
        line(c, glass.topRight, glass.bottomRight, metal, 1.5);
        shape(c, [
          Offset(x - 9, -104),
          Offset(x, -111),
          Offset(x + 9, -104),
        ], metal);
        line(c, Offset(x - 6, -86), Offset(x + 6, -86), metal, 2);
      }
    }
    c.restore();
  }
}

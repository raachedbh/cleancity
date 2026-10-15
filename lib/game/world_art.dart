import 'tunis_clock.dart';
import 'urban_architecture.dart';
import 'reference_architecture.dart';
import 'city_scenery.dart';
import '../data/city_layout.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../data/catalog.dart';
import 'architecture.dart';

const specialCharacterRegions = [
  [
    Rect.fromLTRB(34, 12, 380, 479),
    Rect.fromLTRB(430, 12, 656, 479),
    Rect.fromLTRB(822, 12, 1098, 479),
    Rect.fromLTRB(1261, 12, 1492, 479),
  ],
  [
    Rect.fromLTRB(72, 490, 339, 995),
    Rect.fromLTRB(415, 490, 656, 997),
    Rect.fromLTRB(825, 490, 1092, 994),
    Rect.fromLTRB(1261, 490, 1500, 997),
  ],
];

/// Small reusable geometry, recorded once per map. No painted building cutouts.
class WorldArt {
  WorldArt(this.area) {
    final recorder = ui.PictureRecorder();
    CityScenery.ground(Canvas(recorder), area);
    ground = recorder.endRecording();
    // Paving contains thousands of joints. Rasterize only the flat ground once;
    // buildings/trees remain sharp vector pictures with independent depth sorting.
    // At most 2048 x 2048 RGBA pixels (<16 MiB), released when changing cities.
    final scale = min(
      1.0,
      2048 / max(area.worldSize.width, area.worldSize.height),
    );
    final cacheRecorder = ui.PictureRecorder();
    final cacheCanvas = Canvas(cacheRecorder)..scale(scale);
    cacheCanvas.drawPicture(ground);
    final cachePicture = cacheRecorder.endRecording();
    groundImage = cachePicture.toImageSync(
      (area.worldSize.width * scale).ceil(),
      (area.worldSize.height * scale).ceil(),
    );
    cachePicture.dispose();
    for (var i = 0; i < blocks.length; i++) {
      final r = ui.PictureRecorder();
      paintLot(Canvas(r), area, blocks[i], i);
      lots.add(r.endRecording());
    }
    for (final tree in area.layout.trees) {
      final r = ui.PictureRecorder();
      CityScenery.tree(Canvas(r), tree, night: area.night);
      props.add((
        position: tree.position,
        bounds: Rect.fromLTRB(
          tree.position.dx - 65 * CityScenery.treeScale(tree),
          tree.position.dy - 165 * CityScenery.treeScale(tree),
          tree.position.dx + 90 * CityScenery.treeScale(tree),
          tree.position.dy + 40 * CityScenery.treeScale(tree),
        ),
        picture: r.endRecording(),
      ));
    }
    for (final prop in area.layout.props) {
      final r = ui.PictureRecorder();
      CityScenery.streetProp(Canvas(r), prop, area.night);
      props.add((
        position: prop.position,
        bounds: Rect.fromLTWH(
          prop.position.dx - 65,
          prop.position.dy - 105,
          140,
          135,
        ),
        picture: r.endRecording(),
      ));
    }
    for (final lamp in area.layout.lamps) {
      final r = ui.PictureRecorder();
      CityScenery.lamp(Canvas(r), lamp, area.id);
      props.add((
        position: lamp,
        bounds: Rect.fromLTWH(lamp.dx - 24, lamp.dy - 120, 80, 150),
        picture: r.endRecording(),
      ));
    }
  }
  final District area;
  late final ui.Picture ground;
  late final ui.Image groundImage;
  final List<ui.Picture> lots = [];
  final List<({Offset position, Rect bounds, ui.Picture picture})> props = [];
  List<Rect> get blocks => area.blocks;
  static const outline = Color(0xFF344A46);
  static Color shade(Color c, double amount) =>
      Color.lerp(c, amount < 0 ? Colors.black : Colors.white, amount.abs())!;
  static void polygon(
    Canvas c,
    List<Offset> vertices,
    Color color, {
    double stroke = 2.4,
  }) {
    final path = Path()..addPolygon(vertices, true);
    c.drawPath(path, Paint()..color = color);
    if (stroke > 0) {
      c.drawPath(
        path,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  static void rect(
    Canvas c,
    Rect r,
    Color color, {
    double radius = 0,
    double stroke = 2,
  }) {
    final shape = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(shape, Paint()..color = color);
    if (stroke > 0) {
      c.drawRRect(
        shape,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }
  }

  static void line(Canvas c, Offset a, Offset b, Color color, double width) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void dispose() {
    ground.dispose();
    groundImage.dispose();
    for (final p in props) {
      p.picture.dispose();
    }
    for (final p in lots) {
      p.dispose();
    }
  }

  void drawGround(Canvas c) {
    c.drawRect(
      Rect.fromLTWH(
        -400,
        -400,
        area.worldSize.width + 800,
        area.worldSize.height + 800,
      ),
      Paint()..color = CityScenery.terrain(area),
    );
    c.drawImageRect(
      groundImage,
      Rect.fromLTWH(
        0,
        0,
        groundImage.width.toDouble(),
        groundImage.height.toDouble(),
      ),
      Offset.zero & area.worldSize,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  Rect spriteRect(int i) => area.id == 2 && i == area.landmarkBlock
      ? Rect.fromLTRB(
          blocks[i].left - 35,
          blocks[i].center.dy - TunisClock.height - 30,
          blocks[i].right + 35,
          blocks[i].bottom + 20,
        )
      : Rect.fromLTRB(
          blocks[i].left - 70,
          min(
            blocks[i].top - 290,
            blocks[i].bottom - 410 * blocks[i].height / 230,
          ),
          blocks[i].right + 75,
          blocks[i].bottom + 14,
        );
  void drawBlock(Canvas c, int i, Offset player) {
    final fades =
        spriteRect(i).contains(player - const Offset(0, 45)) &&
        player.dy < blocks[i].top;
    if (fades) {
      c.saveLayer(spriteRect(i), Paint()..color = const Color(0x88FFFFFF));
    }
    c.drawPicture(lots[i]);
    if (fades) c.restore();
  }

  void drawProp(Canvas c, int index, Offset player) {
    final p = props[index];
    final fade =
        p.bounds.contains(player - const Offset(0, 45)) &&
        player.dy < p.position.dy;
    if (fade) c.saveLayer(p.bounds, Paint()..color = const Color(0xAAFFFFFF));
    c.drawPicture(p.picture);
    if (fade) c.restore();
  }

  static void paintLot(Canvas c, District area, Rect b, int i) {
    if (area.id == 2 && i == area.landmarkBlock) {
      TunisClock.draw(c, b);
      return;
    }
    if (area.layout.footprints[i] case final List<Offset> points) {
      final original = area.blocks[i];
      final mapped = points
          .map(
            (p) => Offset(
              b.left + (p.dx - original.left) / original.width * b.width,
              b.top + (p.dy - original.top) / original.height * b.height,
            ),
          )
          .toList();
      UrbanArchitecture.paint(c, area, mapped, i);
      return;
    }
    c.save();
    c.translate(b.left, b.top);
    // Architectural details use a consistent design space; footprints are city-specific.
    c.scale(b.width / 310, b.height / 230);
    const lot = Rect.fromLTWH(0, 0, 310, 230);
    if (area.layout.gardenLots.contains(i)) {
      gardenLot(c, area, lot, i);
    } else if (i == area.landmarkBlock) {
      landmark(c, lot, area);
    } else {
      CityScenery.tree(
        c,
        CityTree(
          const Offset(20, 60),
          area.layout.treeKind(i),
          scale: .72,
          seed: i,
        ),
        night: area.night,
      );
      if (ReferenceArchitecture.supports(area, i)) {
        ReferenceArchitecture.paint(c, area, lot, i);
      } else {
        CityArchitecture.paint(c, area, lot, i);
      }
      if (i.isOdd) {
        CityScenery.tree(
          c,
          CityTree(
            const Offset(289, 201),
            area.layout.treeKind(i + 1),
            scale: .58,
            seed: i + 7,
          ),
          night: area.night,
        );
      }
      bush(c, const Offset(7, 214), area.night, 12);
      if (area.id == 3 || i % 3 == 1) {
        bench(c, const Offset(266, 225), area.night);
      }
    }
    c.restore();
  }

  static void gardenLot(Canvas c, District area, Rect b, int index) {
    rect(
      c,
      b.deflate(6),
      area.night ? const Color(0xFF414D4B) : const Color(0xFF637E4D),
      radius: 12,
      stroke: 1,
    );
    rect(
      c,
      b.deflate(17),
      area.night ? const Color(0xFF586059) : const Color(0xFF9DB27B),
      radius: 10,
      stroke: 0,
    );
    for (var y = 40.0; y < 210; y += 70) {
      for (var x = 45.0; x < 285; x += 85) {
        if (area.night) {
          rect(
            c,
            Rect.fromLTWH(x - 9, y - 28, 20, 29),
            const Color(0xFF949393),
            radius: 8,
            stroke: 1,
          );
          line(
            c,
            Offset(x - 4, y - 13),
            Offset(x + 5, y - 13),
            const Color(0xFF646773),
            1.4,
          );
        } else {
          bush(c, Offset(x, y), false, 18);
          for (var j = 0; j < 5; j++) {
            c.drawCircle(
              Offset(x - 9 + j * 4, y - 4 - j % 2 * 5),
              2.8,
              Paint()
                ..color = (index + j).isEven
                    ? const Color(0xFFDDAD7F)
                    : const Color(0xFFE5D9B2),
            );
          }
        }
      }
    }
    CityScenery.tree(
      c,
      CityTree(
        const Offset(265, 104),
        area.layout.treeKind(index),
        scale: 1.0,
        seed: index,
      ),
      night: area.night,
    );
    bench(c, const Offset(140, 216), area.night);
  }

  static void bush(Canvas c, Offset p, bool night, double size) {
    final color = night ? const Color(0xFF48615C) : const Color(0xFF628C59);
    for (var j = 0; j < 3; j++) {
      final q = p + Offset((j - 1) * size * .55, j == 1 ? -size * .32 : 0);
      c.drawCircle(q, size * .65, Paint()..color = shade(color, j * .06));
    }
    c.drawCircle(
      p + Offset(-size * .2, -size * .5),
      size * .18,
      Paint()..color = shade(color, .28),
    );
  }

  static void tree(Canvas c, Offset p, bool night, double scale) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    c.drawOval(
      const Rect.fromLTWH(-22, -3, 60, 17),
      Paint()..color = const Color(0x25334639),
    );
    rect(
      c,
      const Rect.fromLTWH(-4, -37, 9, 39),
      const Color(0xFF877158),
      radius: 2,
      stroke: 1.3,
    );
    line(
      c,
      const Offset(0, -19),
      const Offset(17, -42),
      const Color(0xFF877158),
      5,
    );
    final color = night ? const Color(0xFF405D59) : const Color(0xFF5D8C59);
    for (final q in [
      const Offset(-16, -40),
      const Offset(18, -43),
      const Offset(0, -61),
    ]) {
      c.drawCircle(q, 24, Paint()..color = shade(color, q.dx == 0 ? .15 : 0));
      c.drawArc(
        Rect.fromCircle(center: q, radius: 24),
        3.5,
        1.7,
        false,
        Paint()
          ..color = shade(color, .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    c.restore();
  }

  static void bench(Canvas c, Offset p, bool night) {
    c.save();
    c.translate(p.dx, p.dy);
    for (final x in [-18.0, 18.0]) {
      line(c, Offset(x, -11), Offset(x, 1), outline, 3);
    }
    for (var j = 0; j < 3; j++) {
      rect(
        c,
        Rect.fromLTWH(-23, -27 + j * 6.0, 46, 4),
        night ? const Color(0xFF9E8774) : const Color(0xFFB69066),
        radius: 1,
        stroke: .8,
      );
    }
    polygon(
      c,
      [
        const Offset(-23, -11),
        const Offset(23, -11),
        const Offset(27, -6),
        const Offset(-19, -6),
      ],
      const Color(0xFFB69066),
      stroke: 1.2,
    );
    c.restore();
  }

  static void label(
    Canvas c,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(c, center - Offset(painter.width / 2, 0));
    painter.dispose();
  }

  static void landmark(Canvas c, Rect b, District area) {
    final p = Offset(b.center.dx, b.bottom - 44);
    final stone = area.night
        ? const Color(0xFF9290A8)
        : const Color(0xFFE5D8B9);
    c.drawOval(
      Rect.fromCenter(
        center: b.center + const Offset(0, 35),
        width: 270,
        height: 165,
      ),
      Paint()
        ..color = area.night
            ? const Color(0xFF797181)
            : const Color(0xFFDDD4BF),
    );
    CityScenery.tree(
      c,
      CityTree(
        Offset(b.left + 28, b.top + 69),
        area.layout.treeKind(0),
        seed: 41,
      ),
      night: area.night,
    );
    CityScenery.tree(
      c,
      CityTree(
        Offset(b.right - 27, b.top + 74),
        area.layout.treeKind(1),
        scale: .9,
        seed: 43,
      ),
      night: area.night,
    );
    bench(c, Offset(b.left + 38, b.bottom - 12), area.night);
    bench(c, Offset(b.right - 38, b.bottom - 12), area.night);
    if (area.id == 2) {
      // Original interpretation of the Habib Bourguiba avenue clock tower.
      rect(
        c,
        Rect.fromCenter(center: p, width: 112, height: 20),
        stone,
        radius: 5,
      );
      rect(
        c,
        Rect.fromLTWH(p.dx - 34, p.dy - 28, 68, 22),
        shade(stone, -.12),
        stroke: 1.5,
      );
      final gold = const Color(0xFFC49B57);
      polygon(c, [
        p + const Offset(-20, -26),
        p + const Offset(20, -26),
        p + const Offset(12, -237),
        p + const Offset(-12, -237),
      ], gold);
      for (final x in [-10.0, 0.0, 10.0]) {
        line(
          c,
          p + Offset(x, -32),
          p + Offset(x * .5, -231),
          const Color(0xFFF0CB83),
          2,
        );
      }
      for (var y = -42.0; y > -225; y -= 19) {
        line(c, p + Offset(-18, y), p + Offset(18, y), shade(gold, -.2), 1.5);
      }
      rect(c, Rect.fromLTWH(p.dx - 28, p.dy - 279, 56, 54), gold, radius: 4);
      c.drawCircle(
        p + const Offset(0, -253),
        21,
        Paint()..color = const Color(0xFFFFF2D3),
      );
      for (var j = 0; j < 12; j++) {
        final dir = Offset(sin(j * pi / 6), -cos(j * pi / 6));
        line(
          c,
          p + const Offset(0, -253) + dir * 16,
          p + const Offset(0, -253) + dir * 19,
          outline,
          1.5,
        );
      }
      line(c, p + const Offset(0, -253), p + const Offset(0, -268), outline, 2);
      line(
        c,
        p + const Offset(0, -253),
        p + const Offset(11, -246),
        outline,
        2,
      );
      polygon(c, [
        p + const Offset(-31, -282),
        p + const Offset(0, -300),
        p + const Offset(31, -282),
      ], gold);
    } else if (area.id == 4) {
      rect(
        c,
        Rect.fromCenter(
          center: p - const Offset(0, 26),
          width: 190,
          height: 88,
        ),
        const Color(0xFF85BABC),
        radius: 34,
        stroke: 3,
      );
      polygon(c, [
        p + const Offset(-76, -12),
        p + const Offset(-32, -47),
        p + const Offset(45, -47),
        p + const Offset(87, -12),
      ], const Color(0xFFAC7759));
      for (final x in [-68.0, -25.0, 33.0, 79.0]) {
        line(
          c,
          p + Offset(x, -15),
          p + Offset(x, -49),
          const Color(0xFFAD5542),
          6,
        );
      }
      line(
        c,
        p + const Offset(-75, -40),
        p + const Offset(84, -40),
        const Color(0xFFAD5542),
        6,
      );
      tree(c, p + const Offset(-91, -85), false, .85);
    } else {
      // Tiered fountain with visible stone depth and water surface.
      c.drawOval(
        Rect.fromCenter(
          center: p + const Offset(8, 12),
          width: 176,
          height: 53,
        ),
        Paint()..color = const Color(0x24384439),
      );
      rect(
        c,
        Rect.fromCenter(center: p, width: 158, height: 49),
        shade(stone, -.2),
        radius: 24,
      );
      c.drawOval(
        Rect.fromCenter(
          center: p - const Offset(0, 15),
          width: 156,
          height: 48,
        ),
        Paint()..color = stone,
      );
      c.drawOval(
        Rect.fromCenter(
          center: p - const Offset(0, 15),
          width: 131,
          height: 33,
        ),
        Paint()
          ..color = area.night
              ? const Color(0xFF8B7EB6)
              : const Color(0xFF80BDC2),
      );
      rect(c, Rect.fromLTWH(p.dx - 10, p.dy - 76, 20, 58), stone, radius: 6);
      c.drawOval(
        Rect.fromCenter(center: p - const Offset(0, 76), width: 74, height: 20),
        Paint()..color = shade(stone, -.15),
      );
      c.drawOval(
        Rect.fromCenter(center: p - const Offset(0, 80), width: 70, height: 17),
        Paint()..color = stone,
      );
      line(c, p - const Offset(0, 80), p - const Offset(0, 112), stone, 11);
      c.drawCircle(p - const Offset(0, 114), 10, Paint()..color = stone);
      for (final x in [-24.0, 24.0]) {
        line(
          c,
          p + Offset(x, -78),
          p + Offset(x * 1.8, -16),
          const Color(0xFFB8DFD5),
          3,
        );
      }
      if (area.id == 5) {
        for (final x in [-83.0, 83.0]) {
          line(c, p + Offset(x, -2), p + Offset(x, -132), outline, 5);
          rect(
            c,
            Rect.fromLTWH(p.dx + x - 10, p.dy - 151, 20, 24),
            const Color(0xFFE7B878),
            radius: 4,
          );
        }
      }
    }
    label(
      c,
      area.id == 2
          ? 'AVENUE HABIB BOURGUIBA'
          : area.id == 1
          ? 'PIAZZA DEL SOLE'
          : area.id == 4
          ? 'LANTERN GARDEN'
          : area.night
          ? 'MIDNIGHT SQUARE'
          : 'NEIGHBORHOOD SQUARE',
      Offset(b.center.dx, b.bottom + 1),
      10,
      area.night ? const Color(0xFFD4CEDD) : outline,
    );
  }

  void drawGardens(Canvas c, int count) {
    for (var i = 0; i < count; i++) {
      final b = blocks[min(i, blocks.length - 1)];
      for (var n = 0; n < 7; n++) {
        final p = Offset(b.center.dx - 43 + n * 14, b.bottom + 9);
        bush(c, p, area.night, 8);
        c.drawCircle(
          p - const Offset(0, 6),
          4,
          Paint()
            ..color = [
              const Color(0xFFE9A6A6),
              const Color(0xFFF8D687),
              const Color(0xFFC6ABDC),
            ][n % 3],
        );
      }
    }
  }
}

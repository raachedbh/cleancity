import 'dart:math';
import 'package:flutter/material.dart';
import '../data/catalog.dart';
import 'architecture.dart';

final _box = CityArchitecture.box;
final _shape = CityArchitecture.shape;
final _line = CityArchitecture.stroke;
final _face = CityArchitecture.face;
final _tint = CityArchitecture.tint;
final _text = CityArchitecture.lettering;
const _stone = Color(0xFFE8DECA);
const _shadow = Color(0xFF464D48);
const _glass = Color(0xFF546F76);

/// Original vector interpretations of the references documented in docs/architecture-references.md.
/// Recorded into each lot's picture once, then culled and depth sorted by WorldArt.
class ReferenceArchitecture {
  static bool supports(District city, int address) =>
      city.id >= 1 && city.id <= 4;

  static void paint(Canvas c, District city, Rect lot, int address) {
    c.save();
    c.translate(lot.left + 12, lot.bottom - 24);
    // Stone forecourts, rather than a lawn beneath every urban building.
    _shape(
      c,
      [
        const Offset(-6, 12),
        const Offset(278, 12),
        const Offset(302, -47),
        const Offset(17, -47),
      ],
      const Color(0xFFC5C0AD),
      edge: .5,
    );
    for (var x = 0.0; x < 280; x += 23) {
      _line(
        c,
        Offset(x, 12),
        Offset(x + 23, -47),
        const Color(0xFFADA998),
        .65,
      );
    }
    for (var y = -35.0; y < 12; y += 15) {
      _line(c, Offset(1, y), Offset(280, y), const Color(0xFFADA998), .65);
    }
    if (address == 0 && city.id == 1) {
      _florenceArch(c);
    } else if (address == 0 && city.id == 2) {
      _tunisTheatre(c);
    } else if (city.id == 1 && address % 3 == 1) {
      _italianPalazzo(c, address);
    } else if (city.id == 1 && address % 3 == 2) {
      _italianLoggia(c, address);
    } else if (city.id == 2 && address % 3 != 0) {
      _tunisCorner(c, address);
    } else if (city.id == 2) {
      _tunisCourtyard(c, address);
    } else if (city.id == 4 && address % 3 == 1) {
      _kyotoTeahouse(c, address);
    } else if (city.id == 4) {
      _machiyaStreet(c, address);
    } else if (city.id == 3 && address % 3 == 2) {
      _parisCorner(c, address);
    } else if (city.id == 3) {
      _vosges(c, address);
    } else {
      _cityTerrace(c, city.id, address);
    }
    c.restore();
  }

  static void _italianPalazzo(Canvas c, int address) {
    final wall = address.isEven
        ? const Color(0xFFD9C59E)
        : const Color(0xFFDDCDB0);
    const w = 262.0, h = 249.0;
    _volume(c, w, h, wall, depth: const Offset(23, -38));
    // Rusticated stone base, tall piano nobile and a deep projecting cornice.
    for (var y = -73.0; y < 0; y += 13) {
      _line(c, Offset(0, y), Offset(w, y), _tint(wall, -.22), 1.2);
      for (var x = (y.toInt().isOdd ? 0.0 : 16.0); x < w; x += 32) {
        _line(c, Offset(x, y), Offset(x, y + 12), _tint(wall, -.18), .8);
      }
    }
    for (final y in [-224.0, -155.0]) {
      for (var x = 20.0; x < 250; x += 47) {
        _window(
          c,
          Rect.fromLTWH(x, y, 23, 41),
          _stone,
          shutters: address.isEven,
          accent: const Color(0xFF536957),
        );
        _course(c, x - 2, y - 6, 27, _stone, height: 3);
        if (y == -155) {
          _shape(
            c,
            [
              Offset(x - 6, y - 7),
              Offset(x + 11, y - 19),
              Offset(x + 29, y - 7),
            ],
            _tint(_stone, -.08),
            edge: .65,
          );
        }
      }
      _course(c, 0, y + 51, w, _stone, height: 4);
    }
    for (var x = 20.0; x < 245; x += 50) {
      _arch(
        c,
        Rect.fromLTWH(x, -62, 31, 62),
        _stone,
        inside: const Color(0xFF4E5C50),
        trim: 4,
      );
      _line(
        c,
        Offset(x + 16, -43),
        Offset(x + 16, -2),
        const Color(0xFF9A9175),
        1.4,
      );
    }
    _course(c, 0, -h - 7, w, _stone, height: 10);
    _course(c, -3, -h - 15, w + 5, _tint(_stone, .15), height: 6);
    for (var x = 2.0; x < w; x += 10) {
      _box(c, Rect.fromLTWH(x, -h + 2, 4, 7), _tint(wall, -.2), edge: 0);
    }
    _shape(c, [
      const Offset(-5, -265),
      const Offset(268, -265),
      const Offset(290, -292),
      const Offset(18, -292),
    ], const Color(0xFFA97959));
    for (var x = 0.0; x < 268; x += 8) {
      _line(
        c,
        Offset(x, -266),
        Offset(x + 24, -291),
        const Color(0xFFD0A080),
        1,
      );
    }
    _rail(c, 78, -103, 105);
    _text(c, 'PALAZZO DEL SOLE', const Offset(130, -87), 8, _shadow);
    _lamp(c, const Offset(13, -62));
    _lamp(c, const Offset(253, -62));
  }

  static void _italianLoggia(Canvas c, int address) {
    const stone = Color(0xFFD9C7A2);
    // A civic loggia and a narrow brick campanile break up the terraced frontage.
    _volume(c, 178, 119, stone);
    for (var x = 9.0; x < 168; x += 43) {
      _arch(
        c,
        Rect.fromLTWH(x, -89, 34, 89),
        _stone,
        inside: const Color(0xFF62695A),
        trim: 5,
      );
      _box(c, Rect.fromLTWH(x - 3, -17, 8, 17), _stone, edge: .6);
    }
    _course(c, 0, -121, 180, _stone, height: 9);
    _shape(c, [
      const Offset(-8, -132),
      const Offset(182, -132),
      const Offset(210, -168),
      const Offset(18, -168),
    ], const Color(0xFFA97653));
    for (var x = 0.0; x < 180; x += 9) {
      _line(
        c,
        Offset(x, -132),
        Offset(x + 27, -166),
        const Color(0xFFD3A077),
        1.2,
      );
    }
    c.save();
    c.translate(196, -5);
    _volume(c, 57, 266, const Color(0xFFB88D70), depth: const Offset(20, -31));
    for (var y = -253.0; y < 0; y += 9) {
      _line(c, Offset(0, y), Offset(57, y), const Color(0xFFD0AC8A), .6);
    }
    for (final y in [-231.0, -151.0, -72.0]) {
      _arch(
        c,
        Rect.fromLTWH(16, y, 23, 43),
        _stone,
        inside: const Color(0xFF525B52),
        trim: 3,
      );
      _course(c, 0, y + 50, 57, _stone, height: 4);
    }
    _course(c, -3, -269, 63, _stone, height: 8);
    _shape(c, [
      const Offset(-5, -279),
      const Offset(65, -279),
      const Offset(29, -318),
    ], const Color(0xFF9E6D50));
    c.restore();
    _text(
      c,
      address.isEven ? 'MERCATO' : 'LOGGIA',
      const Offset(89, -111),
      7,
      _shadow,
    );
    for (final p in [const Offset(21, 6), const Offset(165, 6)]) {
      CityArchitecture.planter(c, p, false, address);
    }
  }

  static void _tunisCorner(Canvas c, int address) {
    final wall = address.isEven
        ? const Color(0xFFEDE5CF)
        : const Color(0xFFDCDAC8);
    const accent = Color(0xFF417B80);
    // Avenue apartment house with an Art Deco stair tower and wraparound balconies.
    _volume(c, 252, 228, wall, depth: const Offset(28, -36));
    _box(c, const Rect.fromLTWH(0, -62, 252, 62), _tint(wall, -.08), edge: .6);
    for (final y in [-205.0, -139.0]) {
      for (final x in [14.0, 63.0, 172.0, 216.0]) {
        _window(
          c,
          Rect.fromLTWH(x, y, 24, 42),
          _stone,
          shutters: address.isOdd,
          accent: accent,
        );
      }
      for (final x in [8.0, 166.0]) {
        _box(
          c,
          Rect.fromLTWH(x + 4, y + 43, 81, 7),
          const Color(0x403B473F),
          edge: 0,
        );
        _course(c, x, y + 39, 82, _stone, height: 5);
        _rail(c, x + 2, y + 20, 79);
      }
    }
    _volumeAt(c, const Offset(111, 0), 44, 259, _tint(wall, .08));
    for (var y = -232.0; y < -72; y += 42) {
      _window(c, Rect.fromLTWH(123, y, 18, 29), _stone, accent: accent);
      _line(c, Offset(115, y - 5), Offset(150, y - 5), _tint(wall, -.13), 1);
    }
    _course(c, 109, -267, 49, _stone, height: 8);
    _course(c, 112, -275, 42, _stone, height: 5);
    _course(c, 0, -232, 110, _stone, height: 7);
    _course(c, 160, -232, 95, _stone, height: 7);
    for (final x in [14.0, 67.0, 171.0, 218.0]) {
      _arch(c, Rect.fromLTWH(x, -56, 30, 56), _stone, inside: accent, trim: 4);
      _line(c, Offset(x + 15, -43), Offset(x + 15, -2), _tint(accent, .5), 1.3);
    }
    _arch(
      c,
      const Rect.fromLTWH(121, -62, 27, 62),
      _stone,
      inside: const Color(0xFF45636A),
      trim: 4,
    );
    for (final x in [9.0, 163.0]) {
      _shape(c, [
        Offset(x, -64),
        Offset(x + 89, -64),
        Offset(x + 98, -49),
        Offset(x + 7, -49),
      ], accent);
      for (var j = 0; j < 9; j += 2) {
        _shape(
          c,
          [
            Offset(x + j * 10, -64),
            Offset(x + j * 10 + 5, -64),
            Offset(x + j * 10 + 14, -49),
            Offset(x + j * 10 + 9, -49),
          ],
          _stone,
          edge: 0,
        );
      }
    }
    _text(
      c,
      address.isOdd ? 'CAFE DE L’AVENUE' : 'MAISON DES ARTS',
      const Offset(57, -80),
      6.5,
      _shadow,
    );
    _text(c, 'TUNIS', const Offset(205, -80), 7, _shadow);
    _lamp(c, const Offset(105, -72));
  }

  static void _volumeAt(Canvas c, Offset at, double w, double h, Color color) {
    c.save();
    c.translate(at.dx, at.dy);
    _volume(c, w, h, color, depth: const Offset(13, -18));
    c.restore();
  }

  static void _tunisCourtyard(Canvas c, int address) {
    const white = Color(0xFFE8E5CF), blue = Color(0xFF477F8A);
    // A lower white courtyard house, arched entrance and tiled shop arcade.
    _volume(c, 266, 139, white, depth: const Offset(25, -38));
    _course(c, 0, -143, 268, _stone, height: 8);
    _course(c, 8, -160, 251, _stone, height: 5);
    for (var x = 12.0; x < 255; x += 15) {
      _box(c, Rect.fromLTWH(x, -158, 6, 15), white, edge: .5);
    }
    for (final x in [17.0, 73.0, 191.0]) {
      _arch(c, Rect.fromLTWH(x, -106, 36, 46), _stone, inside: blue, trim: 5);
      for (var tx = x + 5; tx < x + 32; tx += 5) {
        _line(c, Offset(tx, -85), Offset(tx, -61), _tint(blue, .35), .8);
      }
    }
    _arch(
      c,
      const Rect.fromLTWH(119, -90, 48, 90),
      _stone,
      inside: blue,
      trim: 7,
    );
    _line(c, const Offset(143, -65), const Offset(143, -2), _tint(blue, .4), 2);
    for (final x in [126.0, 158.0]) {
      for (var y = -53.0; y < -5; y += 13) {
        c.drawCircle(
          Offset(x, y),
          1.3,
          Paint()..color = const Color(0xFFDCCB8B),
        );
      }
    }
    for (final x in [12.0, 191.0]) {
      _box(c, Rect.fromLTWH(x, -47, 72, 46), blue, edge: 1);
      _window(c, Rect.fromLTWH(x + 6, -42, 60, 34), _stone);
      _shape(c, [
        Offset(x - 3, -54),
        Offset(x + 75, -54),
        Offset(x + 83, -38),
        Offset(x + 5, -38),
      ], const Color(0xFFBB9B6B));
    }
    _text(
      c,
      address.isEven ? 'DAR EL YASMINE' : 'ATELIER',
      const Offset(143, -118),
      7,
      _shadow,
    );
    _lamp(c, const Offset(177, -79));
    CityArchitecture.planter(c, const Offset(100, 2), false, address);
  }

  static void _parisCorner(Canvas c, int address) {
    const wall = Color(0xFFDFD5BE), roof = Color(0xFF67747F);
    _volume(c, 254, 246, wall, depth: const Offset(27, -34));
    for (final y in [-224.0, -159.0, -94.0]) {
      for (var x = 18.0; x < 244; x += 44) {
        _window(c, Rect.fromLTWH(x, y, 23, 43), _stone);
      }
      _course(c, 0, y + 50, 255, _stone, height: 4);
      if (y != -159) _rail(c, 4, y + 29, 247);
    }
    for (final x in [17.0, 83.0, 151.0, 216.0]) {
      _arch(
        c,
        Rect.fromLTWH(x, -35, 26, 35),
        _stone,
        inside: const Color(0xFF4A6963),
        trim: 3,
      );
    }
    _course(c, 0, -250, 254, _stone, height: 7);
    _shape(c, [
      const Offset(-6, -255),
      const Offset(258, -255),
      const Offset(242, -308),
      const Offset(12, -308),
    ], roof);
    _shape(c, [
      const Offset(258, -255),
      const Offset(285, -290),
      const Offset(268, -341),
      const Offset(242, -308),
    ], _tint(roof, -.16));
    for (var x = 16.0; x < 246; x += 22) {
      _line(c, Offset(x, -257), Offset(x + 5, -305), _tint(roof, .2), .9);
    }
    for (var x = 23.0; x < 242; x += 50) {
      _box(c, Rect.fromLTWH(x, -291, 21, 31), _stone, edge: .8);
      _shape(c, [
        Offset(x - 3, -293),
        Offset(x + 11, -306),
        Offset(x + 25, -293),
      ], _stone);
      _window(c, Rect.fromLTWH(x + 5, -287, 12, 22), _stone);
    }
    for (final x in [42.0, 211.0]) {
      _box(
        c,
        Rect.fromLTWH(x, -334, 10, 40),
        const Color(0xFFB6856A),
        edge: .7,
      );
      _course(c, x - 1, -337, 12, _stone, height: 3);
    }
    _text(
      c,
      address.isOdd ? 'BOULANGERIE' : 'LIBRAIRIE',
      const Offset(128, -42),
      7,
      _shadow,
    );
  }

  static void _kyotoTeahouse(Canvas c, int address) {
    const timber = Color(0xFF705E4A),
        plaster = Color(0xFFD6CBAA),
        roof = Color(0xFF657270);
    // One-storey tea pavilion beside a garden wall, with a deep tiled gable.
    _volume(c, 180, 117, timber, depth: const Offset(36, -44));
    _box(c, const Rect.fromLTWH(3, -113, 174, 37), plaster, edge: .5);
    for (var x = 7.0; x < 178; x += 24) {
      _box(c, Rect.fromLTWH(x, -73, 19, 68), const Color(0xFFB6B294), edge: .7);
      for (var j = 1; j < 4; j++) {
        _line(c, Offset(x + j * 4.6, -72), Offset(x + j * 4.6, -6), timber, .9);
      }
      for (var y = -60.0; y < -5; y += 14) {
        _line(c, Offset(x, y), Offset(x + 19, y), timber, 1);
      }
    }
    _shape(c, [
      const Offset(-13, -118),
      const Offset(195, -118),
      const Offset(169, -154),
      const Offset(10, -154),
    ], roof);
    _shape(c, [
      const Offset(10, -154),
      const Offset(169, -154),
      const Offset(207, -198),
      const Offset(46, -198),
    ], _tint(roof, .13));
    for (var x = -5.0; x < 189; x += 8) {
      _line(c, Offset(x, -120), Offset(x + 13, -152), _tint(roof, .25), 1);
    }
    for (var x = 14.0; x < 166; x += 8) {
      _line(c, Offset(x, -155), Offset(x + 38, -196), _tint(roof, .25), 1);
    }
    _course(c, -8, -121, 201, roof, height: 4);
    _box(
      c,
      const Rect.fromLTWH(-7, 0, 199, 11),
      const Color(0xFFAEA78B),
      edge: .8,
    );
    for (final x in [9.0, 169.0]) {
      _box(c, Rect.fromLTWH(x, -118, 5, 119), _tint(timber, -.1), edge: .5);
    }
    _box(c, const Rect.fromLTWH(198, -67, 68, 67), plaster, edge: .6);
    _shape(c, [
      const Offset(193, -68),
      const Offset(270, -68),
      const Offset(276, -81),
      const Offset(201, -81),
    ], roof);
    for (var x = 204.0; x < 263; x += 13) {
      _line(c, Offset(x, -64), Offset(x, -4), _tint(plaster, -.12), .7);
    }
    for (final x in [29.0, 152.0]) {
      c.drawOval(
        Rect.fromLTWH(x, -111, 15, 24),
        Paint()..color = const Color(0xFFE6B17C),
      );
      for (var y = -107.0; y < -88; y += 5) {
        _line(c, Offset(x, y), Offset(x + 15, y), const Color(0xFFAD7554), .8);
      }
    }
    _text(
      c,
      address.isOdd ? 'TEA GARDEN' : 'RIVER HOUSE',
      const Offset(93, -96),
      7,
      _shadow,
    );
    CityArchitecture.planter(c, const Offset(231, -3), false, address);
  }

  static void _volume(
    Canvas c,
    double w,
    double h,
    Color color, {
    Offset depth = const Offset(25, -38),
  }) {
    _shape(
      c,
      [
        const Offset(-4, 7),
        Offset(w + 12, 7),
        Offset(w + depth.dx + 28, depth.dy - 8),
        Offset(28, depth.dy - 12),
      ],
      const Color(0x34393E37),
      edge: 0,
    );
    _shape(c, [
      Offset(w, 0),
      Offset(w, -h),
      Offset(w, -h) + depth,
      Offset(w, 0) + depth,
    ], _tint(color, -.25));
    _face(c, Rect.fromLTWH(0, -h, w, h), color);
    _shape(c, [
      Offset(0, -h),
      Offset(w, -h),
      Offset(w, -h) + depth,
      Offset(0, -h) + depth,
    ], _tint(color, .13));
    for (var y = -h + 30; y < -20; y += 73) {
      final a = Offset(w + 6, y), b = a + depth * .6;
      _shape(
        c,
        [a, b, b + const Offset(0, 36), a + const Offset(0, 36)],
        _glass,
        edge: .6,
      );
      _line(
        c,
        a + depth * .3,
        a + depth * .3 + const Offset(0, 36),
        _stone,
        1.6,
      );
    }
  }

  static void _course(
    Canvas c,
    double x,
    double y,
    double w,
    Color color, {
    double height = 5,
  }) {
    _box(
      c,
      Rect.fromLTWH(x - 2, y + height, w + 5, 3),
      const Color(0x383B3B32),
      edge: 0,
    );
    _box(c, Rect.fromLTWH(x - 3, y, w + 6, height), color, edge: .55);
    _line(c, Offset(x - 2, y), Offset(x + w + 2, y), _tint(color, .4), 1.1);
  }

  static Path _archPath(Rect r) => Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + r.width / 2)
    ..cubicTo(
      r.left,
      r.top - r.width / 6,
      r.right,
      r.top - r.width / 6,
      r.right,
      r.top + r.width / 2,
    )
    ..lineTo(r.right, r.bottom)
    ..close();

  static void _arch(
    Canvas c,
    Rect r,
    Color surround, {
    Color inside = _glass,
    double trim = 5,
  }) {
    c.drawPath(
      _archPath(r.inflate(trim)),
      Paint()..color = _tint(surround, -.2),
    );
    c.drawPath(_archPath(r.inflate(trim - 1)), Paint()..color = surround);
    c.drawPath(_archPath(r), Paint()..color = inside);
    // Reveal and reflected light give each opening a recessed interior.
    c.save();
    c.clipPath(_archPath(r));
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [_tint(inside, -.3), inside, _tint(inside, .12)],
        ).createShader(r),
    );
    _line(
      c,
      r.topLeft + const Offset(3, 0),
      r.bottomLeft + const Offset(3, 0),
      _tint(inside, -.3),
      4,
    );
    c.restore();
  }

  static void _window(
    Canvas c,
    Rect r,
    Color trim, {
    bool shutters = false,
    Color accent = const Color(0xFF566654),
    bool arched = false,
  }) {
    if (arched) {
      _arch(c, r, trim, trim: 3);
    } else {
      _box(c, r.inflate(3), _tint(trim, -.16), edge: .7);
      _box(c, r.inflate(1.8), trim, edge: 0);
      _face(c, r, _glass);
    }
    _shape(
      c,
      [
        r.topLeft + const Offset(3, 3),
        r.topRight - const Offset(3, -3),
        r.bottomLeft + Offset(3, -r.height * .4),
      ],
      const Color(0x337BBDCB),
      edge: 0,
    );
    _line(c, r.topCenter, r.bottomCenter, trim, 1.8);
    _line(c, r.centerLeft, r.centerRight, trim, 1.8);
    _course(c, r.left - 2, r.bottom + 2, r.width + 4, trim, height: 2.5);
    if (shutters) {
      for (final x in [r.left - 12, r.right + 4]) {
        _box(c, Rect.fromLTWH(x, r.top, 8, r.height), accent, edge: .6);
        for (var y = r.top + 4; y < r.bottom - 2; y += 4) {
          _line(c, Offset(x + 1, y), Offset(x + 7, y), _tint(accent, .25), .7);
        }
      }
    }
  }

  static void _rail(
    Canvas c,
    double x,
    double y,
    double width, {
    Color color = _shadow,
  }) {
    _box(c, Rect.fromLTWH(x - 3, y + 12, width + 6, 5), _stone, edge: .6);
    for (var i = 0.0; i <= width; i += 6) {
      _line(c, Offset(x + i, y), Offset(x + i, y + 12), color, 1.2);
    }
    _line(c, Offset(x - 1, y), Offset(x + width + 1, y), color, 2);
    _line(c, Offset(x, y + 9), Offset(x + width, y + 9), color, 1);
  }

  static void _lamp(Canvas c, Offset p) {
    _line(c, p, p + const Offset(0, -12), _shadow, 2);
    _box(
      c,
      Rect.fromCenter(center: p, width: 8, height: 12),
      const Color(0xFFE7C579),
      radius: 2,
      edge: .8,
    );
    _line(c, p + const Offset(-4, -6), p + const Offset(4, -6), _shadow, 2);
  }

  static void _florenceArch(Canvas c) {
    const wall = Color(0xFFC2A583), trim = Color(0xFFE3CBA8);
    _volume(c, 264, 242, wall);
    for (var y = -230.0; y < -5; y += 15) {
      _line(c, Offset(1, y), Offset(263, y), _tint(wall, -.16), .65);
    }
    // The Arcone: a high central vault, paired pilasters and a raised attic.
    _arch(
      c,
      const Rect.fromLTWH(87, -173, 90, 174),
      trim,
      inside: const Color(0xFF494C43),
      trim: 10,
    );
    _arch(
      c,
      const Rect.fromLTWH(104, -153, 69, 154),
      const Color(0xFF8F8872),
      inside: const Color(0xFF718779),
      trim: 2,
    );
    _shape(
      c,
      [
        const Offset(88, 0),
        const Offset(177, 0),
        const Offset(168, -26),
        const Offset(109, -26),
      ],
      const Color(0xFFB7AD96),
      edge: 0,
    );
    for (final x in [8.0, 60.0, 193.0, 245.0]) {
      _box(c, Rect.fromLTWH(x, -222, 12, 220), trim, edge: .7);
      _line(c, Offset(x + 4, -214), Offset(x + 4, -12), _tint(trim, -.17), 1.2);
      _course(c, x - 3, -227, 18, trim, height: 6);
      _course(c, x - 4, -10, 20, trim, height: 8);
      c.drawCircle(Offset(x + 1, -218), 3, Paint()..color = _tint(trim, -.2));
      c.drawCircle(Offset(x + 11, -218), 3, Paint()..color = _tint(trim, -.2));
    }
    for (final x in [31.0, 214.0]) {
      _window(c, Rect.fromLTWH(x, -194, 21, 40), trim);
      _window(c, Rect.fromLTWH(x, -128, 21, 42), trim);
      _arch(
        c,
        Rect.fromLTWH(x - 2, -62, 25, 62),
        trim,
        inside: const Color(0xFF4C6358),
        trim: 3,
      );
    }
    for (final y in [-247.0, -236.0, -204.0]) {
      _course(c, 0, y, 264, trim, height: y == -247 ? 8 : 4);
    }
    // Balustrade and the inscription panel above the monumental central arch.
    _box(c, const Rect.fromLTWH(79, -276, 106, 31), trim, edge: .8);
    _course(c, 75, -280, 114, trim, height: 5);
    _text(c, 'FIRENZE', const Offset(132, -267), 11, const Color(0xFF78664D));
    _text(
      c,
      'PIAZZA DELLA REPUBBLICA',
      const Offset(132, -220),
      5.5,
      const Color(0xFF78664D),
    );
    for (final begin in [2.0, 191.0]) {
      for (var x = begin; x < begin + 70; x += 8) {
        _box(c, Rect.fromLTWH(x, -266, 3, 20), trim, edge: .4);
      }
      _course(c, begin, -270, 70, trim, height: 4);
    }
    _lamp(c, const Offset(74, -72));
    _lamp(c, const Offset(189, -72));
  }

  static void _tunisTheatre(Canvas c) {
    const wall = Color(0xFFECE6D9),
        trim = Color(0xFFFFF7E7),
        recess = Color(0xFFACA68F);
    _volume(c, 261, 231, wall, depth: const Offset(29, -39));
    // Curved Art Nouveau front and cornice, observed on the Municipal Theatre.
    final front = Path()
      ..moveTo(24, 0)
      ..lineTo(24, -234)
      ..cubicTo(50, -242, 61, -263, 103, -255)
      ..quadraticBezierTo(130, -271, 158, -255)
      ..cubicTo(201, -263, 213, -242, 239, -234)
      ..lineTo(239, 0)
      ..close();
    c.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          colors: [trim, wall, Color(0xFFD3CEBF)],
        ).createShader(const Rect.fromLTWH(24, -270, 215, 270)),
    );
    final curve = Path()
      ..moveTo(24, -234)
      ..cubicTo(50, -242, 61, -263, 103, -255)
      ..quadraticBezierTo(130, -271, 158, -255)
      ..cubicTo(201, -263, 213, -242, 239, -234);
    c.drawPath(
      curve.shift(const Offset(0, 6)),
      Paint()
        ..color = recess
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    c.drawPath(
      curve,
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    for (final x in [7.0, 245.0]) {
      for (final y in [-191.0, -133.0]) {
        _window(c, Rect.fromLTWH(x, y, 12, 28), trim);
      }
    }
    for (final x in [48.0, 110.0, 173.0]) {
      _arch(
        c,
        Rect.fromLTWH(x, -79, 36, 79),
        trim,
        inside: const Color(0xFF62574A),
        trim: 6,
      );
      _line(
        c,
        Offset(x + 18, -59),
        Offset(x + 18, -2),
        const Color(0xFFC6B183),
        1.8,
      );
      for (final dx in [6.0, 23.0]) {
        _box(
          c,
          Rect.fromLTWH(x + dx, -45, 9, 29),
          const Color(0xFF866E53),
          edge: .6,
        );
      }
      _arch(c, Rect.fromLTWH(x - 1, -176, 38, 65), trim, trim: 6);
      _line(c, Offset(x + 18, -167), Offset(x + 18, -112), trim, 2);
      _line(c, Offset(x, -143), Offset(x + 36, -143), trim, 2);
    }
    _course(c, 37, -98, 185, trim, height: 9);
    _rail(c, 45, -113, 170, color: recess);
    // The relief is suggested with a central lyre, laurel and two reclining muses.
    c.drawOval(
      const Rect.fromLTWH(99, -226, 61, 27),
      Paint()..color = const Color(0xFFD1CBBB),
    );
    for (final side in [-1.0, 1.0]) {
      final center = Offset(130 + side * 35, -211);
      c.drawOval(
        Rect.fromCenter(center: center, width: 33, height: 10),
        Paint()..color = trim,
      );
      c.drawCircle(Offset(130 + side * 25, -224), 4.5, Paint()..color = trim);
      _line(
        c,
        Offset(130 + side * 25, -219),
        Offset(130 + side * 36, -207),
        trim,
        6,
      );
      for (var i = 0; i < 5; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(
              130 + side * (45 + i * 7),
              -209 - sin(i / 4 * pi) * 9,
            ),
            width: 10,
            height: 4,
          ),
          Paint()..color = trim,
        );
      }
    }
    _box(c, const Rect.fromLTWH(126, -225, 8, 22), trim, radius: 3, edge: .5);
    _text(
      c,
      'THEATRE MUNICIPAL',
      const Offset(131, -192),
      7.7,
      const Color(0xFF84775E),
    );
    for (final x in [31.0, 223.0]) {
      _box(c, Rect.fromLTWH(x, -221, 9, 216), trim, edge: .6);
      c.drawOval(
        Rect.fromCenter(center: Offset(x + 4, -209), width: 15, height: 22),
        Paint()..color = trim,
      );
      _lamp(c, Offset(x + 4, -84));
    }
    for (var i = 0; i < 3; i++) {
      _box(
        c,
        Rect.fromLTWH(30 - i * 4, 1 + i * 4, 205 + i * 8, 4),
        _tint(wall, -.1 - i * .04),
        edge: .4,
      );
    }
  }

  static void _vosges(Canvas c, int address) {
    const trim = Color(0xFFE6DACA), roof = Color(0xFF566473);
    for (var wing = 0; wing < 2; wing++) {
      final w = wing == 0 ? 137.0 : 128.0;
      final h = 215.0 + ((address + wing) % 3) * 10;
      c.save();
      c.translate(wing == 0 ? 0 : 138, wing == 0 ? 0 : -8);
      final brick = [
        const Color(0xFFB97E65),
        const Color(0xFFB98673),
        const Color(0xFFA5715E),
      ][(address + wing) % 3];
      _volume(c, w, h, brick, depth: const Offset(22, -34));
      for (var y = -h + 5; y < -76; y += 7) {
        _line(c, Offset(0, y), Offset(w, y), _tint(brick, .2), .6);
        for (var x = (y.toInt().isEven ? 0.0 : 10.0); x < w; x += 20) {
          _line(c, Offset(x, y - 6), Offset(x, y), _tint(brick, .2), .5);
        }
      }
      // Pale stone vertical chains against brick are characteristic of Place des Vosges.
      for (final x in [1.0, w / 2 - 4, w - 9]) {
        for (var y = -h + 1; y < -76; y += 13) {
          _box(
            c,
            Rect.fromLTWH(x - (y.toInt().isEven ? 1 : 0), y, 9, 12),
            trim,
            edge: .3,
          );
        }
      }
      for (final y in [-h + 18, -h + 83]) {
        for (final x in [w * .24 - 12, w * .75 - 12]) {
          _window(c, Rect.fromLTWH(x, y, 24, 42), trim);
        }
      }
      _course(c, 0, -77, w, trim, height: 7);
      _box(c, Rect.fromLTWH(0, -69, w, 69), trim, edge: .4);
      for (final x in [12.0, w / 2 + 7]) {
        _arch(
          c,
          Rect.fromLTWH(x, -60, w / 2 - 24, 60),
          trim,
          inside: const Color(0xFF5B625A),
          trim: 4,
        );
        _box(
          c,
          Rect.fromLTWH(x + 6, -38, w / 2 - 38, 38),
          const Color(0xFF526A61),
          edge: .7,
        );
        _line(
          c,
          Offset(x + 9, -34),
          Offset(x + 9, -3),
          const Color(0xFFAD9F7F),
          1.3,
        );
      }
      _course(c, 0, -h - 3, w, trim, height: 7);
      _shape(c, [
        Offset(-4, -h - 4),
        Offset(w + 4, -h - 4),
        Offset(w - 10, -h - 55),
        Offset(17, -h - 55),
      ], roof);
      _shape(c, [
        Offset(w + 4, -h - 4),
        Offset(w + 26, -h - 38),
        Offset(w + 12, -h - 87),
        Offset(w - 10, -h - 55),
      ], _tint(roof, -.18));
      for (var x = 6.0; x < w - 5; x += 10) {
        _line(
          c,
          Offset(x, -h - 7),
          Offset(x + 9, -h - 51),
          _tint(roof, .2),
          .6,
        );
      }
      for (final x in [w * .24 - 10, w * .75 - 10]) {
        _box(c, Rect.fromLTWH(x, -h - 41, 20, 30), trim, edge: .7);
        _shape(c, [
          Offset(x - 3, -h - 41),
          Offset(x + 10, -h - 54),
          Offset(x + 23, -h - 41),
        ], trim);
        _window(c, Rect.fromLTWH(x + 5, -h - 36, 10, 21), trim);
      }
      _box(
        c,
        Rect.fromLTWH(w - 8, -h - 78, 9, 46),
        _tint(trim, -.18),
        edge: .7,
      );
      _course(c, w - 9, -h - 81, 11, trim, height: 3);
      _text(
        c,
        wing == 0 ? 'GALERIE' : 'CAFE DES ARCADES',
        Offset(w / 2, -74),
        wing == 0 ? 6 : 5,
        _shadow,
      );
      c.restore();
    }
  }

  static void _cityTerrace(Canvas c, int city, int address) {
    final seed = Random(city * 751 + address * 47);
    final widths = [122.0 + seed.nextInt(16), 126.0];
    var x = 0.0;
    for (var wing = 0; wing < 2; wing++) {
      final w = widths[wing], h = 215.0 + seed.nextInt(29);
      final warm = city == 1;
      final wall = (warm
          ? [
              const Color(0xFFD5B58D),
              const Color(0xFFE0C6A0),
              const Color(0xFFC9A489),
            ]
          : [
              const Color(0xFFE7E2D4),
              const Color(0xFFD8D4C6),
              const Color(0xFFE4D8C3),
            ])[(address + wing) % 3];
      final trim = _tint(wall, .28),
          accent = city == 2
              ? const Color(0xFF3C7A87)
              : const Color(0xFF526450);
      c.save();
      c.translate(x, wing == 1 ? -10 : 0);
      _volume(c, w, h, wall);
      for (var y = -h + 14; y < -6; y += 15) {
        _line(c, Offset(0, y), Offset(w, y), _tint(wall, -.12), .55);
      }
      for (final y in [-h + 20, -h + 85]) {
        for (final wx in [w * .26 - 11, w * .74 - 11]) {
          _window(
            c,
            Rect.fromLTWH(wx, y, 22, 43),
            trim,
            shutters: warm || address.isOdd,
            accent: accent,
            arched: city == 2 && address % 3 == 1,
          );
        }
        if (!warm || (address + wing).isEven) {
          _rail(c, 14, y + 34, w - 28);
        }
        _course(c, 0, y + 51, w, trim, height: 3);
      }
      _course(c, 0, -h - 6, w, trim, height: 8);
      if (warm) {
        _shape(c, [
          Offset(-4, -h - 7),
          Offset(w + 4, -h - 7),
          Offset(w + 27, -h - 44),
          Offset(20, -h - 44),
        ], const Color(0xFFA46F54));
        for (var tx = 1.0; tx < w; tx += 7) {
          _line(
            c,
            Offset(tx, -h - 9),
            Offset(tx + 24, -h - 42),
            const Color(0xFFD29A70),
            1,
          );
        }
      } else {
        _course(c, 0, -h - 16, w, trim, height: 5);
        for (var tx = 4.0; tx < w; tx += 11) {
          _box(c, Rect.fromLTWH(tx, -h - 28, 5, 12), trim, edge: .4);
        }
        _course(c, 0, -h - 30, w, trim, height: 4);
      }
      // Full-height timber shopfronts, recessed doors and striped canvas awnings.
      final doorX = (address + wing).isEven ? 13.0 : w - 42;
      _arch(
        c,
        Rect.fromLTWH(doorX, -65, 29, 65),
        trim,
        inside: const Color(0xFF5F6856),
        trim: 4,
      );
      _line(c, Offset(doorX + 15, -46), Offset(doorX + 15, -3), trim, 1.2);
      final shopX = doorX < w / 2 ? 51.0 : 10.0;
      _box(c, Rect.fromLTWH(shopX, -55, 53, 54), accent, edge: 1);
      _window(c, Rect.fromLTWH(shopX + 5, -49, 42, 42), _tint(accent, .3));
      for (var stripe = 0; stripe < 8; stripe++) {
        _shape(
          c,
          [
            Offset(shopX - 4 + stripe * 8, -64),
            Offset(shopX + 4 + stripe * 8, -64),
            Offset(shopX + 9 + stripe * 8, -50),
            Offset(shopX + 1 + stripe * 8, -50),
          ],
          stripe.isEven ? trim : accent,
          edge: .3,
        );
      }
      _text(
        c,
        warm
            ? ['FORNO', 'BOTTEGA', 'LIBRERIA'][(address + wing) % 3]
            : ['CAFE', 'LIBRAIRIE', 'ATELIER'][(address + wing) % 3],
        Offset(shopX + 26, -78),
        6.4,
        _shadow,
      );
      _lamp(c, Offset(doorX - 6, -52));
      CityArchitecture.planter(c, Offset(w - 8, 4), false, address + wing);
      c.restore();
      x += w + 4;
    }
  }

  static void _machiyaStreet(Canvas c, int address) {
    final widths = address.isEven ? [143.0, 118.0] : [109.0, 151.0];
    var x = 0.0;
    for (var wing = 0; wing < 2; wing++) {
      final w = widths[wing], h = 165.0 + (address + wing) % 3 * 14;
      final timber = (address + wing).isEven
          ? const Color(0xFF66564A)
          : const Color(0xFF594D46);
      final plaster = (address + wing) % 3 == 0
          ? const Color(0xFFD3C6A8)
          : const Color(0xFFB5A58D);
      c.save();
      c.translate(x, wing == 1 ? -7 : 0);
      _volume(c, w, h, timber);
      _box(c, Rect.fromLTWH(3, -h + 5, w - 6, 66), plaster, edge: .4);
      _box(
        c,
        Rect.fromLTWH(7, -h + 15, w - 14, 46),
        const Color(0xFF3D3D38),
        edge: .6,
      );
      // Sudare bamboo blinds and closely spaced wooden lattices, as on Gion's machiya.
      for (var tx = 9.0; tx < w - 8; tx += 3.5) {
        _line(
          c,
          Offset(tx, -h + 16),
          Offset(tx, -h + 60),
          _tint(timber, .2),
          .85,
        );
      }
      if ((address + wing).isEven) {
        _box(
          c,
          Rect.fromLTWH(7, -h + 11, w - 14, 32),
          const Color(0xFF988A6E),
          edge: .5,
        );
        for (var y = -h + 14; y < -h + 42; y += 2.5) {
          _line(c, Offset(8, y), Offset(w - 8, y), const Color(0xFFC0AE88), .6);
        }
        for (final tx in [w * .25, w * .73]) {
          _line(
            c,
            Offset(tx, -h + 11),
            Offset(tx, -h + 44),
            const Color(0xFF695C46),
            1.2,
          );
        }
      }
      _box(
        c,
        Rect.fromLTWH(8, -80, w - 16, 79),
        const Color(0xFF414540),
        edge: .7,
      );
      final doorX = w * .6;
      for (var tx = 10.0; tx < w - 7; tx += 5) {
        _line(c, Offset(tx, -78), Offset(tx, -3), _tint(timber, .13), 1.6);
      }
      _line(c, const Offset(8, -30), Offset(w - 8, -30), timber, 3);
      _box(c, Rect.fromLTWH(doorX, -77, 30, 76), timber, edge: 1);
      for (var tx = doorX + 4; tx < doorX + 29; tx += 4) {
        _line(c, Offset(tx, -72), Offset(tx, -4), const Color(0xFFAD9370), .7);
      }
      for (final y in [-h - 1, -92.0]) {
        final roof = const Color(0xFF56646C);
        _shape(c, [
          Offset(-6, y - 19),
          Offset(w + 1, y - 19),
          Offset(w + 15, y + 1),
          Offset(-12, y + 1),
        ], roof);
        _shape(c, [
          Offset(-6, y - 19),
          Offset(w + 1, y - 19),
          Offset(w + 27, y - 50),
          Offset(18, y - 50),
        ], _tint(roof, .13));
        for (var tx = -6.0; tx < w + 7; tx += 6) {
          _line(
            c,
            Offset(tx, y - 17),
            Offset(tx + 6, y - 1),
            _tint(roof, .3),
            1,
          );
        }
        _line(
          c,
          Offset(-11, y + 2),
          Offset(w + 15, y + 2),
          const Color(0xFF313D40),
          3,
        );
      }
      for (final tx in [2.0, w - 3]) {
        _box(c, Rect.fromLTWH(tx, -h, 4, h), _tint(timber, .1), edge: .4);
      }
      // Noren curtain, warm lantern and raised stone threshold.
      for (var panel = 0; panel < 3; panel++) {
        _box(
          c,
          Rect.fromLTWH(doorX - 3 + panel * 12, -76, 11, 29),
          address.isEven ? const Color(0xFF526C79) : const Color(0xFFAB785E),
          edge: .3,
        );
      }
      _text(
        c,
        wing == 0 ? 'TEA' : 'CRAFT',
        Offset(doorX + 14, -68),
        5.2,
        const Color(0xFFE8DDCB),
      );
      _box(
        c,
        Rect.fromLTWH(doorX - 4, 0, 41, 5),
        const Color(0xFFABA998),
        edge: .6,
      );
      final lantern = Offset(doorX - 13, -66);
      c.drawOval(
        Rect.fromCenter(center: lantern, width: 12, height: 21),
        Paint()..color = const Color(0xFFEAC086),
      );
      for (var y = -73.0; y < -56; y += 4) {
        _line(
          c,
          Offset(doorX - 18, y),
          Offset(doorX - 8, y),
          const Color(0xFFBE8A60),
          .7,
        );
      }
      _line(
        c,
        lantern + const Offset(0, -11),
        lantern + const Offset(0, -20),
        _shadow,
        1.4,
      );
      CityArchitecture.planter(c, Offset(9, 5), false, address + wing);
      c.restore();
      x += w + 3;
    }
  }
}

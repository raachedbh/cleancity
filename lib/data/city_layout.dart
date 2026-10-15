import 'dart:math';
import 'dart:ui';

enum StreetSurface { asphalt, stone, granite, cobble, gravel }

enum BuildingKind { townhouse, apartment, cafe, market, villa, civic, workshop }

class CityBuilding {
  const CityBuilding(this.kind, this.height, this.variant);
  final BuildingKind kind;
  final double height;
  final int variant;
}

enum TreeKind {
  oak,
  cypress,
  lemon,
  ficus,
  palm,
  plane,
  cherry,
  willow,
  pine,
  bare,
}

class CityStreet {
  const CityStreet(
    this.points,
    this.width,
    this.surface, {
    this.marked = false,
  });
  final List<Offset> points;
  final double width;
  final StreetSurface surface;
  final bool marked;

  double distanceTo(Offset point) {
    var nearest = double.infinity;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], delta = points[i] - a;
      if (delta.distanceSquared == 0) continue;
      final t =
          (((point - a).dx * delta.dx + (point - a).dy * delta.dy) /
                  delta.distanceSquared)
              .clamp(0.0, 1.0);
      nearest = min(nearest, (point - a - delta * t).distance);
    }
    return nearest;
  }

  /// Filled round caps and joins, shared by paving, curbs and surface textures.
  Path footprint({double extraWidth = 0}) {
    final radius = (width + extraWidth) / 2;
    var result = Path();
    void merge(Path shape) {
      result = Path.combine(PathOperation.union, result, shape);
    }

    for (final p in points) {
      merge(Path()..addOval(Rect.fromCircle(center: p, radius: radius)));
    }
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i], delta = b - a;
      if (delta.distance < .001) continue;
      final n = Offset(-delta.dy, delta.dx) / delta.distance * radius;
      merge(Path()..addPolygon([a + n, b + n, b - n, a - n], true));
    }
    return result;
  }
}

class CityTree {
  const CityTree(this.position, this.kind, {this.scale = 1, this.seed = 0});
  final Offset position;
  final TreeKind kind;
  final double scale;
  final int seed;
}

class CityProp {
  const CityProp(this.position, this.kind, this.seed);
  final Offset position;
  final int kind, seed; // 0 cafe, 1 market stall, 2 bench
}

/// Streets are reserved first; building silhouettes and footprints must stay off them.
class CityLayout {
  CityLayout._(this.id, this.columns, this.rows) {
    size = const [
      Size(2700, 1900),
      Size(3300, 2600),
      Size(4000, 2700),
      Size(4200, 3300),
      Size(4700, 3300),
      Size(5100, 3800),
    ][id];
    walkable = Rect.fromLTWH(28, 28, size.width - 56, size.height - 56);
    boundaryPoints = [
      for (final p in const [
        [
          Offset(.07, .02),
          Offset(.9, .02),
          Offset(.98, .15),
          Offset(.98, .87),
          Offset(.9, .98),
          Offset(.09, .98),
          Offset(.02, .9),
          Offset(.02, .12),
        ],
        [
          Offset(.17, .02),
          Offset(.86, .02),
          Offset(.98, .23),
          Offset(.98, .85),
          Offset(.8, .98),
          Offset(.1, .98),
          Offset(.02, .8),
          Offset(.02, .2),
        ],
        [
          Offset(.05, .02),
          Offset(.9, .02),
          Offset(.98, .15),
          Offset(.98, .78),
          Offset(.85, .98),
          Offset(.12, .98),
          Offset(.02, .84),
          Offset(.02, .12),
        ],
        [
          Offset(.05, .02),
          Offset(.95, .02),
          Offset(.98, .07),
          Offset(.98, .92),
          Offset(.93, .98),
          Offset(.08, .98),
          Offset(.02, .91),
          Offset(.02, .07),
        ],
        [
          Offset(.17, .02),
          Offset(.8, .02),
          Offset(.98, .15),
          Offset(.98, .85),
          Offset(.81, .98),
          Offset(.14, .98),
          Offset(.02, .86),
          Offset(.02, .14),
        ],
        [
          Offset(.2, .02),
          Offset(.7, .02),
          Offset(.96, .18),
          Offset(.98, .71),
          Offset(.8, .98),
          Offset(.2, .96),
          Offset(.03, .72),
          Offset(.02, .26),
        ],
      ][id])
        at(p.dx, p.dy),
    ];
    switch (id) {
      case 0:
        _willow();
      case 1:
        _lucca();
      case 2:
        _tunis();
      case 3:
        _paris();
      case 4:
        _kyoto();
      default:
        _midnight();
    }
    final candidates = [stationAnchor, ...stationSites];
    for (final candidate in candidates) {
      final p = safe(candidate, clearance: 95, offRoad: true);
      stations.add(p);
      stationObstacles.add(
        Rect.fromCenter(
          center: p + const Offset(0, -12),
          width: 142,
          height: 40,
        ),
      );
    }
    _placePolice();
    obstacles = List.unmodifiable([
      ...blocks,
      ...planters,
      ...waterObstacles,
      ...stationObstacles,
      ...sceneObstacles,
    ]);
    start = safe(stations.first + const Offset(0, 80), clearance: 20);
    reviewPoint = safe(reviewAnchor, clearance: 24);
    // Small planted clusters mark corners; no repeated tree ring around every city.
    for (var edge = 0; edge < boundaryPoints.length; edge++) {
      final a = boundaryPoints[edge],
          b = boundaryPoints[(edge + 1) % boundaryPoints.length];
      for (var t = .12; t < 1; t += .26) {
        final p = Offset.lerp(a, b, t)!;
        trees.add(
          CityTree(
            p,
            treeKind(edge),
            scale: .75,
            seed: edge * 81 + (t * 100).round(),
          ),
        );
      }
    }
  }
  static final Map<int, CityLayout> _cache = {};
  static CityLayout forCity(int id, int columns, int rows) =>
      _cache.putIfAbsent(id, () => CityLayout._(id, columns, rows));
  final int id, columns, rows;
  late final Size size;
  late final Rect walkable;
  late final List<Offset> boundaryPoints;
  late final List<Rect> obstacles;
  late Offset start, reviewPoint, stationAnchor, reviewAnchor;
  late Offset police, policeEntrance;
  Rect get policeBounds => Rect.fromLTRB(
    police.dx - 88,
    police.dy - 108,
    police.dx + 88,
    police.dy + 18,
  );
  void _placePolice() {
    final anchor = stations.first;
    Offset? chosen;
    var best = double.infinity;
    for (var y = 180.0; y < size.height - 100; y += 50) {
      for (var x = 130.0; x < size.width - 130; x += 50) {
        final p = Offset(x, y);
        final bounds = Rect.fromLTRB(x - 98, y - 118, x + 98, y + 95);
        if (!contains(bounds.topLeft, clearance: 25) ||
            !contains(bounds.bottomRight, clearance: 25) ||
            roadHits(bounds, setback: 28)) {
          continue;
        }
        if ([
          ...blocks,
          ...buildingEnvelopes.values,
          ...planters,
          ...waterObstacles,
          ...stationObstacles,
          ...sceneObstacles,
        ].any((r) => r.inflate(25).overlaps(bounds))) {
          continue;
        }
        if (stations.any((s) => (s - p).distance < 240)) continue;
        final roadDistance = streets
            .map((r) => r.distanceTo(p) - r.width / 2)
            .reduce(min);
        if (roadDistance > 300) continue;
        final score = (p - anchor).distance + roadDistance * 2;
        if (score < best) {
          best = score;
          chosen = p;
        }
      }
    }
    if (chosen == null) throw StateError('No police lot in city $id');
    police = chosen;
    policeEntrance = chosen + const Offset(0, 65);
    sceneObstacles.add(
      Rect.fromCenter(
        center: chosen + const Offset(0, -18),
        width: 170,
        height: 60,
      ),
    );
    trees.removeWhere((t) => policeBounds.inflate(65).contains(t.position));
    props.removeWhere((p) => policeBounds.inflate(80).contains(p.position));
  }

  Offset? interviewAnchor;
  List<Offset> get interviewSpots => interviewAnchor == null
      ? []
      : [
          interviewAnchor!,
          interviewAnchor! + const Offset(70, 0),
          interviewAnchor! + const Offset(-76, 30),
        ];
  int landmark = 0;
  final List<Offset> stations = [], stationSites = [];
  final List<Rect> blocks = [],
      planters = [],
      waterObstacles = [],
      stationObstacles = [],
      sceneObstacles = [],
      parks = [];
  final Map<int, List<Offset>> footprints = {};
  final Map<int, CityBuilding> buildings = {};
  final Map<int, Rect> buildingEnvelopes = {};
  final List<CityStreet> streets = [];
  final List<CityTree> trees = [];
  final List<CityProp> props = [];
  final List<Offset> lamps = [];
  final Set<int> gardenLots = {};
  Rect? plaza, garden, canal;
  bool ovalPlaza = false;
  final List<double> bridges = [];
  Offset get center => Offset(size.width / 2, size.height / 2);
  Offset at(double x, double y) => Offset(size.width * x, size.height * y);
  Path get boundary => Path()..addPolygon(boundaryPoints, true);
  Path get plazaPath => ovalPlaza
      ? (Path()..addOval(plaza!))
      : (Path()..addRRect(
          RRect.fromRectAndRadius(plaza!, Radius.circular(id == 2 ? 95 : 24)),
        ));
  bool contains(Offset p, {double clearance = 12}) {
    // All boundary polygons are convex. Inset edge distances keep routes inside.
    for (var i = 0; i < boundaryPoints.length; i++) {
      final a = boundaryPoints[i],
          edge = boundaryPoints[(i + 1) % boundaryPoints.length] - a,
          v = p - a;
      if ((edge.dx * v.dy - edge.dy * v.dx) / edge.distance < clearance) {
        return false;
      }
    }
    return true;
  }

  static bool segmentHits(Offset a, Offset b, Rect r) {
    var lo = 0.0, hi = 1.0;
    final d = b - a;
    for (var axis = 0; axis < 2; axis++) {
      final p = axis == 0 ? a.dx : a.dy,
          v = axis == 0 ? d.dx : d.dy,
          low = axis == 0 ? r.left : r.top,
          high = axis == 0 ? r.right : r.bottom;
      if (v.abs() < .00001) {
        if (p < low || p > high) return false;
      } else {
        final t1 = (low - p) / v, t2 = (high - p) / v;
        lo = max(lo, min(t1, t2));
        hi = min(hi, max(t1, t2));
        if (lo > hi) return false;
      }
    }
    return true;
  }

  bool roadHits(Rect r, {double setback = 28}) {
    for (final s in streets) {
      final expanded = r.inflate(s.width / 2 + setback);
      for (var i = 1; i < s.points.length; i++) {
        if (segmentHits(s.points[i - 1], s.points[i], expanded)) return true;
      }
    }
    return false;
  }

  Offset safe(Offset desired, {double clearance = 20, bool offRoad = false}) {
    bool valid(Offset p) =>
        contains(p, clearance: clearance) &&
        ![
          ...blocks,
          ...planters,
          ...waterObstacles,
          ...stationObstacles,
          ...sceneObstacles,
        ].any((r) => r.inflate(clearance).contains(p)) &&
        (!offRoad ||
            !roadHits(
              Rect.fromCenter(center: p, width: 160, height: 50),
              setback: 8,
            ));
    if (valid(desired)) return desired;
    for (
      var radius = 25.0;
      radius < max(size.width, size.height);
      radius += 25
    ) {
      for (var a = 0.0; a < 2 * pi; a += pi / 16) {
        final p = desired + Offset(cos(a), sin(a)) * radius;
        if (valid(p)) return p;
      }
    }
    throw StateError('No safe spawn in city $id');
  }

  TreeKind treeKind(int i) => switch (id) {
    0 => TreeKind.oak,
    1 => i.isEven ? TreeKind.cypress : TreeKind.lemon,
    2 => i % 5 == 0 ? TreeKind.palm : TreeKind.ficus,
    3 => TreeKind.plane,
    4 => i % 3 == 0 ? TreeKind.willow : TreeKind.cherry,
    _ => i.isEven ? TreeKind.bare : TreeKind.pine,
  };
  void road(
    List<Offset> p,
    double width,
    StreetSurface surface, {
    bool marked = false,
  }) => streets.add(CityStreet(p, width, surface, marked: marked));
  void avenue(List<Offset> p, {double width = 120}) =>
      road(p, width, StreetSurface.asphalt, marked: true);
  List<Offset> oval(Offset p, double rx, double ry) => [
    for (var i = 0; i <= 96; i++)
      p + Offset(cos(i / 96 * 2 * pi) * rx, sin(i / 96 * 2 * pi) * ry),
  ];
  int lot(
    Rect b, {
    bool urban = false,
    BuildingKind kind = BuildingKind.townhouse,
    double height = 145,
    int variant = 0,
  }) {
    final index = blocks.length;
    blocks.add(b);
    if (urban) {
      footprints[index] = [b.topLeft, b.topRight, b.bottomRight, b.bottomLeft];
      buildings[index] = CityBuilding(kind, height, variant);
      buildingEnvelopes[index] = envelope(b, height);
    }
    return index;
  }

  Rect envelope(Rect b, double h) =>
      Rect.fromLTRB(b.left - 22, b.top - h - 55, b.right + 16, b.bottom + 16);
  int building(Rect b, BuildingKind kind, int variant) {
    final height = switch (kind) {
      BuildingKind.apartment => 210.0 + (variant % 3) * 18,
      BuildingKind.civic => 225.0,
      BuildingKind.market => 105.0,
      BuildingKind.cafe => 115.0,
      BuildingKind.villa => 140.0,
      BuildingKind.workshop => 105.0,
      _ => 150.0 + (variant % 3) * 12,
    };
    final shape = envelope(b, height);
    if (![
          shape.topLeft,
          shape.topRight,
          shape.bottomRight,
          shape.bottomLeft,
        ].every((p) => contains(p, clearance: 35)) ||
        roadHits(shape) ||
        buildingEnvelopes.values.any((r) => r.inflate(6).overlaps(shape)) ||
        blocks.any((r) => r.inflate(22).overlaps(b)) ||
        parks.any((r) => r.overlaps(shape)) ||
        (plaza != null && plaza!.inflate(30).overlaps(shape)) ||
        (garden != null && garden!.inflate(20).overlaps(shape)) ||
        (canal != null && canal!.inflate(50).overlaps(shape))) {
      return -1;
    }
    return lot(b, urban: true, kind: kind, height: height, variant: variant);
  }

  void row(
    double left,
    double right,
    double baseline, {
    int seed = 0,
    List<BuildingKind>? kinds,
  }) {
    final types = kinds ?? BuildingKind.values;
    var x = left, i = 0;
    while (x + 155 < right) {
      final kind = types[(i + seed) % types.length];
      final width = switch (kind) {
        BuildingKind.market || BuildingKind.civic => 290.0,
        BuildingKind.apartment => 245.0,
        BuildingKind.villa => 200.0,
        _ => 165.0 + (i % 2) * 25,
      };
      if (x + width > right) break;
      final depth = kind == BuildingKind.market
          ? 145.0
          : kind == BuildingKind.villa
          ? 155.0
          : 130.0 + (i % 3) * 12;
      building(
        Rect.fromLTWH(x, baseline - depth, width, depth),
        kind,
        seed + i,
      );
      x += width + 52;
      i++;
    }
  }

  void tree(Offset p, TreeKind kind, {double scale = .85}) {
    final ground = Rect.fromCenter(center: p, width: 30, height: 24);
    if (!contains(p, clearance: 60) ||
        roadHits(ground, setback: 12) ||
        blocks.any((b) => b.inflate(45).contains(p)) ||
        waterObstacles.any((r) => r.inflate(25).contains(p))) {
      return;
    }
    planters.add(ground);
    trees.add(CityTree(p, kind, scale: scale, seed: trees.length * 47));
  }

  void prop(Offset p, int kind) {
    final ground = Rect.fromCenter(
      center: p,
      width: kind == 1
          ? 86
          : kind == 0
          ? 52
          : 58,
      height: kind == 1 ? 38 : 24,
    );
    if (!contains(p, clearance: 50) ||
        roadHits(ground, setback: 16) ||
        [
          ...blocks,
          ...planters,
          ...waterObstacles,
        ].any((b) => b.inflate(45).overlaps(ground))) {
      return;
    }
    props.add(CityProp(p, kind, props.length));
    planters.add(ground);
  }

  void parkTrees(Rect r, {int count = 5}) {
    parks.add(r);
    for (var i = 0; i < count; i++) {
      tree(
        Offset(
          r.left + 40 + i * (r.width - 80) / max(1, count - 1),
          r.bottom - 40,
        ),
        treeKind(i),
      );
    }
  }

  void _willow() {
    avenue([
      const Offset(180, 1250),
      const Offset(920, 1250),
      const Offset(1300, 1130),
      const Offset(2430, 1130),
    ], width: 130);
    avenue([
      const Offset(420, 1250),
      const Offset(420, 340),
      const Offset(2240, 340),
      const Offset(2240, 1130),
    ], width: 100);
    avenue([const Offset(1340, 340), const Offset(1340, 1130)], width: 92);
    avenue([
      const Offset(420, 1250),
      const Offset(420, 1640),
      const Offset(2250, 1640),
      const Offset(2430, 1130),
    ], width: 98);
    garden = const Rect.fromLTWH(1670, 910, 360, 150);
    parks.add(garden!);
    landmark = lot(const Rect.fromLTWH(1790, 955, 110, 90));
    row(610, 1190, 970, seed: 0);
    row(1540, 2100, 570, seed: 3);
    row(1510, 2110, 1060, seed: 1);
    row(590, 1180, 1170, seed: 2);
    row(
      640,
      2100,
      1550,
      seed: 2,
      kinds: [BuildingKind.cafe, BuildingKind.market, BuildingKind.workshop],
    );
    // Northern cottages and workshops, with a clear rear lane below.
    row(560, 2070, 255, seed: 0, kinds: [BuildingKind.cafe]);
    for (final p in [
      const Offset(620, 560),
      const Offset(940, 570),
      const Offset(1490, 720),
      const Offset(2070, 890),
      const Offset(970, 1450),
    ]) {
      tree(p, TreeKind.oak);
    }
    prop(const Offset(1590, 990), 0);
    prop(const Offset(1770, 950), 2);
    row(
      1510,
      2120,
      850,
      seed: 0,
      kinds: [BuildingKind.villa, BuildingKind.cafe, BuildingKind.workshop],
    );
    row(
      1430,
      2150,
      1538,
      seed: 0,
      kinds: [BuildingKind.market, BuildingKind.cafe],
    );
    building(const Rect.fromLTWH(135, 770, 165, 125), BuildingKind.workshop, 3);
    building(const Rect.fromLTWH(135, 420, 165, 125), BuildingKind.cafe, 5);
    stationAnchor = const Offset(850, 1080);
    stationSites.add(const Offset(1880, 1470));
    reviewAnchor = const Offset(1250, 1290);
  }

  void _lucca() {
    final c = const Offset(1080, 1370);
    plaza = Rect.fromCenter(center: c, width: 860, height: 650);
    ovalPlaza = true;
    road(
      [
        const Offset(340, 300),
        const Offset(2890, 300),
        const Offset(2890, 2280),
        const Offset(340, 2280),
        const Offset(340, 300),
      ],
      110,
      StreetSurface.stone,
    );
    road(
      [const Offset(1910, 300), const Offset(1910, 2280)],
      110,
      StreetSurface.stone,
    );
    road(
      [const Offset(1510, 1370), const Offset(2890, 1370)],
      108,
      StreetSurface.stone,
    );
    road(
      [const Offset(340, 1370), const Offset(650, 1370)],
      98,
      StreetSurface.stone,
    );
    road(
      [const Offset(1080, 300), const Offset(1080, 1070)],
      85,
      StreetSurface.stone,
    );
    road(
      [const Offset(1080, 1670), const Offset(1080, 2280)],
      85,
      StreetSurface.stone,
    );
    landmark = lot(
      Rect.fromCenter(
        center: c + const Offset(-120, -30),
        width: 115,
        height: 90,
      ),
    );
    row(
      500,
      940,
      955,
      seed: 1,
      kinds: [BuildingKind.townhouse, BuildingKind.apartment],
    );
    row(1260, 1760, 950, seed: 2);
    row(480, 950, 2150, seed: 3);
    row(1260, 1760, 2150, seed: 4);
    row(2100, 2750, 1210, seed: 2);
    row(2090, 2740, 2130, seed: 5);
    // Independent market, civic palazzo and low cafes in the eastern quarter.
    building(const Rect.fromLTWH(2090, 760, 320, 160), BuildingKind.market, 8);
    for (var i = 0; i < 5; i++) {
      prop(Offset(780 + i * 135.0, 1610), 0);
    }
    tree(const Offset(700, 1100), TreeKind.lemon);
    tree(const Offset(1450, 1130), TreeKind.cypress);
    parkTrees(const Rect.fromLTWH(2410, 1520, 310, 220), count: 3);
    building(const Rect.fromLTWH(450, 1140, 135, 120), BuildingKind.cafe, 1);
    building(const Rect.fromLTWH(450, 1640, 135, 120), BuildingKind.cafe, 3);
    building(
      const Rect.fromLTWH(1610, 1845, 165, 135),
      BuildingKind.townhouse,
      4,
    );
    stationAnchor = c + const Offset(-170, 160);
    stationSites.addAll([const Offset(2470, 1240), const Offset(1590, 1860)]);
    reviewAnchor = c + const Offset(160, 30);
  }

  void _tunis() {
    final c = const Offset(2900, 1390);
    avenue(oval(c, 360, 255), width: 140);
    avenue([const Offset(400, 1135), Offset(c.dx, 1135)], width: 140);
    avenue([const Offset(400, 1645), Offset(c.dx, 1645)], width: 140);
    avenue([
      const Offset(400, 350),
      const Offset(400, 2410),
      const Offset(3340, 2410),
    ], width: 112);
    avenue([const Offset(400, 350), const Offset(3240, 350)], width: 102);
    for (final x in [1480.0, 2100.0]) {
      avenue([Offset(x, 350), Offset(x, 1135)], width: 92);
    }
    avenue([const Offset(1480, 1645), const Offset(1480, 2410)], width: 92);
    avenue([
      c + const Offset(335, -95),
      const Offset(3650, 950),
      const Offset(3610, 490),
    ], width: 120);
    avenue([
      c + const Offset(315, 124),
      const Offset(3600, 2030),
      const Offset(3340, 2410),
    ], width: 126);
    plaza = const Rect.fromLTWH(560, 1270, 1880, 240);
    landmark = lot(Rect.fromCenter(center: c, width: 340, height: 230));
    row(610, 1320, 995, seed: 4);
    row(1640, 1940, 995, seed: 1);
    row(2250, 2750, 995, seed: 5);
    row(610, 1320, 2250, seed: 2);
    row(1640, 2780, 2250, seed: 3);
    row(2990, 3320, 850, seed: 0);
    row(3000, 3280, 2220, seed: 6);
    for (var x = 680.0; x < 2500; x += 205) {
      tree(Offset(x, 1290), TreeKind.ficus, scale: .82);
      if (x < 2300) {
        tree(Offset(x, 1490), TreeKind.ficus, scale: .82);
        lamps.add(Offset(x + 82, 1500));
      }
    }
    // Two regular rows along the edges, with a clear central walking lane.
    // Leave the station and the interview area open.
    for (var x = 985.0; x <= 2220; x += 205) {
      prop(Offset(x, 1325), 2);
      prop(Offset(x, 1460), 2);
    }
    interviewAnchor = const Offset(2340, 1390);
    for (final p in interviewSpots) {
      sceneObstacles.add(Rect.fromCenter(center: p, width: 30, height: 24));
    }
    parkTrees(const Rect.fromLTWH(1750, 1770, 330, 130), count: 3);
    prop(const Offset(1120, 1780), 1);
    stationAnchor = const Offset(760, 1390);
    stationSites.addAll([const Offset(2300, 1830), const Offset(3180, 1120)]);
    reviewAnchor = c + const Offset(-110, 160);
  }

  void _paris() {
    final r = const Rect.fromLTRB(1120, 1030, 3050, 2350);
    avenue([
      r.topLeft,
      r.topRight,
      r.bottomRight,
      r.bottomLeft,
      r.topLeft,
    ], width: 138);
    avenue([const Offset(450, 300), const Offset(3750, 300)], width: 140);
    avenue([
      const Offset(450, 300),
      const Offset(450, 2700),
      const Offset(1120, 2350),
    ], width: 120);
    avenue([
      const Offset(3750, 300),
      const Offset(3750, 2760),
      const Offset(3050, 2350),
    ], width: 116);
    avenue([const Offset(2090, 300), const Offset(2090, 1030)], width: 110);
    avenue([const Offset(2090, 2350), const Offset(2090, 3030)], width: 106);
    garden = const Rect.fromLTWH(1320, 1220, 1510, 940);
    final c = garden!.center;
    landmark = lot(Rect.fromCenter(center: c, width: 170, height: 120));
    for (final p in [
      [Offset(1360, c.dy), c - const Offset(170, 0)],
      [c + const Offset(170, 0), Offset(2790, c.dy)],
      [Offset(c.dx, 1240), c - const Offset(0, 150)],
      [c + const Offset(0, 150), Offset(c.dx, 2120)],
    ]) {
      road(p, 66, StreetSurface.gravel);
    }
    row(670, 1930, 870, seed: 3);
    row(2250, 3530, 870, seed: 4);
    row(620, 940, 1640, seed: 3);
    row(620, 940, 2210, seed: 0);
    row(3230, 3550, 1640, seed: 5);
    row(3230, 3550, 2210, seed: 6);
    row(1260, 1900, 3020, seed: 1);
    row(2270, 2930, 3020, seed: 2);
    for (final x in [1430.0, 1790.0, 2360.0, 2700.0]) {
      for (final y in [1340.0, 2070.0]) {
        tree(Offset(x, y), TreeKind.plane, scale: .9);
      }
    }
    for (final p in [
      const Offset(1570, 1440),
      const Offset(2420, 1440),
      const Offset(1570, 1880),
      const Offset(2420, 1880),
    ]) {
      gardenLots.add(lot(Rect.fromCenter(center: p, width: 220, height: 115)));
    }
    for (final p in [const Offset(1780, 1760), const Offset(2320, 1760)]) {
      prop(p, 2);
    }
    stationAnchor = const Offset(1540, 1790);
    stationSites.addAll([const Offset(2770, 2240), const Offset(900, 980)]);
    reviewAnchor = c + const Offset(-170, 140);
  }

  void _kyoto() {
    canal = const Rect.fromLTWH(2320, 160, 190, 2960);
    bridges.addAll([440, 1000, 1560, 2120, 2680]);
    var y = canal!.top;
    for (final bridge in bridges) {
      if (bridge - 68 > y) {
        waterObstacles.add(
          Rect.fromLTRB(canal!.left - 8, y, canal!.right + 8, bridge - 68),
        );
      }
      y = bridge + 68;
    }
    if (y < canal!.bottom) {
      waterObstacles.add(
        Rect.fromLTRB(canal!.left - 8, y, canal!.right + 8, canal!.bottom),
      );
    }
    for (final x in [1640.0, 2160.0, 2690.0, 3280.0]) {
      road(
        [Offset(x, 330), Offset(x, 2970)],
        x == 1640 || x == 3280 ? 104 : 86,
        StreetSurface.stone,
      );
    }
    for (final bridge in bridges) {
      road(
        [Offset(1640, bridge), Offset(3280, bridge)],
        108,
        StreetSurface.stone,
      );
    }
    for (final yy in [1030.0, 1850.0, 2740.0]) {
      road([Offset(450, yy), Offset(1640, yy)], 100, StreetSurface.gravel);
    }
    for (final yy in [810.0, 1830.0, 2820.0]) {
      road([Offset(3280, yy), Offset(4250, yy)], 98, StreetSurface.stone);
    }
    garden = const Rect.fromLTWH(3650, 1110, 510, 470);
    landmark = lot(const Rect.fromLTWH(3850, 1370, 150, 100));
    for (var i = 0; i < bridges.length; i++) {
      final base = bridges[i] + 445;
      row(
        1790,
        2010,
        base,
        seed: i,
        kinds: [BuildingKind.cafe, BuildingKind.townhouse],
      );
      row(
        2840,
        3130,
        base,
        seed: i + 3,
        kinds: [BuildingKind.workshop, BuildingKind.villa],
      );
    }
    for (var i = 0; i < 3; i++) {
      row(580, 1460, 860 + i * 830.0, seed: i + 2);
    }
    row(3450, 4170, 650, seed: 2);
    row(3450, 4170, 1710, seed: 0);
    row(3450, 4170, 2680, seed: 4);
    for (var i = 0; i < 5; i++) {
      final yy = 690 + i * 560.0;
      trees.add(
        CityTree(
          Offset(i.isEven ? 2332 : 2495, yy),
          TreeKind.willow,
          scale: .9,
          seed: i,
        ),
      );
      lamps.add(Offset(2250, yy + 120));
    }
    for (final p in [
      const Offset(3590, 1270),
      const Offset(4190, 1510),
      const Offset(1420, 1240),
      const Offset(1230, 2060),
    ]) {
      tree(p, TreeKind.cherry);
    }
    prop(const Offset(3550, 2300), 1);
    stationAnchor = const Offset(2060, 1240);
    stationSites.addAll([const Offset(2870, 2290), const Offset(950, 1680)]);
    reviewAnchor = const Offset(2650, 1660);
  }

  void _midnight() {
    road(
      [
        const Offset(580, 2900),
        const Offset(1270, 2900),
        const Offset(1870, 2490),
        const Offset(2600, 2520),
        const Offset(3220, 2070),
        const Offset(3720, 1510),
        const Offset(4340, 1000),
      ],
      130,
      StreetSurface.cobble,
    );
    road(
      [
        const Offset(1870, 2490),
        const Offset(1560, 1860),
        const Offset(1030, 1420),
        const Offset(1050, 780),
        const Offset(2020, 550),
        const Offset(3060, 800),
        const Offset(3720, 1510),
      ],
      110,
      StreetSurface.cobble,
    );
    road(
      [
        const Offset(2600, 2520),
        const Offset(2910, 3220),
        const Offset(4020, 3070),
        const Offset(4340, 2330),
        const Offset(3720, 1510),
      ],
      104,
      StreetSurface.cobble,
    );
    road(
      [const Offset(2900, 1700), const Offset(3500, 1756)],
      90,
      StreetSurface.cobble,
    );
    plaza = const Rect.fromLTWH(2190, 1370, 740, 620);
    landmark = lot(const Rect.fromLTWH(2480, 1660, 145, 110));
    row(1250, 2960, 1220, seed: 0);
    row(460, 920, 1320, seed: 5);
    row(600, 1330, 2480, seed: 6);
    row(1770, 2990, 2350, seed: 2);
    row(930, 2190, 3350, seed: 3);
    row(3300, 4070, 2800, seed: 5);
    row(4010, 4540, 1840, seed: 1);
    gardenLots.add(lot(const Rect.fromLTWH(630, 1770, 510, 360)));
    for (final p in [
      const Offset(1390, 1570),
      const Offset(2980, 1470),
      const Offset(3130, 2770),
      const Offset(3550, 3190),
      const Offset(1840, 3350),
      const Offset(1300, 2120),
    ]) {
      tree(p, treeKind(trees.length));
    }
    for (final p in [
      const Offset(2320, 1530),
      const Offset(2800, 1530),
      const Offset(2320, 1910),
      const Offset(2800, 1910),
    ]) {
      lamps.add(p);
    }
    prop(const Offset(2240, 1810), 1);
    stationAnchor = const Offset(2470, 1990);
    stationSites.addAll([const Offset(3300, 2420), const Offset(1310, 2610)]);
    reviewAnchor = const Offset(2690, 1840);
  }
}

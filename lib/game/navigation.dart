import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';

/// Visibility graph shared by pedestrians and station routes in a district.
/// Vertices are outside inflated obstacles, so the entire route has foot clearance.
class CityNavigation {
  CityNavigation(this.district) {
    obstacles = district.obstacles.map((r) => r.inflate(14)).toList();
    nodes = [
      for (final r in obstacles) ...[
        r.inflate(2).topLeft,
        r.inflate(2).topRight,
        r.inflate(2).bottomLeft,
        r.inflate(2).bottomRight,
      ],
    ].where((p) => district.canStand(p, clearance: 13)).toList();
    edges = List.generate(nodes.length, (_) => <(int, double)>[]);
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        if (visible(nodes[i], nodes[j])) {
          final d = (nodes[i] - nodes[j]).distance;
          edges[i].add((j, d));
          edges[j].add((i, d));
        }
      }
    }
  }
  final District district;
  late final List<Rect> obstacles;
  late final List<Offset> nodes;
  late final List<List<(int, double)>> edges;
  bool visible(Offset a, Offset b) =>
      district.layout.contains(a, clearance: 12) &&
      district.layout.contains(b, clearance: 12) &&
      !obstacles.any((r) => segmentHitsRect(a, b, r));
  Offset nearestWalkable(Offset p) {
    final b = district.walkable.deflate(18);
    var goal = Offset(p.dx.clamp(b.left, b.right), p.dy.clamp(b.top, b.bottom));
    if (!district.layout.contains(goal, clearance: 16)) {
      goal = district.layout.safe(goal, clearance: 16);
    }
    for (var retry = 0; retry < 4; retry++) {
      final blocking = obstacles.where((r) => r.contains(goal));
      if (blocking.isEmpty) return goal;
      final r = blocking.first.inflate(2);
      final options =
          [
            Offset(r.left, goal.dy),
            Offset(r.right, goal.dy),
            Offset(goal.dx, r.top),
            Offset(goal.dx, r.bottom),
          ].where((p) => district.canStand(p, clearance: 13)).toList()..sort(
            (a, b) => (a - goal).distance.compareTo((b - goal).distance),
          );
      if (options.isEmpty) return district.start;
      goal = options.first;
    }
    return district.start;
  }

  List<Offset> route(
    Offset start,
    Offset destination, {
    Rect? temporaryObstacle,
  }) {
    var goal = nearestWalkable(destination);
    final extra = <Offset>[];
    if (temporaryObstacle case final obstacle?) {
      final r = obstacle.inflate(3);
      extra.addAll(
        [
          r.topLeft,
          r.topRight,
          r.bottomLeft,
          r.bottomRight,
        ].where((p) => district.canStand(p, clearance: 13)),
      );
      if (obstacle.contains(goal)) {
        final exits =
            [
              ...extra,
              Offset(r.left, goal.dy),
              Offset(r.right, goal.dy),
              Offset(goal.dx, r.top),
              Offset(goal.dx, r.bottom),
            ].where((p) => district.canStand(p, clearance: 13)).toList()..sort(
              (a, b) => (a - goal).distanceSquared.compareTo(
                (b - goal).distanceSquared,
              ),
            );
        if (exits.isEmpty) return [];
        goal = exits.first;
      }
    }
    bool clear(Offset a, Offset b) {
      if (!visible(a, b)) return false;
      final obstacle = temporaryObstacle;
      if (obstacle == null || !segmentHitsRect(a, b, obstacle)) return true;
      // An NPC touching a truck can leave the conservative square detour
      // boundary, but may not cross toward its center.
      final other = a == start
          ? b
          : b == start
          ? a
          : null;
      if (other == null ||
          !obstacle.contains(start) ||
          obstacle.contains(other)) {
        return false;
      }
      final away = start - obstacle.center, movement = other - start;
      return away.dx * movement.dx + away.dy * movement.dy > 0;
    }

    if (clear(start, goal)) return [goal];
    final points = [...nodes, ...extra, start, goal];
    final startId = points.length - 2, goalId = points.length - 1;
    final graph = [
      for (var i = 0; i < edges.length; i++)
        [
          for (final e in edges[i])
            if (temporaryObstacle == null ||
                !segmentHitsRect(nodes[i], nodes[e.$1], temporaryObstacle))
              e,
        ],
      for (final _ in extra) <(int, double)>[],
      <(int, double)>[],
      <(int, double)>[],
    ];
    for (var i = nodes.length; i < points.length; i++) {
      for (var j = 0; j < i; j++) {
        if (!clear(points[i], points[j])) continue;
        final d = (points[i] - points[j]).distance;
        graph[i].add((j, d));
        graph[j].add((i, d));
      }
    }
    final distances = List.filled(points.length, double.infinity)
      ..[startId] = 0;
    final previous = List.filled(points.length, -1), visited = <int>{};
    for (var count = 0; count < points.length; count++) {
      var current = -1;
      for (var i = 0; i < points.length; i++) {
        if (!visited.contains(i) &&
            (current == -1 || distances[i] < distances[current])) {
          current = i;
        }
      }
      if (current < 0 || distances[current].isInfinite || current == goalId) {
        break;
      }
      visited.add(current);
      for (final (next, distance) in graph[current]) {
        final candidate = distances[current] + distance;
        if (candidate < distances[next]) {
          distances[next] = candidate;
          previous[next] = current;
        }
      }
    }
    if (distances[goalId].isInfinite) return [];
    final path = <Offset>[];
    for (var at = goalId; at != startId; at = previous[at]) {
      path.add(points[at]);
    }
    return path.reversed.toList();
  }
}

bool segmentHitsRect(Offset a, Offset b, Rect r) {
  var low = 0.0, high = 1.0;
  final delta = b - a;
  for (var axis = 0; axis < 2; axis++) {
    final p = axis == 0 ? a.dx : a.dy, d = axis == 0 ? delta.dx : delta.dy;
    final lo = axis == 0 ? r.left : r.top, hi = axis == 0 ? r.right : r.bottom;
    if (d.abs() < .00001) {
      if (p < lo || p > hi) return false;
    } else {
      final t1 = (lo - p) / d, t2 = (hi - p) / d;
      low = max(low, min(t1, t2));
      high = min(high, max(t1, t2));
      if (low > high) return false;
    }
  }
  return low <= high;
}

// Retained for the focused station-route tests.
List<Offset> routeAround(Offset start, Offset destination, Rect obstacle) {
  final safe = obstacle.inflate(8);
  var goal = destination;
  if (safe.contains(goal)) {
    final options = [
      Offset(safe.left - 2, goal.dy),
      Offset(safe.right + 2, goal.dy),
      Offset(goal.dx, safe.top - 2),
      Offset(goal.dx, safe.bottom + 2),
    ]..sort((a, b) => (a - goal).distance.compareTo((b - goal).distance));
    goal = options.first;
  }
  bool visible(Offset a, Offset b) =>
      !segmentHitsRect(a, b, obstacle.inflate(3));
  if (visible(start, goal)) return [goal];
  final nodes = [
    start,
    goal,
    safe.topLeft,
    safe.topRight,
    safe.bottomLeft,
    safe.bottomRight,
  ];
  final dist = List.filled(6, double.infinity)..[0] = 0;
  final prev = List.filled(6, -1), visited = <int>{};
  for (var count = 0; count < 6; count++) {
    var current = -1;
    for (var i = 0; i < 6; i++) {
      if (!visited.contains(i) && (current < 0 || dist[i] < dist[current])) {
        current = i;
      }
    }
    if (current < 0 || current == 1 || dist[current].isInfinite) break;
    visited.add(current);
    for (var i = 0; i < 6; i++) {
      if (i == current || !visible(nodes[current], nodes[i])) continue;
      final d = dist[current] + (nodes[current] - nodes[i]).distance;
      if (d < dist[i]) {
        dist[i] = d;
        prev[i] = current;
      }
    }
  }
  if (dist[1].isInfinite) return [];
  final result = <Offset>[];
  for (var i = 1; i > 0; i = prev[i]) {
    result.add(nodes[i]);
  }
  return result.reversed.toList();
}

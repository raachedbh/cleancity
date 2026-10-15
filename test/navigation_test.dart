import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/game/navigation.dart';

void main() {
  const station = Rect.fromLTRB(730, 760, 860, 798);
  test('returning from below routes around the bins without getting stuck', () {
    const start = Offset(795, 875), goal = Offset(795, 725);
    final route = routeAround(start, goal, station);
    expect(route.length, greaterThan(1));
    expect(route.last, goal);
    var from = start;
    for (final to in route) {
      for (var step = 0; step <= 100; step++) {
        expect(station.contains(Offset.lerp(from, to, step / 100)!), isFalse);
      }
      from = to;
    }
  });
  test('clear destinations keep a direct path', () {
    expect(
      routeAround(const Offset(400, 600), const Offset(900, 600), station),
      [const Offset(900, 600)],
    );
  });
  test('tapping the station ends beside it, never inside it', () {
    final route = routeAround(const Offset(700, 700), station.center, station);
    expect(route, isNotEmpty);
    expect(station.contains(route.last), isFalse);
  });
}

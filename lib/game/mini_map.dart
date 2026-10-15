import 'dart:math';
import 'dart:ui';
import '../data/catalog.dart';

/// Preserve city proportions and group nearby litter into readable dots.
class MiniMapProjection {
  MiniMapProjection(Size world, Size panel)
    : scale = min(panel.width / world.width, panel.height / world.height) {
    offset = Offset(
      (panel.width - world.width * scale) / 2,
      (panel.height - world.height * scale) / 2,
    );
    bounds = offset & Size(world.width * scale, world.height * scale);
  }
  final double scale;
  late final Offset offset;
  late final Rect bounds;
  Offset point(Offset p) => offset + p * scale;
  Rect rect(Rect r) => Rect.fromPoints(point(r.topLeft), point(r.bottomRight));

  List<({Offset point, bool truck})> litterMarkers(Iterable<Litter> litter) {
    final cells = <(int, int), ({Offset point, bool truck})>{};
    for (final item in litter) {
      final p = point(item.position);
      if (!bounds.inflate(.01).contains(p)) continue;
      final cell = ((p.dx / 3).floor(), (p.dy / 3).floor());
      // Truck reward dots take priority when several pieces share a cell.
      if (!cells.containsKey(cell) || item.truckDroppedAt != null) {
        cells[cell] = (point: p, truck: item.truckDroppedAt != null);
      }
    }
    return cells.values.toList();
  }
}

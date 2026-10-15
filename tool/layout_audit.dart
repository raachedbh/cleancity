// Diagnostic geometry report, deliberately written to stdout.
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';

void main() {
  test('layout audit', () {
    for (final d in districts) {
      final l = d.layout;
      print(
        '${d.name}: ${d.worldSize} buildings=${l.buildings.length} types=${l.buildings.values.map((b) => b.kind.name).toSet()}',
      );
      for (final e in l.buildings.entries) {
        print('  ${e.key} ${e.value.kind.name} ${l.blocks[e.key]}');
      }
      print('  start=${l.start} stations=${l.stations}');
    }
  });
}

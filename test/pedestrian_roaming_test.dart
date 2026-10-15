import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/city_life.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/state/game_state.dart';
import 'game_state_test.dart' show MemoryStore;

void main() {
  test(
    'every city has spread-out pedestrians that visit distant neighborhoods',
    () async {
      for (final district in districts) {
        final state = GameState(MemoryStore());
        state.unlockedMaps.add(district.id);
        state.travel(district.id);
        final navigation = CityNavigation(district);
        final life = CityLife(state, navigation);
        final starts = life.people.map((p) => p.position).toList();
        final size = district.worldSize;
        int zone(Offset p) =>
            (p.dx >= size.width / 2 ? 1 : 0) +
            (p.dy >= size.height / 2 ? 2 : 0);
        final visited = [
          for (final p in starts) {zone(p)},
        ];
        final farthest = List.filled(starts.length, 0.0);
        expect(
          starts.map((p) => zone(p)).toSet().length,
          4,
          reason: '${district.name}: populated in all four neighborhoods',
        );
        expect(
          starts.map((p) => p.dx).reduce(max) -
              starts.map((p) => p.dx).reduce(min),
          greaterThan(size.width * .7),
        );
        expect(
          starts.map((p) => p.dy).reduce(max) -
              starts.map((p) => p.dy).reduce(min),
          greaterThan(size.height * .7),
        );

        // Six active minutes: even the slowest walkers should cross the larger
        // maps, using the same collision routes as normal frame updates.
        for (var frame = 0; frame < 1800; frame++) {
          life.update(.2);
          for (final person in life.people) {
            visited[person.id].add(zone(person.position));
            farthest[person.id] = max(
              farthest[person.id],
              (person.position - starts[person.id]).distance,
            );
            if (frame % 10 == 0) {
              expect(
                district.canStand(person.position),
                isTrue,
                reason: '${district.name}: walker ${person.id} stays on land',
              );
            }
          }
        }
        for (final person in life.people) {
          expect(
            visited[person.id].length,
            greaterThanOrEqualTo(3),
            reason:
                '${district.name}: walker ${person.id} must leave its block',
          );
          expect(
            farthest[person.id],
            greaterThan(min(size.width, size.height) * .4),
            reason: '${district.name}: walker ${person.id} travels across town',
          );
        }
        await state.flush();
        state.dispose();
      }
    },
  );
}

import 'dart:ui';

enum ValuableKind {
  jewelry('Jewelry', 6),
  wallet('Wallets', 3),
  handbag('Handbags', 4),
  watch('Watches', 5);

  const ValuableKind(this.label, this.reward);
  final String label;
  final int reward;
}

class ValuableDrop {
  const ValuableDrop(this.id, this.kind, this.district, this.position);
  final int id, district;
  final ValuableKind kind;
  final Offset position;
  List<Object> toJson() => [id, kind.index, district, position.dx, position.dy];
}

enum AlbumMetric { collected, recycled, thieves, returned, cities }

class Souvenir {
  const Souvenir(this.id, this.name, this.metric, this.target);
  final String id, name;
  final AlbumMetric metric;
  final int target;
}

const souvenirs = [
  Souvenir('recycled100', 'First green leaf', AlbumMetric.recycled, 100),
  Souvenir('recycled1000', 'Copper sprout', AlbumMetric.recycled, 1000),
  Souvenir('recycled10000', 'Silver tree', AlbumMetric.recycled, 10000),
  Souvenir('recycled100000', 'Golden city', AlbumMetric.recycled, 100000),
  Souvenir('collected1000', 'Street keeper', AlbumMetric.collected, 1000),
  Souvenir('collected25000', 'City guardian', AlbumMetric.collected, 25000),
  Souvenir('thieves10', 'Helping hand', AlbumMetric.thieves, 10),
  Souvenir('thieves100', 'Neighborhood hero', AlbumMetric.thieves, 100),
  Souvenir('returned25', 'Honest citizen', AlbumMetric.returned, 25),
  Souvenir('returned250', 'Trust badge', AlbumMetric.returned, 250),
  Souvenir('cities3', 'City explorer', AlbumMetric.cities, 3),
  Souvenir('cities6', 'World passport', AlbumMetric.cities, 6),
];

String albumNumber(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

class AlbumProgress {
  final found = List<int>.filled(ValuableKind.values.length, 0);
  final returned = List<int>.filled(ValuableKind.values.length, 0);
  final drops = <ValuableDrop>[];
  final earned = <String>{};
  int nextId = 0;
  int held(ValuableKind kind) => found[kind.index] - returned[kind.index];
  int get carried => ValuableKind.values.fold(0, (n, k) => n + held(k));
  int get totalFound => found.fold(0, (a, b) => a + b);
  int get totalReturned => returned.fold(0, (a, b) => a + b);
  int get returnReward =>
      ValuableKind.values.fold(0, (n, k) => n + held(k) * k.reward);
  Map<String, Object> toJson() => {
    'found': found,
    'returned': returned,
    'nextId': nextId,
    'drops': drops.map((d) => d.toJson()).toList(),
    'earned': earned.toList(),
  };

  static AlbumProgress read(
    dynamic raw,
    int cities,
    bool Function(int, Offset) canStand,
  ) {
    final result = AlbumProgress();
    if (raw == null) return result;
    if (raw is! Map) throw const FormatException('Invalid album');
    for (final entry in [
      ('found', result.found),
      ('returned', result.returned),
    ]) {
      final values = raw[entry.$1];
      if (values is! List || values.length != ValuableKind.values.length) {
        throw const FormatException('Invalid album counts');
      }
      for (var i = 0; i < values.length; i++) {
        if (values[i] is! int || values[i] < 0) {
          throw const FormatException('Invalid album count');
        }
        entry.$2[i] = values[i] as int;
      }
    }
    if (ValuableKind.values.any((k) => result.held(k) < 0)) {
      throw const FormatException('Invalid returned items');
    }
    final nextId = raw['nextId'];
    if (nextId is! int || nextId < 0) {
      throw const FormatException('Invalid album sequence');
    }
    result.nextId = nextId;
    final ids = <int>{};
    for (final d in raw['drops'] as List) {
      if (d is! List ||
          d.length != 5 ||
          d[0] is! int ||
          d[1] is! int ||
          d[2] is! int ||
          d[3] is! num ||
          d[4] is! num) {
        throw const FormatException('Invalid valuable');
      }
      final id = d[0] as int, kind = d[1] as int, city = d[2] as int;
      final p = Offset((d[3] as num).toDouble(), (d[4] as num).toDouble());
      if (id < 0 ||
          id >= nextId ||
          !ids.add(id) ||
          kind < 0 ||
          kind >= ValuableKind.values.length ||
          city < 0 ||
          city >= cities ||
          !p.dx.isFinite ||
          !p.dy.isFinite ||
          !canStand(city, p)) {
        throw const FormatException('Invalid valuable position');
      }
      result.drops.add(ValuableDrop(id, ValuableKind.values[kind], city, p));
    }
    result.earned.addAll(
      (raw['earned'] as List).cast<String>().where(
        (id) => souvenirs.any((s) => s.id == id),
      ),
    );
    return result;
  }
}

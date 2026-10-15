import 'dart:math';
import 'dart:ui';
import 'city_layout.dart';

enum MaterialKind {
  bottle('Plastic bottle', 2, Color(0xFF59B9A6)),
  can('Aluminium can', 3, Color(0xFFE5A64E)),
  paper('Cardboard', 4, Color(0xFFB98A65));

  const MaterialKind(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class District {
  const District(
    this.id,
    this.name,
    this.subtitle,
    this.country,
    this.color,
    this.columns,
    this.rows,
    this.requiredLevel,
    this.price,
    this.earningMultiplier,
    this.unlockBonus, {
    this.gemPrice = 0,
    this.bonusOutfit,
    this.night = false,
  });
  final int id, columns, rows, requiredLevel, price, gemPrice, unlockBonus;
  final int? bonusOutfit;
  final String name, subtitle, country;
  final Color color;
  final double earningMultiplier;
  final bool night;
  bool get premium => gemPrice > 0;
  int get litterCount => 600 + id * 220;
  int get initialLitterCount => 45 + id * 12;
  int get streetLitterLimit => 65 + id * 15;
  int get maximumLitterCount => streetLitterLimit + 36;
  CityLayout get layout => CityLayout.forCity(id, columns, rows);
  List<Offset> get pedestrianStops => [
    // Sidewalk destinations reach the outskirts as well as the building lots.
    for (final street in layout.streets)
      for (var segment = 1; segment < street.points.length; segment++)
        ..._sidewalkStops(
          street.points[segment - 1],
          street.points[segment],
          street.width,
        ),
    for (final b in blocks) ...[
      Offset(b.left - 42, b.top - 40),
      Offset(b.right + 42, b.top - 40),
      Offset(b.right + 42, b.bottom + 40),
      Offset(b.left - 42, b.bottom + 40),
    ],
  ];
  Iterable<Offset> _sidewalkStops(Offset a, Offset b, double width) sync* {
    final delta = b - a, length = delta.distance;
    if (length == 0) return;
    final side = Offset(-delta.dy, delta.dx) / length * (width / 2 + 22);
    final steps = max(1, (length / 260).ceil());
    for (var step = 0; step <= steps; step++) {
      final center = Offset.lerp(a, b, step / steps)!;
      yield center + side;
      yield center - side;
    }
  }

  Size get worldSize => layout.size;
  Rect get walkable => layout.walkable;
  Offset get start => layout.start;
  Offset get station => stations.first;
  List<Offset> get stations => layout.stations;
  List<Rect> get blocks => layout.blocks;
  int get landmarkBlock => layout.landmark;
  List<Rect> get obstacles => layout.obstacles;
  bool canStand(Offset p, {double clearance = 12}) =>
      layout.contains(p, clearance: clearance) &&
      !obstacles.any((r) => r.inflate(clearance).contains(p));
  List<String> get projectNames => [
    'Plant the street gardens',
    'Restore the gathering places',
    'Make ${name.split(' ').first} bloom',
  ];
}

const districts = [
  District(
    0,
    'Willow Lane',
    'Your first little corner of the world.',
    'HOME',
    Color(0xFF71967A),
    3,
    2,
    1,
    0,
    1,
    0,
  ),
  District(
    1,
    'Porto Sole',
    'Terracotta roofs. Lemon trees. A fresh start.',
    'ITALY',
    Color(0xFFCF865F),
    3,
    3,
    10,
    4500,
    1.35,
    350,
  ),
  District(
    2,
    'Tunis Avenue',
    'Palms and the golden clock of Habib Bourguiba.',
    'TUNISIA',
    Color(0xFF419BA3),
    4,
    3,
    18,
    14000,
    1.75,
    750,
  ),
  District(
    3,
    'Paris Gardens',
    'Cafe corners and streets worth caring for.',
    'FRANCE',
    Color(0xFFA57F99),
    4,
    4,
    26,
    32000,
    2.2,
    1500,
  ),
  District(
    4,
    'Kyoto Lanterns',
    'A quieter path beneath the cherry blossoms.',
    'JAPAN',
    Color(0xFFCD8691),
    5,
    4,
    35,
    65000,
    2.8,
    3000,
    bonusOutfit: 5,
  ),
  District(
    5,
    'Midnight Hollow',
    'A little spooky. A lot to discover.',
    'NIGHT COLLECTION',
    Color(0xFF7967AB),
    5,
    5,
    1,
    0,
    3.2,
    1200,
    gemPrice: 80,
    bonusOutfit: 4,
    night: true,
  ),
];

class Outfit {
  const Outfit(
    this.name,
    this.description,
    this.price,
    this.color, {
    this.gems = 0,
    this.mapGift,
  });
  final String name, description;
  final int price, gems;
  final int? mapGift;
  final Color color;
}

const outfits = [
  Outfit(
    'The everyday',
    'Your favorite tee. Every story starts somewhere.',
    0,
    Color(0xFF58A891),
  ),
  Outfit(
    'Sunshine crew',
    'A bright vest for your city adventures.',
    1000,
    Color(0xFFE4AC4D),
  ),
  Outfit(
    'Lavender days',
    'A cozy hoodie for the long way home.',
    3000,
    Color(0xFFB49AD4),
  ),
  Outfit(
    'The caretaker',
    'A classic look, earned one street at a time.',
    7500,
    Color(0xFF566681),
  ),
  Outfit(
    'Velvet vampire',
    'An original night look. Included with Midnight Hollow.',
    0,
    Color(0xFF824768),
    gems: 35,
    mapGift: 5,
  ),
  Outfit(
    'Lantern ranger',
    'An original explorer outfit. A gift when you unlock Kyoto.',
    0,
    Color(0xFF39858D),
    gems: 50,
    mapGift: 4,
  ),
  Outfit(
    'Firefighter',
    'A red helmet, reflective stripes and sturdy boots.',
    12000,
    Color(0xFFD69B42),
  ),
  Outfit(
    'Alchemist',
    'A plum coat, brass goggles and a belt full of potions.',
    0,
    Color(0xFF9875B0),
    gems: 55,
  ),
  Outfit(
    'Doctor',
    'A fresh white coat, teal scrubs and a stethoscope.',
    15000,
    Color(0xFF65AFA8),
  ),
  Outfit(
    'City chef',
    'A tall chef hat, double-breasted jacket and red neckerchief.',
    18000,
    Color(0xFFD88B75),
  ),
  Outfit(
    'Astronaut',
    'A space suit with a glass helmet and an oxygen backpack.',
    0,
    Color(0xFF859FC2),
    gems: 70,
  ),
  Outfit(
    'Mechanic',
    'Work overalls, a copper cap and a handy tool belt.',
    22000,
    Color(0xFF6E8DA1),
  ),
];

enum Upgrade { bag, reach, value, speed, processing }

const upgradeNames = [
  'Roomier bag',
  'Helping hand',
  'Better recycling',
  'Faster machine',
  'Larger batches',
];
const upgradePrices = [350, 550, 800, 650, 500];
const maxUpgradeLevel = 6;
int xpForLevel(int level) {
  final n = max(0, level - 1);
  return 120 * n + 40 * n * n;
}

class Litter {
  const Litter(
    this.id,
    this.position,
    this.kind,
    this.district, {
    this.truckDroppedAt,
  });
  final String id;
  final Offset position;
  final MaterialKind kind;
  final int district;
  final int? truckDroppedAt;
  int truckBonus(int nowMs) => truckDroppedAt == null
      ? 0
      : max(1, 8 - max(0, nowMs - truckDroppedAt!) ~/ 4000);
}

// A finite cleanup quota. A generous opening selection is placed at once;
// pedestrians introduce the rest as the player clears space on the streets.
List<Litter> createLitter(int district, int cycle, {int? count}) {
  final area = districts[district],
      random = Random(413 + district * 997 + cycle * 73);
  final result = <Litter>[];
  final blocks = area.blocks;
  for (
    var attempt = 0;
    result.length < min(count ?? area.litterCount, area.litterCount) &&
        attempt < 100000;
    attempt++
  ) {
    // Alternate open streets, public squares and shop fronts so large avenues
    // have things to collect, rather than hiding nearly everything by buildings.
    final Offset p;
    final publicSpace = area.layout.plaza ?? area.layout.garden;
    if (attempt % 11 == 10) {
      // A small plaza can fill before the city does. Keep placing the remaining
      // quota on other valid ground instead of retrying the same full area.
      p = Offset(
        area.walkable.left + random.nextDouble() * area.walkable.width,
        area.walkable.top + random.nextDouble() * area.walkable.height,
      );
    } else if (result.length % 5 == 2 && publicSpace != null) {
      p = Offset(
        publicSpace.left + random.nextDouble() * publicSpace.width,
        publicSpace.top + random.nextDouble() * publicSpace.height,
      );
    } else if (result.length % 5 != 4) {
      final street =
          area.layout.streets[random.nextInt(area.layout.streets.length)];
      final segment = 1 + random.nextInt(street.points.length - 1);
      final a = street.points[segment - 1], b = street.points[segment];
      final delta = b - a;
      if (delta.distance < 1) continue;
      final normal = Offset(-delta.dy, delta.dx) / delta.distance;
      p =
          Offset.lerp(a, b, random.nextDouble())! +
          normal * ((random.nextDouble() - .5) * (street.width + 30));
    } else {
      final b = blocks[(result.length + attempt ~/ 30) % blocks.length];
      final along = .1 + random.nextDouble() * .8;
      final edge = 34 + random.nextDouble() * 19;
      p = switch (random.nextInt(4)) {
        0 => Offset(b.left + b.width * along, b.top - edge),
        1 => Offset(b.right + edge, b.top + b.height * along),
        2 => Offset(b.left + b.width * along, b.bottom + edge),
        _ => Offset(b.left - edge, b.top + b.height * along),
      };
    }
    if (!area.canStand(p, clearance: 20) ||
        area.stations.any((s) => (s - p).distance < 105) ||
        result.any((s) => (s.position - p).distance < 24)) {
      continue;
    }
    result.add(
      Litter(
        '$district:$cycle:${result.length}',
        p,
        MaterialKind.values[random.nextInt(3)],
        district,
      ),
    );
  }
  return result;
}

enum GoalPeriod { daily, weekly, monthly }

class Mission {
  const Mission(
    this.id,
    this.title,
    this.target,
    this.reward,
    this.metric,
    this.period, {
    this.gems = 0,
  });
  final String id, title, metric;
  final int target, reward, gems;
  final GoalPeriod period;
  String get description =>
      '${metric == 'collected' ? 'Collect' : 'Recycle'} $target pieces of litter.';
}

const missions = [
  Mission(
    'daily_collect',
    'A little everyday good',
    50,
    50,
    'collected',
    GoalPeriod.daily,
  ),
  Mission(
    'daily_recycle',
    'Give it another life',
    150,
    150,
    'recycled',
    GoalPeriod.daily,
  ),
  Mission(
    'weekly_collect',
    'A week of cleaner streets',
    1500,
    1200,
    'collected',
    GoalPeriod.weekly,
  ),
  Mission(
    'weekly_recycle',
    'The weekly champion',
    2200,
    1800,
    'recycled',
    GoalPeriod.weekly,
    gems: 1,
  ),
  Mission(
    'monthly_collect',
    'A city transformed',
    9000,
    7500,
    'collected',
    GoalPeriod.monthly,
  ),
  Mission(
    'monthly_recycle',
    'The extraordinary effort',
    12000,
    11000,
    'recycled',
    GoalPeriod.monthly,
    gems: 2,
  ),
];
const dailyCoins = [25, 40, 60, 85, 120, 160, 250];

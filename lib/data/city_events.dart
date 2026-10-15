import 'dart:ui';

enum CityEventMetric { collected, bottles, recycled }

class CityEventDefinition {
  const CityEventDefinition(
    this.name,
    this.description,
    this.metric,
    this.target,
    this.coins,
    this.xp,
    this.color,
  );
  final String name, description;
  final CityEventMetric metric;
  final int target, coins, xp;
  final Color color;
}

const cityEvents = [
  CityEventDefinition(
    'Street sweep',
    'Neighbors are tidying the streets. Collect 12 pieces of litter in this city.',
    CityEventMetric.collected,
    12,
    140,
    30,
    Color(0xFFE5AA54),
  ),
  CityEventDefinition(
    'Bottle hunt',
    'Follow the teal sparkles and collect 8 plastic bottles in this city.',
    CityEventMetric.bottles,
    8,
    180,
    40,
    Color(0xFF5FBDB2),
  ),
  CityEventDefinition(
    'Recycling rally',
    'Recycle 20 pieces from this city in batches started after you join.',
    CityEventMetric.recycled,
    20,
    240,
    55,
    Color(0xFFA98BCD),
  ),
];

class CityEventRun {
  CityEventRun({
    required this.id,
    required this.type,
    required this.district,
    this.joined = false,
    this.progress = 0,
  });
  final int id, type, district;
  bool joined;
  int progress;
  CityEventDefinition get definition => cityEvents[type];
  bool get ready => joined && progress >= definition.target;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'district': district,
    'joined': joined,
    'progress': progress,
  };

  static CityEventRun? read(dynamic data, int districtCount) {
    if (data is! Map) return null;
    final id = data['id'],
        type = data['type'],
        district = data['district'],
        progress = data['progress'];
    if (id is! int ||
        id < 1 ||
        type is! int ||
        type < 0 ||
        type >= cityEvents.length ||
        district is! int ||
        district < 0 ||
        district >= districtCount ||
        progress is! int ||
        progress < 0) {
      return null;
    }
    return CityEventRun(
      id: id,
      type: type,
      district: district,
      joined: data['joined'] == true,
      progress: data['joined'] == true
          ? progress.clamp(0, cityEvents[type].target)
          : 0,
    );
  }
}

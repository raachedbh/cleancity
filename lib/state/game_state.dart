import '../data/album.dart';
import '../data/city_events.dart';
import '../data/cleanup_ranks.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalog.dart';

abstract class SaveStore {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalSaveStore implements SaveStore {
  LocalSaveStore({this.key = 'greenhaven_save_v1'});
  final String key;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  // Keep the original key and application ID so installed previews migrate in place.
  @override
  Future<String?> read() => _prefs.getString(key);
  @override
  Future<void> write(String value) => _prefs.setString(key, value);
}

enum JoystickPosition { left, center, right }

typedef BagItem = ({int kind, int district});

class RecyclingJob {
  const RecyclingJob(
    this.district,
    this.items,
    this.coins,
    this.startedAt,
    this.readyAt, {
    this.cityEventId,
  });
  final int district, coins, startedAt, readyAt;
  final int? cityEventId;
  final List<BagItem> items;
  Map<String, dynamic> toJson() => {
    'district': district,
    'items': items.map((v) => [v.kind, v.district]).toList(),
    'coins': coins,
    'startedAt': startedAt,
    'readyAt': readyAt,
    'cityEventId': cityEventId,
  };
}

class GoalTracker {
  GoalTracker(
    this.key, {
    this.collected = 0,
    this.recycled = 0,
    Set<String>? claims,
  }) : claims = claims ?? {};
  final String key;
  int collected, recycled;
  final Set<String> claims;
  Map<String, dynamic> toJson() => {
    'key': key,
    'collected': collected,
    'recycled': recycled,
    'claims': claims.toList(),
  };
}

class GameState extends ChangeNotifier {
  GameState(this.store, {DateTime Function()? now})
    : clock = now ?? DateTime.now;
  final SaveStore store;
  final DateTime Function() clock;
  int coins = 0, gems = 0, xp = 0, district = 0, outfit = 0;
  int totalCollected = 0, totalRecycled = 0, totalEarned = 0;
  int thievesCaught = 0;
  AlbumProgress album = AlbumProgress();
  final cityAlerts = <({int district, String text})>[];
  void alertCity(String text) =>
      cityAlerts.add((district: district, text: text));
  bool get nearPolice =>
      (position - districts[district].layout.policeEntrance).distance <= 85;
  int albumMetric(AlbumMetric metric) => switch (metric) {
    AlbumMetric.collected => totalCollected,
    AlbumMetric.recycled => totalRecycled,
    AlbumMetric.thieves => thievesCaught,
    AlbumMetric.returned => album.totalReturned,
    AlbumMetric.cities => unlockedMaps.length,
  };
  void _syncSouvenirs({bool announce = true}) {
    var unlocked = 0;
    for (final souvenir in souvenirs) {
      if (albumMetric(souvenir.metric) >= souvenir.target &&
          album.earned.add(souvenir.id)) {
        unlocked++;
      }
    }
    if (announce && unlocked > 0) events.add('New souvenir in Album');
  }

  bool collectValuable(int id) {
    final index = album.drops.indexWhere(
      (d) => d.id == id && d.district == district,
    );
    if (index < 0) return false;
    final drop = album.drops[index];
    if ((drop.position - position).distance > 42) return false;
    album.drops.removeAt(index);
    album.found[drop.kind.index]++;
    playerRewardText =
        '+1 ${switch (drop.kind) {
          ValuableKind.jewelry => 'jewelry',
          ValuableKind.wallet => 'wallet',
          ValuableKind.handbag => 'handbag',
          ValuableKind.watch => 'watch',
        }}';
    playerRewardSequence++;
    _changed();
    return true;
  }

  int returnValuables() {
    if (!nearPolice || album.carried == 0) return 0;
    final reward = album.returnReward;
    for (final kind in ValuableKind.values) {
      album.returned[kind.index] = album.found[kind.index];
    }
    _earn(reward);
    playerRewardText = 'Returned! +$reward coins';
    playerRewardSequence++;
    _changed();
    return reward;
  }

  int playerRewardSequence = 0;
  String? playerRewardText;
  List<int> upgrades = List.filled(Upgrade.values.length, 0);
  List<int> projects = List.filled(districts.length, 0);
  List<int> recycledByDistrict = List.filled(districts.length, 0);
  List<int> cycles = List.filled(districts.length, 0);
  List<int> cleanupTargets = [for (final area in districts) area.litterCount];
  int get cleanupTarget => cleanupTargets[district];
  List<Set<String>> removed = List.generate(districts.length, (_) => {});
  List<List<Litter>> streetLitter = List.generate(
    districts.length,
    (id) => createLitter(id, 0, count: districts[id].initialLitterCount),
  );
  Set<int> ownedOutfits = {0}, unlockedMaps = {0};
  List<BagItem> bag = [];
  final Map<int, RecyclingJob> jobs = {};
  final Map<GoalPeriod, GoalTracker> goals = {};
  final List<String> events = [];
  CityEventRun? cityEvent;
  int cityEventSequence = 0, completedCityEvents = 0;
  double cityEventWaitMs = 120000;
  double thiefWaitMs = 150000;
  double truckWaitMs = 210000;
  Offset position = districts[0].start;
  bool introduced = false, sound = true, haptics = true;
  bool darkMode = true, hudVisible = true;
  double hudOpacity = .38;
  JoystickPosition joystickPosition = JoystickPosition.left;
  bool testMode = false;
  bool saveFailed = false, recoveredSave = false;
  int lastDailyDay = -1, dailyStreak = 0, lastSeenMs = 0;
  int magnetUntil = 0, magnetReadyAt = 0;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  int get nowMs => max(lastSeenMs, clock().toUtc().millisecondsSinceEpoch);
  DateTime get now => DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
  int get today => nowMs ~/ Duration.millisecondsPerDay;
  int get level {
    var l = 1;
    while (l < 100 && xp >= xpForLevel(l + 1)) {
      l++;
    }
    return l;
  }

  double get levelProgress => level == 100
      ? 1
      : (xp - xpForLevel(level)) / (xpForLevel(level + 1) - xpForLevel(level));
  int get capacity => 16 + upgrades[0] * 8;
  double get pickupRadius =>
      magnetActive ? 185 + upgrades[1] * 8.0 : 42 + upgrades[1] * 7.0;
  int get batchCapacity => 16 + upgrades[4] * 12;
  int get processingSeconds => max(3, 15 - upgrades[3] * 2);
  int get restored => projects.fold(0, (a, b) => a + b);
  bool get magnetUnlocked => level >= 5;
  bool get magnetActive => nowMs < magnetUntil;
  int get magnetSeconds => max(0, ((magnetUntil - nowMs) / 1000).ceil());
  int get magnetCooldown => max(0, ((magnetReadyAt - nowMs) / 1000).ceil());
  bool get nearStation =>
      districts[district].stations.any((p) => (position - p).distance <= 125);
  int valueOf(Iterable<BagItem> items) => items
      .fold<double>(
        0,
        (sum, item) =>
            sum +
            MaterialKind.values[item.kind].value *
                districts[item.district].earningMultiplier *
                (1 + upgrades[2] * .12),
      )
      .round();
  int get bagValue => valueOf(bag);
  int get batchValue => valueOf(bag.take(batchCapacity));
  int get readyMissions =>
      missions.where((m) => !isClaimed(m) && progress(m) >= m.target).length;
  bool isUnlocked(int id) =>
      id >= 0 && id < districts.length && unlockedMaps.contains(id);
  bool canUnlock(int id) {
    if (id <= 0 || id >= districts.length || isUnlocked(id)) return false;
    final d = districts[id];
    return d.premium
        ? gems >= d.gemPrice
        : level >= d.requiredLevel && coins >= d.price;
  }

  int upgradePrice(Upgrade item) =>
      (upgradePrices[item.index] * pow(1.85, upgrades[item.index])).round();
  int get projectPrice =>
      [800, 2200, 5500][min(projects[district], 2)] * (district + 1);
  int get projectRequirement => [150, 500, 1200][min(projects[district], 2)];
  bool get canRestore =>
      projects[district] < 3 &&
      coins >= projectPrice &&
      recycledByDistrict[district] >= projectRequirement;
  bool get canRenew =>
      removed[district].length >= cleanupTarget &&
      bag.isEmpty &&
      !jobs.containsKey(district) &&
      nearStation;
  int secondsForJob(RecyclingJob job) =>
      max(0, ((job.readyAt - nowMs) / 1000).ceil());

  String periodKey(GoalPeriod p, DateTime time) {
    final d = time.toUtc();
    final midnight = DateTime.utc(d.year, d.month, d.day);
    return switch (p) {
      GoalPeriod.daily => '${d.year}-${d.month}-${d.day}',
      GoalPeriod.weekly =>
        midnight.subtract(Duration(days: d.weekday - 1)).toIso8601String(),
      GoalPeriod.monthly => '${d.year}-${d.month}',
    };
  }

  DateTime periodEnd(GoalPeriod p) {
    final d = now;
    return switch (p) {
      GoalPeriod.daily => DateTime.utc(d.year, d.month, d.day + 1),
      GoalPeriod.weekly => DateTime.utc(
        d.year,
        d.month,
        d.day + (8 - d.weekday),
      ),
      GoalPeriod.monthly => DateTime.utc(d.year, d.month + 1),
    };
  }

  bool _rollGoals() {
    var changed = false;
    for (final p in GoalPeriod.values) {
      final key = periodKey(p, now);
      if (goals[p]?.key != key) {
        goals[p] = GoalTracker(key);
        changed = true;
      }
    }
    return changed;
  }

  void _record(String metric, int count, {DateTime? at}) {
    _rollGoals();
    final timestamp = at ?? now;
    for (final p in GoalPeriod.values) {
      final t = goals[p]!;
      // Offline batches count toward the period in which they finished.
      if (t.key != periodKey(p, timestamp)) continue;
      if (metric == 'collected') {
        t.collected += count;
      } else {
        t.recycled += count;
      }
    }
  }

  int progress(Mission m) {
    final t = goals[m.period];
    if (t == null || t.key != periodKey(m.period, now)) return 0;
    return m.metric == 'collected' ? t.collected : t.recycled;
  }

  bool isClaimed(Mission m) =>
      goals[m.period]?.key == periodKey(m.period, now) &&
      (goals[m.period]?.claims.contains(m.id) ?? false);
  void _earn(int amount) {
    coins += amount;
    totalEarned += amount;
  }

  void _gainXp(int amount) {
    final before = level;
    xp += amount;
    for (var l = before + 1; l <= level; l++) {
      var reward = 10 + l * 2;
      if (l % 5 == 0) reward += l * 15;
      if (l % 10 == 0) reward += l * 25;
      _earn(reward);
      events.add(
        'Level $l! +$reward coins${l == 5
            ? ' · Magnet unlocked!'
            : l % 10 == 0
            ? ' · Major milestone!'
            : ''}',
      );
    }
  }

  /// Used only by the separate test build and its separate save slot.
  void unlockTestContent() {
    testMode = true;
    xp = max(xp, xpForLevel(100));
    unlockedMaps.addAll(List.generate(districts.length, (i) => i));
    ownedOutfits.addAll(List.generate(outfits.length, (i) => i));
    upgrades = List.filled(Upgrade.values.length, maxUpgradeLevel);
    projects = List.filled(districts.length, 3);
    refillTestSupplies();
  }

  void refillTestSupplies() {
    if (!testMode) return;
    coins = max(coins, 1000000);
    gems = max(gems, 10000);
    magnetUntil = 0;
    magnetReadyAt = 0;
    _changed();
  }

  void setTestGear(bool upgraded) {
    if (!testMode) return;
    upgrades = List.filled(
      Upgrade.values.length,
      upgraded ? maxUpgradeLevel : 0,
    );
    _changed();
  }

  /// Only the running world advances this timer. Menus and time away do not.
  void advanceCityEvents(double seconds) {
    if (!introduced || cityEvent != null || !seconds.isFinite || seconds <= 0) {
      return;
    }
    cityEventWaitMs = max(0.0, cityEventWaitMs - seconds * 1000);
    if (cityEventWaitMs == 0) _offerCityEvent();
  }

  void _offerCityEvent() {
    if (cityEvent != null) return;
    final type = cityEventSequence % cityEvents.length;
    cityEventSequence++;
    cityEvent = CityEventRun(
      id: cityEventSequence,
      type: type,
      district: district,
    );
    alertCity('${cityEvent!.definition.name} available');
    _changed();
  }

  void offerTestCityEvent() {
    if (!testMode) return;
    cityEvent = null;
    _offerCityEvent();
  }

  static const thiefCatchReward = 25;

  void rewardCaughtThief({
    List<({ValuableKind kind, Offset position})> valuables = const [],
  }) {
    for (final item in valuables) {
      if (!districts[district].canStand(item.position)) continue;
      album.drops.add(
        ValuableDrop(album.nextId++, item.kind, district, item.position),
      );
    }
    thievesCaught++;
    _earn(thiefCatchReward);
    playerRewardText = 'Caught! +$thiefCatchReward coins';
    playerRewardSequence++;
    _changed();
  }

  void scheduleNextThief(double seconds) {
    thiefWaitMs = seconds.clamp(30, 360) * 1000;
    _changed();
  }

  bool joinCityEvent() {
    final event = cityEvent;
    if (event == null || event.joined || district != event.district) {
      return false;
    }
    event.joined = true;
    _changed();
    return true;
  }

  void _eventProgress(
    CityEventMetric metric,
    int count,
    int fromDistrict, {
    int? jobEventId,
  }) {
    final event = cityEvent;
    if (event == null ||
        !event.joined ||
        event.ready ||
        event.district != fromDistrict ||
        event.definition.metric != metric) {
      return;
    }
    if (metric == CityEventMetric.recycled && jobEventId != event.id) return;
    event.progress = min(event.definition.target, event.progress + count);
    if (event.ready) {
      events.add(
        '${event.definition.name} complete! Your event reward is ready.',
      );
    }
  }

  bool claimCityEvent() {
    final event = cityEvent;
    if (event == null || !event.ready) return false;
    // Clear before saving or notifying so repeated taps cannot pay twice.
    cityEvent = null;
    cityEventWaitMs = 360000;
    completedCityEvents++;
    _earn(event.definition.coins);
    _gainXp(event.definition.xp);
    _changed();
    return true;
  }

  void leaveCityEvent() {
    if (cityEvent == null) return;
    cityEvent = null;
    cityEventWaitMs = 360000;
    _changed();
  }

  bool activateMagnet() {
    if (!magnetUnlocked || magnetCooldown > 0) return false;
    magnetUntil = nowMs + 15000;
    magnetReadyAt = magnetUntil + 90000;
    _changed();
    return true;
  }

  bool checkIn() {
    if (lastDailyDay >= today) return false;
    dailyStreak = lastDailyDay == today - 1 ? dailyStreak % 7 + 1 : 1;
    lastDailyDay = today;
    _earn(dailyCoins[dailyStreak - 1]);
    if (dailyStreak == 7) gems += 5;
    events.add(
      'Day $dailyStreak gift: +${dailyCoins[dailyStreak - 1]} coins${dailyStreak == 7 ? ' +5 gems!' : '!'}',
    );
    _changed();
    return true;
  }

  /// Runs while foregrounded and once on loading/resuming. No background engine needed.
  void tick({bool attendance = false}) {
    lastSeenMs = nowMs;
    var changed = _rollGoals();
    final finished = jobs.values.where((j) => j.readyAt <= nowMs).toList();
    for (final j in finished) {
      jobs.remove(j.district);
      totalRecycled += j.items.length;
      for (final item in j.items) {
        recycledByDistrict[item.district]++;
      }
      _record(
        'recycled',
        j.items.length,
        at: DateTime.fromMillisecondsSinceEpoch(j.readyAt, isUtc: true),
      );
      _eventProgress(
        CityEventMetric.recycled,
        j.items.where((item) => item.district == j.district).length,
        j.district,
        jobEventId: j.cityEventId,
      );
      _earn(j.coins);
      _gainXp(j.items.length * 3);
      changed = true;
    }
    if (finished.isNotEmpty) {
      final coins = finished.fold<int>(0, (sum, job) => sum + job.coins);
      playerRewardText = '+$coins coins';
      playerRewardSequence++;
    }
    if (changed) _changed();
    if (attendance && introduced) checkIn();
  }

  /// All emissions are finite and persisted. Reopening cannot refill the street.
  Litter? dropLitter(
    Offset position, {
    bool fromThief = false,
    bool fromTruck = false,
  }) {
    final area = districts[district], active = streetLitter[district];
    if (active.length >=
            (fromThief || fromTruck
                ? area.maximumLitterCount
                : area.streetLitterLimit) ||
        active.length + removed[district].length >= cleanupTarget ||
        !area.canStand(position, clearance: 20) ||
        area.stations.any((s) => (s - position).distance < 105) ||
        active.any((s) => (s.position - position).distance < 20)) {
      return null;
    }
    final used = {...removed[district], ...active.map((i) => i.id)};
    var index = 0;
    while (used.contains('$district:${cycles[district]}:$index')) {
      index++;
    }
    final item = Litter(
      '$district:${cycles[district]}:$index',
      position,
      MaterialKind.values[(index + cycles[district]) % 3],
      district,
      truckDroppedAt: fromTruck ? nowMs : null,
    );
    active.add(item);
    _changed();
    return item;
  }

  bool collect(Litter item) {
    final actual = streetLitter[district]
        .where((v) => v.id == item.id)
        .firstOrNull;
    if (item.district != district ||
        bag.length >= capacity ||
        removed[district].contains(item.id) ||
        !streetLitter[district].any(
          (v) =>
              v.id == item.id &&
              v.kind == item.kind &&
              v.position == item.position,
        )) {
      return false;
    }
    streetLitter[district].removeWhere((v) => v.id == item.id);
    removed[district].add(item.id);
    bag.add((kind: item.kind.index, district: district));
    final bonus = actual!.truckBonus(nowMs);
    if (bonus > 0) {
      _earn(bonus);
      playerRewardText = '+$bonus truck coins';
      playerRewardSequence++;
    }
    final previousRank = cleanupRankIndex(totalCollected);
    totalCollected++;
    final rank = cleanupRankIndex(totalCollected);
    if (rank > previousRank) {
      events.add('New rank: ${cleanupRanks[rank].name}!');
    }
    _record('collected', 1);
    _eventProgress(CityEventMetric.collected, 1, district);
    if (item.kind == MaterialKind.bottle) {
      _eventProgress(CityEventMetric.bottles, 1, district);
    }
    _gainXp(1);
    _changed();
    return true;
  }

  bool startRecycling() {
    tick();
    if (bag.isEmpty || !nearStation || jobs.containsKey(district)) return false;
    final items = bag.take(batchCapacity).toList();
    final value = valueOf(items);
    bag.removeRange(0, items.length);
    final start = nowMs;
    jobs[district] = RecyclingJob(
      district,
      items,
      value,
      start,
      start + processingSeconds * 1000,
      cityEventId:
          cityEvent?.joined == true &&
              cityEvent?.district == district &&
              cityEvent?.ready == false
          ? cityEvent!.id
          : null,
    );
    _changed();
    return true;
  }

  bool buyUpgrade(Upgrade item) {
    final cost = upgradePrice(item);
    if (upgrades[item.index] >= maxUpgradeLevel || coins < cost) return false;
    coins -= cost;
    upgrades[item.index]++;
    _changed();
    return true;
  }

  bool equipOutfit(int id) {
    if (id < 0 || id >= outfits.length) return false;
    if (!ownedOutfits.contains(id)) {
      final item = outfits[id];
      if (item.gems > 0) {
        if (gems < item.gems) return false;
        gems -= item.gems;
      } else {
        if (coins < item.price) return false;
        coins -= item.price;
      }
      ownedOutfits.add(id);
    }
    outfit = id;
    _changed();
    return true;
  }

  bool unlockMap(int id) {
    if (!canUnlock(id)) return false;
    final d = districts[id];
    if (d.premium) {
      gems -= d.gemPrice;
    } else {
      coins -= d.price;
    }
    unlockedMaps.add(id);
    _earn(d.unlockBonus);
    if (d.bonusOutfit != null) ownedOutfits.add(d.bonusOutfit!);
    events.add(
      '${d.name} unlocked! +${d.unlockBonus} coins${d.bonusOutfit == null ? '' : ' + ${outfits[d.bonusOutfit!].name}'}',
    );
    _changed();
    return true;
  }

  bool restore() {
    if (!canRestore) return false;
    coins -= projectPrice;
    projects[district]++;
    _changed();
    return true;
  }

  bool claim(Mission m) {
    _rollGoals();
    if (!missions.contains(m) || isClaimed(m) || progress(m) < m.target) {
      return false;
    }
    goals[m.period]!.claims.add(m.id);
    _earn(m.reward);
    gems += m.gems;
    _changed();
    return true;
  }

  bool travel(int id) {
    if (!isUnlocked(id)) return false;
    district = id;
    position = districts[id].start;
    _changed();
    return true;
  }

  bool nextCleanup() {
    if (!canRenew) return false;
    _startCleanupRound();
    return true;
  }

  /// Active play starts another round once every piece is collected. Existing
  /// inventory and recycling jobs belong to the player, not the street cycle.
  bool replenishClearedStreets() {
    if (!introduced ||
        streetLitter[district].isNotEmpty ||
        removed[district].length < cleanupTarget) {
      return false;
    }
    _startCleanupRound();
    return true;
  }

  void _startCleanupRound() {
    cycles[district]++;
    cleanupTargets[district] = districts[district].litterCount;
    removed[district].clear();
    streetLitter[district] = createLitter(
      district,
      cycles[district],
      count: districts[district].initialLitterCount,
    );
    _changed();
  }

  void completeIntro() {
    introduced = true;
    _changed();
    checkIn();
  }

  void setSound(bool v) {
    sound = v;
    _changed();
  }

  void setHaptics(bool v) {
    haptics = v;
    _changed();
  }

  void setDarkMode(bool value) {
    darkMode = value;
    _changed();
  }

  void setJoystickPosition(JoystickPosition value) {
    joystickPosition = value;
    _changed();
  }

  void setHudOpacity(double value) {
    if (!value.isFinite) return;
    hudOpacity = value.clamp(.20, .80);
    _changed();
  }

  void setHudVisible(bool value) {
    hudVisible = value;
    _changed();
  }

  Future<void> load() async {
    try {
      final raw = await store.read();
      if (raw == null) {
        _rollGoals();
        return;
      }
      // Parse into an isolated object before adopting anything from the save.
      final candidate = GameState(store, now: clock);
      candidate._readSave(jsonDecode(raw) as Map<String, dynamic>);
      _readSave(candidate.toJson());
      candidate.dispose();
      tick();
      await save();
    } catch (_) {
      recoveredSave = true;
    }
  }

  void _readSave(Map<String, dynamic> d) {
    final version = d['version'];
    if (version != 1 &&
        version != 2 &&
        version != 3 &&
        version != 4 &&
        version != 5 &&
        version != 6 &&
        version != 7 &&
        version != 8 &&
        version != 9 &&
        version != 10 &&
        version != 11 &&
        version != 12 &&
        version != 13 &&
        version != 14 &&
        version != 15 &&
        version != 16 &&
        version != 17) {
      throw const FormatException('Unsupported save');
    }
    int n(String k, [int fallback = 0]) =>
        max(0, (d[k] as num?)?.toInt() ?? fallback);
    List<int> values(String key, int count, int cap) {
      final list = d[key] as List<dynamic>? ?? [];
      return List.generate(
        count,
        (i) => i < list.length ? (list[i] as num).toInt().clamp(0, cap) : 0,
      );
    }

    List<BagItem> items(dynamic source) =>
        ((source as List<dynamic>?) ?? []).map((v) {
          final a = v as List<dynamic>;
          final kind = (a[0] as num).toInt(), area = (a[1] as num).toInt();
          if (kind < 0 || kind >= 3 || area < 0 || area >= districts.length) {
            throw const FormatException('Invalid inventory');
          }
          return (kind: kind, district: area);
        }).toList();
    coins = n('coins');
    gems = n('gems');
    district = n('district').clamp(0, districts.length - 1);
    upgrades = values('upgrades', Upgrade.values.length, maxUpgradeLevel);
    projects = values('projects', districts.length, 3);
    recycledByDistrict = values(
      'recycledByDistrict',
      districts.length,
      100000000,
    );
    cycles = values('cycles', districts.length, 10000000);
    totalCollected = n('totalCollected');
    totalRecycled = n('totalRecycled');
    totalEarned = n('totalEarned');
    xp = n('xp', version == 1 ? totalCollected + totalRecycled * 3 : 0);
    bag = items(d['bag']);
    ownedOutfits =
        (d['ownedOutfits'] as List<dynamic>? ?? [0])
            .cast<int>()
            .where((v) => v >= 0 && v < outfits.length)
            .toSet()
          ..add(0);
    unlockedMaps =
        (d['unlockedMaps'] as List<dynamic>? ?? [0])
            .cast<int>()
            .where((v) => v >= 0 && v < districts.length)
            .toSet()
          ..add(0);
    if (version == 1) {
      if (restored >= 1) unlockedMaps.add(1);
      if (restored >= 3) unlockedMaps.add(2);
    }
    outfit = n('outfit');
    if (!ownedOutfits.contains(outfit)) outfit = 0;
    if (!unlockedMaps.contains(district)) district = 0;
    final oldRemoved = d['removed'] as List<dynamic>? ?? [];
    removed = List.generate(
      districts.length,
      (i) => version >= 2 && i < oldRemoved.length
          ? (oldRemoved[i] as List<dynamic>).cast<String>().toSet()
          : <String>{},
    );
    // Completed legacy rounds remain complete. Unfinished rounds gain a larger
    // litter budget, without changing collected IDs, inventory or rewards.
    final savedTargets = d['cleanupTargets'] as List<dynamic>?;
    cleanupTargets = List.generate(districts.length, (id) {
      final legacyTarget = 120 + id * 45;
      if (version < 14) {
        return removed[id].length >= legacyTarget
            ? max(legacyTarget, removed[id].length)
            : districts[id].litterCount;
      }
      final target = savedTargets != null && id < savedTargets.length
          ? savedTargets[id]
          : null;
      if (savedTargets?.length != districts.length ||
          target is! int ||
          target < legacyTarget ||
          target > districts[id].litterCount) {
        throw const FormatException('Invalid cleanup target');
      }
      return target;
    });
    final savedStreets = d['streetLitter'] as List<dynamic>?;
    streetLitter = List.generate(districts.length, (id) {
      if (version < 3) {
        return createLitter(id, cycles[id])
            .where(
              (i) =>
                  !removed[id].contains(i.id) &&
                  int.parse(i.id.split(':').last) < cleanupTargets[id],
            )
            .take(districts[id].initialLitterCount)
            .toList();
      }
      if (savedStreets == null || savedStreets.length != districts.length) {
        throw const FormatException('Missing street state');
      }
      final seen = <String>{};
      final placements = version < 8
          ? createLitter(id, cycles[id])
          : <Litter>[];
      final items = (savedStreets[id] as List<dynamic>).map((raw) {
        final a = raw as List<dynamic>, key = a[0] as String;
        final pos = Offset((a[1] as num).toDouble(), (a[2] as num).toDouble());
        final kind = (a[3] as num).toInt();
        final index = int.tryParse(key.split(':').last);
        if (!key.startsWith('$id:${cycles[id]}:') ||
            index == null ||
            index < 0 ||
            index >= cleanupTargets[id] ||
            !seen.add(key) ||
            removed[id].contains(key) ||
            !pos.dx.isFinite ||
            !pos.dy.isFinite ||
            !(version < 8
                ? districts[id].walkable.contains(pos)
                : version < 17
                ? districts[id].layout.contains(pos)
                : districts[id].canStand(pos)) ||
            kind < 0 ||
            kind > 2) {
          throw const FormatException('Invalid street item');
        }
        // A layout update must never treat an old building/water overlap as a
        // corrupt save. Relocate active items only; do not recreate collected IDs.
        final location = version < 8
            ? placements[index].position
            : version < 17 && !districts[id].canStand(pos, clearance: 20)
            ? districts[id].layout.safe(pos, clearance: 20)
            : pos;
        final droppedAt = version >= 11 && a.length > 4 ? a[4] : null;
        if (droppedAt != null && (droppedAt is! int || droppedAt < 0)) {
          throw const FormatException('Invalid truck drop time');
        }
        return Litter(
          key,
          location,
          MaterialKind.values[kind],
          id,
          truckDroppedAt: droppedAt as int?,
        );
      }).toList();
      if (items.length >
              (version == 3
                  ? 48
                  : version < 15
                  ? 316 + id * 100
                  : version == 15
                  ? 206 + id * 60
                  : districts[id].maximumLitterCount) ||
          items.length + removed[id].length > cleanupTargets[id]) {
        throw const FormatException('Street capacity exceeded');
      }
      // v3 streets had a higher cap. Deferred items can be emitted later;
      // trimming them never counts as collection or changes the cleanup quota.
      // Reduce already-populated v14/v15 streets as well as new games. Keep truck
      // drops first (newest bonuses first); retired uncollected IDs can be
      // emitted later and never count toward progress or rewards.
      if (version < 16 && items.length > districts[id].initialLitterCount) {
        final truckItems = items.where((i) => i.truckDroppedAt != null).toList()
          ..sort((a, b) => b.truckDroppedAt!.compareTo(a.truckDroppedAt!));
        final normal = items.where((i) => i.truckDroppedAt == null).toList();
        final target = districts[id].initialLitterCount;
        final balanced = truckItems.take(target).toList();
        final remaining = target - balanced.length;
        for (var n = 0; n < remaining; n++) {
          balanced.add(normal[(n * normal.length / remaining).floor()]);
        }
        items
          ..clear()
          ..addAll(balanced);
      }
      final active = items.take(districts[id].maximumLitterCount).toList();
      // One-time denser streets on upgrade, within the remaining cleanup quota.
      // Keep retained item metadata and never recreate a collected ID.
      if (version < 14) {
        final used = {...removed[id], ...active.map((item) => item.id)};
        for (final candidate in createLitter(id, cycles[id])) {
          if (active.length >= districts[id].initialLitterCount ||
              active.length + removed[id].length >= cleanupTargets[id]) {
            break;
          }
          if (used.contains(candidate.id) ||
              active.any(
                (item) => (item.position - candidate.position).distance < 20,
              )) {
            continue;
          }
          active.add(candidate);
          used.add(candidate.id);
        }
      }
      return active;
    });
    final p = (d['position'] as List<dynamic>? ?? [130, 420]).cast<num>();
    final pos = Offset(p[0].toDouble(), p[1].toDouble());
    if (!pos.dx.isFinite || !pos.dy.isFinite) {
      throw const FormatException('Invalid position');
    }
    position = version >= 2 && districts[district].canStand(pos)
        ? pos
        : districts[district].start;
    introduced = d['introduced'] == true;
    sound = d['sound'] != false;
    haptics = d['haptics'] != false;
    darkMode = d['darkMode'] != false;
    hudVisible = d['hudVisible'] != false;
    final opacity = d['hudOpacity'];
    hudOpacity = opacity is num && opacity.isFinite
        ? opacity.toDouble().clamp(.20, .80)
        : .38;
    joystickPosition = JoystickPosition.values.firstWhere(
      (value) => value.name == d['joystickPosition'],
      orElse: () => JoystickPosition.left,
    );
    cityEvent = CityEventRun.read(d['cityEvent'], districts.length);
    cityEventSequence = max(n('cityEventSequence'), cityEvent?.id ?? 0);
    completedCityEvents = n('completedCityEvents');
    thievesCaught = n('thievesCaught');
    double wait(String key, double initial, double cap) {
      final value = d[key];
      final saved = value is num && value.isFinite
          ? value.toDouble().clamp(0.0, cap)
          : initial;
      return version < 17 ? max(initial, saved) : saved;
    }

    cityEventWaitMs = wait('cityEventWaitMs', 120000, 360000);
    thiefWaitMs = wait('thiefWaitMs', 150000, 360000);
    truckWaitMs = wait('truckWaitMs', 210000, 420000);
    album = AlbumProgress.read(
      d['album'],
      districts.length,
      (id, p) => districts[id].canStand(p),
    );
    _syncSouvenirs(announce: false);
    lastDailyDay = (d['lastDailyDay'] as num?)?.toInt() ?? -1;
    dailyStreak = n('dailyStreak').clamp(0, 7);
    lastSeenMs = n('lastSeenMs');
    magnetUntil = n('magnetUntil');
    magnetReadyAt = n('magnetReadyAt');
    jobs.clear();
    for (final raw in d['jobs'] as List<dynamic>? ?? []) {
      final j = raw as Map<String, dynamic>;
      final id = (j['district'] as num).toInt();
      final batch = items(j['items']);
      final start = (j['startedAt'] as num).toInt(),
          end = (j['readyAt'] as num).toInt(),
          value = (j['coins'] as num).toInt();
      if (id < 0 ||
          id >= districts.length ||
          end < start ||
          value < 0 ||
          batch.isEmpty ||
          jobs.containsKey(id)) {
        throw const FormatException('Invalid batch');
      }
      jobs[id] = RecyclingJob(
        id,
        batch,
        value,
        start,
        end,
        cityEventId: j['cityEventId'] is int ? j['cityEventId'] as int : null,
      );
    }
    goals.clear();
    final savedGoals = d['goals'] as Map<String, dynamic>? ?? {};
    for (final p in GoalPeriod.values) {
      final t = savedGoals[p.name] as Map<String, dynamic>?;
      if (t != null) {
        goals[p] = GoalTracker(
          t['key'] as String,
          collected: (t['collected'] as num).toInt(),
          recycled: (t['recycled'] as num).toInt(),
          claims: (t['claims'] as List<dynamic>).cast<String>().toSet(),
        );
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 17,
    'album': album.toJson(),
    'coins': coins,
    'gems': gems,
    'xp': xp,
    'district': district,
    'outfit': outfit,
    'upgrades': upgrades,
    'projects': projects,
    'cycles': cycles,
    'cleanupTargets': cleanupTargets,
    'recycledByDistrict': recycledByDistrict,
    'removed': removed.map((v) => v.toList()).toList(),
    'streetLitter': streetLitter
        .map(
          (items) => items
              .map(
                (i) => [
                  i.id,
                  i.position.dx,
                  i.position.dy,
                  i.kind.index,
                  i.truckDroppedAt,
                ],
              )
              .toList(),
        )
        .toList(),
    'bag': bag.map((v) => [v.kind, v.district]).toList(),
    'ownedOutfits': ownedOutfits.toList(),
    'unlockedMaps': unlockedMaps.toList(),
    'totalCollected': totalCollected,
    'thievesCaught': thievesCaught,
    'totalRecycled': totalRecycled,
    'totalEarned': totalEarned,
    'position': [position.dx, position.dy],
    'introduced': introduced,
    'sound': sound,
    'haptics': haptics,
    'darkMode': darkMode,
    'hudVisible': hudVisible,
    'hudOpacity': hudOpacity,
    'joystickPosition': joystickPosition.name,
    'lastDailyDay': lastDailyDay,
    'dailyStreak': dailyStreak,
    'lastSeenMs': lastSeenMs,
    'magnetUntil': magnetUntil,
    'magnetReadyAt': magnetReadyAt,
    'cityEvent': cityEvent?.toJson(),
    'cityEventSequence': cityEventSequence,
    'completedCityEvents': completedCityEvents,
    'cityEventWaitMs': cityEventWaitMs,
    'thiefWaitMs': thiefWaitMs,
    'truckWaitMs': truckWaitMs,
    'jobs': jobs.values.map((j) => j.toJson()).toList(),
    'goals': {for (final p in goals.keys) p.name: goals[p]!.toJson()},
  };
  Future<void> save() {
    final snapshot = jsonEncode(toJson());
    _pending = _pending.then((_) async {
      try {
        await store.write(snapshot);
        if (saveFailed) {
          saveFailed = false;
          if (!_disposed) notifyListeners();
        }
      } catch (_) {
        saveFailed = true;
        if (!_disposed) notifyListeners();
      }
    });
    return _pending;
  }

  Future<void> flush() => _pending;
  void _changed() {
    _syncSouvenirs();
    if (!_disposed) notifyListeners();
    unawaited(save());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

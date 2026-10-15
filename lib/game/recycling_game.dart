import 'album_art.dart';
import '../data/city_events.dart';
import 'player_art.dart';
import 'walk_cycle.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/catalog.dart';
import '../state/game_state.dart';
import 'sound.dart';
import 'navigation.dart';
import 'world_art.dart';
import 'city_life.dart';
import 'people_art.dart';
import 'trash_truck.dart';
import 'tree_apples.dart';
import 'mini_map.dart';

const characterRegions = [
  [
    Rect.fromLTRB(173, 4, 307, 252),
    Rect.fromLTRB(516, 4, 645, 252),
    Rect.fromLTRB(894, 4, 1024, 252),
    Rect.fromLTRB(1223, 4, 1361, 252),
  ],
  [
    Rect.fromLTRB(173, 260, 307, 508),
    Rect.fromLTRB(511, 260, 645, 508),
    Rect.fromLTRB(894, 260, 1028, 508),
    Rect.fromLTRB(1223, 260, 1368, 508),
  ],
  [
    Rect.fromLTRB(168, 516, 312, 764),
    Rect.fromLTRB(506, 516, 650, 764),
    Rect.fromLTRB(889, 516, 1030, 764),
    Rect.fromLTRB(1218, 516, 1370, 764),
  ],
  [
    Rect.fromLTRB(165, 772, 314, 1024),
    Rect.fromLTRB(503, 772, 653, 1024),
    Rect.fromLTRB(887, 772, 1032, 1024),
    Rect.fromLTRB(1217, 772, 1372, 1024),
  ],
];

class PickupEffect {
  PickupEffect(this.position, this.color);
  final Offset position;
  final Color color;
  double time = 0;
}

class RecyclingGame extends FlameGame {
  RecyclingGame(this.state, this.sounds, {required this.onNotice}) {
    pauseWhenBackgrounded = false;
  }
  final GameState state;
  final GameSound sounds;
  final void Function(String) onNotice;
  final nearStation = ValueNotifier(false),
      nearPolice = ValueNotifier(false),
      sceneReady = ValueNotifier(false);
  final List<PickupEffect> _effects = [];
  ui.Image? characterAtlas, specialAtlas;
  CityLife? life;
  WorldArt? art;
  CityNavigation? navigation;
  List<Litter> _litter = [];
  List<({Offset point, bool truck})> _miniLitter = [];
  double _miniRefresh = -1;
  int _miniCount = -1;
  Offset input = Offset.zero, _velocity = Offset.zero;
  Offset? target;
  final List<Offset> _route = [];
  Offset _camera = const Offset(350, 560);
  double _time = 0, _saveTime = 0, _pickupTime = 0;
  int _rewardSequence = 0;
  String? _playerMessage;
  double _messageTime = 0;
  bool _bagFullNotified = false;
  bool autoMoving = false;
  double _blockedTime = 0;
  VoidCallback? onAutoMoveBlocked;

  RecyclingJob? get displayedJob =>
      state.jobs[state.district] ??
      (state.jobs.isEmpty ? null : state.jobs.values.first);
  String? get playerStatusText {
    if (_messageTime > 0) return _playerMessage;
    final job = displayedJob;
    return job == null
        ? (life?.apples.boostSeconds ?? 0) > 0
              ? 'Speed +35%  ${life!.apples.boostSeconds.ceil()}s'
              : autoMoving
              ? 'Auto-walk'
              : null
        : '${state.secondsForJob(job)}s \u00b7 +${job.coins} coins';
  }

  void showPlayerMessage(String text) {
    _playerMessage = text;
    _messageTime = 2.8;
  }

  void showRecyclingTimer() {
    _messageTime = 0;
    _playerMessage = null;
  }

  int _facing = 0;
  bool moving = false;
  final gait = WalkCycle();
  District get area => districts[state.district];
  double get zoom => max(size.x / 650, size.y / 1120);
  Offset get viewCenter => Offset(size.x / 2, size.y / 2);
  @override
  Color backgroundColor() =>
      area.night ? const Color(0xFF353345) : const Color(0xFF7EAA79);
  ui.Image? imageForOutfit(int id) =>
      id < 4 || id >= 6 ? characterAtlas : specialAtlas;
  static Rect sourceForOutfit(int id, int facing) => id >= 6
      ? characterRegions[0][facing]
      : id < 4
      ? characterRegions[id][facing]
      : specialCharacterRegions[id - 4][facing];

  @override
  Future<void> onLoad() async {
    final loaded = await Future.wait(
      ['characters.png', 'special_skins_v2.png'].map(images.load),
    );
    characterAtlas = loaded[0];
    specialAtlas = loaded[1];
    await loadDistrict();
  }

  Future<void> loadDistrict() async {
    sceneReady.value = false;
    clearInput();
    _effects.clear();
    art?.dispose();
    art = WorldArt(area);
    navigation = CityNavigation(area);
    life = CityLife(state, navigation!);
    _bagFullNotified = false;
    if (!area.canStand(state.position)) state.position = area.start;
    refreshLitter();
    _miniRefresh = -1;
    _camera = _clampCamera(_cameraFocus);
    _syncStation();
    sceneReady.value = true;
  }

  void refreshLitter() => _litter = state.streetLitter[state.district];
  void clearInput() {
    autoMoving = false;
    _blockedTime = 0;
    input = Offset.zero;
    _velocity = Offset.zero;
    target = null;
    _route.clear();
    moving = false;
    gait.stop();
  }

  void setInput(Offset value) {
    autoMoving = false;
    _blockedTime = 0;
    input = value;
    target = null;
    _route.clear();
  }

  void startAutoMove(Offset direction) {
    setInput(direction);
    autoMoving = true;
  }

  void walkTo(Offset destination) {
    clearInput();
    _route.addAll(
      navigation?.route(
            state.position,
            destination,
            temporaryObstacle: life?.truck.navigationObstacle,
          ) ??
          [],
    );
    target = _route.isNotEmpty ? _route.removeAt(0) : null;
    if (target == null) onNotice('Try a nearby street or use the joystick.');
  }

  void goToPolice() {
    walkTo(area.layout.policeEntrance);
    if (target != null) onNotice('To the police station');
  }

  void goToStation() {
    // Choose by actual walk distance, not distance through buildings.
    List<Offset>? best;
    var bestDistance = double.infinity;
    for (final station in area.stations) {
      final route = navigation!.route(
        state.position,
        station + const Offset(0, 78),
        temporaryObstacle: life?.truck.navigationObstacle,
      );
      if (route.isEmpty) continue;
      var distance = 0.0, from = state.position;
      for (final to in route) {
        distance += (to - from).distance;
        from = to;
      }
      if (distance < bestDistance) {
        bestDistance = distance;
        best = route;
      }
    }
    clearInput();
    if (best != null) {
      _route.addAll(best);
      target = _route.removeAt(0);
    }
    onNotice('Following the streets to the nearest station');
  }

  Offset get _cameraFocus {
    var lift = 80.0;
    if (state.district == 2) {
      final tower = area.blocks[area.landmarkBlock].center;
      final closeness = ((1000 - (state.position - tower).distance) / 500)
          .clamp(0.0, 1.0);
      lift += 200 * closeness;
    }
    return state.position - Offset(0, lift);
  }

  Offset _clampCamera(Offset p) {
    final halfW = size.x / (2 * zoom), halfH = size.y / (2 * zoom);
    return Offset(
      p.dx.clamp(
        min(halfW - 150, area.worldSize.width / 2),
        max(area.worldSize.width - halfW + 150, area.worldSize.width / 2),
      ),
      p.dy.clamp(
        min(halfH - 220, area.worldSize.height / 2),
        max(area.worldSize.height - halfH + 160, area.worldSize.height / 2),
      ),
    );
  }

  bool _canStand(Offset p) =>
      area.canStand(p) &&
      !(life?.truck.blocksMovement(state.position, p) ?? false);
  void _syncStation() {
    if (nearPolice.value != state.nearPolice) {
      nearPolice.value = state.nearPolice;
    }
    if (nearStation.value != state.nearStation) {
      nearStation.value = state.nearStation;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!sceneReady.value) return;
    dt = min(dt, .05);
    _time += dt;
    _saveTime += dt;
    _pickupTime -= dt;
    if (state.replenishClearedStreets()) {
      refreshLitter();
      _miniRefresh = -1;
      showPlayerMessage('New cleanup');
    }
    life?.update(dt);
    _messageTime = max(0, _messageTime - dt);
    if (_rewardSequence != state.playerRewardSequence) {
      _rewardSequence = state.playerRewardSequence;
      showPlayerMessage(state.playerRewardText!);
      sounds.play('reward', enabled: state.sound);
    }
    state.advanceCityEvents(dt);
    if (state.bag.length < state.capacity) _bagFullNotified = false;
    var direction = input;
    var maxStep = double.infinity;
    if (target != null && input.distance < .08) {
      final diff = target! - state.position;
      if (diff.distance < 4) {
        target = _route.isNotEmpty ? _route.removeAt(0) : null;
      } else {
        direction = diff / diff.distance;
        maxStep = diff.distance;
      }
    }
    final beforeMove = state.position;
    if (direction.distance < .08) direction = Offset.zero;
    if (direction.distance > 1) direction /= direction.distance;
    _velocity = Offset.lerp(
      _velocity,
      direction,
      1 - exp(-dt * (direction == Offset.zero ? 20 : 12)),
    )!;
    if (direction == Offset.zero && _velocity.distance < .03) {
      _velocity = Offset.zero;
    }
    moving = _velocity.distance > .05;
    if (moving) {
      final step =
          _velocity *
          min(220 * (life?.apples.speedMultiplier ?? 1) * dt, maxStep);
      final next = state.position + step;
      if (_canStand(next)) {
        state.position = next;
      } else {
        final x = Offset(next.dx, state.position.dy),
            y = Offset(state.position.dx, next.dy);
        if (_canStand(x)) {
          state.position = x;
        } else if (_canStand(y)) {
          state.position = y;
        }
      }
    }
    final displacement = state.position - beforeMove;
    if (autoMoving) {
      _blockedTime = displacement.distance < .1 ? _blockedTime + dt : 0;
      if (_blockedTime > .35) {
        clearInput();
        onAutoMoveBlocked?.call();
      }
    }
    if (life?.apples.eatAt(state.position) == true) {
      showPlayerMessage('Speed +35%');
      sounds.play('reward', enabled: state.sound);
      _effects.add(PickupEffect(state.position, const Color(0xFF91D977)));
    }
    for (final drop in state.album.drops.toList()) {
      if (drop.district != state.district ||
          (drop.position - state.position).distance > 42 ||
          !navigation!.visible(state.position, drop.position)) {
        continue;
      }
      if (life!.truck.blocksMovement(
        state.position,
        drop.position,
        clearance: 0,
      )) {
        continue;
      }
      if (state.collectValuable(drop.id)) {
        _effects.add(PickupEffect(drop.position, AlbumArt.gold));
        sounds.play('pickup', enabled: state.sound);
      }
    }
    moving = displacement.distance > .02;
    gait.update(displacement.distance, dt);
    if (moving) _facing = facingFor(displacement, _facing);
    _syncStation();
    _camera = Offset.lerp(_camera, _clampCamera(_cameraFocus), min(1, dt * 7))!;
    if (_pickupTime <= 0) {
      for (final item in _litter) {
        if ((life?.inFlight(item.id) ?? false) ||
            state.removed[state.district].contains(item.id) ||
            (item.position - state.position).distance > state.pickupRadius) {
          continue;
        }
        if (!navigation!.visible(state.position, item.position)) continue;
        if (life!.truck.blocksMovement(
          state.position,
          item.position,
          clearance: 0,
        )) {
          continue;
        }
        if (state.collect(item)) {
          _effects.add(PickupEffect(item.position, item.kind.color));
          sounds.play('pickup', enabled: state.sound);
          if (state.haptics) unawaited(HapticFeedback.selectionClick());
          _pickupTime = state.magnetActive ? .055 : .13;
          break;
        } else if (!_bagFullNotified && state.bag.length >= state.capacity) {
          onNotice('Bag full');
          _bagFullNotified = true;
        }
      }
    }
    for (final e in _effects) {
      e.time += dt;
    }
    _effects.removeWhere((e) => e.time > .65);
    if (_saveTime > 5 && moving) {
      _saveTime = 0;
      unawaited(state.save());
    }
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    super.render(canvas);
    if (art == null || !sceneReady.value) return;
    c.save();
    c.translate(viewCenter.dx, viewCenter.dy);
    c.scale(zoom);
    c.translate(-_camera.dx, -_camera.dy);
    final visible = Rect.fromCenter(
      center: _camera,
      width: size.x / zoom + 250,
      height: size.y / zoom + 400,
    );
    art!.drawGround(c);
    if (state.magnetActive) {
      c.drawCircle(
        state.position,
        state.pickupRadius,
        Paint()..color = const Color(0x2247D9D0),
      );
      c.drawCircle(
        state.position,
        state.pickupRadius * (.85 + sin(_time * 5) * .08),
        Paint()
          ..color = const Color(0x887EE9DC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (final item in _litter) {
      if (!(life?.inFlight(item.id) ?? false) &&
          !state.removed[state.district].contains(item.id) &&
          visible.contains(item.position)) {
        c.save();
        c.translate(item.position.dx, item.position.dy);
        if (item.truckDroppedAt != null) {
          final bonus = item.truckBonus(state.nowMs);
          c.drawOval(
            const Rect.fromLTWH(-20, -10, 40, 20),
            Paint()
              ..color = Color.lerp(
                const Color(0x447F9480),
                const Color(0x99F5C45F),
                (bonus - 1) / 7,
              )!,
          );
          WorldArt.label(
            c,
            '+$bonus',
            const Offset(0, -31),
            13,
            area.night ? const Color(0xFFFFDF86) : const Color(0xFF865E21),
          );
        }
        final event = state.cityEvent;
        if (event?.joined == true &&
            event?.ready == false &&
            event?.district == state.district &&
            (event!.definition.metric == CityEventMetric.collected ||
                event.definition.metric == CityEventMetric.bottles &&
                    item.kind == MaterialKind.bottle)) {
          final color = event.definition.color;
          c.drawOval(
            const Rect.fromLTWH(-16, -7, 32, 14),
            Paint()..color = color.withValues(alpha: .3),
          );
          final sparkle = Offset(
            11,
            -20 + sin(_time * 2 + item.position.dx) * 2,
          );
          c.drawLine(
            sparkle - const Offset(3, 0),
            sparkle + const Offset(3, 0),
            Paint()
              ..color = color
              ..strokeWidth = 2,
          );
          c.drawLine(
            sparkle - const Offset(0, 3),
            sparkle + const Offset(0, 3),
            Paint()
              ..color = color
              ..strokeWidth = 2,
          );
        }
        c.scale(.72);
        c.rotate(sin(item.position.dx * 13) * .7);
        drawLitter(c, item.kind, _time + item.position.dx);
        c.restore();
      }
    }
    for (final drop in state.album.drops) {
      if (drop.district != state.district || !visible.contains(drop.position)) {
        continue;
      }
      c.drawOval(
        Rect.fromCenter(center: drop.position, width: 44, height: 24),
        Paint()..color = const Color(0x77F5C560),
      );
      c.drawOval(
        Rect.fromCenter(center: drop.position, width: 48, height: 27),
        Paint()
          ..color = const Color(0xCCFFF0B0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      AlbumArt.valuable(
        c,
        drop.kind,
        drop.position + Offset(0, -13 + sin(_time * 3 + drop.id) * 2),
        scale: .62,
      );
    }
    if (target != null) {
      final routePaint = Paint()
        ..color = const Color(0x8876B797)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      var previous = state.position;
      for (final p in [target!, ..._route]) {
        c.drawLine(previous, p, routePaint);
        previous = p;
      }
      c.drawOval(
        Rect.fromCenter(center: previous, width: 20, height: 12),
        Paint()..color = const Color(0xCC387C5B),
      );
    }
    final draws = <({double depth, void Function() draw})>[
      if (visible.overlaps(area.layout.policeBounds))
        (
          depth: area.layout.police.dy + 12,
          draw: () => AlbumArt.police(c, area.layout.police, state.district),
        ),
      for (final apple in life?.apples.apples ?? <TreeApple>[])
        if (visible.contains(apple.position))
          (depth: apple.position.dy, draw: () => TreeApples.draw(c, apple)),
      if (life?.truck.actor case final truck?)
        if (visible.contains(truck.position))
          (
            depth: truck.position.dy + 28,
            draw: () => TrashTruckEncounter.draw(c, truck),
          ),
      (depth: state.position.dy, draw: () => _drawPlayer(c)),
      for (var i = 0; i < area.layout.interviewSpots.length; i++)
        if (visible.contains(area.layout.interviewSpots[i]))
          (
            depth: area.layout.interviewSpots[i].dy,
            draw: () => PeopleArt.draw(
              c,
              id: const [4, 0, 3][i],
              position: area.layout.interviewSpots[i],
              facing: i == 1 ? 3 : 1,
              walking: false,
              time: _time,
              throwing: false,
              night: area.night,
              interviewRole: InterviewRole.values[i],
            ),
          ),
      if (life?.thief.actor case final t?)
        if (visible.contains(t.position))
          (
            depth: t.position.dy,
            draw: () {
              if (t.fade > 0) {
                for (var i = 0; i < 5; i++) {
                  c.drawCircle(
                    t.position + Offset((i - 2) * 12.0 * t.fade, -25 - i * 8.0),
                    12 + t.fade * 15,
                    Paint()
                      ..color = const Color(
                        0xFFB9B9B2,
                      ).withValues(alpha: ((1.2 - t.fade) / 1.2).clamp(0, 1)),
                  );
                }
                return;
              }
              PeopleArt.draw(
                c,
                id: 0,
                position: t.position,
                facing: t.facing,
                walking: t.running,
                time: t.age,
                throwing: t.gesture > 0,
                night: area.night,
                gait: t.gait,
                thief: true,
              );
              _thiefMarker(
                c,
                t.position - Offset(0, 132 + sin(_time * 4) * 4),
                15,
              );
            },
          ),
      for (final p in life?.people ?? <Pedestrian>[])
        if (visible.contains(p.position))
          (
            depth: p.position.dy,
            draw: () => CityLife.drawPerson(c, p, area.night),
          ),
      for (var i = 0; i < art!.blocks.length; i++)
        if (visible.overlaps(art!.spriteRect(i)))
          (
            depth: art!.blocks[i].bottom,
            draw: () => art!.drawBlock(c, i, state.position),
          ),
      for (var i = 0; i < art!.props.length; i++)
        if (visible.overlaps(art!.props[i].bounds))
          (
            depth: art!.props[i].position.dy,
            draw: () => art!.drawProp(c, i, state.position),
          ),
      for (final p in area.stations)
        if (visible.contains(p)) (depth: p.dy, draw: () => _drawStation(c, p)),
    ]..sort((a, b) => a.depth.compareTo(b.depth));
    for (final d in draws) {
      d.draw();
    }
    art!.drawGardens(c, state.projects[state.district]);
    for (final toss in life?.tosses ?? <LitterToss>[]) {
      if (!visible.contains(toss.position)) continue;
      c.save();
      c.translate(toss.position.dx, toss.position.dy);
      c.scale(.72);
      c.rotate(toss.progress * pi * 2);
      drawLitter(c, toss.item.kind, 0);
      c.restore();
    }
    for (final e in _effects) {
      final t = e.time / .65,
          point = Offset.lerp(
            e.position,
            state.position + const Offset(10, -40),
            e.time / .65,
          )!;
      final paint = Paint()..color = e.color.withValues(alpha: 1 - t);
      c.drawCircle(point, 7 * (1 - t), paint);
      for (var i = 0; i < 4; i++) {
        c.drawCircle(
          point + Offset(cos(i * pi / 2) * t * 22, sin(i * pi / 2) * t * 22),
          2,
          paint,
        );
      }
    }
    c.restore();
    // A subtle evening tint reduces glare without obscuring litter or routes.
    if (state.darkMode && !area.night) {
      c.drawRect(
        Offset.zero & Size(size.x, size.y),
        Paint()..color = const Color(0x3213222D),
      );
    }
    _drawMiniMap(c);
    _drawPlayerStatus(c);
  }

  void _drawPlayerStatus(Canvas c) {
    final text = playerStatusText;
    if (text == null) return;
    final label = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFFF8F6ED),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final head =
        viewCenter + (state.position - _camera - const Offset(0, 124)) * zoom;
    final width = label.width + 28, height = 35.0;
    final left = (head.dx - width / 2)
        .clamp(8.0, max(8.0, size.x - width - 8))
        .toDouble();
    final top = (head.dy - height)
        .clamp(12.0, max(12.0, size.y - height - 90))
        .toDouble();
    final rect = Rect.fromLTWH(left, top, width, height);
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(11)),
      Paint()..color = const Color(0xEB214B3D),
    );
    label.paint(c, Offset(left + 14, top + 7));
    final job = displayedJob;
    if (_messageTime <= 0 && job != null) {
      final progress =
          ((state.nowMs - job.startedAt) / (job.readyAt - job.startedAt)).clamp(
            0.0,
            1.0,
          );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left + 10,
            top + height - 5,
            (width - 20) * progress,
            2.5,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFB6DE98),
      );
    }
    label.dispose();
  }

  static void _thiefMarker(Canvas c, Offset p, double radius) {
    c.drawCircle(p, radius + 2, Paint()..color = const Color(0xFFFFF0C7));
    c.drawCircle(p, radius, Paint()..color = const Color(0xFFD36144));
    WorldArt.label(
      c,
      '!',
      p - Offset(0, radius * .92),
      radius * 1.7,
      const Color(0xFFFFFFFF),
    );
  }

  void _drawMiniMap(Canvas c) {
    const width = 96.0, height = 76.0;
    final origin = Offset(size.x - 109, 161);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - 4, origin.dy - 4, width + 8, height + 22),
        const Radius.circular(12),
      ),
      Paint()
        ..color = state.darkMode
            ? const Color(0xEA18251F)
            : const Color(0xEAF8F6ED),
    );
    c.save();
    c.translate(origin.dx, origin.dy);
    final projection = MiniMapProjection(
      area.worldSize,
      const Size(width, height),
    );
    final sx = projection.scale, sy = projection.scale;
    c.save();
    c.translate(projection.offset.dx, projection.offset.dy);
    Rect small(Rect r) =>
        Rect.fromLTRB(r.left * sx, r.top * sy, r.right * sx, r.bottom * sy);
    c.drawPath(
      Path()..addPolygon(
        area.layout.boundaryPoints
            .map((p) => Offset(p.dx * sx, p.dy * sy))
            .toList(),
        true,
      ),
      Paint()..color = area.color.withValues(alpha: .12),
    );
    if (area.layout.garden case final Rect garden) {
      c.drawRect(small(garden), Paint()..color = const Color(0x6687A573));
    }
    for (final road in area.layout.streets) {
      final path = Path()
        ..moveTo(road.points.first.dx * sx, road.points.first.dy * sy);
      for (final p in road.points.skip(1)) {
        path.lineTo(p.dx * sx, p.dy * sy);
      }
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0x448E9385)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    if (area.layout.canal case final Rect canal) {
      c.drawRect(small(canal), Paint()..color = const Color(0xAA589DAD));
      for (final y in area.layout.bridges) {
        c.drawLine(
          Offset((canal.left - 10) * sx, y * sy),
          Offset((canal.right + 10) * sx, y * sy),
          Paint()
            ..color = const Color(0xFFE0C896)
            ..strokeWidth = 2,
        );
      }
    }
    for (var i = 0; i < area.blocks.length; i++) {
      final path = Path();
      if (area.layout.footprints[i] case final List<Offset> points) {
        path.addPolygon(
          points.map((p) => Offset(p.dx * sx, p.dy * sy)).toList(),
          true,
        );
      } else {
        path.addRect(small(area.blocks[i]));
      }
      c.drawPath(path, Paint()..color = area.color.withValues(alpha: .6));
    }
    if (_time - _miniRefresh >= .2 ||
        _miniRefresh < 0 ||
        _miniCount != _litter.length) {
      _miniLitter = projection.litterMarkers(_litter);
      _miniRefresh = _time;
      _miniCount = _litter.length;
    }
    for (final marker in _miniLitter) {
      c.drawCircle(
        marker.point - projection.offset,
        marker.truck ? 1.6 : 1.2,
        Paint()
          ..color = marker.truck
              ? const Color(0xFFE9A340)
              : state.darkMode
              ? const Color(0xFFA3E9C4)
              : const Color(0xFF24785D),
      );
    }
    final viewport =
        small(
          Rect.fromCenter(
            center: _camera,
            width: size.x / zoom,
            height: size.y / zoom,
          ),
        ).intersect(
          Rect.fromLTWH(
            0,
            0,
            area.worldSize.width * sx,
            area.worldSize.height * sy,
          ),
        );
    c.drawRect(
      viewport,
      Paint()
        ..color = const Color(0x88668EA3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    for (final drop in state.album.drops) {
      if (drop.district != state.district) continue;
      final p = Offset(drop.position.dx * sx, drop.position.dy * sy);
      c.drawCircle(p, 2.5, Paint()..color = const Color(0xFF9E65B7));
      c.drawCircle(p, 1.3, Paint()..color = AlbumArt.gold);
    }
    AlbumArt.badge(
      c,
      Offset(area.layout.police.dx * sx, area.layout.police.dy * sy),
      8,
    );
    for (final p in area.stations) {
      c.drawCircle(
        Offset(p.dx * sx, p.dy * sy),
        3.3,
        Paint()..color = const Color(0xFFF8F6ED),
      );
      c.drawCircle(
        Offset(p.dx * sx, p.dy * sy),
        2.4,
        Paint()..color = const Color(0xFF3D8AA5),
      );
    }
    c.drawCircle(
      Offset(state.position.dx * sx, state.position.dy * sy),
      4.2,
      Paint()..color = const Color(0xFFF8F6ED),
    );
    c.drawCircle(
      Offset(state.position.dx * sx, state.position.dy * sy),
      3,
      Paint()..color = const Color(0xFFDB9846),
    );
    if (life?.thief.actor case final t?) {
      if (t.fade == 0) {
        _thiefMarker(c, Offset(t.position.dx * sx, t.position.dy * sy), 5.5);
      }
    }
    if (life?.truck.actor case final truck?) {
      final point = Offset(truck.position.dx * sx, truck.position.dy * sy);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: point, width: 10, height: 7),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF49815A),
      );
      c.drawCircle(
        point + const Offset(-3, 4),
        1.5,
        Paint()..color = const Color(0xFF293E38),
      );
      c.drawCircle(
        point + const Offset(3, 4),
        1.5,
        Paint()..color = const Color(0xFF293E38),
      );
    }
    c.restore();
    c.drawCircle(
      const Offset(10, height + 6),
      2,
      Paint()
        ..color = state.darkMode
            ? const Color(0xFFA3E9C4)
            : const Color(0xFF24785D),
    );
    _text(
      c,
      'Trash',
      const Offset(16, height),
      9,
      state.darkMode ? const Color(0xFFDCE9E0) : const Color(0xFF355E4C),
    );
    AlbumArt.badge(c, const Offset(56, height + 6), 8);
    _text(
      c,
      'Police',
      const Offset(63, height),
      9,
      state.darkMode ? const Color(0xFFDCE9E0) : const Color(0xFF355E4C),
    );
    c.restore();
  }

  void _drawPlayer(Canvas c) {
    final atlas = imageForOutfit(state.outfit);
    if (atlas == null) return;
    PlayerArt.draw(
      c,
      atlas: atlas,
      source: sourceForOutfit(state.outfit, _facing),
      outfit: state.outfit,
      facing: _facing,
      position: state.position,
      gait: gait,
      time: _time,
      lean: _velocity.dx.clamp(-1.0, 1.0),
    );
  }

  void _drawStation(Canvas c, Offset p) {
    c.save();
    c.translate(p.dx, p.dy);
    final event = state.cityEvent;
    if (event != null && event.district == state.district) {
      final color = event.definition.color;
      for (final x in [-88.0, 88.0]) {
        c.drawLine(
          Offset(x, 4),
          Offset(x, -119),
          Paint()
            ..color = const Color(0xFF735F48)
            ..strokeWidth = 3,
        );
        final flag = Path()
          ..moveTo(x, -119)
          ..lineTo(x + 23, -115)
          ..lineTo(x + 18, -97)
          ..lineTo(x, -100)
          ..close();
        c.drawPath(flag, Paint()..color = color);
        _text(
          c,
          event.ready ? '+' : '*',
          Offset(x + 6, -119),
          16,
          Colors.white,
          bold: true,
        );
      }
    }
    c.drawOval(
      const Rect.fromLTWH(-84, -2, 168, 25),
      Paint()..color = const Color(0x302D392D),
    );
    for (var i = 0; i < 3; i++) {
      final x = -66.0 + i * 46;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -52, 42, 60),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF34463D),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 3, -49, 36, 53),
          const Radius.circular(4),
        ),
        Paint()..color = MaterialKind.values[i].color,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 3, -56, 48, 10),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF33463D),
      );
      _text(c, '♻', Offset(x + 8, -39), 25, Colors.white);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-71, -91, 142, 26),
        const Radius.circular(13),
      ),
      Paint()..color = const Color(0xFFFAF9F1),
    );
    _text(
      c,
      'RECYCLE HERE',
      const Offset(-49, -86),
      12,
      const Color(0xFF365A48),
      bold: true,
    );
    if (state.jobs.containsKey(state.district)) {
      final pulse = 5 + sin(_time * 4) * 2;
      c.drawCircle(
        const Offset(61, -78),
        pulse,
        Paint()..color = const Color(0xFFE5AC53),
      );
    }
    c.restore();
  }

  @override
  void onRemove() {
    art?.dispose();
    art = null;
    nearStation.dispose();
    nearPolice.dispose();
    sceneReady.dispose();
    super.onRemove();
  }

  static void drawLitter(Canvas c, MaterialKind kind, double time) {
    c.drawOval(
      const Rect.fromLTWH(-11, 1, 24, 8),
      Paint()..color = const Color(0x252F3C32),
    );
    c.save();
    c.rotate(kind.index == 0 ? -.4 : .25);
    final outline = Paint()
      ..color = const Color(0xFF395045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fill = Paint()..color = kind.color;
    if (kind == MaterialKind.bottle) {
      final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -20, 14, 26),
        const Radius.circular(4),
      );
      c.drawRRect(body, fill);
      c.drawRRect(body, outline);
      c.drawRect(
        const Rect.fromLTWH(-4, -25, 8, 6),
        Paint()..color = const Color(0xFF387B70),
      );
      c.drawRect(
        const Rect.fromLTWH(-6, -10, 12, 8),
        Paint()..color = const Color(0xFFDAEDDC),
      );
      c.drawLine(
        const Offset(-3, -17),
        const Offset(-3, -12),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    } else if (kind == MaterialKind.can) {
      final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -17, 18, 24),
        const Radius.circular(4),
      );
      c.drawRRect(body, fill);
      c.drawRRect(body, outline);
      c.drawOval(
        const Rect.fromLTWH(-9, -19, 18, 6),
        Paint()..color = const Color(0xFFE8E7D8),
      );
      c.drawLine(
        const Offset(-5, -11),
        const Offset(4, -8),
        Paint()
          ..color = const Color(0xFFFFF5CA)
          ..strokeWidth = 3,
      );
    } else {
      c.drawRect(const Rect.fromLTWH(-13, -13, 26, 18), fill);
      c.drawRect(const Rect.fromLTWH(-13, -13, 26, 18), outline);
      c.drawRect(
        const Rect.fromLTWH(-3, -13, 6, 18),
        Paint()..color = const Color(0xFFE4C697),
      );
    }
    c.restore();
    if (sin(time * 1.6) > .92) {
      c.drawLine(
        const Offset(13, -20),
        const Offset(13, -12),
        Paint()
          ..color = const Color(0xFFFAFFF4)
          ..strokeWidth = 2,
      );
      c.drawLine(
        const Offset(9, -16),
        const Offset(17, -16),
        Paint()
          ..color = const Color(0xFFFAFFF4)
          ..strokeWidth = 2,
      );
    }
  }

  static final Map<String, TextPainter> _textCache = {};

  static void _text(
    Canvas c,
    String text,
    Offset p,
    double size,
    Color color, {
    bool bold = false,
  }) {
    final key = '$text:$size:$color:$bold';
    final painter = _textCache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: size,
            color: color,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    painter.paint(c, p);
  }
}

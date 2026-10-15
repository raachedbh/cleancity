import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/catalog.dart';
import '../game/recycling_game.dart';
import '../game/sound.dart';
import '../state/game_state.dart';
import 'joystick.dart';
import 'panels.dart';
import 'theme.dart';
import 'brand_mark.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.state});
  final GameState state;
  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final RecyclingGame game;
  late final GameSound sounds;
  late final JoystickInput joystick;
  final focus = FocusNode();
  Timer? noticeTimer, clockTimer;
  String? notice;
  bool panelOpen = false, foreground = true;
  GameState get state => widget.state;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sounds = GameSound();
    game = RecyclingGame(state, sounds, onNotice: showNotice);
    joystick = JoystickInput(game.setInput, onAutoMove: game.startAutoMove);
    game.onAutoMoveBlocked = joystick.reset;
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !foreground) return;
      state.tick(attendance: true);
      _drainEvents();
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      state.tick(attendance: true);
      if (!state.introduced) openPanel('welcome');
      if (state.recoveredSave) {
        showNotice(
          'Your previous save could not be read. A fresh start is ready.',
        );
      }
      _drainEvents();
    });
  }

  void _drainEvents() {
    if (panelOpen) return;
    state.cityAlerts.removeWhere((a) => a.district != state.district);
    if (notice != null) return;
    if (state.cityAlerts.isNotEmpty) {
      showNotice(
        state.cityAlerts.removeAt(0).text,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    if (state.events.isEmpty) return;
    final messages = state.events.toList();
    state.events.clear();
    reward(
      messages.length <= 2
          ? messages.join('\n')
          : '${messages.last}\n${messages.length - 1} more rewards added.',
    );
  }

  void showNotice(
    String text, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    noticeTimer?.cancel();
    setState(() => notice = text);
    noticeTimer = Timer(duration, () {
      if (mounted) setState(() => notice = null);
    });
  }

  void reward(String text) {
    sounds.play('reward', enabled: state.sound);
    if (state.haptics) unawaited(HapticFeedback.lightImpact());
    showNotice(text);
  }

  Future<void> openPanel(String page) async {
    if (panelOpen || !mounted) return;
    setState(() => panelOpen = true);
    joystick.reset();
    game.clearInput();
    game.pauseEngine();
    unawaited(state.save());
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => ListenableBuilder(
          listenable: state,
          builder: (context, _) => Theme(
            data: state.darkMode ? darkGameTheme : gameTheme,
            child: Material(
              color: UiColors(state.darkMode).paper,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * .91,
                child: StatefulBuilder(
                  builder: (context, setSheetState) => _TimedPanel(
                    page: page,
                    state: state,
                    game: game,
                    onReward: reward,
                    onTravel: (id) async {
                      if (!state.travel(id)) return;
                      await game.loadDistrict();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      showNotice('Welcome to ${districts[id].name}');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Every normal dismissal finishes the first-launch guide, including
      // Close, Back, barrier taps and swipe-down, so it never repeats.
      if (page == 'welcome' && !state.introduced) state.completeIntro();
    } finally {
      panelOpen = false;
      if (mounted) {
        if (foreground) {
          game.resumeEngine();
          focus.requestFocus();
        }
        setState(() {});
        _drainEvents();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) {
      joystick.reset();
      game.clearInput();
      game.pauseEngine();
      unawaited(this.state.save());
    } else {
      this.state.tick(attendance: true);
      if (!panelOpen) game.resumeEngine();
      _drainEvents();
    }
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (panelOpen) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    double axis(
      LogicalKeyboardKey plus,
      LogicalKeyboardKey plus2,
      LogicalKeyboardKey minus,
      LogicalKeyboardKey minus2,
    ) =>
        (keys.contains(plus) || keys.contains(plus2) ? 1.0 : 0.0) -
        (keys.contains(minus) || keys.contains(minus2) ? 1.0 : 0.0);
    final movement = {
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyS,
    };
    if (!movement.contains(event.logicalKey)) return KeyEventResult.ignored;
    game.setInput(
      Offset(
        axis(
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.keyD,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.keyA,
        ),
        axis(
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.keyS,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.keyW,
        ),
      ),
    );
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    noticeTimer?.cancel();
    clockTimer?.cancel();
    focus.dispose();
    joystick.reset();
    joystick.dispose();
    game.clearInput();
    game.pauseEngine();
    unawaited(state.save());
    unawaited(sounds.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Focus(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: onKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ListenableBuilder(
            listenable: state,
            builder: (context, _) => FloatingMovementJoystick(
              key: const ValueKey('game-world'),
              input: joystick,
              position: state.joystickPosition,
              enabled: foreground && !panelOpen && game.sceneReady.value,
              onFocus: focus.requestFocus,
              child: GameWidget(
                game: game,
                loadingBuilder: (_) => Center(
                  child: CircularProgressIndicator(color: context.ui.green),
                ),
                errorBuilder: (_, error) => const Center(
                  child: Text(
                    'The city could not load. Please reopen CleanCity.',
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: state.hudVisible ? _header() : _collapsedHeader(),
                  ),
                  Positioned(
                    top: state.hudVisible ? 106 : 64,
                    left: 14,
                    child: Row(
                      children: [
                        Badge(
                          isLabelVisible: state.album.carried > 0,
                          label: Text('${state.album.carried}'),
                          child: _roundAction(
                            'Album',
                            Icons.menu_book_rounded,
                            'album',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _roundAction(
                          'Ranking',
                          Icons.emoji_events_outlined,
                          'ranking',
                        ),
                        const SizedBox(width: 8),
                        _roundAction(
                          'Daily gifts',
                          Icons.card_giftcard_outlined,
                          'daily',
                        ),
                        const SizedBox(width: 8),
                        _roundAction(
                          'Restore your city',
                          Icons.local_florist_outlined,
                          'projects',
                        ),
                        const SizedBox(width: 8),
                        Badge(
                          isLabelVisible: state.cityEvent != null,
                          backgroundColor: state.cityEvent?.ready == true
                              ? green
                              : amber,
                          child: _roundAction(
                            'Events',
                            Icons.celebration_outlined,
                            'events',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.saveFailed)
                    Positioned(
                      top: state.hudVisible ? 212 : 170,
                      left: 14,
                      right: 14,
                      child: Material(
                        color: context.ui.paper,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          dense: true,
                          title: const Text('Progress could not be saved.'),
                          trailing: TextButton(
                            onPressed: state.save,
                            child: const Text('Retry'),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: state.joystickPosition == JoystickPosition.center
                        ? 207
                        : 97,
                    left: state.joystickPosition == JoystickPosition.right
                        ? 16
                        : null,
                    right: state.joystickPosition == JoystickPosition.right
                        ? null
                        : 16,
                    child: _actions(),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: _navigation(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _collapsedHeader() => Row(
    children: [
      if (notice != null)
        Expanded(
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.ui.paper.withValues(alpha: .84),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  notice!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        )
      else
        const Spacer(),
      const SizedBox(width: 8),
      Material(
        color: context.ui.paper.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('show-hud'),
              tooltip: 'Show top bar',
              onPressed: () => state.setHudVisible(true),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            IconButton(
              key: const ValueKey('settings-button'),
              tooltip: 'Settings',
              onPressed: () => openPanel('settings'),
              icon: const Icon(Icons.tune_rounded, size: 20),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _header() => Container(
    key: const ValueKey('top-hud'),
    padding: const EdgeInsets.fromLTRB(10, 4, 5, 6),
    decoration: BoxDecoration(
      color: context.ui.paper.withValues(alpha: state.hudOpacity),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.ui.ink.withValues(alpha: .12)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14273C2D),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const BrandMark(size: 25),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                state.testMode ? 'CleanCity TEST' : 'CleanCity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: state.testMode ? 12 : 15,
                  fontWeight: FontWeight.w900,
                  color: context.ui.green,
                ),
              ),
            ),
            CoinPill(state.coins, small: true, opacity: .6),
            const SizedBox(width: 5),
            InkWell(
              onTap: () => openPanel('shop'),
              borderRadius: BorderRadius.circular(30),
              child: GemPill(state.gems, opacity: .6),
            ),
            SizedBox(
              width: 34,
              height: 34,
              child: IconButton(
                key: const ValueKey('settings-button'),
                padding: EdgeInsets.zero,
                tooltip: 'Settings',
                onPressed: () => openPanel('settings'),
                icon: const Icon(Icons.tune_rounded, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 24,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    liveRegion: notice != null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        notice ?? districts[state.district].name,
                        key: ValueKey(notice ?? 'district-name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: notice == null ? 16 : 12,
                          fontWeight: FontWeight.w900,
                          color: notice == 'Bag full'
                              ? (context.ui.dark
                                    ? amber
                                    : const Color(0xFF996420))
                              : context.ui.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              key: const ValueKey('level-button'),
              onTap: () => openPanel('levels'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.ui.tint(const Color(0xFFE5EDDE)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'LV ${state.level}',
                  style: TextStyle(
                    color: context.ui.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              height: 26,
              child: IconButton(
                key: const ValueKey('hide-hud'),
                tooltip: 'Hide top bar',
                padding: EdgeInsets.zero,
                onPressed: () => state.setHudVisible(false),
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(Icons.backpack_outlined, size: 14, color: context.ui.green),
            const SizedBox(width: 4),
            Text(
              '${state.bag.length}/${state.capacity}',
              key: const ValueKey('bag-count'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.levelProgress,
                  minHeight: 5,
                  backgroundColor: context.ui.line,
                  color: context.ui.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.cityEvent?.joined == true
                  ? 'Event ${state.cityEvent!.progress}/${state.cityEvent!.definition.target}'
                  : '${state.removed[state.district].length}/${state.cleanupTarget} clean',
              style: TextStyle(fontSize: 10, color: context.ui.muted),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ],
    ),
  );
  Widget _roundAction(String label, IconData icon, String page) => Material(
    color: context.ui.paper.withValues(alpha: .55),
    shape: const CircleBorder(),
    elevation: 1,
    child: IconButton(
      key: ValueKey('action-$page'),
      tooltip: label,
      onPressed: () => openPanel(page),
      icon: Icon(icon, color: context.ui.green, size: 22),
    ),
  );
  void recycleAction() {
    if (!state.nearStation) {
      joystick.reset();
      game.goToStation();
    } else if (state.jobs.containsKey(state.district)) {
      return;
    } else if (state.canRenew) {
      if (state.nextCleanup()) {
        game.refreshLitter();
        game.showPlayerMessage('New cleanup');
      }
    } else if (state.bag.isEmpty) {
      game.showPlayerMessage('Bag empty');
    } else if (state.startRecycling()) {
      game.showRecyclingTimer();
      sounds.play('recycle', enabled: state.sound);
    }
  }

  Widget _actions() => Column(
    crossAxisAlignment: state.joystickPosition == JoystickPosition.right
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end,
    children: [
      if (state.album.carried > 0) ...[
        ValueListenableBuilder<bool>(
          valueListenable: game.nearPolice,
          builder: (context, near, _) => FilledButton.icon(
            key: const ValueKey('police-action'),
            style: FilledButton.styleFrom(
              backgroundColor: context.ui.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              joystick.reset();
              if (state.nearPolice) {
                state.returnValuables();
              } else {
                game.goToPolice();
              }
            },
            icon: const Icon(Icons.local_police_outlined, size: 18),
            label: Text(
              near
                  ? 'Return +${state.album.returnReward}'
                  : 'To police (${state.album.carried})',
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      FilledButton.icon(
        key: const ValueKey('magnet-action'),
        style: FilledButton.styleFrom(
          backgroundColor: state.magnetActive
              ? purple
              : context.ui.tint(const Color(0xFFF0E9F7)),
          foregroundColor: state.magnetActive
              ? Colors.white
              : context.ui.purple,
          disabledBackgroundColor: state.magnetActive
              ? purple
              : context.ui.tint(const Color(0xFFE9E2F0)),
          disabledForegroundColor: state.magnetActive
              ? Colors.white
              : context.ui.muted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
        onPressed: !state.magnetUnlocked
            ? () => openPanel('levels')
            : state.magnetCooldown == 0
            ? () {
                if (state.activateMagnet()) {
                  reward('Magnet on! 15 seconds of long-range collecting.');
                }
              }
            : null,
        icon: const Icon(Icons.flash_on_rounded, size: 18),
        label: Text(
          !state.magnetUnlocked
              ? 'Magnet · Lv 5'
              : state.magnetActive
              ? 'Magnet ${state.magnetSeconds}s'
              : state.magnetCooldown > 0
              ? 'Recharge ${state.magnetCooldown}s'
              : 'Magnet · 15s',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      const SizedBox(height: 8),
      ValueListenableBuilder<bool>(
        valueListenable: game.nearStation,
        builder: (context, near, _) => FilledButton.icon(
          key: const ValueKey('station-action'),
          style: FilledButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          ),
          onPressed: near && state.jobs.containsKey(state.district)
              ? null
              : recycleAction,
          icon: Icon(
            near ? Icons.recycling_rounded : Icons.near_me_outlined,
            size: 20,
          ),
          label: Text(
            !near
                ? 'To station'
                : state.jobs.containsKey(state.district)
                ? 'Recycling'
                : state.canRenew
                ? 'New cleanup'
                : 'Recycle',
          ),
        ),
      ),
    ],
  );
  Widget _navigation() => Container(
    padding: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      color: context.ui.paper.withValues(alpha: state.hudOpacity),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: context.ui.ink.withValues(alpha: .12)),
      boxShadow: const [BoxShadow(color: Color(0x16273C2D), blurRadius: 12)],
    ),
    child: Row(
      children: [
        _nav('Maps', Icons.map_outlined, 'town'),
        _nav('Gear', Icons.backpack_outlined, 'gear'),
        _nav('Style', Icons.checkroom_outlined, 'style'),
        _nav(
          'Goals',
          Icons.flag_outlined,
          'goals',
          badge: state.readyMissions > 0,
        ),
        _nav('Shop', Icons.diamond_outlined, 'shop'),
      ],
    ),
  );
  Widget _nav(String label, IconData icon, String page, {bool badge = false}) =>
      Expanded(
        child: InkWell(
          key: ValueKey('nav-$page'),
          onTap: () => openPanel(page),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: badge,
                  smallSize: 7,
                  backgroundColor: amber,
                  child: Icon(icon, color: context.ui.ink, size: 21),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.ui.ink,
                    shadows: [
                      Shadow(
                        color: context.ui.paper.withValues(alpha: .9),
                        blurRadius: 3,
                      ),
                    ],
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Keeps countdowns live inside the modal without restarting its selected tab.
class _TimedPanel extends StatefulWidget {
  const _TimedPanel({
    required this.page,
    required this.state,
    required this.game,
    required this.onReward,
    required this.onTravel,
  });
  final String page;
  final GameState state;
  final RecyclingGame game;
  final ValueChanged<String> onReward;
  final Future<void> Function(int) onTravel;
  @override
  State<_TimedPanel> createState() => _TimedPanelState();
}

class _TimedPanelState extends State<_TimedPanel> {
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GamePanel(
    page: widget.page,
    state: widget.state,
    game: widget.game,
    onReward: widget.onReward,
    onTravel: widget.onTravel,
  );
}

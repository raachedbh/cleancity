import 'package:flutter/material.dart';
import '../state/game_state.dart';
import 'theme.dart';

/// Owns one touch at a time; buttons and other fingers cannot redirect a drag.
class JoystickInput extends ChangeNotifier {
  JoystickInput(this.onChanged, {this.onAutoMove});
  final ValueChanged<Offset> onChanged;
  final ValueChanged<Offset>? onAutoMove;
  int? pointer;
  Offset? origin;
  Offset offset = Offset.zero;
  Offset autoDirection = Offset.zero;
  bool get autoMoving => autoDirection != Offset.zero;
  Offset? _downPoint, _edgeDirection, _lastEdgeDirection, _lastTapPoint;
  Duration _downTime = Duration.zero;
  Duration? _lastTapTime;
  bool _dragged = false;

  void begin(
    int id,
    Offset point, {
    Offset? padCenter,
    Duration timeStamp = Duration.zero,
  }) {
    if (pointer != null) return;
    final wasAuto = autoMoving;
    if (wasAuto) _clearTap();
    autoDirection = Offset.zero;
    pointer = id;
    _downPoint = point;
    _downTime = timeStamp;
    _dragged = false;
    final edge = point - (padCenter ?? point);
    _edgeDirection = !wasAuto && edge.distance >= 24 && edge.distance <= 56
        ? edge / edge.distance
        : null;
    origin = _edgeDirection == null ? point : padCenter;
    offset = Offset.zero;
    onChanged(Offset.zero);
    notifyListeners();
  }

  void move(int id, Offset point) {
    if (id != pointer || origin == null) return;
    final delta = point - origin!;
    if ((point - _downPoint!).distance > 10) _dragged = true;
    offset = delta.distance > 33 ? delta / delta.distance * 33 : delta;
    onChanged(offset.distance < 5 ? Offset.zero : offset / 33);
    notifyListeners();
  }

  void end(int id, {Duration timeStamp = Duration.zero}) {
    if (id != pointer) return;
    final edge = _edgeDirection;
    final isTap =
        !_dragged &&
        edge != null &&
        timeStamp - _downTime <= const Duration(milliseconds: 250);
    final isDouble =
        isTap &&
        _lastTapTime != null &&
        timeStamp - _lastTapTime! <= const Duration(milliseconds: 350) &&
        (_downPoint! - _lastTapPoint!).distance < 25 &&
        edge.dx * _lastEdgeDirection!.dx + edge.dy * _lastEdgeDirection!.dy >
            .85;
    if (isTap && !isDouble) {
      _lastTapTime = timeStamp;
      _lastTapPoint = _downPoint;
      _lastEdgeDirection = edge;
    } else {
      _clearTap();
    }
    pointer = null;
    origin = null;
    autoDirection = isDouble ? edge : Offset.zero;
    offset = autoDirection * 33;
    if (isDouble && onAutoMove != null) {
      onAutoMove!(autoDirection);
    } else {
      onChanged(autoDirection);
    }
    notifyListeners();
  }

  void cancel(int id) {
    if (id == pointer) reset();
  }

  void _clearTap() {
    _lastTapTime = null;
    _lastTapPoint = null;
    _lastEdgeDirection = null;
  }

  void reset() {
    pointer = null;
    origin = null;
    offset = Offset.zero;
    autoDirection = Offset.zero;
    _clearTap();
    onChanged(Offset.zero);
    notifyListeners();
  }
}

class FloatingMovementJoystick extends StatelessWidget {
  const FloatingMovementJoystick({
    super.key,
    required this.input,
    required this.position,
    required this.enabled,
    required this.onFocus,
    required this.child,
  });
  final JoystickInput input;
  final JoystickPosition position;
  final bool enabled;
  final VoidCallback onFocus;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final padding = MediaQuery.paddingOf(context);
      final home = Offset(switch (position) {
        JoystickPosition.left => 69 + padding.left,
        JoystickPosition.center => bounds.maxWidth / 2,
        JoystickPosition.right => bounds.maxWidth - 69 - padding.right,
      }, bounds.maxHeight - padding.bottom - 142);
      Offset padCenter() {
        final raw = input.origin ?? home;
        return Offset(
          raw.dx.clamp(53, bounds.maxWidth - 53),
          raw.dy.clamp(53, bounds.maxHeight - 53),
        );
      }

      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (enabled && e.buttons == 1) {
            input.begin(
              e.pointer,
              e.localPosition,
              padCenter: padCenter(),
              timeStamp: e.timeStamp,
            );
            onFocus();
          }
        },
        onPointerMove: (e) {
          if (enabled) input.move(e.pointer, e.localPosition);
        },
        onPointerUp: (e) => input.end(e.pointer, timeStamp: e.timeStamp),
        onPointerCancel: (e) => input.cancel(e.pointer),
        child: ListenableBuilder(
          listenable: input,
          child: child,
          builder: (context, world) {
            final center = padCenter();
            return Stack(
              fit: StackFit.expand,
              children: [
                world!,
                Positioned(
                  left: center.dx - 53,
                  top: center.dy - 53,
                  child: IgnorePointer(
                    child: Semantics(
                      label: input.autoMoving
                          ? 'Auto-walk. Touch the map to stop.'
                          : 'Drag to walk. Double-tap an edge to auto-walk.',
                      child: Opacity(
                        opacity: input.origin == null && !input.autoMoving
                            ? .65
                            : 1,
                        child: JoystickPad(
                          offset: input.offset,
                          autoMoving: input.autoMoving,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

class JoystickPad extends StatelessWidget {
  const JoystickPad({super.key, required this.offset, this.autoMoving = false});
  final Offset offset;
  final bool autoMoving;
  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('movement-joystick'),
    width: 106,
    height: 106,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.ui.paper.withValues(alpha: .7),
            border: Border.all(
              color: Colors.white.withValues(alpha: .9),
              width: 2,
            ),
          ),
        ),
        Positioned(
          top: 9,
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 17,
            color: context.ui.muted,
          ),
        ),
        Positioned(
          bottom: 9,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 17,
            color: context.ui.muted,
          ),
        ),
        Positioned(
          left: 9,
          child: Icon(
            Icons.keyboard_arrow_left_rounded,
            size: 17,
            color: context.ui.muted,
          ),
        ),
        Positioned(
          right: 9,
          child: Icon(
            Icons.keyboard_arrow_right_rounded,
            size: 17,
            color: context.ui.muted,
          ),
        ),
        Transform.translate(
          offset: offset,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withValues(alpha: .92),
              border: Border.all(color: const Color(0xFFDDEDD9), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30223B2B),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              autoMoving ? Icons.double_arrow_rounded : Icons.open_with_rounded,
              color: const Color(0xFFD8E6D7),
              size: 18,
            ),
          ),
        ),
      ],
    ),
  );
}

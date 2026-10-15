import 'package:flutter/material.dart';

const ink = Color(0xFF243F35);
const green = Color(0xFF387C5B);
const paper = Color(0xFFF8F6ED);
const muted = Color(0xFF7A897B);
const line = Color(0xFFE5E8DA);
const amber = Color(0xFFEAB65E);
const purple = Color(0xFF7860A4);

/// Theme-aware surface and text colors. World art retains its own city palette.
class UiColors {
  const UiColors(this.dark);
  final bool dark;
  Color get ink => dark ? const Color(0xFFE6F0E9) : const Color(0xFF243F35);
  Color get green => dark ? const Color(0xFF9ED5B4) : const Color(0xFF387C5B);
  Color get paper => dark ? const Color(0xFF18251F) : const Color(0xFFF8F6ED);
  Color get muted => dark ? const Color(0xFFAFBEB4) : const Color(0xFF647467);
  Color get line => dark ? const Color(0xFF3D5146) : const Color(0xFFE5E8DA);
  Color get purple => dark ? const Color(0xFFCEB5F3) : const Color(0xFF7860A4);
  Color get card => dark ? const Color(0xFF23352B) : Colors.white;
  Color tint(Color color) =>
      dark ? Color.alphaBlend(color.withValues(alpha: .12), card) : color;
}

extension GameColors on BuildContext {
  UiColors get ui => Theme.of(this).brightness == Brightness.dark
      ? const UiColors(true)
      : const UiColors(false);
}

String compactAmount(int amount) => amount < 10000
    ? '$amount'
    : amount < 1000000
    ? '${(amount / 1000).toStringAsFixed(1)}k'
    : '${(amount / 1000000).toStringAsFixed(1)}m';

class GemPill extends StatelessWidget {
  const GemPill(this.amount, {super.key, this.opacity = 1});
  final double opacity;
  final int amount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: context.ui
          .tint(const Color(0xFFEDE5F8))
          .withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: context.ui.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.diamond_rounded, color: context.ui.purple, size: 16),
        const SizedBox(width: 4),
        Text(
          compactAmount(amount),
          style: TextStyle(
            color: context.ui.purple,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

final gameTheme = buildGameTheme(false);
final darkGameTheme = buildGameTheme(true);

ThemeData buildGameTheme(bool dark) {
  final colors = UiColors(dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: colors.paper,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: scheme.brightness,
    scaffoldBackgroundColor: colors.paper,
    colorScheme: scheme,
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: colors.ink,
        height: 1.12,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w900,
        color: colors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: colors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colors.muted,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? const Color(0xFF366B50) : green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: colors.ink),
    ),
    dividerTheme: DividerThemeData(color: colors.line),
  );
}

class CoinPill extends StatelessWidget {
  const CoinPill(
    this.amount, {
    super.key,
    this.small = false,
    this.opacity = 1,
  });
  final double opacity;
  final int amount;
  final bool small;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: small ? 9 : 13,
      vertical: small ? 5 : 8,
    ),
    decoration: BoxDecoration(
      color: context.ui
          .tint(const Color(0xFFFFEDC9))
          .withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: context.ui.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.toll_rounded,
          size: small ? 16 : 19,
          color: const Color(0xFFB68329),
        ),
        const SizedBox(width: 5),
        Text(
          compactAmount(amount),
          style: TextStyle(
            fontSize: small ? 12 : 15,
            fontWeight: FontWeight.w900,
            color: context.ui.dark ? amber : const Color(0xFF886221),
          ),
        ),
      ],
    ),
  );
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color == null ? context.ui.card : context.ui.tint(color!),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.ui.line),
    ),
    child: child,
  );
}

class PanelLayout extends StatelessWidget {
  const PanelLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });
  final String title, subtitle;
  final List<Widget> children;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 10),
      Container(
        width: 34,
        height: 4,
        decoration: BoxDecoration(
          color: context.ui.line,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            ?trailing,
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
      if (subtitle.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: subtitle.isEmpty
                ? const SizedBox.shrink()
                : Text(subtitle, style: TextStyle(color: context.ui.muted)),
          ),
        ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            for (final child in children) ...[
              child,
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    ],
  );
}

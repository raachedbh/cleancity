import 'package:flutter/material.dart';
import 'brand_mark.dart';
import 'theme.dart';

/// A short, scrollable first-launch overview for normal and test games.
/// The game screen persists dismissal through every exit route.
class QuickStartGuide extends StatelessWidget {
  const QuickStartGuide({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => PanelLayout(
    title: 'Quick start',
    subtitle: '',
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 48),
          const SizedBox(width: 10),
          Text(
            'CleanCity',
            style: TextStyle(
              color: context.ui.green,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      SoftCard(
        child: Column(
          children: [
            _tip(
              context,
              Icons.touch_app_outlined,
              'Move & collect',
              'Drag on the map to walk. Litter collects automatically.',
            ),
            _tip(
              context,
              Icons.recycling_rounded,
              'Recycle & earn',
              'Tap To station, then Recycle. Coins arrive when the timer ends.',
            ),
            _tip(
              context,
              Icons.storefront_outlined,
              'Upgrade & explore',
              'Use Gear, Style and Maps for upgrades, outfits and new cities.',
            ),
            _tip(
              context,
              Icons.card_giftcard_outlined,
              'Rewards & powers',
              'Check Goals and daily gifts. Unlock the magnet at level 5.',
            ),
            _tip(
              context,
              Icons.menu_book_rounded,
              'Album & police',
              'Catch thieves. Collect their valuables and return them to police.',
              last: true,
            ),
          ],
        ),
      ),
      FilledButton(
        key: const ValueKey('start-game'),
        onPressed: onStart,
        child: const Text('Start cleaning'),
      ),
    ],
  );

  Widget _tip(
    BuildContext context,
    IconData icon,
    String title,
    String text, {
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.ui.green.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: context.ui.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: context.ui.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import '../data/album.dart';
import '../game/album_art.dart';
import '../game/recycling_game.dart';
import '../state/game_state.dart';
import 'theme.dart';

class AlbumPanel extends StatefulWidget {
  const AlbumPanel({super.key, required this.state, required this.game});
  final GameState state;
  final RecyclingGame game;
  @override
  State<AlbumPanel> createState() => _AlbumPanelState();
}

class _AlbumPanelState extends State<AlbumPanel> {
  bool progress = false;
  GameState get s => widget.state;
  IconData icon(AlbumMetric metric) => switch (metric) {
    AlbumMetric.collected => Icons.eco_outlined,
    AlbumMetric.recycled => Icons.park_rounded,
    AlbumMetric.thieves => Icons.shield_outlined,
    AlbumMetric.returned => Icons.handshake_outlined,
    AlbumMetric.cities => Icons.public_rounded,
  };
  String metricLabel(AlbumMetric metric) => switch (metric) {
    AlbumMetric.collected => 'Collected',
    AlbumMetric.recycled => 'Recycled',
    AlbumMetric.thieves => 'Thieves caught',
    AlbumMetric.returned => 'Returned',
    AlbumMetric.cities => 'Cities unlocked',
  };
  @override
  Widget build(BuildContext context) => PanelLayout(
    title: 'Album',
    subtitle: '',
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.diamond_outlined),
            label: Text('Rewards'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.auto_awesome_outlined),
            label: Text('Progress'),
          ),
        ],
        selected: {progress},
        onSelectionChanged: (v) => setState(() => progress = v.first),
      ),
      if (!progress) ...[
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.local_police_outlined, color: context.ui.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${s.album.carried} to return',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    '+${s.album.returnReward} coins',
                    style: TextStyle(
                      color: context.ui.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Catch thieves. Collect valuables. Return to police.',
                style: TextStyle(color: context.ui.muted, fontSize: 12),
              ),
              if (s.album.carried > 0) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('album-return'),
                  onPressed: () {
                    Navigator.pop(context);
                    if (s.nearPolice) {
                      s.returnValuables();
                    } else {
                      widget.game.goToPolice();
                    }
                  },
                  icon: Icon(
                    s.nearPolice
                        ? Icons.handshake_outlined
                        : Icons.near_me_outlined,
                  ),
                  label: Text(s.nearPolice ? 'Return valuables' : 'To police'),
                ),
              ],
            ],
          ),
        ),
        for (final kind in ValuableKind.values)
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 82,
                  decoration: BoxDecoration(
                    color: context.ui.purple.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: CustomPaint(painter: _ValuablePainter(kind)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${albumNumber(s.album.found[kind.index])} recovered',
                        style: TextStyle(
                          color: context.ui.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${s.album.held(kind)} held · ${albumNumber(s.album.returned[kind.index])} returned',
                        style: TextStyle(color: context.ui.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ] else ...[
        SoftCard(
          child: Column(
            children: [
              for (final metric in AlbumMetric.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Icon(icon(metric), size: 20, color: context.ui.green),
                      const SizedBox(width: 10),
                      Expanded(child: Text(metricLabel(metric))),
                      Text(
                        albumNumber(s.albumMetric(metric)),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Text(
          'Souvenirs · ${s.album.earned.length}/${souvenirs.length}',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        for (final souvenir in souvenirs) _souvenir(souvenir),
      ],
    ],
  );

  Widget _souvenir(Souvenir souvenir) {
    final earned = s.album.earned.contains(souvenir.id);
    final value = s.albumMetric(souvenir.metric);
    final gold = context.ui.dark
        ? const Color(0xFFF1D18A)
        : const Color(0xFF8D6729);
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 55,
            height: 62,
            decoration: BoxDecoration(
              color: (earned ? gold : context.ui.muted).withValues(alpha: .1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(26),
              ),
              border: Border.all(
                color: (earned ? gold : context.ui.muted).withValues(alpha: .3),
              ),
            ),
            child: Icon(
              earned
                  ? (souvenir.id == 'recycled100000'
                        ? Icons.location_city_rounded
                        : icon(souvenir.metric))
                  : Icons.lock_outline_rounded,
              color: earned ? gold : context.ui.muted,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  souvenir.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${albumNumber(souvenir.target)} ${metricLabel(souvenir.metric).toLowerCase()}',
                  style: TextStyle(color: context.ui.muted, fontSize: 12),
                ),
                const SizedBox(height: 7),
                if (earned)
                  Text(
                    'Collected',
                    style: TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else ...[
                  LinearProgressIndicator(
                    value: (value / souvenir.target).clamp(0.0, 1.0),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${albumNumber(value)} / ${albumNumber(souvenir.target)}',
                    style: TextStyle(color: context.ui.muted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuablePainter extends CustomPainter {
  const _ValuablePainter(this.kind);
  final ValuableKind kind;
  @override
  void paint(Canvas canvas, Size size) =>
      AlbumArt.valuable(canvas, kind, size.center(Offset.zero));
  @override
  bool shouldRepaint(_ValuablePainter oldDelegate) => oldDelegate.kind != kind;
}

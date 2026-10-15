import 'quick_start_guide.dart';
import 'album_panel.dart';
import '../data/city_events.dart';
import '../data/cleanup_ranks.dart';
import 'package:flutter/material.dart';
import '../data/catalog.dart';
import '../state/game_state.dart';
import '../game/recycling_game.dart';
import 'character_preview.dart';
import 'theme.dart';

class GamePanel extends StatefulWidget {
  const GamePanel({
    super.key,
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
  State<GamePanel> createState() => _GamePanelState();
}

class _GamePanelState extends State<GamePanel> {
  GoalPeriod goalPeriod = GoalPeriod.daily;
  GameState get s => widget.state;
  RecyclingGame get game => widget.game;
  Future<bool> confirmGems(String title, int price, String detail) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(
            '$detail\n\nSpend $price gems? Your balance: ${s.gems}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep exploring'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Use $price gems'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([s, game.sceneReady]),
    builder: (context, _) => switch (widget.page) {
      'album' => AlbumPanel(state: s, game: game),
      'town' => _town(),
      'gear' => _gear(),
      'style' => _style(),
      'goals' => _goals(),
      'projects' => _projects(),
      'settings' => _settings(),
      'daily' => _daily(),
      'events' => _cityEvents(),
      'levels' => _levels(),
      'ranking' => _ranking(),
      'shop' => _shop(),
      _ => _welcome(),
    },
  );
  Widget _intro(
    String eyebrow,
    String text, {
    Color color = green,
    IconData icon = Icons.eco_rounded,
  }) => SoftCard(
    color: color.withValues(alpha: .08),
    child: Row(
      children: [
        Icon(
          icon,
          color: context.ui.dark ? Color.lerp(color, Colors.white, .5) : color,
          size: 32,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: context.ui.dark
                      ? Color.lerp(color, Colors.white, .5)
                      : color,
                  fontSize: 12,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(text),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _town() => PanelLayout(
    title: 'Maps',
    subtitle: '+20 litter at local midnight, up to each map\'s limit.',
    children: [
      for (final d in districts)
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: SizedBox(
                  height: 150,
                  child: CustomPaint(painter: _CityPreview(d)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.country,
                      style: TextStyle(
                        fontSize: 10,
                        color: d.color,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (d.premium)
                          Icon(
                            Icons.diamond_outlined,
                            color: context.ui.purple,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _tag('${d.maximumLitterCount} litter max'),
                        _tag(
                          '${d.earningMultiplier.toStringAsFixed(2)}× recycling',
                        ),
                      ],
                    ),
                    if (d.id > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Unlock gift: ${d.unlockBonus} coins${d.bonusOutfit == null ? '' : ' + ${outfits[d.bonusOutfit!].name} outfit'}',
                          style: TextStyle(
                            color: context.ui.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: s.isUnlocked(d.id)
                          ? FilledButton.icon(
                              key: ValueKey('travel-${d.id}'),
                              onPressed: () => widget.onTravel(d.id),
                              icon: const Icon(
                                Icons.near_me_outlined,
                                size: 17,
                              ),
                              label: Text(
                                s.district == d.id
                                    ? 'Explore here'
                                    : 'Visit ${d.name}',
                              ),
                            )
                          : FilledButton.icon(
                              key: ValueKey('unlock-${d.id}'),
                              onPressed: s.canUnlock(d.id)
                                  ? () async {
                                      if (d.premium &&
                                          !await confirmGems(
                                            'Unlock ${d.name}',
                                            d.gemPrice,
                                            'Includes a permanent map, ${d.unlockBonus} coins and the Velvet vampire outfit.',
                                          )) {
                                        return;
                                      }
                                      if (!mounted) return;
                                      if (s.unlockMap(d.id)) {
                                        widget.onReward(
                                          '${d.name} is yours. Your unlock gift has been added.',
                                        );
                                      }
                                    }
                                  : null,
                              icon: Icon(
                                d.premium
                                    ? Icons.diamond_outlined
                                    : Icons.lock_open_rounded,
                                size: 18,
                              ),
                              label: Text(
                                d.premium
                                    ? 'Unlock · ${d.gemPrice} gems'
                                    : 'Level ${d.requiredLevel} · ${d.price} coins',
                              ),
                            ),
                    ),
                    if (!s.isUnlocked(d.id) && !d.premium)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Your level: ${s.level} · Coins: ${s.coins}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.ui.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: context.ui.paper,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: context.ui.muted,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  String _upgradeDetail(Upgrade u) => switch (u) {
    Upgrade.bag => '${s.capacity} items in your bag → ${s.capacity + 8}',
    Upgrade.reach => 'Collect automatically from farther away.',
    Upgrade.value =>
      '+${s.upgrades[2] * 12}% recycling value → +${(s.upgrades[2] + 1) * 12}%',
    Upgrade.speed =>
      '${s.processingSeconds} seconds per batch → ${(15 - (s.upgrades[3] + 1) * 2).clamp(3, 15)} seconds',
    Upgrade.processing =>
      '${s.batchCapacity} items per batch → ${s.batchCapacity + 12}',
  };
  Widget _gear() => PanelLayout(
    title: 'Gear',
    subtitle: '',
    trailing: CoinPill(s.coins, small: true),
    children: [
      for (final u in Upgrade.values)
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    [
                      Icons.backpack_outlined,
                      Icons.pan_tool_alt_outlined,
                      Icons.recycling,
                      Icons.timer_outlined,
                      Icons.inventory_2_outlined,
                    ][u.index],
                    color: context.ui.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      upgradeNames[u.index],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${s.upgrades[u.index]}/$maxUpgradeLevel',
                    style: TextStyle(color: context.ui.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(_upgradeDetail(u), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: s.upgrades[u.index] / maxUpgradeLevel,
                borderRadius: BorderRadius.circular(6),
                minHeight: 5,
                backgroundColor: context.ui.line,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: ValueKey('upgrade-${u.name}'),
                  onPressed:
                      s.upgrades[u.index] < maxUpgradeLevel &&
                          s.coins >= s.upgradePrice(u)
                      ? () {
                          if (s.buyUpgrade(u)) {
                            widget.onReward(
                              '${upgradeNames[u.index]} upgraded!',
                            );
                          }
                        }
                      : null,
                  child: Text(
                    s.upgrades[u.index] >= maxUpgradeLevel
                        ? 'Fully upgraded'
                        : 'Upgrade · ${s.upgradePrice(u)} coins',
                  ),
                ),
              ),
            ],
          ),
        ),
      _intro(
        'MAGNET POWER',
        s.magnetUnlocked
            ? '15 seconds active. 90 seconds to recharge.'
            : 'Reach level 5 to unlock a 15-second magnet power.',
        icon: Icons.flash_on_rounded,
        color: context.ui.purple,
      ),
    ],
  );
  Widget _style() => PanelLayout(
    title: 'Style',
    subtitle: '',
    children: [for (var i = 0; i < outfits.length; i++) _outfit(i)],
  );
  Widget _outfit(int i) {
    final o = outfits[i], owned = s.ownedOutfits.contains(i);
    final affordable = o.gems > 0 ? s.gems >= o.gems : s.coins >= o.price;
    return SoftCard(
      color: o.color.withValues(alpha: .07),
      child: Row(
        children: [
          CharacterPreview(
            image: game.imageForOutfit(i),
            outfit: i,
            height: 132,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                const SizedBox(height: 10),
                FilledButton(
                  key: ValueKey('outfit-$i'),
                  onPressed: s.outfit == i || (!owned && !affordable)
                      ? null
                      : () async {
                          if (!owned &&
                              o.gems > 0 &&
                              !await confirmGems(
                                o.name,
                                o.gems,
                                'This outfit is yours permanently.',
                              )) {
                            return;
                          }
                          if (!mounted) return;
                          if (s.equipOutfit(i)) {
                            widget.onReward('${o.name} equipped.');
                          }
                        },
                  child: Text(
                    s.outfit == i
                        ? 'Wearing'
                        : owned
                        ? 'Wear outfit'
                        : o.gems > 0
                        ? '${o.gems} gems'
                        : '${o.price} coins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resetText(GoalPeriod p) {
    final remaining = s.periodEnd(p).difference(s.now);
    return remaining.inDays > 0
        ? 'Resets in ${remaining.inDays}d ${remaining.inHours % 24}h'
        : 'Resets in ${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }

  Widget _goals() => PanelLayout(
    title: 'Goals',
    subtitle: '',
    children: [
      SegmentedButton<GoalPeriod>(
        segments: const [
          ButtonSegment(value: GoalPeriod.daily, label: Text('Daily')),
          ButtonSegment(value: GoalPeriod.weekly, label: Text('Weekly')),
          ButtonSegment(value: GoalPeriod.monthly, label: Text('Monthly')),
        ],
        selected: {goalPeriod},
        showSelectedIcon: false,
        onSelectionChanged: (v) => setState(() => goalPeriod = v.first),
      ),
      Text(
        '${_resetText(goalPeriod)} · Calendar periods use UTC',
        style: TextStyle(color: context.ui.muted, fontSize: 11),
      ),
      for (final m in missions.where((m) => m.period == goalPeriod))
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(m.description, style: TextStyle(color: context.ui.muted)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (s.progress(m) / m.target).clamp(0, 1),
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: context.ui.line,
              ),
              const SizedBox(height: 8),
              Text(
                '${s.progress(m).clamp(0, m.target)} / ${m.target}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CoinPill(m.reward, small: true),
                  if (m.gems > 0) GemPill(m.gems),
                  FilledButton(
                    key: ValueKey('claim-${m.id}'),
                    onPressed: !s.isClaimed(m) && s.progress(m) >= m.target
                        ? () {
                            if (s.claim(m)) {
                              widget.onReward(
                                '+${m.reward} coins${m.gems > 0 ? ' +${m.gems} gems' : ''}. Well earned!',
                              );
                            }
                          }
                        : null,
                    child: Text(s.isClaimed(m) ? 'Claimed' : 'Claim reward'),
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
  Widget _daily() => PanelLayout(
    title: 'Daily rewards',
    subtitle: '',
    children: [
      _intro(
        'DAY ${s.dailyStreak == 0 ? 1 : s.dailyStreak} OF 7',
        'Visit daily. Miss a day and the streak resets.',
        icon: Icons.card_giftcard_rounded,
      ),
      for (var i = 0; i < 7; i++)
        SoftCard(
          color: s.dailyStreak == i + 1
              ? context.ui.green.withValues(alpha: .12)
              : context.ui.card,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: i < s.dailyStreak
                    ? context.ui.green
                    : context.ui.line,
                child: i < s.dailyStreak
                    ? Icon(
                        Icons.check,
                        color: context.ui.dark
                            ? const Color(0xFF23352B)
                            : Colors.white,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(color: context.ui.muted),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Day ${i + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              CoinPill(dailyCoins[i], small: true),
              if (i == 6) ...[const SizedBox(width: 6), const GemPill(5)],
            ],
          ),
        ),
      Text(
        'A new day starts at 00:00 UTC. After day 7, your next consecutive visit starts a new seven-day cycle.',
        style: TextStyle(color: context.ui.muted, fontSize: 12),
      ),
    ],
  );
  Widget _ranking() {
    final index = cleanupRankIndex(s.totalCollected),
        rank = cleanupRanks[index];
    final next = index + 1 < cleanupRanks.length
        ? cleanupRanks[index + 1]
        : null;
    return PanelLayout(
      title: 'Ranking',
      subtitle: 'Your lifetime litter collection.',
      children: [
        _intro(
          rank.name.toUpperCase(),
          '${s.totalCollected} pieces collected',
          color: rank.color,
          icon: Icons.emoji_events_rounded,
        ),
        if (s.testMode) const Text('Test progress only.'),
        if (next != null) ...[
          LinearProgressIndicator(
            value:
                ((s.totalCollected - rank.required) /
                        (next.required - rank.required))
                    .clamp(0, 1),
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
            color: rank.color,
          ),
          Text('${next.required - s.totalCollected} to ${next.name}'),
        ],
        for (var i = 0; i < cleanupRanks.length; i++)
          SoftCard(
            child: Row(
              children: [
                Icon(
                  i <= index ? Icons.emoji_events_rounded : Icons.lock_outline,
                  color: cleanupRanks[i].color,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cleanupRanks[i].name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${cleanupRanks[i].required}'),
                if (i == index)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle_outline, size: 19),
                  ),
              ],
            ),
          ),
        const Text(
          'Personal ranks saved on this device.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _levels() => PanelLayout(
    title: 'Levels',
    subtitle: 'Earn 1 XP for collecting and 3 XP for recycling an item.',
    children: [
      _intro(
        'LEVEL ${s.level}',
        s.level == 100
            ? 'You reached the highest level. Keep your city shining!'
            : '${s.xp - xpForLevel(s.level)} / ${xpForLevel(s.level + 1) - xpForLevel(s.level)} XP toward level ${s.level + 1}',
        icon: Icons.auto_awesome_rounded,
      ),
      LinearProgressIndicator(
        value: s.levelProgress,
        minHeight: 9,
        borderRadius: BorderRadius.circular(9),
        backgroundColor: context.ui.line,
      ),
      const SoftCard(
        child: Text(
          'Every level: a small coin gift.\nEvery 5 levels: a bigger coin bonus.\nEvery 10 levels: an extra milestone bonus.\nLevel 5: your magnet power unlocks.',
        ),
      ),
      for (final l in [5, 10, 15, 20, 25, 30, 35, 40, 50, 75, 100])
        SoftCard(
          child: Row(
            children: [
              Icon(
                s.level >= l
                    ? Icons.check_circle_rounded
                    : Icons.auto_awesome_outlined,
                color: s.level >= l ? context.ui.green : context.ui.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Level $l${l == 5
                      ? ' · Magnet power'
                      : l % 10 == 0
                      ? ' · Major milestone'
                      : ''}',
                ),
              ),
              Text(
                '+${10 + l * 2 + l * 15 + (l % 10 == 0 ? l * 25 : 0)} coins',
                style: TextStyle(
                  color: context.ui.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
    ],
  );
  Widget _shop() => PanelLayout(
    title: 'Shop',
    subtitle: '',
    trailing: GemPill(s.gems),
    children: [
      _intro(
        'EARN YOUR GEMS',
        'Day 7 of your daily rewards: 5 gems.\nWeekly recycling challenge: 1 gem.\nMonthly recycling challenge: 2 gems.',
        color: context.ui.purple,
        icon: Icons.diamond_outlined,
      ),
      SoftCard(
        color: const Color(0xFFF0EAF8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.diamond_rounded, color: context.ui.purple, size: 35),
                SizedBox(width: 10),
                Text(
                  '100 gems',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: context.ui.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Planned pack · around €5',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'Gem purchases are coming later. You can already earn gems by playing.',
              style: TextStyle(color: context.ui.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: ValueKey('buy-gems'),
                onPressed: null,
                child: Text('Purchases not available yet'),
              ),
            ),
          ],
        ),
      ),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 140,
              child: CustomPaint(painter: _CityPreview(districts[5])),
            ),
            const Text(
              'Midnight Hollow bundle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'A sprawling night district, the Velvet vampire outfit and 1,200 bonus coins.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('shop-spooky'),
              onPressed: s.canUnlock(5)
                  ? () async {
                      if (!await confirmGems(
                        'Midnight Hollow bundle',
                        80,
                        'Includes the map, vampire outfit and 1,200 coins.',
                      )) {
                        return;
                      }
                      if (!mounted) return;
                      if (s.unlockMap(5)) {
                        widget.onReward(
                          'Midnight Hollow unlocked. Your vampire outfit is ready!',
                        );
                      }
                    }
                  : null,
              child: Text(
                s.isUnlocked(5) ? 'Bundle owned' : 'Unlock · 80 gems',
              ),
            ),
          ],
        ),
      ),
      _outfit(4),
      _outfit(5),
    ],
  );
  Widget _projects() => PanelLayout(
    title: 'City upgrades',
    subtitle: '',
    children: [
      for (var i = 0; i < 3; i++)
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    s.projects[s.district] > i
                        ? Icons.check_circle
                        : Icons.local_florist_outlined,
                    color: context.ui.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      districts[s.district].projectNames[i],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (s.projects[s.district] == i) ...[
                Text(
                  'Recycle ${s.projectRequirement} items here · ${s.recycledByDistrict[s.district]} so far',
                  style: TextStyle(color: context.ui.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  key: const ValueKey('restore-project'),
                  onPressed: s.canRestore
                      ? () {
                          if (s.restore()) {
                            widget.onReward(
                              'Your new street garden is growing!',
                            );
                          }
                        }
                      : null,
                  child: Text('Restore · ${s.projectPrice} coins'),
                ),
              ] else
                Text(
                  s.projects[s.district] > i
                      ? 'Restored. Thank you for caring.'
                      : 'Complete the previous project first.',
                  style: TextStyle(color: context.ui.muted),
                ),
            ],
          ),
        ),
    ],
  );
  Widget _cityEvents() {
    final event = s.cityEvent;
    return PanelLayout(
      title: 'Events',
      subtitle: '',
      children: [
        if (game.life?.thief.actor case final thief?)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  thief.running ? 'Thief on the run!' : 'Thief spotted!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Catch the thief. Recover stolen valuables.'),
                TextButton.icon(
                  key: const ValueKey('find-thief'),
                  onPressed: () {
                    Navigator.pop(context);
                    game.walkTo(thief.position);
                  },
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text('Find thief'),
                ),
              ],
            ),
          ),
        if (game.life?.truck.actor case final truck?)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Trash Truck',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Fresh litter: up to 8 bonus coins. After 28s: 1 coin.',
                ),
                TextButton.icon(
                  key: const ValueKey('find-truck'),
                  onPressed: () {
                    Navigator.pop(context);
                    game.walkTo(truck.position);
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Find truck'),
                ),
              ],
            ),
          ),
        if (event == null) ...[
          _intro(
            'A QUIET MOMENT',
            'Explore to discover more events.',
            icon: Icons.celebration_outlined,
          ),
          Text(
            '${s.completedCityEvents} events completed',
            style: TextStyle(color: context.ui.muted),
          ),
        ] else ...[
          _intro(
            event.ready
                ? 'REWARD READY'
                : event.joined
                ? 'YOU ARE TAKING PART'
                : 'YOU ARE INVITED',
            event.definition.name,
            icon: event.ready ? Icons.task_alt : Icons.celebration_outlined,
            color: event.definition.color,
          ),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  districts[event.district].name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(event.definition.description),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CoinPill(event.definition.coins, small: true),
                    const SizedBox(width: 12),
                    Text('+${event.definition.xp} XP'),
                  ],
                ),
                if (event.joined) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: event.progress / event.definition.target,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${event.progress} / ${event.definition.target}',
                    key: const ValueKey('event-progress'),
                  ),
                ],
              ],
            ),
          ),
          if (event.ready)
            FilledButton.icon(
              key: const ValueKey('event-claim'),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Collect reward'),
              onPressed: () {
                final coins = event.definition.coins, xp = event.definition.xp;
                if (s.claimCityEvent()) {
                  widget.onReward('Event reward: +$coins coins and +$xp XP');
                }
              },
            )
          else if (event.district != s.district)
            FilledButton.icon(
              key: const ValueKey('event-travel'),
              onPressed: () => widget.onTravel(event.district),
              icon: const Icon(Icons.map_outlined),
              label: Text('Visit ${districts[event.district].name}'),
            )
          else if (!event.joined)
            FilledButton.icon(
              key: const ValueKey('event-join'),
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('Join event'),
              onPressed: () {
                if (s.joinCityEvent()) {
                  Navigator.pop(context);
                  widget.onReward('${event.definition.name} joined');
                }
              },
            )
          else
            FilledButton(
              key: const ValueKey('event-continue'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep exploring'),
            ),
          if (!event.ready)
            TextButton(
              key: const ValueKey('event-leave'),
              onPressed: s.leaveCityEvent,
              child: Text(event.joined ? 'Leave event' : 'Maybe another time'),
            ),
          Text(
            'Your progress stays when you close the game or visit another map.',
            style: TextStyle(color: context.ui.muted),
          ),
        ],
        Text('Look out for', style: Theme.of(context).textTheme.titleMedium),
        for (final definition in cityEvents)
          SoftCard(
            child: Row(
              children: [
                Icon(switch (definition.metric) {
                  CityEventMetric.collected => Icons.cleaning_services_outlined,
                  CityEventMetric.bottles => Icons.search_rounded,
                  CityEventMetric.recycled => Icons.recycling,
                }, color: context.ui.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        definition.description,
                        style: TextStyle(color: context.ui.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _settings() => PanelLayout(
    title: 'Settings',
    subtitle: s.testMode
        ? 'CleanCity - Test build 0.18.0'
        : 'CleanCity - Version 0.18.0',
    children: [
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              key: const ValueKey('appearance-setting'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Light', key: ValueKey('theme-light')),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Dark', key: ValueKey('theme-dark')),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {s.darkMode},
              onSelectionChanged: (value) => s.setDarkMode(value.single),
            ),
            const SizedBox(height: 22),
            Text(
              'Joystick resting position',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Drag to walk. Double-tap an edge to auto-walk. Tap the map to stop.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<JoystickPosition>(
              key: const ValueKey('joystick-setting'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: JoystickPosition.left,
                  label: Text('Left', key: ValueKey('joystick-left')),
                ),
                ButtonSegment(
                  value: JoystickPosition.center,
                  label: Text('Middle', key: ValueKey('joystick-center')),
                ),
                ButtonSegment(
                  value: JoystickPosition.right,
                  label: Text('Right', key: ValueKey('joystick-right')),
                ),
              ],
              selected: {s.joystickPosition},
              onSelectionChanged: (value) {
                game.clearInput();
                s.setJoystickPosition(value.single);
              },
            ),
            const SizedBox(height: 12),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const ValueKey('hud-setting'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Show top bar'),
                subtitle: const Text(
                  'You can also use the arrow while playing.',
                ),
                value: s.hudVisible,
                onChanged: s.setHudVisible,
              ),
            ),
          ],
        ),
      ),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bar visibility - ${(s.hudOpacity * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('Make the top and bottom bars more see-through.'),
            Slider(
              key: const ValueKey('hud-opacity'),
              value: s.hudOpacity,
              min: .20,
              max: .80,
              divisions: 30,
              label: '${(s.hudOpacity * 100).round()}%',
              semanticFormatterCallback: (value) =>
                  '${(value * 100).round()} percent visible',
              onChanged: s.setHudOpacity,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'More view',
                  style: TextStyle(color: context.ui.muted, fontSize: 11),
                ),
                Text(
                  'More contrast',
                  style: TextStyle(color: context.ui.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      if (s.testMode) ...[
        _intro(
          'TEST MODE - EVERYTHING UNLOCKED',
          'All six maps, every outfit, level 100, max gear and restored gardens. This test save is separate from your normal progress.',
          icon: Icons.science_outlined,
          color: context.ui.purple,
        ),
        FilledButton.icon(
          key: const ValueKey('test-refill'),
          onPressed: () {
            s.refillTestSupplies();
            widget.onReward('Test wallet refilled - Magnet ready');
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refill wallet & recharge magnet'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('test-event'),
          onPressed: () {
            s.offerTestCityEvent();
            widget.onReward('A new event is available. Tap Events to join.');
          },
          icon: const Icon(Icons.celebration_outlined),
          label: const Text('Preview next city event'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('test-thief'),
          onPressed: () {
            final spawned = game.life?.thief.spawn(preview: true) ?? false;
            widget.onReward(
              spawned
                  ? 'Thief spotted! Follow the !'
                  : 'A thief is already nearby',
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.priority_high_rounded),
          label: const Text('Preview thief'),
        ),
        OutlinedButton(
          key: const ValueKey('test-gear-toggle'),
          onPressed: () => s.setTestGear(s.upgrades.first == 0),
          child: Text(
            s.upgrades.first == 0 ? 'Use max gear' : 'Try starter gear',
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('test-truck'),
          onPressed: () {
            final spawned =
                game.life?.truck.spawn(
                  preview: true,
                  pedestrians: game.life!.people.map((p) => p.position),
                ) ??
                false;
            widget.onReward(
              spawned
                  ? 'Trash truck nearby!'
                  : 'Try an open street with litter space.',
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Preview trash truck'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('test-apple'),
          onPressed: () {
            final dropped = game.life?.apples.drop(preview: true) ?? false;
            widget.onReward(
              dropped ? 'Apple near a tree!' : 'Try near another tree.',
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.apple_outlined),
          label: const Text('Drop an apple'),
        ),
      ],
      SoftCard(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound effects'),
                value: s.sound,
                onChanged: s.setSound,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gentle vibrations'),
                value: s.haptics,
                onChanged: s.setHaptics,
              ),
            ],
          ),
        ),
      ),
      _intro(
        'SAVED ON THIS DEVICE',
        s.saveFailed
            ? 'Your last save failed. Please try again.'
            : 'Your streets, outfits, gems and progress save automatically.',
      ),
      if (s.saveFailed)
        FilledButton(onPressed: s.save, child: const Text('Retry saving')),
      const SoftCard(
        child: Text(
          'Touch anywhere on the map, then drag to walk. Nearby litter is collected automatically. Tap Recycle to find the closest station.\n\nUnlock the magnet at level 5. Complete goals and visit every day for rewards.',
        ),
      ),
      const SoftCard(
        child: Text(
          'Outfit references: Chasersgaming - NPC Characters (OpenGameArt), and Kenney - Roguelike Characters. Both CC0. Redrawn for CleanCity.\n\nopengameart.org/content/npc-characters-20\nkenney.nl/assets/roguelike-characters',
          style: TextStyle(fontSize: 11),
        ),
      ),
      Text(
        'Coins: ${s.coins} · Gems: ${s.gems}\nLevel: ${s.level} · Total XP: ${s.xp}\nCollected: ${s.totalCollected} · Recycled: ${s.totalRecycled}',
        style: TextStyle(color: context.ui.muted),
      ),
    ],
  );
  Widget _welcome() => QuickStartGuide(
    onStart: () {
      if (s.introduced) return;
      s.completeIntro();
      Navigator.pop(context);
    },
  );
}

class _CityPreview extends CustomPainter {
  _CityPreview(this.d);
  final District d;
  @override
  void paint(Canvas c, Size size) {
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..color = d.night ? const Color(0xFF4A485F) : const Color(0xFFD9E1C7),
    );
    c.save();
    final scale = (size.height - 14) / d.worldSize.height;
    c.translate((size.width - d.worldSize.width * scale) / 2, 7);
    c.scale(scale);
    final layout = d.layout;
    c.drawPath(
      layout.boundary,
      Paint()
        ..color = d.night ? const Color(0xFF777080) : const Color(0xFFC6BFAB),
    );
    c.clipPath(layout.boundary);
    for (final street in layout.streets) {
      final path = Path()..addPolygon(street.points, false);
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF8A928D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = street.width,
      );
    }
    if (layout.garden case final Rect garden) {
      c.drawRect(garden, Paint()..color = const Color(0xFF8F9E73));
    }
    if (layout.plaza != null) {
      c.drawPath(layout.plazaPath, Paint()..color = const Color(0xFFDFD3B8));
    }
    if (layout.canal case final Rect water) {
      c.drawRect(water, Paint()..color = const Color(0xFF699B99));
    }
    for (var i = 0; i < d.blocks.length; i++) {
      final path = Path();
      if (layout.footprints[i] case final List<Offset> points) {
        path.addPolygon(points, true);
      } else {
        path.addRect(d.blocks[i]);
      }
      c.drawPath(
        path,
        Paint()
          ..color = d.id == 1
              ? const Color(0xFFBA7F5E)
              : d.color.withValues(alpha: .65),
      );
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFC9BDA2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (final tree in layout.trees) {
      c.drawCircle(tree.position, 20, Paint()..color = const Color(0xFF6E895E));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_CityPreview old) => old.d != d;
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_pacing_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/mini_game_service.dart';
import '../services/smart_ad_manager.dart';
import '../widgets/minimizable_native_ad.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_banner_ad.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFF080B12);
  static const surface  = Color(0xFF0E1420);
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const goldDark = Color(0xFFE08800);
  static const electric = Color(0xFF00D4FF);
  static const green    = Color(0xFF00E5A0);
  static const purple   = Color(0xFFB06EFF);
  static const pink     = Color(0xFFFF6B9D);
  static const textHi   = Color(0xFFF0F4FF);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);
}

// ─── Data models ──────────────────────────────────────────────────────────────
class _DailyInfo {
  final String label;
  final String desc;
  final String? rigLabel;
  const _DailyInfo(this.label, this.desc, this.rigLabel);
}

class _AdReward {
  final String type;
  final String label;
  final String desc;
  final IconData icon;
  final Color accent;
  const _AdReward(this.type, this.label, this.desc, this.icon, this.accent);
}

class _Milestone {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  const _Milestone(this.id, this.title, this.desc, this.icon);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game   = context.watch<GameStateService>();
    final ad     = context.watch<SmartAdManager>();
    final pacing = context.watch<AdPacingService>();
    final adCfg  = context.watch<AdRemoteConfigService>();
    final spin   = context.watch<LuckySpinService>();

    final canClaim     = game.canClaimDaily;
    final nextDay      = game.nextDailyStreakDay;
    final dailyRewards = _buildDailyRewards();
    final adRewards    = _buildAdRewards();
    final milestones   = _buildMilestones();

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // Ambient glows
            Positioned(
              top: -80,
              right: -60,
              child: _Blob(color: _D.purple.withValues(alpha: 0.06), size: 300),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: _Blob(color: _D.gold.withValues(alpha: 0.05), size: 280),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── App bar ──────────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: _D.bg.withValues(alpha: 0.92),
                    surfaceTintColor: Colors.transparent,
                    title: Row(children: [
                      const Icon(Icons.redeem_rounded, color: _D.gold, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'REWARDS',
                        style: TextStyle(
                          color: _D.gold,
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ]),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ── Daily claim hero ─────────────────────────
                        _DailyClaimHero(
                          canClaim: canClaim,
                          nextDay:  nextDay,
                          game:     game,
                        ),
                        const SizedBox(height: 20),

                        // ── 7-day cycle ──────────────────────────────
                        _SectionLabel(label: '7-DAY CYCLE'),
                        const SizedBox(height: 10),
                        _DailyCycleRow(
                          dailyRewards: dailyRewards,
                          nextDay:      nextDay,
                          canClaim:     canClaim,
                          game:         game,
                        ),
                        const SizedBox(height: 20),

                        // ── Lucky spin ───────────────────────────────
                        _SectionLabel(label: 'LUCKY SPIN'),
                        const SizedBox(height: 10),
                        _LuckySpinCard(spin: spin),
                        const SizedBox(height: 20),

                        // ── Mini-game (tap challenge) ──────────────────
                        _SectionLabel(label: 'TAP CHALLENGE'),
                        const SizedBox(height: 10),
                        _MiniGameCard(),
                        const SizedBox(height: 20),

                        // ── Ad rewards ───────────────────────────────
                        if (adCfg.adsActive || adCfg.canShowWebsiteRedirect) ...[
                          _SectionLabel(label: adCfg.useCustomTab ? 'LINK REWARDS' : 'AD REWARDS'),
                          const SizedBox(height: 4),
                          Text(
                            adCfg.useCustomTab
                                ? 'Open the link to earn a reward.'
                                : 'Watch a short ad to earn one of these rewards.',
                            style: const TextStyle(color: _D.textMid, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          ...adRewards.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AdRewardTile(
                              reward:  r,
                              ad:      ad,
                              adCfg:   adCfg,
                              pacing:  pacing,
                              game:    game,
                            ),
                          )),
                          const SizedBox(height: 12),
                        ],

                        // ── Milestones ───────────────────────────────
                        _SectionLabel(label: 'MILESTONES'),
                        const SizedBox(height: 10),
                        ...milestones.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MilestoneTile(milestone: m, game: game),
                        )),

                        // ── Ads ──────────────────────────────────────
                        if (adCfg.adsActive) ...[
                          const SizedBox(height: 12),
                          const MinimizableNativeAd(title: 'Sponsored'),
                          const SizedBox(height: 10),
                          const Center(child: SmartBannerAd()),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DailyInfo> _buildDailyRewards() => const [
    _DailyInfo('Day 1', '10 coins',    null),
    _DailyInfo('Day 2', '50 coins',    null),
    _DailyInfo('Day 3', 'GPU rig',     'GPU rig'),
    _DailyInfo('Day 4', 'Bonus BTC',   null),
    _DailyInfo('Day 5', 'Bonus BTC',   null),
    _DailyInfo('Day 6', 'Bonus BTC',   null),
    _DailyInfo('Day 7', 'Rare miner',  'Mining rack'),
  ];

  List<_AdReward> _buildAdRewards() => const [
    _AdReward('small_btc',  'Small BTC bonus',   '+0.00001 BTC',         Icons.monetization_on_rounded, _D.green),
    _AdReward('medium_btc', 'Medium BTC bonus',  '+0.00005 BTC',         Icons.savings_rounded,         _D.electric),
    _AdReward('large_btc',  'Large BTC bonus',   '+0.0001 BTC',          Icons.diamond_rounded,         _D.gold),
    _AdReward('boost_15m',  '2× Boost 15 min',   'Double mining speed',  Icons.bolt_rounded,            _D.purple),
    _AdReward('gpu_rig',    'Free GPU rig',       '1× GPU rig',           Icons.memory_rounded,          _D.pink),
  ];

  List<_Milestone> _buildMilestones() => const [
    _Milestone('sessions_5',    'Session Starter',  'Start 5 mining sessions · +0.00005 BTC', Icons.rocket_launch_rounded),
    _Milestone('sessions_20',   'Session Veteran',  'Start 20 sessions · 1× Mining rack',     Icons.workspace_premium_rounded),
    _Milestone('lifetime_0005', 'Half-milli Miner', 'Mine 0.0005 BTC total · +0.0001 BTC',    Icons.track_changes_rounded),
  ];
}

// ─── Daily claim hero ─────────────────────────────────────────────────────────
class _DailyClaimHero extends StatelessWidget {
  final bool canClaim;
  final int nextDay;
  final GameStateService game;
  const _DailyClaimHero({
    required this.canClaim,
    required this.nextDay,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final day = (nextDay >= 1 && nextDay <= 7) ? nextDay : 1;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canClaim
              ? [const Color(0xFF1E2A14), const Color(0xFF0F1A0A)]
              : [const Color(0xFF141826), const Color(0xFF0E1420)],
        ),
        border: Border.all(
          color: canClaim
              ? _D.green.withValues(alpha: 0.4)
              : _D.cardBord,
          width: 1,
        ),
        boxShadow: canClaim
            ? [BoxShadow(color: _D.green.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 6))]
            : [],
      ),
      child: Stack(
        children: [
          if (canClaim)
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _D.green.withValues(alpha: 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (canClaim ? _D.green : _D.textLow).withValues(alpha: 0.12),
                  border: Border.all(
                    color: (canClaim ? _D.green : _D.textLow).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: canClaim
                      ? [BoxShadow(color: _D.green.withValues(alpha: 0.25), blurRadius: 20)]
                      : [],
                ),
                child: Icon(
                  canClaim ? Icons.card_giftcard_rounded : Icons.check_circle_rounded,
                  size: 34,
                  color: canClaim ? _D.green : _D.textLow,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                canClaim ? 'Daily Reward Ready!' : 'Already Claimed Today',
                style: TextStyle(
                  color: canClaim ? _D.textHi : _D.textMid,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                canClaim ? 'Day $day of 7-day cycle' : 'Come back tomorrow for the next reward',
                style: const TextStyle(color: _D.textMid, fontSize: 13),
              ),
              if (canClaim) ...[
                const SizedBox(height: 20),
                _GoldBtn(
                  label: 'Claim Day $day Reward',
                  icon: Icons.redeem_rounded,
                  onTap: () async {
                    await game.claimDaily();
                    if (context.mounted) _toast(context, '🎁 Day $day reward claimed!');
                  },
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── 7-day cycle row ──────────────────────────────────────────────────────────
class _DailyCycleRow extends StatelessWidget {
  final List<_DailyInfo> dailyRewards;
  final int nextDay;
  final bool canClaim;
  final GameStateService game;
  const _DailyCycleRow({
    required this.dailyRewards,
    required this.nextDay,
    required this.canClaim,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final currentDay = (nextDay >= 1 && nextDay <= 7) ? nextDay : 1;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dailyRewards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day  = i + 1;
          final info = dailyRewards[i];
          final isPast    = day < currentDay || (!canClaim && day <= currentDay);
          final isCurrent = canClaim && day == currentDay;
          final isFuture  = day > currentDay || (!canClaim && day > currentDay);
          final btc = game.dailyRewardBtc(day);
          final rig = game.dailyRewardRigId(day);
          final isSpecial = rig != null;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72,
            decoration: BoxDecoration(
              color: isCurrent
                  ? _D.gold.withValues(alpha: 0.15)
                  : isPast
                  ? _D.green.withValues(alpha: 0.07)
                  : _D.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? _D.gold.withValues(alpha: 0.6)
                    : isPast
                    ? _D.green.withValues(alpha: 0.3)
                    : _D.cardBord,
                width: isCurrent ? 1.5 : 1,
              ),
              boxShadow: isCurrent
                  ? [BoxShadow(color: _D.gold.withValues(alpha: 0.2), blurRadius: 12)]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isPast
                    ? const Icon(Icons.check_rounded, color: _D.green, size: 18)
                    : Icon(
                  isSpecial ? Icons.memory_rounded : Icons.currency_bitcoin,
                  color: isCurrent ? _D.gold : _D.textLow,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  'Day $day',
                  style: TextStyle(
                    color: isCurrent ? _D.gold : isPast ? _D.green : _D.textLow,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  btc != null && btc > 0
                      ? '+${btc.toStringAsFixed(5)}'
                      : rig != null
                      ? 'Rig'
                      : info.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? _D.gold.withValues(alpha: 0.8) : _D.textLow,
                    fontSize: 9,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Mini-game (tap challenge) card ───────────────────────────────────────────
class _MiniGameCard extends StatelessWidget {
  const _MiniGameCard();

  @override
  Widget build(BuildContext context) {
    final mini = context.watch<MiniGameService>();
    return Container(
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _D.gold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _D.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.touch_app_rounded, color: _D.gold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tap challenge',
                  style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tap ${MiniGameService.tapTarget}x in ${MiniGameService.tapTimeSec}s · +${MiniGameService.rewardBtc.toStringAsFixed(5)} BTC · ${mini.playsLeft} plays left',
                  style: const TextStyle(color: _D.textMid, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: mini.canPlay ? () => Navigator.pushNamed(context, '/mini-game') : null,
            child: const Text('Play'),
          ),
        ]),
      ),
    );
  }
}

// ─── Lucky spin card ──────────────────────────────────────────────────────────
class _LuckySpinCard extends StatelessWidget {
  final LuckySpinService spin;
  const _LuckySpinCard({required this.spin});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: spin.canSpin
            ? _D.purple.withValues(alpha: 0.4)
            : _D.cardBord,
      ),
      boxShadow: spin.canSpin
          ? [BoxShadow(color: _D.purple.withValues(alpha: 0.12), blurRadius: 16)]
          : [],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _D.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _D.purple.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.casino_rounded, color: _D.purple, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Spin Wheel',
              style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Text(
            spin.canSpin
                ? 'Win BTC, boosts, or free rigs!'
                : 'Available every 24 hours',
            style: const TextStyle(color: _D.textMid, fontSize: 12),
          ),
        ])),
        const SizedBox(width: 12),
        _ActionBtn(
          label:    spin.canSpin ? 'Spin!' : 'Later',
          accent:   _D.purple,
          enabled:  spin.canSpin,
          onTap: () {
            if (!spin.canSpin) return;
            Navigator.of(context).pushNamed('/lucky-spin');
          },
        ),
      ]),
    ),
  );
}

// ─── Ad reward tile ───────────────────────────────────────────────────────────
class _AdRewardTile extends StatelessWidget {
  final _AdReward reward;
  final SmartAdManager ad;
  final AdRemoteConfigService adCfg;
  final AdPacingService pacing;
  final GameStateService game;
  const _AdRewardTile({
    required this.reward,
    required this.ad,
    required this.adCfg,
    required this.pacing,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final loading = ad.loadingRewarded && !adCfg.useCustomTab;
    return Container(
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.cardBord),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reward.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: reward.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(reward.icon, color: reward.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reward.label,
                style: const TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(reward.desc,
                style: TextStyle(
                  color: reward.accent,
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
          ])),
          const SizedBox(width: 10),
          _ActionBtn(
            label:   adCfg.useCustomTab ? 'Open' : (loading ? '…' : 'Watch'),
            accent:  reward.accent,
            enabled: !loading,
            leading: loading
                ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: reward.accent),
            )
                : Icon(
              adCfg.useCustomTab ? Icons.open_in_browser_rounded : Icons.play_circle_filled_rounded,
              color: Colors.black,
              size: 14,
            ),
            onTap: () async {
              if (adCfg.useCustomTab && adCfg.customTabUrl.isNotEmpty) {
                game.grantAdReward(reward.type);
                await pacing.markRewardedShown();
                if (context.mounted) _toast(context, 'Earned: ${reward.label}');
                await adCfg.openCustomTab(adCfg.customTabUrl);
                return;
              }
              final canShow = await pacing.canShowRewarded();
              if (!canShow) {
                if (context.mounted) {
                  final left = pacing.rewardedCooldownLeft().inSeconds;
                  _toast(context, 'Wait ${left}s before next ad.');
                }
                return;
              }
              final shown = await ad.showRewarded(
                onEarned: () => game.grantAdReward(reward.type),
              );
              if (context.mounted) {
                if (shown) {
                  await pacing.markRewardedShown();
                  _toast(context, 'Earned: ${reward.label}');
                } else {
                  _toast(context, ad.lastError ?? 'Ad not ready');
                }
              }
            },
          ),
        ]),
      ),
    );
  }
}

// ─── Milestone tile ───────────────────────────────────────────────────────────
class _MilestoneTile extends StatelessWidget {
  final _Milestone milestone;
  final GameStateService game;
  const _MilestoneTile({required this.milestone, required this.game});

  @override
  Widget build(BuildContext context) {
    final canClaim = game.canClaimMilestone(milestone.id);
    final claimed  = game.claimedMilestones.contains(milestone.id);
    final Color accent = claimed ? _D.green : canClaim ? _D.gold : _D.textLow;

    return Container(
      decoration: BoxDecoration(
        color: claimed
            ? _D.green.withValues(alpha: 0.05)
            : canClaim
            ? _D.gold.withValues(alpha: 0.05)
            : _D.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: claimed
              ? _D.green.withValues(alpha: 0.25)
              : canClaim
              ? _D.gold.withValues(alpha: 0.35)
              : _D.cardBord,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(
              claimed ? Icons.check_circle_rounded : milestone.icon,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(milestone.title,
                style: TextStyle(
                  color: claimed ? _D.textMid : _D.textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
            const SizedBox(height: 2),
            Text(milestone.desc,
                style: const TextStyle(color: _D.textMid, fontSize: 11)),
          ])),
          const SizedBox(width: 10),
          if (claimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _D.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _D.green.withValues(alpha: 0.25)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                    color: _D.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  )),
            )
          else
            _ActionBtn(
              label:   canClaim ? 'Claim' : 'Locked',
              accent:  canClaim ? _D.gold : _D.textLow,
              enabled: canClaim,
              onTap: () async {
                await game.claimMilestone(milestone.id);
                if (context.mounted) _toast(context, '🏆 ${milestone.title} claimed!');
              },
            ),
        ]),
      ),
    );
  }
}

// ─── Shared components ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _D.textMid,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final Color accent;
  final bool enabled;
  final Widget? leading;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.accent,
    required this.enabled,
    this.leading,
    this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isGold = widget.accent == _D.gold && widget.enabled;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) { setState(() => _pressed = false); widget.onTap?.call(); } : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? (isGold
                ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)])
                : null)
                : null,
            color: widget.enabled && !isGold
                ? widget.accent.withValues(alpha: 0.15)
                : widget.enabled
                ? null
                : _D.cardBord,
            borderRadius: BorderRadius.circular(9),
            border: widget.enabled && !isGold
                ? Border.all(color: widget.accent.withValues(alpha: 0.4))
                : null,
            boxShadow: widget.enabled && isGold
                ? [BoxShadow(color: _D.gold.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 5)],
            Text(
              widget.label,
              style: TextStyle(
                color: widget.enabled
                    ? (isGold ? Colors.black : widget.accent)
                    : _D.textLow,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GoldBtn extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, this.icon, required this.onTap});

  @override
  State<_GoldBtn> createState() => _GoldBtnState();
}

class _GoldBtnState extends State<_GoldBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)]),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
          ],
          Text(widget.label,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
      ),
    ),
  );
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox.shrink(),
    ),
  );
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _D.textHi)),
    backgroundColor: _D.card,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: _D.cardBord),
    ),
  ));
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: AppTheme.fontFamily,
  textTheme: AppTheme.darkTextTheme,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);
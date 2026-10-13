import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../services/ad_pacing_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/mini_game_service.dart';
import '../services/smart_ad_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_ad_slot.dart';

class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const greenText = Color(0xFFBBF7D0);
  static const greenBg = Color(0xFF0A2E22);
  static const greenBdr = Color(0x6614F195);
  static const electric = Color(0xFF38BDF8);
  static const electricBg = Color(0xFF0C1A24);
  static const electricBdr = Color(0xFF164E63);
  static const violet = Color(0xFFA78BFA);
  static const pink = Color(0xFFEC4899);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);
  static const line = Color(0x1FFFFFFF);
}

TextStyle _sg({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _D.textHi,
  double? spacing,
  double? height,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );

TextStyle _mono({
  double size = 12,
  FontWeight weight = FontWeight.w600,
  Color color = _D.textHi,
}) =>
    GoogleFonts.spaceMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.15,
    );

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

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const _dailyRewards = [
    _DailyInfo('Day 1', '10 coins', null),
    _DailyInfo('Day 2', '50 coins', null),
    _DailyInfo('Day 3', 'GPU rig', 'GPU rig'),
    _DailyInfo('Day 4', 'Bonus SOL', null),
    _DailyInfo('Day 5', 'Bonus SOL', null),
    _DailyInfo('Day 6', 'Bonus SOL', null),
    _DailyInfo('Day 7', 'Rare miner', 'Mining rack'),
  ];

  static const _adRewards = [
    _AdReward('small_btc', 'Small SOL bonus', '+0.005 SOL', Icons.monetization_on_rounded, _D.green),
    _AdReward('medium_btc', 'Medium SOL bonus', '+0.025 SOL', Icons.savings_rounded, _D.electric),
    _AdReward('large_btc', 'Large SOL bonus', '+0.05 SOL', Icons.diamond_rounded, _D.gold),
    _AdReward('boost_15m', '2× Boost 15 min', 'Double mining speed', Icons.bolt_rounded, _D.violet),
    _AdReward('gpu_rig', 'Free GPU rig', '1× GPU rig', Icons.memory_rounded, _D.pink),
  ];

  static const _milestones = [
    _Milestone('sessions_5', 'Session Starter', 'Start 5 mining sessions · +0.025 SOL', Icons.rocket_launch_rounded),
    _Milestone('sessions_20', 'Session Veteran', 'Start 20 sessions · 1× Mining rack', Icons.workspace_premium_rounded),
    _Milestone('lifetime_0005', 'Half-milli Miner', 'Mine 0.25 SOL total · +0.05 SOL', Icons.track_changes_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final ad = context.watch<SmartAdManager>();
    final pacing = context.watch<AdPacingService>();
    final adCfg = context.watch<AdRemoteConfigService>();
    final spin = context.watch<LuckySpinService>();
    final canClaim = game.canClaimDaily;
    final nextDay = game.nextDailyStreakDay;

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: AppTheme.pageScroll,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: const Color(0xCC08080A),
                    surfaceTintColor: Colors.transparent,
                    toolbarHeight: 68,
                    flexibleSpace: const ColoredBox(color: Color(0xF208080A)),
                    title: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _D.goldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _D.goldBdr),
                          ),
                          child: const Icon(Icons.redeem_rounded, color: _D.gold, size: 18),
                        ),
                        const SizedBox(width: 11),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (r) => const LinearGradient(
                                colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                              ).createShader(r),
                              child: Text('Rewards', style: _sg(size: 16, weight: FontWeight.w700, spacing: -0.3, color: Colors.white)),
                            ),
                            Text('DAILY VAULT', style: _sg(size: 9, weight: FontWeight.w700, color: _D.gold, spacing: 1.6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, AppTheme.pageBottomPadding(context)),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _DailyClaimHero(canClaim: canClaim, nextDay: nextDay, game: game),
                        const SizedBox(height: 22),
                        const _SectionLabel('7-day cycle'),
                        const SizedBox(height: 12),
                        _DailyCycleRow(rewards: _dailyRewards, nextDay: nextDay, canClaim: canClaim, game: game),
                        const SizedBox(height: 22),
                        const _SectionLabel('Play'),
                        const SizedBox(height: 12),
                        _LuckySpinCard(spin: spin),
                        const SizedBox(height: 12),
                        const _MiniGameCard(),
                        const SizedBox(height: 22),
                        const _SectionLabel('Daily ad challenge'),
                        const SizedBox(height: 12),
                        _DailyAdChallengeCard(pacing: pacing, ad: ad, adCfg: adCfg, game: game),
                        if (adCfg.adsActive || adCfg.canShowWebsiteRedirect) ...[
                          const SizedBox(height: 22),
                          _SectionLabel(adCfg.useCustomTab ? 'Link rewards' : 'Ad rewards'),
                          const SizedBox(height: 6),
                          Text(
                            adCfg.useCustomTab
                                ? 'Open the link to earn a reward.'
                                : 'Watch a short ad to earn one of these rewards.',
                            style: _sg(size: 12.5, color: _D.textMid, height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          for (final reward in _adRewards) ...[
                            _AdRewardTile(reward: reward, ad: ad, adCfg: adCfg, pacing: pacing, game: game),
                            const SizedBox(height: 10),
                          ],
                        ],
                        const SizedBox(height: 12),
                        const _SectionLabel('Milestones'),
                        const SizedBox(height: 12),
                        for (final milestone in _milestones) ...[
                          _MilestoneTile(milestone: milestone, game: game),
                          const SizedBox(height: 10),
                        ],
                        if (adCfg.shouldShowSdkAds && !game.isPremiumActive) ...[
                          const SizedBox(height: 8),
                          const ScreenAdSlot(title: 'Rewards offer'),
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
}

class _DailyClaimHero extends StatelessWidget {
  final bool canClaim;
  final int nextDay;
  final GameStateService game;

  const _DailyClaimHero({required this.canClaim, required this.nextDay, required this.game});

  @override
  Widget build(BuildContext context) {
    final day = nextDay.clamp(1, 7);
    return _Glass(
      radius: 28,
      tint: canClaim ? const Color(0xC00A2E22) : const Color(0xC0111114),
      border: canClaim ? _D.greenBdr : _D.line,
      glow: canClaim
          ? [BoxShadow(color: _D.green.withValues(alpha: 0.14), blurRadius: 28, offset: const Offset(0, 10))]
          : null,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (canClaim ? _D.green : _D.textLow).withValues(alpha: 0.12),
              border: Border.all(color: (canClaim ? _D.green : _D.textLow).withValues(alpha: 0.32)),
            ),
            child: Icon(
              canClaim ? Icons.card_giftcard_rounded : Icons.check_circle_rounded,
              color: canClaim ? _D.green : _D.textLow,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            canClaim ? 'Daily reward ready' : 'Already claimed today',
            textAlign: TextAlign.center,
            style: _sg(size: 22, weight: FontWeight.w700, spacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            canClaim ? 'Day $day of the 7-day cycle' : 'Come back tomorrow for the next reward',
            textAlign: TextAlign.center,
            style: _sg(size: 13, color: _D.textMid),
          ),
          if (canClaim) ...[
            const SizedBox(height: 18),
            _GradientButton(
              label: 'Claim day $day',
              icon: Icons.redeem_rounded,
              onTap: () async {
                HapticFeedback.mediumImpact();
                await game.claimDaily();
                if (context.mounted) _toast(context, 'Day $day reward claimed');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyCycleRow extends StatelessWidget {
  final List<_DailyInfo> rewards;
  final int nextDay;
  final bool canClaim;
  final GameStateService game;

  const _DailyCycleRow({
    required this.rewards,
    required this.nextDay,
    required this.canClaim,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final currentDay = nextDay.clamp(1, 7);
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: rewards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final day = index + 1;
          final info = rewards[index];
          final past = day < currentDay || (!canClaim && day <= currentDay);
          final current = canClaim && day == currentDay;
          final btc = game.dailyRewardBtc(day);
          final rig = game.dailyRewardRigId(day);
          final color = current ? _D.gold : past ? _D.green : _D.textLow;
          final value = btc != null && btc > 0
              ? '+${btc.toStringAsFixed(5)}'
              : rig != null
              ? 'Rig'
              : info.desc;

          return Container(
            width: 78,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: current
                  ? _D.gold.withValues(alpha: 0.13)
                  : past
                  ? _D.green.withValues(alpha: 0.08)
                  : const Color(0xB318181C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: current ? _D.goldBdr : past ? _D.greenBdr : _D.line,
                width: current ? 1.2 : 0.8,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(past ? Icons.check_rounded : (rig != null ? Icons.memory_rounded : Icons.hexagon_rounded), color: color, size: 18),
                const SizedBox(height: 7),
                Text('Day $day', style: _sg(size: 11, weight: FontWeight.w700, color: color)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _mono(size: 8.5, color: color.withValues(alpha: 0.85))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LuckySpinCard extends StatelessWidget {
  final LuckySpinService spin;
  const _LuckySpinCard({required this.spin});

  @override
  Widget build(BuildContext context) {
    return _FeatureCard(
      icon: Icons.casino_rounded,
      color: _D.violet,
      tint: const Color(0xFF1A1228),
      border: const Color(0xFF4C1D95),
      title: 'Lucky spin',
      subtitle: spin.canSpin ? 'Win SOL, boosts, or free rigs' : 'Available every 24 hours',
      action: 'Spin',
      enabled: spin.canSpin,
      onTap: spin.canSpin ? () => Navigator.of(context).pushNamed('/lucky-spin') : null,
    );
  }
}

class _MiniGameCard extends StatelessWidget {
  const _MiniGameCard();

  @override
  Widget build(BuildContext context) {
    final mini = context.watch<MiniGameService>();
    return _FeatureCard(
      icon: Icons.touch_app_rounded,
      color: _D.gold,
      tint: _D.goldBg,
      border: _D.goldBdr,
      title: 'Hash burst',
      subtitle: 'Land ${MiniGameService.tapTarget} hashes in ${MiniGameService.tapTimeSec}s · +${MiningEconomy.toSol(MiniGameService.rewardBtc).toStringAsFixed(6)} SOL · ${mini.playsLeft} left',
      action: 'Play',
      enabled: mini.canPlay,
      onTap: mini.canPlay ? () => Navigator.pushNamed(context, '/mini-game') : null,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final Color border;
  final String title;
  final String subtitle;
  final String action;
  final bool enabled;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.tint,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      border: enabled ? border : _D.line,
      child: Row(
        children: [
          _IconTile(icon: icon, color: color, tint: tint, border: border),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _sg(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: _sg(size: 12, color: _D.textMid, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(label: enabled ? action : 'Later', color: color, enabled: enabled, onTap: onTap),
        ],
      ),
    );
  }
}

class _DailyAdChallengeCard extends StatelessWidget {
  final AdPacingService pacing;
  final SmartAdManager ad;
  final AdRemoteConfigService adCfg;
  final GameStateService game;

  const _DailyAdChallengeCard({
    required this.pacing,
    required this.ad,
    required this.adCfg,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final progress = pacing.dailyAdChallengeProgress;
    final target = AdPacingService.dailyAdChallengeTarget;
    final claimed = pacing.dailyAdChallengeClaimed;
    final canClaim = pacing.canClaimDailyAdChallenge;
    final reward = MiningEconomy.toSol(AdPacingService.dailyAdChallengeRewardBtc).toStringAsFixed(6);

    return _Glass(
      border: canClaim ? _D.greenBdr : _D.electricBdr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconTile(icon: Icons.play_circle_filled_rounded, color: _D.electric, tint: _D.electricBg, border: _D.electricBdr),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watch 6 ads today', style: _sg(size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      claimed ? 'Done for today. Resets tomorrow.' : 'Every rewarded ad counts. Claim +$reward SOL at 6/6.',
                      style: _sg(size: 12, color: _D.textMid, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (progress / target).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: claimed ? _D.green : _D.electric,
            ),
          ),
          const SizedBox(height: 7),
          Text('$progress / $target ads today', style: _mono(size: 11, color: _D.textMid)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: ad.loadingRewarded ? '…' : 'Watch ad',
                  color: _D.electric,
                  enabled: !claimed && !ad.loadingRewarded,
                  onTap: () => _watch(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: claimed ? 'Claimed' : (canClaim ? 'Claim' : 'Locked'),
                  color: _D.green,
                  enabled: canClaim,
                  onTap: () async {
                    final ok = await pacing.claimDailyAdChallenge();
                    if (!ok || !context.mounted) return;
                    await game.grantDirectBtc(AdPacingService.dailyAdChallengeRewardBtc);
                    if (context.mounted) _toast(context, '+$reward SOL');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _watch(BuildContext context) async {
    final canShow = await pacing.canShowRewarded();
    if (!canShow) {
      if (context.mounted) _toast(context, 'Wait ${pacing.rewardedCooldownLeft().inSeconds}s before next ad.');
      return;
    }
    final shown = await ad.showRewarded(onEarned: () {});
    if (!context.mounted) return;
    if (shown) {
      await pacing.markRewardedShown();
      _toast(context, 'Ad counted · ${pacing.dailyAdChallengeProgress}/${AdPacingService.dailyAdChallengeTarget}');
    } else {
      _toast(context, ad.lastError ?? 'Ad not ready');
    }
  }
}

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
    return _Glass(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          _IconTile(icon: reward.icon, color: reward.accent, tint: reward.accent.withValues(alpha: 0.12), border: reward.accent.withValues(alpha: 0.28), size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.label, style: _sg(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(reward.desc, style: _mono(size: 11, color: reward.accent)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: loading ? '…' : 'Watch',
            color: reward.accent,
            enabled: !loading,
            onTap: () => _earn(context),
          ),
        ],
      ),
    );
  }

  Future<void> _earn(BuildContext context) async {
    final canShow = await pacing.canShowRewarded();
    if (!canShow) {
      if (context.mounted) _toast(context, 'Wait ${pacing.rewardedCooldownLeft().inSeconds}s before next ad.');
      return;
    }
    final shown = await ad.showRewarded(onEarned: () => game.grantAdReward(reward.type));
    if (!context.mounted) return;
    if (shown) {
      await pacing.markRewardedShown();
      _toast(context, 'Earned: ${reward.label}');
    } else {
      _toast(context, ad.lastError ?? 'Ad not ready');
    }
  }
}

class _MilestoneTile extends StatelessWidget {
  final _Milestone milestone;
  final GameStateService game;

  const _MilestoneTile({required this.milestone, required this.game});

  @override
  Widget build(BuildContext context) {
    final canClaim = game.canClaimMilestone(milestone.id);
    final claimed = game.claimedMilestones.contains(milestone.id);
    final color = claimed ? _D.green : canClaim ? _D.gold : _D.textLow;

    return _Glass(
      tint: claimed
          ? _D.green.withValues(alpha: 0.07)
          : canClaim
          ? _D.gold.withValues(alpha: 0.07)
          : const Color(0xB318181C),
      border: claimed ? _D.greenBdr : canClaim ? _D.goldBdr : _D.line,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          _IconTile(
            icon: claimed ? Icons.check_circle_rounded : milestone.icon,
            color: color,
            tint: color.withValues(alpha: 0.12),
            border: color.withValues(alpha: 0.28),
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.title, style: _sg(size: 14, weight: FontWeight.w700, color: claimed ? _D.textMid : _D.textHi)),
                const SizedBox(height: 2),
                Text(milestone.desc, style: _sg(size: 11.5, color: _D.textMid, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          claimed
              ? Text('Done', style: _sg(size: 12, weight: FontWeight.w700, color: _D.green))
              : _ActionButton(
            label: canClaim ? 'Claim' : 'Locked',
            color: color,
            enabled: canClaim,
            onTap: () async {
              await game.claimMilestone(milestone.id);
              if (context.mounted) _toast(context, '${milestone.title} claimed');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: _D.gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label.toUpperCase(), style: _sg(size: 10, weight: FontWeight.w700, color: _D.textMid, spacing: 1.5)),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final Color border;
  final double size;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.tint,
    required this.border,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.color, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gold = color == _D.gold && enabled;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gold ? const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]) : null,
            color: gold ? null : (enabled ? color.withValues(alpha: 0.13) : Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
            border: gold ? null : Border.all(color: enabled ? color.withValues(alpha: 0.34) : _D.line),
          ),
          child: Text(label, style: _sg(size: 12, weight: FontWeight.w800, color: gold ? Colors.white : (enabled ? color : _D.textLow))),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: _sg(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;
  final Color border;
  final List<BoxShadow>? glow;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.tint = const Color(0xF21F1F26),
    this.border = _D.line,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow ??
            [
              BoxShadow(
                color: const Color(0xFF9945FF).withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint.withValues(alpha: 0.96), const Color(0xE6121216)],
                ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border, width: 0.8),
              ),
              child: child,
            ),
            const Positioned(
              top: 0,
              left: 18,
              right: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                  child: SizedBox(height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(Offset(size.width * 0.9, 20), 190, const Color(0x349945FF));
    glow(Offset(-20, size.height * 0.62), 180, const Color(0x2214F195));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _sg(size: 13, weight: FontWeight.w600)),
      backgroundColor: _D.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _D.line)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);
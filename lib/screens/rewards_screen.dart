import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lucky_spin_service.dart';
import '../services/ad_pacing_service.dart';
import '../services/game_state_service.dart';
import '../services/smart_ad_manager.dart';
import '../theme/app_theme.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final ad = context.watch<SmartAdManager>();
    final pacing = context.watch<AdPacingService>();
    final spin = context.watch<LuckySpinService>();
    final canClaim = game.canClaimDaily;
    final nextDay = game.nextDailyStreakDay;
    final dailyRewards = _buildDailyRewards();
    final adRewards = _buildAdRewards();
    final milestones = _buildMilestones();

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Daily reward',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            color: canClaim ? AppTheme.primary.withValues(alpha: 0.2) : null,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    canClaim ? Icons.card_giftcard : Icons.check_circle,
                    size: 64,
                    color: canClaim ? AppTheme.primary : Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    canClaim ? 'Reward available!' : 'Today\'s reward already claimed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (canClaim) ...[
                    const SizedBox(height: 8),
                    Text(
                      nextDay >= 1 && nextDay <= 7
                          ? 'Day $nextDay of cycle'
                          : 'Day 1 of cycle',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await game.claimDaily();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reward claimed!')),
                            );
                          }
                        },
                        child: const Text('Claim'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '7-day cycle',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ...dailyRewards.asMap().entries.map((e) {
            final day = e.key + 1;
            final info = e.value;
            final btc = game.dailyRewardBtc(day);
            final rig = game.dailyRewardRigId(day);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                  child: Text('$day', style: const TextStyle(color: AppTheme.primary)),
                ),
                title: Text(info.label),
                subtitle: Text(info.desc),
                trailing: Text(
                  btc != null && btc > 0
                      ? '+${btc.toStringAsFixed(6)} BTC'
                      : rig != null
                          ? '1× ${info.rigLabel ?? rig}'
                          : '—',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Watch ad rewards',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Watch a short ad to earn one of these rewards.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ...adRewards.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.btcGold.withValues(alpha: 0.3),
                      child: Icon(r.icon, color: AppTheme.btcGold),
                    ),
                    title: Text(r.label),
                    subtitle: Text(r.desc),
                    trailing: FilledButton.icon(
                      onPressed: ad.loadingRewarded
                          ? null
                          : () async {
                              final canShowRewarded = await pacing.canShowRewarded();
                              if (!canShowRewarded) {
                                if (context.mounted) {
                                  final left = pacing.rewardedCooldownLeft().inSeconds;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Please wait ${left}s before next rewarded ad.')),
                                  );
                                }
                                return;
                              }
                              final shown = await ad.showRewarded(
                                onEarned: () => game.grantAdReward(r.type),
                              );
                              if (context.mounted) {
                                if (shown) {
                                  await pacing.markRewardedShown();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Earned: ${r.label}')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(ad.lastError ?? 'Ad not ready')),
                                  );
                                }
                              }
                            },
                      icon: ad.loadingRewarded ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_circle_filled, size: 20),
                      label: Text(ad.loadingRewarded ? 'Loading...' : 'Watch ad'),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 20),
          Text(
            'Milestone rewards',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          ...milestones.map((m) {
            final canClaimMilestone = game.canClaimMilestone(m.id);
            final claimed = game.claimedMilestones.contains(m.id);
            return Card(
              child: ListTile(
                leading: Icon(m.icon, color: claimed ? Colors.green : AppTheme.primary),
                title: Text(m.title),
                subtitle: Text(m.desc),
                trailing: FilledButton(
                  onPressed: canClaimMilestone
                      ? () async {
                          await game.claimMilestone(m.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Claimed: ${m.title}')),
                            );
                          }
                        }
                      : null,
                  child: Text(claimed ? 'Claimed' : 'Claim'),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text(
            'Lucky spin wheel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              leading: const Icon(Icons.casino, color: AppTheme.primary),
              title: const Text('Daily spin'),
              subtitle: Text(spin.canSpin
                  ? 'Spin now to win BTC / boosts / free rigs'
                  : 'Available every 24 hours'),
              trailing: FilledButton(
                onPressed: spin.canSpin
                    ? () async {
                        final result = await spin.spin();
                        if (result == null) return;
                        if (result.btc > 0) await game.grantDirectBtc(result.btc);
                        if (result.rigId != null) await game.grantRig(result.rigId!);
                        if (result.boost != null) await game.activateBoost(duration: result.boost!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Spin reward: ${result.label}')),
                          );
                        }
                      }
                    : null,
                child: const Text('Spin'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DailyInfo> _buildDailyRewards() {
    return const [
      _DailyInfo('Day 1', '10 coins', null),
      _DailyInfo('Day 2', '50 coins', null),
      _DailyInfo('Day 3', 'GPU rig', 'GPU rig'),
      _DailyInfo('Day 4', 'Bonus BTC', null),
      _DailyInfo('Day 5', 'Bonus BTC', null),
      _DailyInfo('Day 6', 'Bonus BTC', null),
      _DailyInfo('Day 7', 'Rare miner', 'Mining rack'),
    ];
  }

  List<_AdReward> _buildAdRewards() {
    return const [
      _AdReward('small_btc', 'Small BTC bonus', '+0.00001 BTC', Icons.monetization_on),
      _AdReward('medium_btc', 'Medium BTC bonus', '+0.00005 BTC', Icons.savings),
      _AdReward('large_btc', 'Large BTC bonus', '+0.0001 BTC', Icons.diamond),
      _AdReward('boost_15m', '2× Boost 15 min', 'Double mining for 15 min', Icons.bolt),
      _AdReward('gpu_rig', 'Free GPU rig', '1× GPU rig', Icons.memory),
    ];
  }

  List<_Milestone> _buildMilestones() {
    return const [
      _Milestone('sessions_5', 'Session Starter', 'Start 5 mining sessions · reward +0.00005 BTC', Icons.rocket_launch),
      _Milestone('sessions_20', 'Session Veteran', 'Start 20 sessions · reward 1x Mining rack', Icons.workspace_premium),
      _Milestone('lifetime_0005', 'Half-milli Miner', 'Mine 0.0005 BTC total · reward +0.0001 BTC', Icons.track_changes),
    ];
  }
}

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
  const _AdReward(this.type, this.label, this.desc, this.icon);
}

class _Milestone {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  const _Milestone(this.id, this.title, this.desc, this.icon);
}

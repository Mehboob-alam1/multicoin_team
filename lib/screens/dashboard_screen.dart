import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mining_location.dart';
import '../services/btc_price_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../theme/app_theme.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/minimizable_native_ad.dart';
import '../widgets/smart_banner_ad.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BtcPriceService>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final btcPrice = context.watch<BtcPriceService>();
    final progression = context.watch<ProgressionService>();
    final dailyBoost = context.watch<DailyBoostService>();
    final drop = context.watch<RandomDropService>();
    final energy = context.watch<EnergyCoolingService>();
    final idle = game.getIdleEarnedIfAny();
    final worthUsd = btcPrice.balanceWorthUsd(game.btcBalance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (game.syncInProgress)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              ),
            ),
          if (game.lastSyncError != null && !game.syncInProgress)
            Tooltip(
              message: game.lastSyncError!,
              child: const Icon(Icons.cloud_off, color: Colors.orange, size: 22),
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (idle != null && idle > 0) ...[
            Card(
              color: AppTheme.btcGold.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppTheme.btcGold, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.btcGold,
                                ),
                          ),
                          Text(
                            'Your miners generated ${idle.toStringAsFixed(8)} BTC while you were away.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'BTC Balance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.btcBalance.toStringAsFixed(8),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (worthUsd != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '≈ \$${worthUsd.toStringAsFixed(2)} USD',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.speed, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${game.totalBtcPerMin.toStringAsFixed(8)} BTC/min',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                  if (game.isBoostActive || game.isPremiumActive) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        if (game.isBoostActive)
                          Chip(
                            label: const Text('2x Boost', style: TextStyle(fontSize: 11)),
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (game.isPremiumActive)
                          Chip(
                            label: const Text('Premium', style: TextStyle(fontSize: 11)),
                            backgroundColor: AppTheme.btcGold.withValues(alpha: 0.3),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mining session', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    game.isSessionActive
                        ? 'Active · ${game.sessionTimeLeft.inMinutes}m left · Session bonus x1.25'
                        : 'No active session · Start one for temporary hash bonus',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: game.isSessionActive
                          ? null
                          : () async {
                              await game.startMiningSession();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mining session started (30 min)')),
                                );
                              }
                            },
                      icon: const Icon(Icons.timer),
                      label: Text(game.isSessionActive ? 'Session running' : 'Start 30m session'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mining map progression', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: MiningLocations.all.map((loc) {
                      final unlocked = progression.unlockedLocations.contains(loc.id);
                      return Chip(
                        label: Text(loc.name, style: const TextStyle(fontSize: 11)),
                        backgroundColor: unlocked
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : Colors.white10,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bolt, color: AppTheme.primary),
              title: const Text('Daily mining boost'),
              subtitle: Text(dailyBoost.canClaim
                  ? 'Available now: 2x speed for 30 minutes'
                  : (dailyBoost.isActive
                      ? 'Active until ${dailyBoost.activeUntil?.hour.toString().padLeft(2, '0')}:${dailyBoost.activeUntil?.minute.toString().padLeft(2, '0')}'
                      : 'Claim available every 24 hours')),
              trailing: FilledButton(
                onPressed: dailyBoost.canClaim
                    ? () async {
                        final ok = await dailyBoost.claim();
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Daily boost activated: 2x for 30m')),
                          );
                        }
                      }
                    : null,
                child: const Text('Claim'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (drop.isAvailable)
            Card(
              color: AppTheme.btcGold.withValues(alpha: 0.15),
              child: ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppTheme.btcGold),
                title: const Text('A hidden crypto block appeared!'),
                subtitle: const Text('Tap to collect bonus BTC'),
                trailing: FilledButton(
                  onPressed: () async {
                    final bonus = await drop.collect();
                    if (bonus != null) {
                      await game.grantDirectBtc(bonus);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Collected +${(bonus ?? 0).toStringAsFixed(6)} BTC')),
                      );
                    }
                  },
                  child: const Text('Collect'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.thermostat, color: AppTheme.primary),
              title: const Text('Energy & cooling'),
              subtitle: Text('Heat ${energy.heat.toStringAsFixed(1)}% · Efficiency x${energy.efficiencyMultiplier.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 16),
          const BtcPriceChart(),
          const SizedBox(height: 24),
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.diamond, color: AppTheme.primary),
              title: const Text('Active rigs'),
              trailing: Text('${game.ownedRigIds.length}'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.factory, color: AppTheme.primary),
              title: const Text('Farm tier'),
              subtitle: Text('Capacity ${game.ownedRigIds.length}/${game.rigCapacity}'),
              trailing: Text(game.currentFarmTier.name),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.query_stats, color: AppTheme.primary),
              title: const Text('Lifetime mined'),
              trailing: Text('${game.lifetimeMinedBtc.toStringAsFixed(6)} BTC'),
            ),
          ),
          const SizedBox(height: 8),
          const MinimizableNativeAd(title: 'Sponsored offer'),
          const SizedBox(height: 8),
          const Center(child: SmartBannerAd()),
        ],
      ),
    );
  }
}

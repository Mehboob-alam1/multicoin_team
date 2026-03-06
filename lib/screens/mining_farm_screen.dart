import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mining_rig.dart';
import '../services/game_state_service.dart';
import '../theme/app_theme.dart';

class MiningFarmScreen extends StatelessWidget {
  const MiningFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final counts = <String, int>{};
    for (final id in game.ownedRigIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mining Farm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.currentFarmTier.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Capacity: ${game.ownedRigIds.length}/${game.rigCapacity} rigs · Farm multiplier: x${game.currentFarmTier.miningMultiplier.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  if (game.nextFarmTier != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: game.btcBalance >= game.nextFarmTier!.upgradeCostBtc
                            ? () async {
                                await game.upgradeFarm();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Farm upgraded to ${game.currentFarmTier.name}')),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.upgrade),
                        label: Text(
                          'Upgrade farm (${game.nextFarmTier!.upgradeCostBtc} BTC)',
                        ),
                      ),
                    )
                  else
                    Text(
                      'Maximum farm tier reached',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Power', value: '${game.totalBtcPerMin.toStringAsFixed(8)} BTC/min'),
                  _Stat(label: 'Total rigs', value: '${game.ownedRigIds.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...MiningRigs.all.map((rig) {
            final count = counts[rig.id] ?? 0;
            final cost = game.rigCost(rig);
            final canBuy = rig.costBtc > 0 && game.canAfford(rig) && game.canBuyMoreRigs;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                    child: Icon(_iconForRig(rig.id), color: AppTheme.primary),
                  ),
                  title: Text(rig.name),
                  subtitle: Text(
                    '${rig.btcPerMin} BTC/min${count > 0 ? ' · Owned: $count' : ''}${rig.costBtc > 0 ? ' · ${cost.toStringAsFixed(6)} BTC' : ' (starter)'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Chip(
                          label: Text('x$count'),
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      if (rig.costBtc > 0) ...[
                        if (count > 0) const SizedBox(width: 8),
                        FilledButton(
                          onPressed: canBuy
                              ? () async {
                                  await game.buyRig(rig);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Purchased: ${rig.name}')),
                                    );
                                  }
                                }
                              : null,
                          child: const Text('Buy'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          if (!game.canBuyMoreRigs)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Farm capacity reached. Upgrade your farm to buy more rigs.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForRig(String id) {
    switch (id) {
      case 'laptop': return Icons.laptop;
      case 'gpu_rig': return Icons.memory;
      case 'mining_rack': return Icons.view_module;
      case 'warehouse_farm': return Icons.warehouse;
      case 'mega_facility': return Icons.diamond;
      default: return Icons.hardware;
    }
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
      ],
    );
  }
}

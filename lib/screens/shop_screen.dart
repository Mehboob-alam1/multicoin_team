import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mining_rig.dart';
import '../models/shop_product.dart';
import '../services/event_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/minimizable_native_ad.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final iap = context.watch<IapService>();
    final events = context.watch<EventService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          TextButton.icon(
            onPressed: iap.loading ? null : () => iap.restorePurchases(),
            icon: const Icon(Icons.restore, size: 20),
            label: const Text('Restore'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${game.btcBalance.toStringAsFixed(4)} BTC',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
                  ),
                  if (game.isPremiumActive)
                    Text('PREMIUM', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.btcGold)),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rigs', icon: Icon(Icons.memory, size: 20)),
            Tab(text: 'One-time', icon: Icon(Icons.card_giftcard, size: 20)),
            Tab(text: 'Premium', icon: Icon(Icons.workspace_premium, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _MonetizationHeroCard(game: game),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: MinimizableNativeAd(title: 'Sponsored deal'),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RigsTab(game: game, eventService: events),
                _OneTimeTab(game: game, iap: iap),
                _PremiumTab(game: game, iap: iap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonetizationHeroCard extends StatelessWidget {
  final GameStateService game;
  const _MonetizationHeroCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Card(
        color: AppTheme.primary.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.isPremiumActive ? 'Boost your premium further' : 'Grow faster with packs & premium',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.primary),
                    ),
                    Text(
                      game.isPremiumActive
                          ? 'Extend premium for longer 1.5x gains and better compounding.'
                          : 'Starter packs and premium reduce grind time and unlock stronger mining early.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RigsTab extends StatelessWidget {
  final GameStateService game;
  final EventService eventService;

  const _RigsTab({required this.game, required this.eventService});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (eventService.rigDiscount > 0)
          Card(
            color: AppTheme.btcGold.withValues(alpha: 0.18),
            child: ListTile(
              leading: const Icon(Icons.local_offer, color: AppTheme.btcGold),
              title: Text('${(eventService.rigDiscount * 100).toStringAsFixed(0)}% Rig Sale Event'),
              subtitle: const Text('Weekly event active from Firebase config'),
            ),
          ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_graph, color: AppTheme.primary),
            title: const Text('Compounding tip'),
            subtitle: const Text(
              'Earlier rig upgrades snowball your BTC output. Buy capacity and rate upgrades first.',
            ),
          ),
        ),
        ...MiningRigs.all.where((r) => r.costBtc > 0).map((rig) {
        final canBuy = game.canAfford(rig) && game.canBuyMoreRigs;
        final cost = game.rigCost(rig);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                child: Icon(_iconForRig(rig.id), color: AppTheme.primary),
              ),
              title: Text(rig.name),
              subtitle: Text(
                '${rig.btcPerMin} BTC/min · ${cost.toStringAsFixed(6)} BTC${!canBuy ? " · You have ${game.btcBalance.toStringAsFixed(6)} BTC" : ""}',
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  if (!canBuy) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            !game.canBuyMoreRigs
                                ? 'Farm capacity reached. Upgrade farm first.'
                                : 'Need ${cost.toStringAsFixed(6)} BTC. You have ${game.btcBalance.toStringAsFixed(6)} BTC. Keep mining!',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  await game.buyRig(rig);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Purchased: ${rig.name}')),
                    );
                  }
                },
                child: const Text('Buy'),
              ),
            ),
          ),
        );
      }).toList(),
      ],
    );
  }

  IconData _iconForRig(String id) {
    switch (id) {
      case 'gpu_rig': return Icons.memory;
      case 'mining_rack': return Icons.view_module;
      case 'warehouse_farm': return Icons.warehouse;
      case 'mega_facility': return Icons.diamond;
      default: return Icons.hardware;
    }
  }
}

class _OneTimeTab extends StatelessWidget {
  final GameStateService game;
  final IapService iap;

  const _OneTimeTab({required this.game, required this.iap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (iap.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: Colors.orange.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(iap.error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange)),
              ),
            ),
          ),
        Card(
          color: AppTheme.btcGold.withValues(alpha: 0.12),
          child: const ListTile(
            leading: Icon(Icons.local_fire_department, color: AppTheme.btcGold),
            title: Text('Limited-time value'),
            subtitle: Text('One-time packs give instant mining acceleration and stack with premium.'),
          ),
        ),
        ...ShopProducts.oneTime.map((product) {
          final purchased = game.hasPurchasedOneTime(product.id);
          final canBuyBtc = product.isBtcPrice && game.btcBalance >= _parseBtcPrice(product.price);
          final storeProduct = iap.getProduct(product.id);
          final priceStr = storeProduct?.price ?? product.price;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(product.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                              Text(product.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        Text(priceStr, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: purchased
                            ? null
                            : (product.isBtcPrice ? canBuyBtc : true)
                                ? () => _onPurchase(context, product)
                                : null,
                        child: Text(
                          purchased
                              ? 'Owned'
                              : product.isBtcPrice
                                  ? 'Buy with BTC'
                                  : (iap.available && storeProduct != null ? 'Buy' : 'Claim'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  double _parseBtcPrice(String price) {
    final s = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(s) ?? 0;
  }

  Future<void> _onPurchase(BuildContext context, OneTimeProduct product) async {
    if (product.isBtcPrice) {
      const cost = 0.00005;
      if (!game.canSpendBtc(cost)) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Need 0.00005 BTC')));
        return;
      }
      await game.deductBtc(cost);
      await game.activateBoost1h();
      await game.applyOneTimePurchase(productId: product.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2x Boost active for 1 hour!')));
      return;
    }
    final useStore = iap.available && iap.getProduct(product.id) != null;
    if (useStore) {
      final success = await iap.buyProduct(product.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete purchase in the store. Reward will apply when done.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(iap.error ?? 'Purchase failed')));
        }
      }
      return;
    }
    await game.applyOneTimePurchase(
      productId: product.id,
      btcAmount: product.btcAmount,
      rigId: product.rigId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claimed: ${product.name}')));
    }
  }
}

class _PremiumTab extends StatelessWidget {
  final GameStateService game;
  final IapService iap;

  const _PremiumTab({required this.game, required this.iap});

  @override
  Widget build(BuildContext context) {
    final isPremium = game.isPremiumActive;
    final expiry = game.isPremiumActive ? _formatExpiry(game.premiumExpiry) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isPremium)
          Card(
            color: AppTheme.btcGold.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppTheme.btcGold, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Premium active', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.btcGold)),
                        Text('1.5x mining rate · No ads${expiry != null ? " · Until $expiry" : ""}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isPremium) const SizedBox(height: 16),
        if (!isPremium)
          Card(
            color: AppTheme.btcGold.withValues(alpha: 0.14),
            child: const ListTile(
              leading: Icon(Icons.workspace_premium, color: AppTheme.btcGold),
              title: Text('Best long-term value'),
              subtitle: Text('Premium adds 1.5x mining speed continuously and combines with boosts/events.'),
            ),
          ),
        ...ShopProducts.premiumPlans.map((plan) {
          final storeProduct = iap.getProduct(plan.id);
          final priceStr = storeProduct?.price ?? plan.price;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: AppTheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                              Text(plan.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        Text(priceStr, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.primary)),
                      ],
                    ),
                    if (plan.benefits.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: plan.benefits.map((b) => Chip(label: Text(b, style: const TextStyle(fontSize: 11)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _subscribe(context, plan),
                        icon: const Icon(Icons.star, size: 20),
                        label: Text(iap.loading ? 'Loading...' : (isPremium ? 'Extend' : (iap.available && storeProduct != null ? 'Subscribe' : 'Claim'))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatExpiry(DateTime? e) => e != null ? '${e.day}/${e.month}/${e.year}' : '';

  Future<void> _subscribe(BuildContext context, PremiumPlan plan) async {
    final useStore = iap.available && iap.getProduct(plan.id) != null;
    if (useStore) {
      final success = await iap.buySubscription(plan.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete in the store. Premium will activate when done.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(iap.error ?? 'Purchase failed')));
        }
      }
      return;
    }
    await game.activatePremium(plan.id, plan.durationDays);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${plan.name} activated!')));
    }
  }
}

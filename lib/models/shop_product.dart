/// One-time IAP or in-game product (e.g. starter pack, boost).
class OneTimeProduct {
  final String id;
  final String name;
  final String description;
  final String price; // e.g. "\$2.99" or "0.005 BTC"
  final bool isBtcPrice; // if true, price is in BTC (in-game currency)
  final double? btcAmount; // BTC granted when bought (if applicable)
  final String? rigId; // rig granted when bought (if applicable)
  final String icon; // icon name or emoji

  const OneTimeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isBtcPrice = false,
    this.btcAmount,
    this.rigId,
    this.icon = '🎁',
  });
}

/// Premium subscription plan.
class PremiumPlan {
  final String id;
  final String name;
  final String description;
  final String price;
  final String period; // "month" or "year"
  final int durationDays;
  final List<String> benefits;

  const PremiumPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.durationDays,
    this.benefits = const [],
  });
}

class ShopProducts {
  static const oneTime = [
    OneTimeProduct(
      id: 'starter_pack',
      name: 'Starter Pack',
      description: 'Small BTC + 1 GPU rig',
      price: '\$1.99',
      btcAmount: 0.00005,
      rigId: 'gpu_rig',
      icon: '📦',
    ),
    OneTimeProduct(
      id: 'satoshi_pack',
      name: 'Satoshi Pack',
      description: '~2 days mining worth',
      price: '\$4.99',
      btcAmount: 0.0002,
      icon: '₿',
    ),
    OneTimeProduct(
      id: 'boost_2x_1h',
      name: '2x Boost (1 hour)',
      description: 'Double mining rate for 1 hour',
      price: '0.00005 BTC',
      isBtcPrice: true,
      icon: '⚡',
    ),
    OneTimeProduct(
      id: 'mega_pack',
      name: 'Mega Pack',
      description: 'Larger BTC + Mining rack',
      price: '\$9.99',
      btcAmount: 0.0005,
      rigId: 'mining_rack',
      icon: '💎',
    ),
  ];

  static const premiumPlans = [
    PremiumPlan(
      id: 'premium_monthly',
      name: 'Premium Monthly',
      description: 'Exclusive rigs, 1.5x mining, no ads',
      price: '\$4.99',
      period: 'month',
      durationDays: 30,
      benefits: ['1.5x mining rate', 'Exclusive rigs', 'No ads', 'VIP badge'],
    ),
    PremiumPlan(
      id: 'premium_yearly',
      name: 'Premium Yearly',
      description: 'Best value — save 50%',
      price: '\$29.99',
      period: 'year',
      durationDays: 365,
      benefits: ['1.5x mining rate', 'Exclusive rigs', 'No ads', 'VIP badge', 'Save 50%'],
    ),
  ];

  static OneTimeProduct? oneTimeById(String id) {
    try {
      return oneTime.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static PremiumPlan? planById(String id) {
    try {
      return premiumPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

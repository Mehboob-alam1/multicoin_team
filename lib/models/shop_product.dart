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

  /// Google Play Console in-app product ID (must match exactly).
  String get googleProductId => id;
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

  /// Google Play Console subscription product ID (must match exactly).
  String get googleProductId => id;
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
      price: '\$0.99',
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
    OneTimeProduct(
      id: 'season_pass',
      name: 'Season Pass',
      description: 'Unlock premium season rewards',
      price: '\$2.99',
      icon: '🏆',
    ),
    // ─── Farm rigs (IAP USD only on Farm screen — no BTC) ───────────────────
    OneTimeProduct(
      id: 'laptop_rig',
      name: 'Laptop miner',
      description: '1× Laptop miner rig for your farm',
      price: '\$0.99',
      rigId: 'laptop',
      icon: '💻',
    ),
    OneTimeProduct(
      id: 'rig_gpu',
      name: 'GPU rig',
      description: '1× GPU rig for your farm',
      price: '\$2.99',
      rigId: 'gpu_rig',
      icon: '🖥',
    ),
    OneTimeProduct(
      id: 'rig_rack',
      name: 'Mining rack',
      description: '1× Mining rack for your farm',
      price: '\$9.99',
      rigId: 'mining_rack',
      icon: '📦',
    ),
    OneTimeProduct(
      id: 'warehouse_farm_rig',
      name: 'Warehouse farm',
      description: '1× Warehouse farm rig',
      price: '\$19.99',
      rigId: 'warehouse_farm',
      icon: '🏭',
    ),
    OneTimeProduct(
      id: 'mega_facility_rig',
      name: 'Mega mining facility',
      description: '1× Mega mining facility rig',
      price: '\$49.99',
      rigId: 'mega_facility',
      icon: '🌟',
    ),
    // ─── Multi-coin farm rigs (same USD/IAP flow as legacy rigs) ────────────
    OneTimeProduct(
      id: 'cpu_miner_rig',
      name: 'CPU Miner',
      description: '1× CPU miner (multi-coin)',
      price: '\$0.99',
      rigId: 'cpu_miner',
      icon: '🧮',
    ),
    OneTimeProduct(
      id: 'gaming_gpu_rig_iap',
      name: 'Gaming GPU Rig',
      description: '1× Gaming GPU rig (multi-coin)',
      price: '\$2.99',
      rigId: 'gaming_gpu_rig',
      icon: '🎮',
    ),
    OneTimeProduct(
      id: 'gpu_cluster_rig',
      name: 'GPU Mining Cluster',
      description: '1× GPU mining cluster (multi-coin)',
      price: '\$9.99',
      rigId: 'gpu_cluster',
      icon: '📊',
    ),
    OneTimeProduct(
      id: 'asic_btc_rig',
      name: 'ASIC Bitcoin Miner',
      description: '1× ASIC Bitcoin miner',
      price: '\$19.99',
      rigId: 'asic_btc',
      icon: '⚡',
    ),
    OneTimeProduct(
      id: 'data_center_rig_iap',
      name: 'Advanced Data Center Rig',
      description: '1× Advanced data center rig (multi-coin)',
      price: '\$49.99',
      rigId: 'data_center_rig',
      icon: '🏢',
    ),
    // ─── Premium one-time mining items (all under $200) ─────────────────────
    OneTimeProduct(
      id: 'hash_booster_20',
      name: 'Hash Booster',
      description: 'Permanent +6% mining rate',
      price: '\$19.99',
      icon: '🔧',
    ),
    OneTimeProduct(
      id: 'power_pack_30',
      name: 'Power Miner Pack',
      description: 'Permanent +8% mining rate + 0.0003 BTC',
      price: '\$29.99',
      btcAmount: 0.0003,
      icon: '⚡',
    ),
    OneTimeProduct(
      id: 'pro_upgrade_50',
      name: 'Pro Mining Upgrade',
      description: 'Permanent +12% mining rate + 0.0008 BTC',
      price: '\$49.99',
      btcAmount: 0.0008,
      icon: '💎',
    ),
    OneTimeProduct(
      id: 'elite_bundle_100',
      name: 'Elite Hash Bundle',
      description: 'Permanent +18% mining rate + 0.002 BTC',
      price: '\$99.99',
      btcAmount: 0.002,
      icon: '🏆',
    ),
    OneTimeProduct(
      id: 'tycoon_kit_150',
      name: 'Tycoon Mining Kit',
      description: 'Permanent +22% mining rate + 0.004 BTC',
      price: '\$149.99',
      btcAmount: 0.004,
      icon: '👑',
    ),
    OneTimeProduct(
      id: 'ultimate_pack_200',
      name: 'Ultimate Miner Pack',
      description: 'Permanent +25% mining rate + 0.006 BTC',
      price: '\$199.00',
      btcAmount: 0.006,
      icon: '🌟',
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

  /// IAP product IDs for rigs sold on the Mining Farm (repeatable purchases / consumable in Play).
  static const farmRigIapProductIds = <String>{
    'laptop_rig',
    'rig_gpu',
    'rig_rack',
    'warehouse_farm_rig',
    'mega_facility_rig',
    'cpu_miner_rig',
    'gaming_gpu_rig_iap',
    'gpu_cluster_rig',
    'asic_btc_rig',
    'data_center_rig_iap',
  };

  /// True for farm rig SKUs that can be bought more than once (each purchase adds a rig).
  static bool isRepeatableFarmRigProduct(String productId) =>
      farmRigIapProductIds.contains(productId);

  /// Shop packs / boosts / upgrades — not farm rig SKUs (those are sold on Farm).
  static List<OneTimeProduct> get shopPacks =>
      oneTime.where((p) => !farmRigIapProductIds.contains(p.id)).toList();

  /// Google Play one-time in-app product IDs (managed products).
  static Set<String> get googlePlayOneTimeIds =>
      {for (final p in oneTime) p.googleProductId};

  /// Google Play subscription product IDs.
  static Set<String> get googlePlaySubscriptionIds =>
      {for (final p in premiumPlans) p.googleProductId};

  /// All Google Play product IDs queried at billing init.
  static Set<String> get googlePlayAllIds =>
      {...googlePlayOneTimeIds, ...googlePlaySubscriptionIds};

  /// Consumable in Play Console: farm rigs (repeatable) and the 1-hour boost.
  static bool isConsumableGoogleProduct(String productId) =>
      farmRigIapProductIds.contains(productId) || productId == 'boost_2x_1h';

  static String iapCategory(String productId) {
    if (googlePlaySubscriptionIds.contains(productId)) return 'premium';
    if (farmRigIapProductIds.contains(productId)) return 'farm_rig';
    return 'one_time';
  }

  /// One-time IAP product for this rig on the Farm screen (USD only, not starter_pack).
  static OneTimeProduct? farmIapProductForRig(String rigId) {
    final id = switch (rigId) {
      'laptop' => 'laptop_rig',
      'gpu_rig' => 'rig_gpu',
      'mining_rack' => 'rig_rack',
      'warehouse_farm' => 'warehouse_farm_rig',
      'mega_facility' => 'mega_facility_rig',
      'cpu_miner' => 'cpu_miner_rig',
      'gaming_gpu_rig' => 'gaming_gpu_rig_iap',
      'gpu_cluster' => 'gpu_cluster_rig',
      'asic_btc' => 'asic_btc_rig',
      'data_center_rig' => 'data_center_rig_iap',
      _ => null,
    };
    return id != null ? oneTimeById(id) : null;
  }

  static PremiumPlan? planById(String id) {
    try {
      return premiumPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

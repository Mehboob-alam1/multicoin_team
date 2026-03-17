import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/shop_product.dart';

/// Product IDs must match Google Play Console & App Store Connect.
class IapService extends ChangeNotifier {
  static const oneTimeIds = {
    'starter_pack', 'satoshi_pack', 'mega_pack', 'boost_2x_1h', 'season_pass',
    'hash_booster_20', 'power_pack_30', 'pro_upgrade_50',
    'elite_bundle_100', 'tycoon_kit_150', 'ultimate_pack_200',
  };
  static const subscriptionIds = {'premium_monthly', 'premium_yearly'};
  static const allIds = {...oneTimeIds, ...subscriptionIds};

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _available = false;
  bool _loading = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get available => _available;
  bool get loading => _loading;
  String? get error => _error;

  /// Called when a purchase or restore completes. App should apply reward and record in Firebase.
  void Function(String productId, bool isSubscription, int durationDays)? onPurchaseSuccess;

  ProductDetails? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      _error = 'Store not available';
      notifyListeners();
      return;
    }
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!_available) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _iap.queryProductDetails(allIds);
      if (response.notFoundIDs.isNotEmpty) {
        _error = 'Products not found: ${response.notFoundIDs.join(", ")}. Configure them in Play Console / App Store Connect.';
      }
      _products = response.productDetails;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> details) {
    for (final d in details) {
      if (d.status == PurchaseStatus.purchased || d.status == PurchaseStatus.restored) {
        _deliverPurchase(d.productID);
        if (d.pendingCompletePurchase) _iap.completePurchase(d);
      }
    }
  }

  void _deliverPurchase(String productId) {
    final isSubscription = subscriptionIds.contains(productId);
    int durationDays = 30;
    if (productId == 'premium_yearly') durationDays = 365;
    onPurchaseSuccess?.call(productId, isSubscription, durationDays);
  }

  /// Start purchase flow for one-time product (starter_pack, satoshi_pack, mega_pack, boost_2x_1h).
  Future<bool> buyProduct(String productId) async {
    final product = getProduct(productId);
    if (product == null) return false;
    try {
      return await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Start purchase flow for subscription (premium_monthly, premium_yearly).
  Future<bool> buySubscription(String productId) async {
    final product = getProduct(productId);
    if (product == null) return false;
    try {
      return await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Restore previous purchases; results come via purchaseStream and onPurchaseSuccess.
  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

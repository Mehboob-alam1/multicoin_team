import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/shop_product.dart';

/// Result of a verified Google Play (or App Store) purchase.
class IapPurchaseDelivery {
  final String productId;
  final bool isSubscription;
  final int durationDays;
  final String? purchaseId;
  final String? purchaseToken;
  final String source;

  const IapPurchaseDelivery({
    required this.productId,
    required this.isSubscription,
    required this.durationDays,
    this.purchaseId,
    this.purchaseToken,
    this.source = 'google_play',
  });
}

/// Product IDs come from [ShopProducts] and must match Google Play Console.
class IapService extends ChangeNotifier {
  static Set<String> get oneTimeIds => ShopProducts.googlePlayOneTimeIds;
  static Set<String> get subscriptionIds => ShopProducts.googlePlaySubscriptionIds;
  static Set<String> get allIds => ShopProducts.googlePlayAllIds;

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _available = false;
  bool _loading = false;
  bool _initialized = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Set<String> _fulfilledKeys = {};

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get available => _available;
  bool get loading => _loading;
  String? get error => _error;

  /// Called when a Google Play / store purchase or restore completes.
  void Function(IapPurchaseDelivery delivery)? onPurchaseSuccess;

  ProductDetails? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// True when billing is up and this Google Play product was returned by the store.
  bool isGoogleProductReady(String productId) =>
      _available && getProduct(productId) != null;

  Future<void> init() async {
    if (_initialized && _available) {
      await loadProducts();
      return;
    }
    _available = await _iap.isAvailable();
    if (!_available) {
      _error = 'Google Play Billing is not available on this device.';
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
    _initialized = true;
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
        _error =
            'Google Play products not found: ${response.notFoundIDs.join(", ")}. '
            'Create these IDs in Play Console (In-app products / Subscriptions) '
            'and publish to the same package name.';
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
        _deliverPurchase(d);
        if (d.pendingCompletePurchase) _iap.completePurchase(d);
      } else if (d.status == PurchaseStatus.error) {
        _error = d.error?.message ?? 'Purchase failed';
        notifyListeners();
        if (d.pendingCompletePurchase) _iap.completePurchase(d);
      }
    }
  }

  void _deliverPurchase(PurchaseDetails details) {
    final token = details.verificationData.serverVerificationData;
    final key = details.purchaseID ?? token;
    if (key.isNotEmpty && !_fulfilledKeys.add(key)) return;

    final productId = details.productID;
    final isSubscription = subscriptionIds.contains(productId);
    var durationDays = 30;
    if (productId == 'premium_yearly') durationDays = 365;
    final plan = ShopProducts.planById(productId);
    if (plan != null) durationDays = plan.durationDays;

    onPurchaseSuccess?.call(IapPurchaseDelivery(
      productId: productId,
      isSubscription: isSubscription,
      durationDays: durationDays,
      purchaseId: details.purchaseID,
      purchaseToken: token.isNotEmpty ? token : null,
      source: details.verificationData.source.isNotEmpty
          ? details.verificationData.source
          : 'google_play',
    ));
  }

  /// One-time Google Play product. Farm rigs + 1h boost are consumable.
  Future<bool> buyProduct(String productId) async {
    var product = getProduct(productId);
    if (product == null) {
      await loadProducts();
      product = getProduct(productId);
    }
    if (product == null) {
      _error = 'Google Play product "$productId" is not available. Check Play Console.';
      notifyListeners();
      return false;
    }
    try {
      final param = PurchaseParam(productDetails: product);
      if (ShopProducts.isConsumableGoogleProduct(productId)) {
        return await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
      }
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Google Play subscription (`premium_monthly`, `premium_yearly`).
  Future<bool> buySubscription(String productId) async {
    var product = getProduct(productId);
    if (product == null) {
      await loadProducts();
      product = getProduct(productId);
    }
    if (product == null) {
      _error = 'Google Play subscription "$productId" is not available. Check Play Console.';
      notifyListeners();
      return false;
    }
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

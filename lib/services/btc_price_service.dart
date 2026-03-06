import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches real BTC price from CoinGecko (free, no API key).
/// Rate limit: ~10–15 calls/min.
class BtcPriceService extends ChangeNotifier {
  static const _base = 'https://api.coingecko.com/api/v3';
  double? _priceUsd;
  List<BtcPricePoint> _chartData = [];
  String? _error;
  bool _loading = false;

  double? get priceUsd => _priceUsd;
  List<BtcPricePoint> get chartData => List.unmodifiable(_chartData);
  String? get error => _error;
  bool get loading => _loading;

  /// Current balance worth in USD (balance * price).
  double? balanceWorthUsd(double btcBalance) {
    if (_priceUsd == null) return null;
    return btcBalance * _priceUsd!;
  }

  Future<void> fetchPrice() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await _fetchPrice();
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchChartHistory({int days = 30}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    await _fetchChart(days);
    _loading = false;
    notifyListeners();
  }

  /// Fetch both current price and chart (call on dashboard open).
  Future<void> fetchAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _fetchPrice();
      await _fetchChart(30);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPrice() async {
    try {
      final r = await http.get(Uri.parse('$_base/simple/price?ids=bitcoin&vs_currencies=usd'));
      if (r.statusCode != 200) throw Exception('${r.statusCode}');
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final btc = map['bitcoin'];
      if (btc is! Map) throw Exception('Invalid response');
      _priceUsd = (btc['usd'] as num).toDouble();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _fetchChart(int days) async {
    try {
      final r = await http.get(Uri.parse('$_base/coins/bitcoin/market_chart?vs_currency=usd&days=$days'));
      if (r.statusCode != 200) throw Exception('${r.statusCode}');
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final prices = map['prices'] as List<dynamic>?;
      if (prices == null || prices.isEmpty) throw Exception('No data');
      _chartData = prices
          .map((e) {
            final list = e as List;
            final ts = (list[0] as num).toDouble();
            final p = (list[1] as num).toDouble();
            return BtcPricePoint(DateTime.fromMillisecondsSinceEpoch(ts.toInt()), p);
          })
          .toList();
      _chartData.sort((a, b) => a.time.compareTo(b.time));
      if (_priceUsd == null && _chartData.isNotEmpty) _priceUsd = _chartData.last.price;
    } catch (e) {
      _error = e.toString();
      _chartData = [];
    }
  }
}

class BtcPricePoint {
  final DateTime time;
  final double price;
  BtcPricePoint(this.time, this.price);
}

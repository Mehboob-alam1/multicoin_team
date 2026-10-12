import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches real crypto prices from CoinGecko (free, no API key).
/// Supports multiple coins; rate limit ~10–15 calls/min.
class BtcPriceService extends ChangeNotifier {
  static const _base = 'https://api.coingecko.com/api/v3';

  static const Map<String, String> _coingeckoIds = {
    'btc': 'bitcoin',
    'eth': 'ethereum',
    'sol': 'solana',
    'ltc': 'litecoin',
    'doge': 'dogecoin',
  };

  double? _priceUsd;
  double? _priceChange24h;
  double? _high24h;
  double? _low24h;
  double? _volume24h;
  List<BtcPricePoint> _chartData = [];
  final Map<String, double> _pricesByCoin = {};
  final Map<String, List<BtcPricePoint>> _chartDataByCoin = {};
  String? _error;
  bool _loading = false;

  double? get priceUsd => _priceUsd;
  double? get priceChange24h => _priceChange24h;
  double? get high24h => _high24h;
  double? get low24h => _low24h;
  double? get volume24h => _volume24h;
  List<BtcPricePoint> get chartData => List.unmodifiable(_chartData);
  String? get error => _error;
  bool get loading => _loading;
  bool get isPriceUp => _priceChange24h != null && _priceChange24h! >= 0;

  double? getPrice(String coinId) =>
      _pricesByCoin[coinId] ?? ((coinId == 'sol' || coinId == 'btc') ? _priceUsd : null);
  List<BtcPricePoint> getChartData(String coinId) =>
      List.unmodifiable(_chartDataByCoin[coinId] ??
          ((coinId == 'sol' || coinId == 'btc') ? _chartData : []));

  /// Current balance worth in USD (balance * price) for a given coin.
  double? balanceWorthUsdForCoin(String coinId, double balance) {
    final p = getPrice(coinId);
    return p == null ? null : balance * p;
  }

  /// Legacy: SOL balance worth in USD.
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

  /// Fetch both current price, 24h stats, and chart (call on dashboard open).
  Future<void> fetchAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _fetchBtcMarketData();
      await _fetchChart(30);
      if (_priceUsd != null) {
        _pricesByCoin['sol'] = _priceUsd!;
        _pricesByCoin['btc'] = _priceUsd!;
      }
      _chartDataByCoin['sol'] = List.from(_chartData);
      _chartDataByCoin['btc'] = List.from(_chartData);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch BTC price + 24h change, high, low, volume from CoinGecko.
  Future<void> _fetchBtcMarketData() async {
    try {
      final r = await http.get(Uri.parse(
        '$_base/coins/solana?localization=false&tickers=false&community_data=false&developer_data=false&market_data=true',
      ));
      if (r.statusCode != 200) throw Exception('${r.statusCode}');
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final md = map['market_data'];
      if (md is! Map) return;
      final cur = md['current_price'];
      if (cur is Map && cur['usd'] != null) {
        _priceUsd = (cur['usd'] as num).toDouble();
      }
      if (md['price_change_percentage_24h'] != null) {
        _priceChange24h = (md['price_change_percentage_24h'] as num).toDouble();
      }
      final high = md['high_24h'];
      if (high is Map && high['usd'] != null) _high24h = (high['usd'] as num).toDouble();
      final low = md['low_24h'];
      if (low is Map && low['usd'] != null) _low24h = (low['usd'] as num).toDouble();
      final vol = md['total_volume'];
      if (vol is Map && vol['usd'] != null) _volume24h = (vol['usd'] as num).toDouble();
    } catch (e) {
      _error = e.toString();
      await _fetchPrice();
    }
  }

  /// Fetch price and chart for the given coin ids (e.g. selected mining coins).
  Future<void> fetchForCoins(List<String> coinIds, {int chartDays = 30}) async {
    if (coinIds.isEmpty) coinIds = ['sol'];
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cgIds = coinIds
          .map((id) => _coingeckoIds[id] ?? id)
          .where((x) => _coingeckoIds.containsValue(x) || x == 'bitcoin')
          .toSet()
          .toList();
      if (cgIds.isEmpty) cgIds.add('solana');
      await _fetchPrices(cgIds);
      for (final coinId in coinIds) {
        final cgId = _coingeckoIds[coinId] ?? (coinId == 'sol' ? 'solana' : (coinId == 'btc' ? 'bitcoin' : null));
        if (cgId != null) await _fetchChartFor(cgId, coinId, chartDays);
      }
      if (_priceUsd == null && _pricesByCoin.containsKey('sol')) _priceUsd = _pricesByCoin['sol'];
      if (_chartData.isEmpty && _chartDataByCoin.containsKey('sol')) _chartData = _chartDataByCoin['sol']!;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static String? _gameCoinId(String cgId) {
    for (final e in _coingeckoIds.entries) if (e.value == cgId) return e.key;
    return cgId == 'solana' ? 'sol' : (cgId == 'bitcoin' ? 'btc' : null);
  }

  Future<void> _fetchPrice() async {
    try {
      final r = await http.get(Uri.parse('$_base/simple/price?ids=solana&vs_currencies=usd'));
      if (r.statusCode != 200) throw Exception('${r.statusCode}');
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final sol = map['solana'];
      if (sol is! Map) throw Exception('Invalid response');
      _priceUsd = (sol['usd'] as num).toDouble();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _fetchPrices(List<String> coingeckoIds) async {
    if (coingeckoIds.isEmpty) return;
    try {
      final ids = coingeckoIds.join(',');
      final r = await http.get(Uri.parse('$_base/simple/price?ids=$ids&vs_currencies=usd'));
      if (r.statusCode != 200) throw Exception('${r.statusCode}');
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      for (final cgId in coingeckoIds) {
        final data = map[cgId];
        if (data is Map && data['usd'] != null) {
          final price = (data['usd'] as num).toDouble();
          final coinId = _gameCoinId(cgId) ?? cgId;
          _pricesByCoin[coinId] = price;
          if (cgId == 'solana' || cgId == 'bitcoin') _priceUsd = price;
        }
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _fetchChart(int days) async {
    try {
      final r = await http.get(Uri.parse('$_base/coins/solana/market_chart?vs_currency=usd&days=$days'));
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

  Future<void> _fetchChartFor(String cgId, String coinId, int days) async {
    try {
      final r = await http.get(Uri.parse('$_base/coins/$cgId/market_chart?vs_currency=usd&days=$days'));
      if (r.statusCode != 200) throw Exception('${r.statusCode}');
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final prices = map['prices'] as List<dynamic>?;
      if (prices == null || prices.isEmpty) return;
      final list = prices
          .map((e) {
            final item = e as List;
            final ts = (item[0] as num).toDouble();
            final p = (item[1] as num).toDouble();
            return BtcPricePoint(DateTime.fromMillisecondsSinceEpoch(ts.toInt()), p);
          })
          .toList();
      list.sort((a, b) => a.time.compareTo(b.time));
      _chartDataByCoin[coinId] = list;
      if (coinId == 'sol' || coinId == 'btc') _chartData = list;
    } catch (e) {
      _error = e.toString();
    }
  }
}

class BtcPricePoint {
  final DateTime time;
  final double price;
  BtcPricePoint(this.time, this.price);
}

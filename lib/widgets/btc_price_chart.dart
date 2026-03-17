import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/coin.dart';
import '../services/btc_price_service.dart';

// ─── Design tokens (matches dashboard_screen.dart) ────────────────────────────
class _D {
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF7F8FA);
  static const border     = Color(0x12000000);
  static const borderSm   = Color(0x0D000000);

  static const amber      = Color(0xFFF59E0B);
  static const amberBg    = Color(0xFFFFFBEB);
  static const amberDeep  = Color(0xFF92400E);

  static const green      = Color(0xFF10B981);
  static const greenBg    = Color(0xFFF0FDF6);
  static const greenDeep  = Color(0xFF065F46);

  static const red        = Color(0xFFEF4444);
  static const redBg      = Color(0xFFFEF2F2);
  static const redDeep    = Color(0xFF991B1B);

  static const text       = Color(0xFF0D0F12);
  static const sub        = Color(0xFF6B7280);
  static const hint       = Color(0xFFB0B7C3);

  static const r14 = BorderRadius.all(Radius.circular(14));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r8  = BorderRadius.all(Radius.circular(8));
}

/// Shows price chart for one or more coins. When [coinIds] is set, fetches and shows
/// charts for those coins with a selector. When null, shows BTC only (legacy).
class BtcPriceChart extends StatefulWidget {
  final List<String>? coinIds;
  const BtcPriceChart({super.key, this.coinIds});

  @override
  State<BtcPriceChart> createState() => _BtcPriceChartState();
}

class _BtcPriceChartState extends State<BtcPriceChart> {
  String? _selectedCoinId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<BtcPriceService>();
      if (widget.coinIds != null && widget.coinIds!.isNotEmpty) {
        _selectedCoinId = widget.coinIds!.first;
        svc.fetchForCoins(widget.coinIds!);
      } else {
        svc.fetchAll();
      }
    });
  }

  @override
  void didUpdateWidget(BtcPriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coinIds != null && widget.coinIds!.isNotEmpty) {
      if (!widget.coinIds!.contains(_selectedCoinId)) {
        _selectedCoinId = widget.coinIds!.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coinIds = widget.coinIds;
    if (coinIds != null && coinIds.isNotEmpty) {
      return _MultiCoinChart(
        coinIds: coinIds,
        selectedCoinId: _selectedCoinId ?? coinIds.first,
        onSelectCoin: (id) => setState(() => _selectedCoinId = id),
      );
    }
    return const _SingleCoinChart(coinId: 'btc');
  }
}

// ─── Single coin chart ────────────────────────────────────────────────────────
class _SingleCoinChart extends StatelessWidget {
  final String coinId;
  const _SingleCoinChart({required this.coinId});

  @override
  Widget build(BuildContext context) {
    final svc     = context.watch<BtcPriceService>();
    final data    = coinId == 'btc' ? svc.chartData : svc.getChartData(coinId);
    final price   = svc.getPrice(coinId);
    final loading = svc.loading;
    final error   = svc.error;
    final coin    = Coins.byId(coinId);
    final label   = coin != null
        ? '${coin.symbol} / USD'
        : '${coinId.toUpperCase()} / USD';

    // Loading state
    if (loading && data.isEmpty) {
      return _ChartShell(
        label: label,
        price: null,
        change: null,
        isUp: true,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _D.amber),
          ),
        ),
      );
    }

    // Empty / error state
    if (data.isEmpty) {
      return _ChartShell(
        label: label,
        price: price,
        change: null,
        isUp: true,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(
              Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              color: _D.hint,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              error != null ? 'Chart unavailable' : 'No data',
              style: GoogleFonts.dmSans(color: _D.hint, fontSize: 12),
            ),
          ]),
        ),
      );
    }

    final prices     = data.map((e) => e.price).toList();
    final minY       = prices.reduce((a, b) => a < b ? a : b);
    final maxY       = prices.reduce((a, b) => a > b ? a : b);
    final range      = (maxY - minY).clamp(1.0, double.infinity);
    final pad        = range * 0.12;
    final spots      = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();
    final firstPrice = prices.first;
    final lastPrice  = prices.last;
    final change     = firstPrice > 0
        ? ((lastPrice - firstPrice) / firstPrice) * 100
        : 0.0;
    final isUp       = change >= 0;
    final lineColor  = isUp ? _D.green : _D.red;

    return _ChartShell(
      label: label,
      price: price,
      change: change,
      isUp: isUp,
      child: LineChart(
        LineChartData(
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: range / 4,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0x0A000000),
                strokeWidth: 1,
                dashArray: [4, 6],
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: range / 4,
                  getTitlesWidget: (value, _) => Text(
                    '\$${_shortPrice(value)}',
                    style: GoogleFonts.dmMono(color: _D.hint, fontSize: 9),
                  ),
                ),
              ),
              rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => _D.white,
                tooltipBorder: const BorderSide(color: _D.border, width: 0.5),
                tooltipRoundedRadius: 8,
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  '\$${s.y.toStringAsFixed(0)}',
                  GoogleFonts.dmMono(
                    color: _D.amberDeep,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                )).toList(),
              ),
              handleBuiltInTouches: true,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: lineColor,
                barWidth: 1.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.10),
                      lineColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
    );
  }

  static String _shortPrice(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ─── Multi-coin selector + chart ─────────────────────────────────────────────
class _MultiCoinChart extends StatelessWidget {
  final List<String> coinIds;
  final String selectedCoinId;
  final ValueChanged<String> onSelectCoin;

  const _MultiCoinChart({
    required this.coinIds,
    required this.selectedCoinId,
    required this.onSelectCoin,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (coinIds.length > 1) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: coinIds.map((id) {
              final coin       = Coins.byId(id);
              final isSelected = id == selectedCoinId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelectCoin(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? _D.amberBg : _D.bg,
                      borderRadius: _D.r8,
                      border: Border.all(
                        color: isSelected
                            ? _D.amber.withOpacity(0.3)
                            : _D.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      coin?.symbol ?? id.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: isSelected ? _D.amberDeep : _D.sub,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
      ],
      _SingleCoinChart(coinId: selectedCoinId),
    ],
  );
}

// ─── Chart shell (card wrapper + header + footer) ─────────────────────────────
class _ChartShell extends StatelessWidget {
  final String label;
  final double? price;
  final double? change;
  final bool isUp;
  final Widget child;

  const _ChartShell({
    this.label = 'BTC / USD',
    required this.price,
    required this.change,
    required this.isUp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor  = isUp ? _D.green    : _D.red;
    final changeBg     = isUp ? _D.greenBg  : _D.redBg;
    final changeText   = isUp ? _D.greenDeep : _D.redDeep;
    final changeIcon   = isUp
        ? Icons.arrow_drop_up_rounded
        : Icons.arrow_drop_down_rounded;

    return Container(
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: _D.r14,
        border: Border.all(color: _D.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const headerHeight = 26.0;
            const footerHeight = 18.0;
            const gapAbove = 14.0;
            const gapBelow = 8.0;
            const paddingVertical = 26.0;
            final maxChartHeight = constraints.maxHeight.isFinite
                ? (constraints.maxHeight - paddingVertical - headerHeight - footerHeight - gapAbove - gapBelow).clamp(60.0, 140.0)
                : 140.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────────
                Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: _D.amberBg, borderRadius: _D.r8),
                    child: const Icon(Icons.show_chart_rounded, color: _D.amber, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: _D.sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  if (price != null) ...[
                    Text(
                      '\$${price!.toStringAsFixed(0)}',
                      style: GoogleFonts.dmMono(
                        color: _D.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (change != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: changeBg,
                          borderRadius: _D.r8,
                          border: Border.all(
                            color: changeColor.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(changeIcon, color: changeColor, size: 13),
                          Text(
                            '${change!.abs().toStringAsFixed(2)}%',
                            style: GoogleFonts.dmSans(
                              color: changeText,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ]),

                const SizedBox(height: 14),

                // ── Chart body (height adapts to avoid overflow) ─────────────
                SizedBox(height: maxChartHeight, child: child),

                const SizedBox(height: 8),

                // ── Footer ───────────────────────────────────────────────────
                Row(children: [
                  const Icon(Icons.access_time_rounded, color: _D.hint, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    'Last 30 days',
                    style: GoogleFonts.dmSans(color: _D.hint, fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'CoinGecko',
                    style: GoogleFonts.dmSans(color: _D.hint, fontSize: 10),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}
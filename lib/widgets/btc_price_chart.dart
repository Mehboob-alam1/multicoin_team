import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/btc_price_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFF080B12);
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const goldDark = Color(0xFFE08800);
  static const green    = Color(0xFF00E5A0);
  static const red      = Color(0xFFFF4D6A);
  static const textHi   = Color(0xFFF0F4FF);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);
}

class BtcPriceChart extends StatelessWidget {
  const BtcPriceChart({super.key});

  @override
  Widget build(BuildContext context) {
    final svc     = context.watch<BtcPriceService>();
    final data    = svc.chartData;
    final price   = svc.priceUsd;
    final loading = svc.loading;
    final error   = svc.error;

    // ── Loading ──────────────────────────────────────────────────────────────
    if (loading && data.isEmpty) {
      return _ChartShell(
        price: null,
        change: null,
        isUp: true,
        child: const SizedBox(
          height: 160,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _D.gold),
            ),
          ),
        ),
      );
    }

    // ── Error / no data ───────────────────────────────────────────────────────
    if (data.isEmpty) {
      return _ChartShell(
        price: price,
        change: null,
        isUp: true,
        child: SizedBox(
          height: 100,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                  color: _D.textLow, size: 24),
              const SizedBox(height: 8),
              Text(
                error != null ? 'Chart unavailable' : 'No data',
                style: const TextStyle(color: _D.textLow, fontSize: 12),
              ),
            ]),
          ),
        ),
      );
    }

    // ── Compute stats ─────────────────────────────────────────────────────────
    final prices  = data.map((e) => e.price).toList();
    final minY    = prices.reduce((a, b) => a < b ? a : b);
    final maxY    = prices.reduce((a, b) => a > b ? a : b);
    final range   = (maxY - minY).clamp(1.0, double.infinity);
    final pad     = range * 0.12;
    final spots   = data.asMap().entries
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
      price:  price,
      change: change,
      isUp:   isUp,
      child: SizedBox(
        height: 160,
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
              getDrawingHorizontalLine: (_) => FlLine(
                color: _D.cardBord,
                strokeWidth: 1,
                dashArray: [4, 6],
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 56,
                  interval: range / 4,
                  getTitlesWidget: (value, _) => Text(
                    '\$${_shortPrice(value)}',
                    style: const TextStyle(
                      color: _D.textLow,
                      fontSize: 9,
                      fontFamily: AppTheme.fontFamily,
                    ),
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
                getTooltipColor: (_) => _D.card,
                tooltipBorder: const BorderSide(color: _D.cardBord),
                tooltipRoundedRadius: 8,
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  '\$${s.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: _D.gold,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
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
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                shadow: Shadow(
                  color: lineColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.18),
                      lineColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  String _shortPrice(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ─── Shell wrapper ────────────────────────────────────────────────────────────
class _ChartShell extends StatelessWidget {
  final double? price;
  final double? change;
  final bool isUp;
  final Widget child;

  const _ChartShell({
    required this.price,
    required this.change,
    required this.isUp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor = isUp ? _D.green : _D.red;
    final changeIcon  = isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded;

    return Container(
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _D.cardBord),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(children: [
            // Label
            const Row(children: [
              Icon(Icons.currency_bitcoin, color: _D.gold, size: 16),
              SizedBox(width: 5),
              Text(
                'BTC / USD',
                style: TextStyle(
                  color: _D.textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ]),
            const Spacer(),
            // Price + change badge
            if (price != null) ...[
              Text(
                '\$${price!.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _D.textHi,
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: changeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(changeIcon, color: changeColor, size: 14),
                    Text(
                      '${change!.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ]),

          const SizedBox(height: 12),

          // ── Chart body ──────────────────────────────────────────────────────
          child,

          const SizedBox(height: 6),

          // ── Footer ─────────────────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.show_chart_rounded, color: _D.textLow, size: 11),
            const SizedBox(width: 4),
            const Text(
              'Last 30 days',
              style: TextStyle(color: _D.textLow, fontSize: 10),
            ),
            const Spacer(),
            const Text(
              'CoinGecko',
              style: TextStyle(color: _D.textLow, fontSize: 10),
            ),
          ]),
        ]),
      ),
    );
  }
}
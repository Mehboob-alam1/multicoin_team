import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/coin.dart';
import '../services/btc_price_service.dart';

class _NoBlur extends StatelessWidget {
  const _NoBlur({required this.filter, required this.child, this.blendMode});
  final ImageFilter filter;
  final Widget child;
  final BlendMode? blendMode;
  @override
  Widget build(BuildContext context) => child;
}

class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const amber = Color(0xFF9945FF);
  static const amberText = Color(0xFFE9D5FF);
  static const amberBg = Color(0xFF1A1228);
  static const amberBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const greenText = Color(0xFFBBF7D0);
  static const greenBg = Color(0xFF0A2E22);
  static const red = Color(0xFFF43F5E);
  static const redText = Color(0xFFFECDD3);
  static const redBg = Color(0xFF3F1219);
  static const text = Color(0xFFF4F4F5);
  static const sub = Color(0xFFA1A1AA);
  static const hint = Color(0xFF71717A);
  static const line = Color(0x1FFFFFFF);
}

TextStyle _sg({
  double size = 13,
  FontWeight weight = FontWeight.w500,
  Color color = _D.text,
  double? spacing,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: 1.1,
    );

TextStyle _mono({
  double size = 12,
  FontWeight weight = FontWeight.w600,
  Color color = _D.text,
}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.1,
    );

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
      final service = context.read<BtcPriceService>();
      if (widget.coinIds != null && widget.coinIds!.isNotEmpty) {
        _selectedCoinId = widget.coinIds!.first;
        service.fetchForCoins(widget.coinIds!);
      } else {
        service.fetchAll();
      }
    });
  }

  @override
  void didUpdateWidget(BtcPriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coinIds != null && widget.coinIds!.isNotEmpty && !widget.coinIds!.contains(_selectedCoinId)) {
      _selectedCoinId = widget.coinIds!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.coinIds;
    if (ids != null && ids.isNotEmpty) {
      return _MultiCoinChart(
        coinIds: ids,
        selectedCoinId: _selectedCoinId ?? ids.first,
        onSelectCoin: (id) => setState(() => _selectedCoinId = id),
      );
    }
    return const _SingleCoinChart(coinId: 'sol');
  }
}

class _SingleCoinChart extends StatelessWidget {
  final String coinId;
  const _SingleCoinChart({required this.coinId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BtcPriceService>();
    final data = coinId == 'btc' ? service.chartData : service.getChartData(coinId);
    final price = service.getPrice(coinId);
    final coin = Coins.byId(coinId);
    final label = coin != null ? '${coin.symbol} / USD' : '${coinId.toUpperCase()} / USD';

    if (service.loading && data.isEmpty) {
      return _ChartShell(
        label: label,
        price: null,
        change: null,
        isUp: true,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: _D.amber),
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return _ChartShell(
        label: label,
        price: price,
        change: null,
        isUp: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _D.hint, size: 20),
              const SizedBox(height: 6),
              Text(service.error != null ? 'Chart unavailable' : 'No data', style: _sg(size: 12, color: _D.hint)),
            ],
          ),
        ),
      );
    }

    final prices = data.map((point) => point.price).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).clamp(1.0, double.infinity);
    final pad = range * 0.12;
    final spots = data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.price)).toList();
    final first = prices.first;
    final last = prices.last;
    final change = first > 0 ? ((last - first) / first) * 100 : 0.0;
    final isUp = change >= 0;
    final lineColor = isUp ? _D.green : _D.red;

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
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.055),
              strokeWidth: 1,
              dashArray: [4, 6],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: range / 4,
                getTitlesWidget: (value, _) => Text(_shortPrice(value), style: _mono(size: 9, color: _D.hint)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xF0111114),
              tooltipBorder: const BorderSide(color: _D.line),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touched) => touched
                  .map(
                    (spot) => LineTooltipItem(
                  '\$${spot.y.toStringAsFixed(0)}',
                  _mono(size: 12, weight: FontWeight.w700, color: _D.amberText),
                ),
              )
                  .toList(),
            ),
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
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lineColor.withValues(alpha: 0.18), lineColor.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  static String _shortPrice(double value) {
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
    return '\$${value.toStringAsFixed(0)}';
  }
}

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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (coinIds.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final id in coinIds)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CoinChip(
                      label: Coins.byId(id)?.symbol ?? id.toUpperCase(),
                      selected: id == selectedCoinId,
                      onTap: () => onSelectCoin(id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SingleCoinChart(coinId: selectedCoinId),
      ],
    );
  }
}

class _CoinChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CoinChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _D.amberBg : Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? _D.amberBdr : _D.line),
        ),
        child: Text(label, style: _sg(size: 12, weight: FontWeight.w700, color: selected ? _D.amberText : _D.sub)),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  final String label;
  final double? price;
  final double? change;
  final bool isUp;
  final Widget child;

  const _ChartShell({
    required this.label,
    required this.price,
    required this.change,
    required this.isUp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor = isUp ? _D.green : _D.red;
    final changeText = isUp ? _D.greenText : _D.redText;
    final changeBg = isUp ? _D.greenBg : _D.redBg;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: _NoBlur(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
          decoration: BoxDecoration(
            color: const Color(0xB318181C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _D.line, width: 0.8),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bounded = constraints.maxHeight.isFinite;
              final chart = ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: bounded
                    ? child
                    : SizedBox(height: 148, width: double.infinity, child: child),
              );

              return Column(
                mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _D.amberBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _D.amberBdr),
                        ),
                        child: const Icon(Icons.show_chart_rounded, color: _D.amber, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sg(size: 11, weight: FontWeight.w700, color: _D.sub, spacing: 0.4),
                        ),
                      ),
                      if (price != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('\$${price!.toStringAsFixed(0)}', style: _mono(size: 16, weight: FontWeight.w700)),
                                if (change != null) ...[
                                  const SizedBox(width: 7),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: changeBg,
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: changeColor.withValues(alpha: 0.28)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                          color: changeColor,
                                          size: 15,
                                        ),
                                        Text(
                                          '${change!.abs().toStringAsFixed(2)}%',
                                          style: _sg(size: 10, weight: FontWeight.w700, color: changeText),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (bounded) Expanded(child: chart) else chart,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: _D.hint, size: 12),
                      const SizedBox(width: 5),
                      Text('Last 30 days', style: _sg(size: 10, color: _D.hint)),
                      const Spacer(),
                      Text('COINGECKO', style: _sg(size: 9, weight: FontWeight.w700, color: _D.hint, spacing: 0.8)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
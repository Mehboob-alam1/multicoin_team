import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/btc_price_service.dart';
import '../theme/app_theme.dart';

class BtcPriceChart extends StatelessWidget {
  const BtcPriceChart({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = context.watch<BtcPriceService>();
    final data = priceService.chartData;
    final price = priceService.priceUsd;
    final loading = priceService.loading;
    final error = priceService.error;

    if (loading && data.isEmpty) {
      return Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 12),
                Text('Loading BTC price...', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
              ],
            ),
          ),
        ),
      );
    }

    if (error != null && data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('BTC price (USD)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                  const Spacer(),
                  if (price != null) Text('\$${price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Center(
                  child: Text('Chart unavailable', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final minY = data.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).clamp(1.0, double.infinity);
    final padding = range * 0.1;
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.price)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('BTC price (USD)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                const Spacer(),
                if (price != null)
                  Text(
                    '\$${price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: minY - padding,
                  maxY: maxY + padding,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 200),
              ),
            ),
            Text(
              'Last 30 days · CoinGecko',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

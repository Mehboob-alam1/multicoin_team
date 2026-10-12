import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rate_app_service.dart';
import '../utils/store_launcher.dart';

/// 5-star feedback dialog shown randomly to ask users to rate the app.
class RateAppDialog {
  static const _gold = Color(0xFF9945FF);
  static const _textHi = Color(0xFFF4F4F5);
  static const _textMid = Color(0xFFA1A1AA);
  static const _card = Color(0xFF16161F);
  static const _cardBord = Color(0xFF27272A);

  static Future<void> show(BuildContext context) async {
    final rateService = context.read<RateAppService>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hexagon_rounded, color: _gold, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Enjoying Solana Mining Tycoon?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textHi,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your feedback helps us improve. Rate us on the store!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textMid, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (_) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.star_rounded, color: _gold, size: 36),
                    )),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Maybe later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text('Rate 5 stars'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await rateService.markRateDialogShown();
    if (result == true) {
      await StoreLauncher.openListing();
    }
  }
}

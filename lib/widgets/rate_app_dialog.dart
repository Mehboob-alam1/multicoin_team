import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../services/rate_app_service.dart';

/// 5-star feedback dialog shown randomly to ask users to rate the app.
class RateAppDialog {
  static const _gold = Color(0xFFF5A623);
  static const _textHi = Color(0xFFF0F4FF);
  static const _textMid = Color(0xFF8899BB);
  static const _card = Color(0xFF121826);
  static const _cardBord = Color(0xFF1E2A3A);

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
                  Icon(Icons.currency_bitcoin_rounded, color: _gold, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Enjoying BTC Mining Simulator?',
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
                            foregroundColor: Colors.black,
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
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        } else {
          final uri = Uri.parse(AppConstants.playStoreUrl);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        final uri = Uri.parse(AppConstants.playStoreUrl);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rate_app_service.dart';
import '../utils/store_launcher.dart';

/// 5-star feedback dialog shown randomly to ask users to rate the app.
class RateAppDialog {
  static const _gold = Color(0xFF9945FF);
  static const _green = Color(0xFF14F195);
  static const _textHi = Color(0xFFF4F4F5);
  static const _textMid = Color(0xFFA1A1AA);

  static Future<void> show(BuildContext context) async {
    final rateService = context.read<RateAppService>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xF21F1F26), Color(0xE6121216)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x2DFFFFFF), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: _green.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
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
                        children: List.generate(
                          5,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.star_rounded, color: _gold, size: 36),
                          ),
                        ),
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
        ),
      ),
    );
    await rateService.markRateDialogShown();
    if (result == true) {
      await StoreLauncher.openListing();
    }
  }
}

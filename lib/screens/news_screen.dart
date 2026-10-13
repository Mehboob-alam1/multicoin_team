import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/screen_ad_slot.dart';

class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);
  static const line = Color(0x1FFFFFFF);
}

TextStyle _sg({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _D.textHi,
  double? spacing,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: 1.15,
    );

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  static const String bitcoinNewsUrl = 'https://www.coindesk.com/tag/solana/';

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String? _error;
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_D.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (!mounted) return;
            setState(() => _progress = value / 100);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) async {
            await _syncNavigation();
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!(error.isForMainFrame ?? false) || !mounted) return;
            setState(() {
              _error = error.description;
              _loading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(NewsScreen.bitcoinNewsUrl));
  }

  Future<void> _syncNavigation() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canBack = back;
      _canForward = forward;
    });
  }

  Future<void> _handleBack() async {
    HapticFeedback.selectionClick();
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reload() async {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
      _loading = true;
      _progress = 0;
    });
    await _controller.loadRequest(Uri.parse(NewsScreen.bitcoinNewsUrl));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _D.bg,
      body: Column(
        children: [
          _Header(loading: _loading, onBack: _handleBack, onReload: _reload),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ScreenAdSlot(title: 'News offer'),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: _loading ? 2 : 0,
            child: LinearProgressIndicator(
              value: _progress <= 0 || _progress >= 1 ? null : _progress,
              minHeight: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: _D.gold,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading && _progress < 0.12)
                  const _LoadingVeil(),
                if (_error != null)
                  _ErrorState(message: _error!, onRetry: _reload),
              ],
            ),
          ),
          _BrowserBar(
            bottom: bottom,
            canBack: _canBack,
            canForward: _canForward,
            onBack: _canBack ? () => _controller.goBack() : null,
            onForward: _canForward ? () => _controller.goForward() : null,
            onReload: _reload,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onReload;

  const _Header({
    required this.loading,
    required this.onBack,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 8, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xCC08080A),
            border: Border(bottom: BorderSide(color: _D.line)),
          ),
          child: Row(
            children: [
              _RoundButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _D.goldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _D.goldBdr),
                ),
                child: const Icon(Icons.article_rounded, color: _D.gold, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solana News', style: _sg(size: 16, weight: FontWeight.w700, spacing: -0.3)),
                    const SizedBox(height: 2),
                    Text('COINDESK', style: _sg(size: 9, weight: FontWeight.w700, color: _D.gold, spacing: 1.6)),
                  ],
                ),
              ),
              _RoundButton(
                icon: Icons.refresh_rounded,
                onTap: loading ? null : onReload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserBar extends StatelessWidget {
  final double bottom;
  final bool canBack;
  final bool canForward;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback onReload;

  const _BrowserBar({
    required this.bottom,
    required this.canBack,
    required this.canForward,
    required this.onBack,
    required this.onForward,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 8, 22, bottom + 10),
          decoration: const BoxDecoration(
            color: Color(0xE6111114),
            border: Border(top: BorderSide(color: _D.line)),
          ),
          child: Row(
            children: [
              _RoundButton(icon: Icons.chevron_left_rounded, onTap: onBack, enabled: canBack),
              const SizedBox(width: 10),
              _RoundButton(icon: Icons.chevron_right_rounded, onTap: onForward, enabled: canForward),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _D.goldBg,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _D.goldBdr),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: _D.green, size: 12),
                    const SizedBox(width: 5),
                    Text('coindesk.com', style: _sg(size: 11, weight: FontWeight.w600, color: _D.goldText)),
                  ],
                ),
              ),
              const Spacer(),
              _RoundButton(icon: Icons.refresh_rounded, onTap: onReload),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: active ? 1 : 0.35,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF21F1F26), Color(0xE6121216)],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0x2DFFFFFF), width: 0.8),
          ),
          child: Icon(icon, color: _D.textHi, size: 18),
        ),
      ),
    );
  }
}

class _LoadingVeil extends StatelessWidget {
  const _LoadingVeil();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _D.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _D.goldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _D.goldBdr),
              ),
              child: const Icon(Icons.newspaper_rounded, color: _D.gold, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Loading Solana news', style: _sg(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Fetching the latest CoinDesk coverage', style: _sg(size: 12, color: _D.textMid)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _D.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _D.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _D.line),
                ),
                child: const Icon(Icons.wifi_off_rounded, color: _D.textMid),
              ),
              const SizedBox(height: 18),
              Text('News unavailable', style: _sg(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _sg(size: 13, color: _D.textMid),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Try again', style: _sg(size: 13, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
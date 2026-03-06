import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/smart_ad_manager.dart';

class SmartBannerAd extends StatefulWidget {
  const SmartBannerAd({super.key});

  @override
  State<SmartBannerAd> createState() => _SmartBannerAdState();
}

class _SmartBannerAdState extends State<SmartBannerAd> {
  BannerHandle? _handle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final h = await context.read<SmartAdManager>().loadBanner(AdSize.banner);
      if (!mounted) {
        h?.dispose();
        return;
      }
      setState(() => _handle = h);
    });
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _handle;
    if (h == null) return const SizedBox.shrink();
    return SizedBox(
      width: 320,
      height: 50,
      child: AdWidget(ad: h.ad),
    );
  }
}


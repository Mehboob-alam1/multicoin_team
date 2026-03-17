import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

/// Bitcoin news: single WebView (CoinDesk Bitcoin tag). No multi-coin.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  static const String bitcoinNewsUrl = 'https://www.coindesk.com/tag/bitcoin/';

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(NewsScreen.bitcoinNewsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Bitcoin News'),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5A623)),
            ),
        ],
      ),
    );
  }
}

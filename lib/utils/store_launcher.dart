import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Opens the live store listing (Play Store on Android, App Store on iOS).
class StoreLauncher {
  StoreLauncher._();

  static Future<bool> openListing() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final market = Uri.parse(
        'market://details?id=${AppConstants.packageName}',
      );
      if (await _try(market)) return true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final appStore = Uri.parse(AppConstants.appStoreUrl);
      if (!AppConstants.appStoreUrl.contains('id0000000000')) {
        if (await _try(appStore)) return true;
      }
    }
    return _try(Uri.parse(AppConstants.playStoreUrl));
  }

  static Future<bool> _try(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

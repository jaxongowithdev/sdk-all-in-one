import 'package:flutter/foundation.dart';

import '../all_in_one_sdk_platform_interface.dart';
import 'models/facebook_sdk_config.dart';
import 'models/firebase_dynamic_config.dart';
import 'models/tiktok_sdk_config.dart';

/// Initializes Firebase and Facebook using configs from your host / API.
///
/// Mirrors the idea of passing SDK config into native shell once.
/// Native side caches config and auto-initializes on subsequent launches.
class SdkBootstrap {
  SdkBootstrap._();

  /// Call only when API returns new SDK config.
  ///
  /// Logs `[AllInOneSdk]` to Flutter logcat (visible in release) when done or on error.
  static Future<void> apply({
    FirebaseDynamicConfig? firebase,
    FacebookSdkConfig? facebook,
    TikTokSdkConfig? tiktok,
  }) async {
    try {
      if (firebase != null) {
        await AllInOneSdkPlatform.instance.configureFirebaseSdk(
          firebase.toPersistMap(),
        );
      }
      if (facebook != null) {
        await AllInOneSdkPlatform.instance.configureFacebookSdk(
          facebook.toChannelMap(),
        );
      }
      if (tiktok != null) {
        await AllInOneSdkPlatform.instance.configureTikTokSdk(
          tiktok.toChannelMap(),
        );
      }
      // ignore: avoid_print — intentional for release logcat (I/flutter tag)
      print(
        '[AllInOneSdk] SdkBootstrap.apply ok '
        '(firebase=${firebase != null}, facebook=${facebook != null}, '
        'tiktok=${tiktok != null})',
      );
    } catch (e, stack) {
      print('[AllInOneSdk] SdkBootstrap.apply FAILED: $e');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
      rethrow;
    }
  }
}

/// All-in-one SDK: quick WebView + runtime Firebase / Facebook bootstrap.

export 'all_in_one_sdk_platform_interface.dart';
export 'src/models/facebook_sdk_config.dart';
export 'src/facebook_sdk.dart';
export 'src/models/firebase_dynamic_config.dart';
export 'src/sdk_bootstrap.dart';
export 'src/models/tiktok_sdk_config.dart';
export 'src/tiktok_sdk.dart';

import 'all_in_one_sdk_platform_interface.dart';

class AllInOneSdk {
  Future<String?> getPlatformVersion() {
    return AllInOneSdkPlatform.instance.getPlatformVersion();
  }
}

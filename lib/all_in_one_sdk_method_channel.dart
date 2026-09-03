import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'all_in_one_sdk_platform_interface.dart';

class MethodChannelAllInOneSdk extends AllInOneSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('all_in_one_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> configureFacebookSdk(Map<String, Object?> arguments) async {
    await methodChannel.invokeMethod<void>('configureFacebookSdk', arguments);
  }

  @override
  Future<void> configureFirebaseSdk(Map<String, Object?> arguments) async {
    await methodChannel.invokeMethod<void>('configureFirebaseSdk', arguments);
  }

  @override
  Future<void> configureTikTokSdk(Map<String, Object?> arguments) async {
    await methodChannel.invokeMethod<void>('configureTikTokSdk', arguments);
  }

  @override
  Future<void> trackTikTokEvent(Map<String, Object?> arguments) async {
    await methodChannel.invokeMethod<void>('trackTikTokEvent', arguments);
  }

  @override
  Future<void> flushTikTokEvents() async {
    await methodChannel.invokeMethod<void>('flushTikTokEvents');
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'all_in_one_sdk_method_channel.dart';

abstract class AllInOneSdkPlatform extends PlatformInterface {
  AllInOneSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static AllInOneSdkPlatform _instance = MethodChannelAllInOneSdk();

  static AllInOneSdkPlatform get instance => _instance;

  static set instance(AllInOneSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<void> configureFacebookSdk(Map<String, Object?> arguments) {
    throw UnimplementedError(
      'configureFacebookSdk() has not been implemented.',
    );
  }

  Future<void> trackFacebookEvent(Map<String, Object?> arguments) {
    throw UnimplementedError('trackFacebookEvent() has not been implemented.');
  }

  Future<void> flushFacebookEvents() {
    throw UnimplementedError('flushFacebookEvents() has not been implemented.');
  }

  Future<void> configureFirebaseSdk(Map<String, Object?> arguments) {
    throw UnimplementedError(
      'configureFirebaseSdk() has not been implemented.',
    );
  }

  Future<void> configureTikTokSdk(Map<String, Object?> arguments) {
    throw UnimplementedError('configureTikTokSdk() has not been implemented.');
  }

  Future<void> trackTikTokEvent(Map<String, Object?> arguments) {
    throw UnimplementedError('trackTikTokEvent() has not been implemented.');
  }

  Future<void> flushTikTokEvents() {
    throw UnimplementedError('flushTikTokEvents() has not been implemented.');
  }
}

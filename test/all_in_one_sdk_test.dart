import 'package:all_in_one_sdk/all_in_one_sdk.dart';
import 'package:all_in_one_sdk/all_in_one_sdk_method_channel.dart';
import 'package:all_in_one_sdk/all_in_one_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAllInOneSdkPlatform
    with MockPlatformInterfaceMixin
    implements AllInOneSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> configureFacebookSdk(Map<String, Object?> arguments) async {}

  @override
  Future<void> configureFirebaseSdk(Map<String, Object?> arguments) async {}

  @override
  Future<void> trackFacebookEvent(Map<String, Object?> arguments) async {}

  @override
  Future<void> flushFacebookEvents() async {}

  @override
  Future<void> configureTikTokSdk(Map<String, Object?> arguments) async {}

  @override
  Future<void> trackTikTokEvent(Map<String, Object?> arguments) async {}

  @override
  Future<void> flushTikTokEvents() async {}
}

void main() {
  final AllInOneSdkPlatform initialPlatform = AllInOneSdkPlatform.instance;

  test('$MethodChannelAllInOneSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAllInOneSdk>());
  });

  test('getPlatformVersion', () async {
    final AllInOneSdk plugin = AllInOneSdk();
    final MockAllInOneSdkPlatform fakePlatform = MockAllInOneSdkPlatform();
    AllInOneSdkPlatform.instance = fakePlatform;

    expect(await plugin.getPlatformVersion(), '42');
  });
}

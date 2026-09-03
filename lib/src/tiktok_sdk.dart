import 'package:flutter/foundation.dart';

import '../all_in_one_sdk_platform_interface.dart';

/// Runtime helpers for the TikTok Business (Events) SDK.
///
/// The SDK itself is initialized via [SdkBootstrap.apply] / `TikTokSdkConfig`.
/// Use [trackEvent] to send custom app events (Purchase, Login, etc.).
///
/// iOS only — on Android these calls are safe no-ops.
class TikTokSdk {
  TikTokSdk._();

  /// Track a TikTok app event.
  ///
  /// [eventName] is a standard event (e.g. `Purchase`, `CompleteRegistration`,
  /// `Login`, `ViewContent`) or any custom name.
  /// [properties] are optional event parameters (e.g. `{'value': 9.99,
  /// 'currency': 'USD'}`).
  /// [eventId] is an optional id for deduplication with server-side events.
  static Future<void> trackEvent(
    String eventName, {
    Map<String, Object?>? properties,
    String? eventId,
  }) async {
    if (eventName.isEmpty) {
      throw ArgumentError('eventName must not be empty');
    }
    await AllInOneSdkPlatform.instance.trackTikTokEvent({
      'eventName': eventName,
      if (properties != null && properties.isNotEmpty) 'properties': properties,
      if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
    });
    // ignore: avoid_print — visible in release logcat (I/flutter tag)
    print('[AllInOneSdk] TikTok trackEvent: $eventName');
  }

  /// Force-flush queued TikTok events immediately (otherwise batched).
  static Future<void> flush() async {
    try {
      await AllInOneSdkPlatform.instance.flushTikTokEvents();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AllInOneSdk] TikTok flush failed: $e');
      }
    }
  }
}

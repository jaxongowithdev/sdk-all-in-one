import '../all_in_one_sdk_platform_interface.dart';

/// Runtime helpers for Meta / Facebook App Events.
///
/// Configure the SDK first with [SdkBootstrap.apply]. Events are flushed after
/// each call so a tester can confirm delivery promptly in Meta Test Events.
class FacebookSdk {
  FacebookSdk._();

  /// Sends a Meta standard event (such as `Purchase` or
  /// `CompleteRegistration`) or a custom event.
  ///
  /// Event parameters must be strings or numbers. For a purchase, use for
  /// example `{'_valueToSum': 9.99, 'fb_currency': 'USD'}`.
  static Future<void> trackEvent(
    String eventName, {
    Map<String, Object?>? parameters,
  }) async {
    if (eventName.trim().isEmpty) {
      throw ArgumentError.value(eventName, 'eventName', 'must not be empty');
    }

    await AllInOneSdkPlatform.instance.trackFacebookEvent({
      'eventName': eventName.trim(),
      if (parameters != null && parameters.isNotEmpty) 'parameters': parameters,
    });
    // ignore: avoid_print — visible in release logs for delivery diagnosis.
    print('[AllInOneSdk] Facebook trackEvent: ${eventName.trim()}');
  }

  /// Flushes Meta's queued App Events immediately.
  static Future<void> flush() {
    return AllInOneSdkPlatform.instance.flushFacebookEvents();
  }
}

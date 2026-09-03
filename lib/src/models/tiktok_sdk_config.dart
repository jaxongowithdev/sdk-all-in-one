/// TikTok Business (Events) SDK identifiers from API
/// (applied on native side before events).
///
/// Mirrors the dynamic-config idea used by [FacebookSdkConfig]: the host app /
/// API supplies these values, Flutter forwards them to native, and native
/// caches + initializes the TikTok Business SDK.
///
/// Keys map to iOS `TikTokConfig`
/// (`configWithAccessToken:appId:tiktokAppId:`):
/// `accessToken`, `appId`, `tiktokAppId`, plus optional toggles.
class TikTokSdkConfig {
  const TikTokSdkConfig({
    required this.appId,
    required this.tiktokAppId,
    this.accessToken,
    this.debugModeEnabled,
    this.autoTrackingEnabled,
    this.trackingEnabled,
  });

  /// App identifier — on iOS this is your app's bundle id / App Store id.
  final String appId;

  /// TikTok App ID from TikTok Events Manager.
  ///
  /// Multiple ids may be passed as a comma-separated string (SDK >= 1.3.1).
  final String tiktokAppId;

  /// Access token from TikTok Marketing API dashboard.
  ///
  /// Strongly recommended — enables the non-deprecated init path
  /// (`configWithAccessToken:appId:tiktokAppId:`). When null, native falls
  /// back to the deprecated `initWithAppId:tiktokAppId:`.
  final String? accessToken;

  /// When true, native calls `enableDebugMode` (test events / verbose logs).
  final bool? debugModeEnabled;

  /// When false, native calls `disableAutomaticTracking`
  /// (install/launch/retention auto events).
  final bool? autoTrackingEnabled;

  /// When false, native calls `disableTracking` (no events sent).
  final bool? trackingEnabled;

  factory TikTokSdkConfig.fromApiMap(Map<Object?, Object?> map) {
    bool? parseBool(Object? raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final v = raw.trim().toLowerCase();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
      return null;
    }

    final appId = map['appId'] ?? map['applicationId'] ?? map['bundleId'];
    if (appId is! String || appId.isEmpty) {
      throw ArgumentError(
        'TikTok config requires appId (or applicationId / bundleId)',
      );
    }

    final tiktokAppId = map['tiktokAppId'] ?? map['ttAppId'];
    if (tiktokAppId is! String || tiktokAppId.isEmpty) {
      throw ArgumentError(
        'TikTok config requires tiktokAppId (or ttAppId)',
      );
    }

    return TikTokSdkConfig(
      appId: appId,
      tiktokAppId: tiktokAppId,
      accessToken: _optString(map, 'accessToken'),
      debugModeEnabled: parseBool(map['debugModeEnabled']),
      autoTrackingEnabled: parseBool(map['autoTrackingEnabled']),
      trackingEnabled: parseBool(map['trackingEnabled']),
    );
  }

  static TikTokSdkConfig? tryFromApiMap(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) return null;
    try {
      return TikTokSdkConfig.fromApiMap(map);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> toChannelMap() => {
        'appId': appId,
        'tiktokAppId': tiktokAppId,
        if (accessToken != null) 'accessToken': accessToken,
        if (debugModeEnabled != null) 'debugModeEnabled': debugModeEnabled,
        if (autoTrackingEnabled != null)
          'autoTrackingEnabled': autoTrackingEnabled,
        if (trackingEnabled != null) 'trackingEnabled': trackingEnabled,
      };

  static String? _optString(Map<Object?, Object?> map, String key) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
    return null;
  }
}

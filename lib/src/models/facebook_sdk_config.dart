/// Facebook / Meta SDK identifiers from API (applied on native side before events).
class FacebookSdkConfig {
  const FacebookSdkConfig({
    required this.applicationId,
    this.clientToken,
    this.displayName,
    this.autoLogAppEventsEnabled,
    this.advertiserIdCollectionEnabled,
  });

  /// Facebook App ID (`FacebookAppID`).
  final String applicationId;

  /// Strongly recommended on both iOS and Android.
  final String? clientToken;

  final String? displayName;

  final bool? autoLogAppEventsEnabled;

  final bool? advertiserIdCollectionEnabled;

  factory FacebookSdkConfig.fromApiMap(Map<Object?, Object?> map) {
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

    final appId = map['applicationId'] ?? map['appId'] ?? map['facebookAppId'];
    if (appId is! String || appId.isEmpty) {
      throw ArgumentError(
        'Facebook config requires applicationId (or appId / facebookAppId)',
      );
    }

    return FacebookSdkConfig(
      applicationId: appId,
      clientToken: _optString(map, 'clientToken'),
      displayName: _optString(map, 'displayName'),
      autoLogAppEventsEnabled: parseBool(map['autoLogAppEventsEnabled']),
      advertiserIdCollectionEnabled:
          parseBool(map['advertiserIdCollectionEnabled']),
    );
  }

  static FacebookSdkConfig? tryFromApiMap(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) return null;
    try {
      return FacebookSdkConfig.fromApiMap(map);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> toChannelMap() => {
        'applicationId': applicationId,
        if (clientToken != null) 'clientToken': clientToken,
        if (displayName != null) 'displayName': displayName,
        if (autoLogAppEventsEnabled != null)
          'autoLogAppEventsEnabled': autoLogAppEventsEnabled,
        if (advertiserIdCollectionEnabled != null)
          'advertiserIdCollectionEnabled': advertiserIdCollectionEnabled,
      };

  static String? _optString(Map<Object?, Object?> map, String key) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
    return null;
  }
}

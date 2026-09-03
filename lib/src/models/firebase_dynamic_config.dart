import 'package:firebase_core/firebase_core.dart';

/// Firebase options supplied at runtime (e.g. from your host app API).
///
/// Keys: `googleAppId`, `gcmSenderId`, `apiKey`, `projectId`, optional `storageBucket`.
///
/// `googleAppId` is per-platform — Android API returns the Android
/// `mobilesdk_app_id`, iOS API returns the iOS `GOOGLE_APP_ID`.
///
/// Defaults in SDK (omit from API): `isAnalyticsEnabled` = true;
/// iOS `bundleId` = host app bundle id when omitted.
class FirebaseDynamicConfig {
  const FirebaseDynamicConfig({
    required this.googleAppId,
    required this.gcmSenderId,
    required this.apiKey,
    required this.projectId,
    this.bundleId,
    this.storageBucket,
    this.isAnalyticsEnabled,
  });

  /// Platform-specific Google App ID (`mobilesdk_app_id` / `GOOGLE_APP_ID`).
  final String googleAppId;

  /// Maps from API key `gcmSenderId` → Firebase `messagingSenderId`.
  final String gcmSenderId;

  final String apiKey;
  final String projectId;

  /// Optional; maps to Firebase `iosBundleId`.
  final String? bundleId;

  final String? storageBucket;

  /// When non-null, applied via [FirebaseAnalytics.setAnalyticsCollectionEnabled].
  final bool? isAnalyticsEnabled;

  /// Parse API JSON/object map using the same keys as native `firebaseConfig`.
  factory FirebaseDynamicConfig.fromApiMap(Map<Object?, Object?> map) {
    bool? analyticsFlag;
    final raw = map['isAnalyticsEnabled'];
    if (raw is bool) {
      analyticsFlag = raw;
    } else if (raw is num) {
      analyticsFlag = raw != 0;
    } else if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'true' || v == '1') analyticsFlag = true;
      if (v == 'false' || v == '0') analyticsFlag = false;
    }

    return FirebaseDynamicConfig(
      googleAppId: _reqGoogleAppId(map),
      gcmSenderId: _reqString(map, 'gcmSenderId'),
      apiKey: _reqString(map, 'apiKey'),
      projectId: _reqString(map, 'projectId'),
      bundleId: _optString(map, 'bundleId'),
      storageBucket: _optString(map, 'storageBucket'),
      isAnalyticsEnabled: analyticsFlag ?? true,
    );
  }

  static FirebaseDynamicConfig? tryFromApiMap(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) return null;
    try {
      return FirebaseDynamicConfig.fromApiMap(map);
    } catch (_) {
      return null;
    }
  }

  FirebaseOptions toFirebaseOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: googleAppId,
      messagingSenderId: gcmSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: bundleId,
    );
  }

  Map<String, Object?> toPersistMap() => {
        'googleAppId': googleAppId,
        'gcmSenderId': gcmSenderId,
        'apiKey': apiKey,
        'projectId': projectId,
        if (storageBucket != null) 'storageBucket': storageBucket,
        if (isAnalyticsEnabled == false) 'isAnalyticsEnabled': false,
      };

  static FirebaseDynamicConfig? tryFromPersistMap(Map<String, Object?> map) {
    try {
      return FirebaseDynamicConfig.fromApiMap(map);
    } catch (_) {
      return null;
    }
  }

  static String _reqGoogleAppId(Map<Object?, Object?> map) {
    final v =
        _optString(map, 'googleAppId') ?? _optString(map, 'androidGoogleAppId');
    if (v != null) return v;
    throw ArgumentError('Missing or empty Firebase config key: googleAppId');
  }

  static String _reqString(Map<Object?, Object?> map, String key) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
    throw ArgumentError('Missing or empty Firebase config key: $key');
  }

  static String? _optString(Map<Object?, Object?> map, String key) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
    return null;
  }
}

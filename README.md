# all_in_one_sdk

All-in-one Flutter SDK for dynamic Firebase, Facebook, and TikTok configuration.

## Important — Android setup

Required for Firebase Analytics on Android (API-driven config, no `google-services.json`).

Add **one line** in your Flutter host app `android/app/build.gradle.kts` inside `android { defaultConfig { ... } }`:

```kotlin
manifestPlaceholders["applicationName"] = "com.example.all_in_one_sdk.AllInOneSdkApplication"
```

This wires `AllInOneSdkApplication` so Firebase Measurement reads API `googleAppId` via `getResources()`. Without it, Analytics may not initialize correctly.

## Install

Add dependency to your app `pubspec.yaml`:

```yaml
dependencies:
  all_in_one_sdk:
    git:
      url: https://github.com/codewithlane/sdk-all-in-one.git
```

## How It Works

- Flutter only sends config when your API returns new values.
- Native (Android/iOS) initializes SDKs immediately.
- Native caches config and auto-initializes on next launches.
- If a SDK block is missing or incomplete, that SDK is skipped (no throw).

## API Response Format

Your backend returns a JSON object. Flutter parses each block with `FirebaseDynamicConfig.fromApiMap`, `FacebookSdkConfig.fromApiMap`, and `TikTokSdkConfig.fromApiMap`, then calls `SdkBootstrap.apply`.

Each top-level key is optional — omit or set `null` to skip that SDK.

**Recommended example** (keys to return from your API — optional fields use SDK defaults):

```json
{
  "firebase": {
    "googleAppId": "1:85289965729:android:e76c03eea20fb281df78e0",
    "gcmSenderId": "85289965729",
    "apiKey": "AIzaSyA8j6sN0JJODjnRRm6JgMMuVUjfA4Ec5HU",
    "projectId": "cakhia66net",
    "storageBucket": "cakhia66net.firebasestorage.app"
  },
  "facebook": {
    "applicationId": "123456789012345",
    "clientToken": "your-client-token"
  },
  "tiktok": {
    "appId": "com.cakhiatv.orbit.app",
    "tiktokAppId": "YOUR_TIKTOK_APP_ID",
    "accessToken": "your-access-token"
  }
}
```

| Block | Recommended keys | Omitted (SDK default) |
|-------|------------------|------------------------|
| `firebase` | `googleAppId`, `gcmSenderId`, `apiKey`, `projectId`, `storageBucket` | `isAnalyticsEnabled` → `true` · `bundleId` → host app bundle id (iOS) |
| `facebook` | `applicationId`, `clientToken` | `displayName`, `autoLogAppEventsEnabled`, `advertiserIdCollectionEnabled` |
| `tiktok` | `appId`, `tiktokAppId`, `accessToken` | `debugModeEnabled` → `false` · `autoTrackingEnabled` / `trackingEnabled` → `true` |

**Full example (all keys):**

```json
{
  "firebase": {
    "googleAppId": "1:85289965729:android:e76c03eea20fb281df78e0",
    "gcmSenderId": "85289965729",
    "apiKey": "AIzaSyA8j6sN0JJODjnRRm6JgMMuVUjfA4Ec5HU",
    "projectId": "cakhia66net",
    "storageBucket": "cakhia66net.firebasestorage.app",
    "isAnalyticsEnabled": true,
    "bundleId": "com.cakhiatv.orbit.app"
  },
  "facebook": {
    "applicationId": "123456789012345",
    "clientToken": "your-client-token",
    "displayName": "My App",
    "autoLogAppEventsEnabled": true,
    "advertiserIdCollectionEnabled": true
  },
  "tiktok": {
    "appId": "com.cakhiatv.orbit.app",
    "tiktokAppId": "YOUR_TIKTOK_APP_ID",
    "accessToken": "your-access-token",
    "debugModeEnabled": false,
    "autoTrackingEnabled": true,
    "trackingEnabled": true
  }
}
```

> **Note:** `firebase.googleAppId` is per-platform — use the Android `mobilesdk_app_id` on Android, iOS `GOOGLE_APP_ID` on iOS. Other Firebase keys are usually the same across platforms.

Generate Android `firebase` block from `google-services.json`:

```bash
./convertSDK-Android.sh
```

### Firebase

| Key | Required | Source | Notes |
|-----|----------|--------|-------|
| `googleAppId` | Yes | Android: `client[].client_info.mobilesdk_app_id` · iOS: plist `GOOGLE_APP_ID` | Per-platform value, same key name |
| `gcmSenderId` | Yes | `project_info.project_number` | FCM sender id |
| `apiKey` | Yes | `client[].api_key[0].current_key` | |
| `projectId` | Yes | `project_info.project_id` | |
| `storageBucket` | No | `project_info.storage_bucket` | Recommended |
| `isAnalyticsEnabled` | No | — | Default `true` in SDK; send `false` to disable |
| `bundleId` | No | plist `BUNDLE_ID` | Default: host app bundle id (iOS only) |

No `google-services.json` / `GoogleService-Info.plist` in the host app — config comes from API only.

### Facebook

Same keys on Android and iOS.

| Key | Required | Aliases | Notes |
|-----|----------|---------|-------|
| `applicationId` | Yes | `appId`, `facebookAppId` | Facebook App ID |
| `clientToken` | No | — | Strongly recommended on both platforms |
| `displayName` | No | — | Shown in Facebook login / settings |
| `autoLogAppEventsEnabled` | No | — | Omit = SDK default unchanged |
| `advertiserIdCollectionEnabled` | No | — | Omit = SDK default unchanged |

### TikTok

**iOS only.** Android accepts the call as a no-op (no error).

| Key | Required | Aliases | Notes |
|-----|----------|---------|-------|
| `appId` | Yes | `applicationId`, `bundleId` | Host app id / bundle id |
| `tiktokAppId` | Yes | `ttAppId` | From TikTok Events Manager |
| `accessToken` | No | — | Strongly recommended; without it iOS uses deprecated init |
| `debugModeEnabled` | No | — | Default `false` |
| `autoTrackingEnabled` | No | — | Default `true`; set `false` to disable auto events |
| `trackingEnabled` | No | — | Default `true`; set `false` to stop all events |

## Usage

```dart
import 'package:all_in_one_sdk/all_in_one_sdk.dart';

Future<void> initFromApi(Map<String, dynamic> api) async {
  await SdkBootstrap.apply(
    firebase: FirebaseDynamicConfig.tryFromApiMap(api['firebase']),
    facebook: FacebookSdkConfig.tryFromApiMap(api['facebook']),
    tiktok: TikTokSdkConfig.tryFromApiMap(api['tiktok']),
  );
}
```

Or pass the full API map directly:

```dart
await SdkBootstrap.apply(
  firebase: FirebaseDynamicConfig.fromApiMap({
    'googleAppId': '1:85289965729:android:e76c03eea20fb281df78e0',
    'gcmSenderId': '85289965729',
    'apiKey': 'AIzaSyA8j6sN0JJODjnRRm6JgMMuVUjfA4Ec5HU',
    'projectId': 'cakhia66net',
    'storageBucket': 'cakhia66net.firebasestorage.app',
    'isAnalyticsEnabled': true,
    'bundleId': 'com.cakhiatv.orbit.app',
  }),
  facebook: FacebookSdkConfig.fromApiMap({
    'applicationId': '123456789012345',
    'clientToken': 'your-client-token',
    'displayName': 'My App',
    'autoLogAppEventsEnabled': true,
    'advertiserIdCollectionEnabled': true,
  }),
  tiktok: TikTokSdkConfig.fromApiMap({
    'appId': 'com.cakhiatv.orbit.app',
    'tiktokAppId': 'YOUR_TIKTOK_APP_ID',
    'accessToken': 'your-access-token',
    'debugModeEnabled': false,
    'autoTrackingEnabled': true,
    'trackingEnabled': true,
  }),
);
```

## Optional Config

- `firebase: null` → skip Firebase init
- `facebook: null` → skip Facebook init
- `tiktok: null` → skip TikTok init (Android always no-op)
- all `null` → SDK init is skipped completely

## Android vs iOS (no `google-services.json`)

| | iOS | Android |
|---|-----|---------|
| Config | `FIROptions` from API | `FirebaseOptions` from API |
| Analytics | Works with options only | Also needs `R.string.google_app_id` |
| TikTok | Native SDK initialized | Ignored (no-op) |

This plugin handles Android **without** `google-services.json` (config from API only, like iOS):

- `FirebaseBootstrapProvider` — restore cached Firebase strings before Flutter starts
- `AllInOneSdkApplication` — see [Important — Android setup](#important--android-setup) above

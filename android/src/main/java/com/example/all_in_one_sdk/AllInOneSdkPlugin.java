package com.example.all_in_one_sdk;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Log;

import com.facebook.FacebookException;
import com.facebook.FacebookSdk;
import com.facebook.appevents.AppEventsLogger;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.analytics.FirebaseAnalytics;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** All-in-one SDK: Firebase + Facebook init and native cache (Java). */
public class AllInOneSdkPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "AllInOneSdk";
  private static final String CHANNEL = "all_in_one_sdk";
  private static final String PREFS_NAME = "all_in_one_sdk_prefs";
  private static final String KEY_FIREBASE_CONFIG = "cached_firebase_config_json";
  private static final String KEY_FACEBOOK_CONFIG = "cached_facebook_config_json";

  private MethodChannel channel;
  private Context applicationContext;

  @Override
  public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
    applicationContext = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    channel.setMethodCallHandler(this);
    bootstrapFromCache();
  }

  private void bootstrapFromCache() {
    Context ctx = applicationContext;
    if (ctx == null) {
      Log.w(TAG, "bootstrapFromCache: no context, skip");
      return;
    }
    SharedPreferences prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);

    String firebaseRaw = prefs.getString(KEY_FIREBASE_CONFIG, null);
    if (firebaseRaw != null && !firebaseRaw.isEmpty()) {
      try {
        Log.i(TAG, "bootstrapFromCache: restoring Firebase from native prefs");
        configureFirebase(jsonStringToMap(firebaseRaw), "bootstrapFromCache");
      } catch (Exception e) {
        Log.e(TAG, "bootstrapFromCache: Firebase restore failed", e);
        logFirebaseInitStatus(ctx, "bootstrapFromCache (failed)");
      }
    } else {
      Log.i(TAG, "bootstrapFromCache: no cached Firebase config");
      logFirebaseInitStatus(ctx, "bootstrapFromCache (no cache)");
    }

    String facebookRaw = prefs.getString(KEY_FACEBOOK_CONFIG, null);
    if (facebookRaw != null && !facebookRaw.isEmpty()) {
      try {
        Log.i(TAG, "bootstrapFromCache: restoring Facebook from native prefs");
        configureFacebook(jsonStringToMap(facebookRaw), "cached_config");
      } catch (Exception e) {
        Log.e(TAG, "bootstrapFromCache: Facebook restore failed", e);
      }
    } else {
      Log.i(TAG, "bootstrapFromCache: no cached Facebook config");
    }
  }

  private static Map<String, Object> jsonStringToMap(String raw) throws JSONException {
    JSONObject json = new JSONObject(raw);
    Map<String, Object> out = new HashMap<>();
    Iterator<String> keys = json.keys();
    while (keys.hasNext()) {
      String key = keys.next();
      out.put(key, json.get(key));
    }
    return out;
  }

  /** Logs whether FirebaseApp exists and default app options (tag: AllInOneSdk). */
  private void logFirebaseInitStatus(Context ctx, String source) {
    if (ctx == null) {
      Log.w(TAG, "Firebase status [" + source + "]: no context");
      return;
    }
    List<FirebaseApp> apps = FirebaseApp.getApps(ctx);
    if (apps.isEmpty()) {
      Log.w(TAG, "Firebase status [" + source + "]: NOT initialized (0 FirebaseApp)");
      return;
    }
    Log.i(TAG, "Firebase status [" + source + "]: initialized (" + apps.size() + " app(s))");
    for (FirebaseApp app : apps) {
      FirebaseOptions opts = app.getOptions();
      Log.i(
          TAG,
          "Firebase status [" + source + "]: app name="
              + app.getName()
              + " projectId="
              + opts.getProjectId()
              + " applicationId="
              + opts.getApplicationId()
              + " gcmSenderId="
              + opts.getGcmSenderId());
    }
    try {
      FirebaseApp defaultApp = FirebaseApp.getInstance();
      Log.i(
          TAG,
          "Firebase status ["
              + source
              + "]: default app OK (name="
              + defaultApp.getName()
              + ")");
    } catch (IllegalStateException e) {
      Log.w(TAG, "Firebase status [" + source + "]: default app NOT available", e);
    }
  }

  private void configureFirebase(Map<String, Object> args, String source) {
    Context ctx = applicationContext;
    if (ctx == null) {
      Log.w(TAG, "Firebase [" + source + "]: skipped (no context)");
      return;
    }

    String appId = stringOrNull(args.get("googleAppId"));
    if (appId == null || appId.isEmpty()) {
      appId = stringOrNull(args.get("androidGoogleAppId"));
    }
    String senderId = stringOrNull(args.get("gcmSenderId"));
    String apiKey = stringOrNull(args.get("apiKey"));
    String projectId = stringOrNull(args.get("projectId"));
    String storageBucket = stringOrNull(args.get("storageBucket"));
    Boolean analytics = boolOrNull(args.get("isAnalyticsEnabled"));
    boolean analyticsEnabled = analytics != null ? analytics : true;

    Log.i(
        TAG,
        "Firebase ["
            + source
            + "]: start (projectId="
            + projectId
            + ", appId="
            + appId
            + ", gcmSenderId="
            + senderId
            + ")");

    if (appId == null
        || appId.isEmpty()
        || senderId == null
        || senderId.isEmpty()
        || apiKey == null
        || apiKey.isEmpty()
        || projectId == null
        || projectId.isEmpty()) {
      Log.w(
          TAG,
          "Firebase ["
              + source
              + "]: skipped (missing googleAppId, gcmSenderId, apiKey, or projectId)");
      logFirebaseInitStatus(ctx, source + " (skipped)");
      return;
    }

    // Analytics (FA) requires R.string.google_app_id — not only FirebaseOptions.
    FirebaseResourceInjector.apply(ctx, appId, apiKey, senderId, projectId, storageBucket);

    boolean createdNewApp = false;
    if (FirebaseApp.getApps(ctx).isEmpty()) {
      try {
        FirebaseOptions.Builder builder =
            new FirebaseOptions.Builder()
                .setApplicationId(appId)
                .setGcmSenderId(senderId)
                .setApiKey(apiKey)
                .setProjectId(projectId);
        if (storageBucket != null && !storageBucket.isEmpty()) {
          builder.setStorageBucket(storageBucket);
        }
        FirebaseApp.initializeApp(ctx, builder.build());
        createdNewApp = true;
        Log.i(
            TAG,
            "Firebase ["
                + source
                + "]: initializeApp SUCCESS (projectId="
                + projectId
                + ", appId="
                + appId
                + ")");
      } catch (Exception e) {
        Log.e(TAG, "Firebase [" + source + "]: initializeApp FAILED", e);
        logFirebaseInitStatus(ctx, source + " (init failed)");
        return;
      }
    } else {
      Log.i(
          TAG,
          "Firebase ["
              + source
              + "]: FirebaseApp already exists, skipped initialize (requested projectId="
              + projectId
              + ")");
    }

    try {
      FirebaseAnalytics analyticsInstance = FirebaseAnalytics.getInstance(ctx);
      analyticsInstance.setAnalyticsCollectionEnabled(analyticsEnabled);
      android.os.Bundle probe = new android.os.Bundle();
      probe.putString("source", source);
      analyticsInstance.logEvent("all_in_one_sdk_ready", probe);
      Log.i(
          TAG,
          "Firebase ["
              + source
              + "]: Analytics ON (collectionEnabled="
              + analyticsEnabled
              + (analytics == null ? ", default" : "")
              + ", probe event=all_in_one_sdk_ready)");
        analyticsInstance
            .getAppInstanceId()
            .addOnCompleteListener(
                task -> {
                  if (task.isSuccessful() && task.getResult() != null) {
                    Log.i(
                        TAG,
                        "Firebase Analytics: appInstanceId="
                            + task.getResult()
                            + " (data can take minutes on DebugView, hours on dashboard)");
                  } else {
                    Log.e(
                        TAG,
                        "Firebase Analytics: appInstanceId unavailable — Analytics likely disabled",
                        task.getException());
                  }
                });
      } catch (Exception e) {
        Log.e(TAG, "Firebase [" + source + "]: Analytics FAILED — check google_app_id resource", e);
      }

    logFirebaseInitStatus(
        ctx,
        source + (createdNewApp ? " (new app)" : " (existing app)"));
  }

  private boolean configureFacebook(Map<String, Object> args, String source) {
    String appId = stringOrNull(args.get("applicationId"));
    if (appId == null || appId.isEmpty()) {
      Log.w(TAG, "Facebook SDK: skipped (missing applicationId)");
      return false;
    }

    Context ctx = applicationContext;
    if (ctx == null) {
      Log.w(TAG, "Facebook SDK: skipped sdkInitialize (no context)");
      return false;
    }

    Log.i(TAG, "Facebook SDK: configuring (applicationId=" + appId + ")");
    // App id and client token must be set before sdkInitialize. Facebook SDK 17
    // does not auto-init, and setAutoLogAppEventsEnabled() calls
    // getApplicationContext(), which throws until sdkInitialize() has run.
    FacebookSdk.setApplicationId(appId);

    String token = stringOrNull(args.get("clientToken"));
    if (token != null && !token.isEmpty()) {
      FacebookSdk.setClientToken(token);
    }

    String displayName = stringOrNull(args.get("displayName"));
    if (displayName != null && !displayName.isEmpty()) {
      FacebookSdk.setApplicationName(displayName);
    }

    if (!FacebookSdk.isInitialized()) {
      try {
        FacebookSdk.sdkInitialize(ctx.getApplicationContext());
        Log.i(TAG, "Facebook SDK: sdkInitialize done");
      } catch (FacebookException e) {
        Log.e(TAG, "Facebook SDK: sdkInitialize failed", e);
        return false;
      }
    } else {
      Log.i(TAG, "Facebook SDK: already initialized, updated settings only");
    }

    Boolean autoLog = boolOrNull(args.get("autoLogAppEventsEnabled"));
    if (autoLog != null) {
      FacebookSdk.setAutoLogAppEventsEnabled(autoLog);
      Log.i(TAG, "Facebook SDK: autoLogAppEventsEnabled=" + (autoLog ? "true" : "false"));
    } else {
      Log.i(
          TAG,
          "Facebook SDK: autoLogAppEventsEnabled not set (value="
              + String.valueOf(args.get("autoLogAppEventsEnabled"))
              + "), left unchanged");
    }

    Boolean advertiser = boolOrNull(args.get("advertiserIdCollectionEnabled"));
    if (advertiser != null) {
      FacebookSdk.setAdvertiserIDCollectionEnabled(advertiser);
      Log.i(TAG, "Facebook SDK: advertiserIDCollectionEnabled=" + (advertiser ? "true" : "false"));
    } else {
      Log.i(
          TAG,
          "Facebook SDK: advertiserIdCollectionEnabled not set (value="
              + String.valueOf(args.get("advertiserIdCollectionEnabled"))
              + "), left unchanged");
    }

    FacebookSdk.setAutoInitEnabled(true);
    FacebookSdk.fullyInitialize();
    if (!FacebookSdk.isInitialized()) {
      Log.e(TAG, "Facebook SDK: initialization did not complete");
      return false;
    }

    try {
      logFacebookEvent("all_in_one_sdk_ready", singletonFacebookParameter("source", source));
    } catch (RuntimeException e) {
      Log.e(TAG, "Facebook SDK: ready event could not be queued", e);
      return false;
    }
    Log.i(
        TAG,
        "Facebook SDK: ready (clientTokenSet="
            + (token != null && !token.isEmpty())
            + ", displayNameSet="
            + (displayName != null && !displayName.isEmpty())
            + ", probe event=all_in_one_sdk_ready)");
    return true;
  }

  private void logFacebookEvent(String eventName, Map<String, Object> parameters) {
    Context ctx = applicationContext;
    if (ctx == null || !FacebookSdk.isInitialized()) {
      throw new IllegalStateException("Facebook SDK is not initialized");
    }
    android.os.Bundle bundle = new android.os.Bundle();
    for (Map.Entry<String, Object> entry : parameters.entrySet()) {
      Object value = entry.getValue();
      if (value instanceof String) {
        bundle.putString(entry.getKey(), (String) value);
      } else if (value instanceof Number) {
        bundle.putDouble(entry.getKey(), ((Number) value).doubleValue());
      } else if (value instanceof Boolean) {
        bundle.putBoolean(entry.getKey(), (Boolean) value);
      }
    }
    AppEventsLogger logger = AppEventsLogger.newLogger(ctx.getApplicationContext());
    logger.logEvent(eventName, bundle);
    logger.flush();
    Log.i(TAG, "Facebook App Event: queued and flushed (event=" + eventName + ")");
  }

  private static Map<String, Object> singletonFacebookParameter(String key, Object value) {
    Map<String, Object> parameters = new HashMap<>();
    parameters.put(key, value);
    return parameters;
  }

  private static String stringOrNull(Object v) {
    if (v instanceof String) {
      return (String) v;
    }
    return null;
  }

  private static Boolean boolOrNull(Object v) {
    if (v instanceof Boolean) {
      return (Boolean) v;
    }
    if (v instanceof Number) {
      return ((Number) v).intValue() != 0;
    }
    return null;
  }

  @SuppressWarnings("unchecked")
  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + Build.VERSION.RELEASE);
        return;

      case "configureFacebookSdk": {
        Object raw = call.arguments;
        if (!(raw instanceof Map)) {
          result.error("bad_args", "configureFacebookSdk expects a map", null);
          return;
        }
        Map<String, Object> args = (Map<String, Object>) raw;
        String appId = stringOrNull(args.get("applicationId"));
        if (appId == null || appId.isEmpty()) {
          result.error("bad_app_id", "applicationId is required", null);
          return;
        }
        Context ctx = applicationContext;
        if (ctx == null) {
          result.error("no_context", "Plugin not attached", null);
          return;
        }
        Log.i(TAG, "configureFacebookSdk: from Flutter channel");
        if (!configureFacebook(args, "api_config")) {
          result.error("facebook_init_failed", "Facebook SDK could not initialize or queue its probe event", null);
          return;
        }
        try {
          prefs(ctx).edit().putString(KEY_FACEBOOK_CONFIG, mapToJsonString(args)).apply();
        } catch (JSONException e) {
          Log.e(TAG, "configureFacebookSdk: cache serialize failed", e);
        }
        result.success(null);
        return;
      }

      case "trackFacebookEvent": {
        Object raw = call.arguments;
        if (!(raw instanceof Map)) {
          result.error("bad_args", "trackFacebookEvent expects a map", null);
          return;
        }
        Map<String, Object> args = (Map<String, Object>) raw;
        String eventName = stringOrNull(args.get("eventName"));
        if (eventName == null || eventName.trim().isEmpty()) {
          result.error("bad_args", "eventName is required", null);
          return;
        }
        Map<String, Object> parameters = new HashMap<>();
        Object rawParameters = args.get("parameters");
        if (rawParameters instanceof Map) {
          Map<?, ?> supplied = (Map<?, ?>) rawParameters;
          for (Map.Entry<?, ?> entry : supplied.entrySet()) {
            if (entry.getKey() instanceof String) {
              Object value = entry.getValue();
              if (value instanceof String || value instanceof Number || value instanceof Boolean) {
                parameters.put((String) entry.getKey(), value);
              }
            }
          }
        }
        try {
          logFacebookEvent(eventName.trim(), parameters);
          result.success(null);
        } catch (RuntimeException e) {
          Log.e(TAG, "Facebook trackEvent failed", e);
          result.error("not_initialized", "Facebook SDK is not initialized; call SdkBootstrap.apply first", null);
        }
        return;
      }

      case "flushFacebookEvents": {
        try {
          if (!FacebookSdk.isInitialized()) {
            throw new IllegalStateException("Facebook SDK is not initialized");
          }
          AppEventsLogger.newLogger(applicationContext).flush();
          Log.i(TAG, "Facebook App Events: flush requested");
          result.success(null);
        } catch (RuntimeException e) {
          Log.e(TAG, "Facebook flush failed", e);
          result.error("not_initialized", "Facebook SDK is not initialized; call SdkBootstrap.apply first", null);
        }
        return;
      }

      case "configureFirebaseSdk": {
        Object raw = call.arguments;
        if (!(raw instanceof Map)) {
          result.error("bad_args", "configureFirebaseSdk expects a map", null);
          return;
        }
        Map<String, Object> args = (Map<String, Object>) raw;
        Context ctx = applicationContext;
        if (ctx == null) {
          result.error("no_context", "Plugin not attached", null);
          return;
        }
        Log.i(TAG, "configureFirebaseSdk: from Flutter channel");
        configureFirebase(args, "configureFirebaseSdk");
        try {
          prefs(ctx).edit().putString(KEY_FIREBASE_CONFIG, mapToJsonString(args)).apply();
        } catch (JSONException e) {
          Log.e(TAG, "configureFirebaseSdk: cache serialize failed", e);
        }
        result.success(null);
        return;
      }

      case "configureTikTokSdk":
      case "trackTikTokEvent":
      case "flushTikTokEvents":
        // TikTok Business SDK is integrated on iOS only. No-op on Android so
        // SdkBootstrap.apply(tiktok: ...) / TikTokSdk.* do not throw on Android.
        Log.i(TAG, call.method + ": ignored (TikTok SDK is iOS-only)");
        result.success(null);
        return;

      default:
        result.notImplemented();
    }
  }

  private SharedPreferences prefs(Context ctx) {
    return ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
  }

  private static String mapToJsonString(Map<String, Object> map) throws JSONException {
    JSONObject o = new JSONObject();
    for (Map.Entry<String, Object> e : map.entrySet()) {
      Object v = e.getValue();
      if (v == null) {
        continue;
      }
      o.put(e.getKey(), v);
    }
    return o.toString();
  }

  @Override
  public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    applicationContext = null;
  }
}

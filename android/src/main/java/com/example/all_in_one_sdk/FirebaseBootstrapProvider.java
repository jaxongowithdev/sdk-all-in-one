package com.example.all_in_one_sdk;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.net.Uri;
import android.util.Log;

import org.json.JSONObject;

/**
 * Runs before {@link android.app.Application#onCreate} to apply cached Firebase resource overrides
 * (Analytics {@code google_app_id}) — same idea as iOS {@code bootstrapFromCachedConfig}.
 */
public class FirebaseBootstrapProvider extends ContentProvider {
  private static final String TAG = "AllInOneSdk";
  static final String PREFS_NAME = "all_in_one_sdk_prefs";
  static final String KEY_FIREBASE_CONFIG = "cached_firebase_config_json";

  @Override
  public boolean onCreate() {
    Context ctx = getContext();
    if (ctx == null) {
      return false;
    }
    String raw =
        ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_FIREBASE_CONFIG, null);
    if (raw == null || raw.isEmpty()) {
      Log.i(TAG, "FirebaseBootstrapProvider: no cached config");
      return false;
    }
    try {
      JSONObject json = new JSONObject(raw);
      String appId = firstNonEmpty(json, "googleAppId", "androidGoogleAppId");
      String apiKey = json.optString("apiKey", "");
      String senderId = json.optString("gcmSenderId", "");
      String projectId = json.optString("projectId", "");
      String storageBucket = json.optString("storageBucket", "");
      if (appId.isEmpty() || apiKey.isEmpty() || senderId.isEmpty() || projectId.isEmpty()) {
        Log.w(TAG, "FirebaseBootstrapProvider: cached config incomplete");
        return false;
      }
      FirebaseResourceInjector.applyEarly(
          ctx, appId, apiKey, senderId, projectId, storageBucket.isEmpty() ? null : storageBucket);
      Log.i(TAG, "FirebaseBootstrapProvider: cached resource overrides applied");
    } catch (Exception e) {
      Log.e(TAG, "FirebaseBootstrapProvider: failed", e);
    }
    return false;
  }

  private static String firstNonEmpty(JSONObject json, String... keys) {
    for (String key : keys) {
      String v = json.optString(key, "");
      if (!v.isEmpty()) {
        return v;
      }
    }
    return "";
  }

  @Override
  public Cursor query(Uri uri, String[] projection, String selection, String[] args, String sort) {
    return null;
  }

  @Override
  public String getType(Uri uri) {
    return null;
  }

  @Override
  public Uri insert(Uri uri, ContentValues values) {
    return null;
  }

  @Override
  public int delete(Uri uri, String selection, String[] args) {
    return 0;
  }

  @Override
  public int update(Uri uri, ContentValues values, String selection, String[] args) {
    return 0;
  }
}

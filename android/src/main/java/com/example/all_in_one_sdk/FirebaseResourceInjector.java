package com.example.all_in_one_sdk;

import android.app.Application;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.Resources;
import android.util.Log;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Dynamic Firebase Measurement strings from API (no {@code google-services.json}), aligned with
 * iOS {@code FIROptions}. Android Analytics reads {@code R.string.google_app_id}; use with
 * {@link AllInOneSdkApplication} or early {@link FirebaseBootstrapProvider}.
 */
final class FirebaseResourceInjector {
  private static final String TAG = "AllInOneSdk";

  private FirebaseResourceInjector() {}

  static void applyEarly(
      Context context,
      String googleAppId,
      String apiKey,
      String gcmSenderId,
      String projectId,
      String storageBucket) {
    setOverrides(googleAppId, apiKey, gcmSenderId, projectId, storageBucket);
    tryPatchContextChain(context, "early");
  }

  static void apply(
      Context context,
      String googleAppId,
      String apiKey,
      String gcmSenderId,
      String projectId,
      String storageBucket) {
    setOverrides(googleAppId, apiKey, gcmSenderId, projectId, storageBucket);
    tryPatchContextChain(context, "configure");
    Context app = context.getApplicationContext();
    verifyGoogleAppId(app.getResources(), app.getPackageName(), googleAppId);
  }

  static Resources wrapIfNeeded(Resources base) {
    if (base == null || !FirebaseResourceHolder.hasOverrides()) {
      return base;
    }
    if (base instanceof FirebaseOverridingResources) {
      ((FirebaseOverridingResources) base).updateOverrides(FirebaseResourceHolder.get());
      return base;
    }
    return new FirebaseOverridingResources(base, FirebaseResourceHolder.get());
  }

  private static void setOverrides(
      String googleAppId,
      String apiKey,
      String gcmSenderId,
      String projectId,
      String storageBucket) {
    Map<String, String> overrides = new HashMap<>();
    overrides.put("google_app_id", googleAppId);
    overrides.put("google_api_key", apiKey);
    overrides.put("gcm_defaultSenderId", gcmSenderId);
    overrides.put("project_id", projectId);
    if (storageBucket != null && !storageBucket.isEmpty()) {
      overrides.put("google_storage_bucket", storageBucket);
    }
    FirebaseResourceHolder.set(overrides);
  }

  private static void tryPatchContextChain(Context start, String label) {
    boolean patched = false;
    Context ctx = start;
    Set<Context> seen = new HashSet<>();
    while (ctx != null && seen.add(ctx)) {
      if (patchResourceFields(ctx, FirebaseResourceHolder.get(), label)) {
        patched = true;
      }
      if (ctx instanceof ContextWrapper) {
        ctx = ((ContextWrapper) ctx).getBaseContext();
      } else {
        break;
      }
    }
    Context appCtx = start.getApplicationContext();
    if (appCtx instanceof Application && appCtx != start) {
      patched |= patchResourceFields(appCtx, FirebaseResourceHolder.get(), label + ":app");
    }
    if (!patched && start.getApplicationContext().getResources() instanceof FirebaseOverridingResources) {
      patched = true;
    }
    if (!patched) {
      Log.i(
          TAG,
          "Firebase resources: use AllInOneSdkApplication — see README (flutter.applicationName)");
    }
  }

  private static boolean patchResourceFields(
      Object target, Map<String, String> overrides, String label) {
    Class<?> type = target.getClass();
    while (type != null) {
      for (Field field : type.getDeclaredFields()) {
        if (!Resources.class.isAssignableFrom(field.getType())) {
          continue;
        }
        try {
          field.setAccessible(true);
          Resources current = (Resources) field.get(target);
          if (current == null && target instanceof Context) {
            current = ((Context) target).getResources();
          }
          if (current == null) {
            continue;
          }
          Resources wrapped = wrapResourcesInstance(current, overrides);
          field.set(target, wrapped);
          Log.i(TAG, "Firebase resources: patched " + field.getName() + " (" + label + ")");
          return true;
        } catch (ReflectiveOperationException | RuntimeException e) {
          Log.d(TAG, "Firebase resources: skip " + field.getName() + ": " + e.getMessage());
        }
      }
      type = type.getSuperclass();
    }
    return false;
  }

  private static Resources wrapResourcesInstance(Resources current, Map<String, String> overrides) {
    if (current instanceof FirebaseOverridingResources) {
      ((FirebaseOverridingResources) current).updateOverrides(overrides);
      return current;
    }
    return new FirebaseOverridingResources(current, overrides);
  }

  private static void verifyGoogleAppId(Resources res, String pkg, String expected) {
    int id = res.getIdentifier("google_app_id", "string", pkg);
    if (id == 0) {
      Log.e(TAG, "Firebase Analytics: google_app_id missing in merged resources");
      return;
    }
    try {
      String current = res.getString(id);
      boolean ok = expected.equals(current);
      Log.i(
          TAG,
          "Firebase Analytics: google_app_id "
              + (ok ? "OK" : "MISMATCH")
              + " (read="
              + current
              + ")");
    } catch (Exception e) {
      Log.w(TAG, "Firebase Analytics: verify failed", e);
    }
  }
}

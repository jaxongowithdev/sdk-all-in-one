package com.example.all_in_one_sdk;

import android.content.res.Resources;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

/**
 * {@link Resources} wrapper so Firebase Measurement reads API-driven string values
 * (google_app_id, etc.) without the google-services Gradle plugin.
 */
final class FirebaseOverridingResources extends Resources {
  private static final String TAG = "AllInOneSdk";

  private final Resources base;
  private final Map<String, String> overrides;

  FirebaseOverridingResources(Resources base, Map<String, String> overrides) {
    super(base.getAssets(), base.getDisplayMetrics(), base.getConfiguration());
    this.base = base;
    this.overrides = new HashMap<>(overrides);
  }

  void updateOverrides(Map<String, String> newOverrides) {
    overrides.clear();
    overrides.putAll(newOverrides);
  }

  @Override
  public String getString(int id) throws NotFoundException {
    try {
      if ("string".equals(getResourceTypeName(id))) {
        String entry = getResourceEntryName(id);
        String value = overrides.get(entry);
        if (value != null) {
          return value;
        }
      }
    } catch (NotFoundException e) {
      Log.d(TAG, "FirebaseOverridingResources: getString fallback id=" + id, e);
    }
    return base.getString(id);
  }

  @Override
  public CharSequence getText(int id) throws NotFoundException {
    try {
      if ("string".equals(getResourceTypeName(id))) {
        String entry = getResourceEntryName(id);
        String value = overrides.get(entry);
        if (value != null) {
          return value;
        }
      }
    } catch (NotFoundException ignored) {
      // fall through
    }
    return base.getText(id);
  }
}

package com.example.all_in_one_sdk;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/** API-driven Firebase string overrides (read by {@link AllInOneSdkApplication#getResources()}). */
final class FirebaseResourceHolder {
  private static volatile Map<String, String> overrides = Collections.emptyMap();

  private FirebaseResourceHolder() {}

  static void set(Map<String, String> values) {
    overrides = Collections.unmodifiableMap(new HashMap<>(values));
  }

  static Map<String, String> get() {
    return overrides;
  }

  static boolean hasOverrides() {
    return !overrides.isEmpty();
  }
}

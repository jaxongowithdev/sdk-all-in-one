package com.example.all_in_one_sdk;

import android.app.Application;
import android.content.res.Resources;

/**
 * Merged into the host app by this plugin (see AndroidManifest). Supplies {@code google_app_id}
 * from API config so Analytics works without {@code google-services.json}.
 *
 * <p>If the host app already has a custom {@link Application}, extend this class instead.
 */
public class AllInOneSdkApplication extends Application {
  @Override
  public Resources getResources() {
    return FirebaseResourceInjector.wrapIfNeeded(super.getResources());
  }
}

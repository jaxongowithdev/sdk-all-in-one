# Keep plugin + Firebase when host app uses minifyEnabled (release).
-keep class com.example.all_in_one_sdk.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.measurement.** { *; }
-dontwarn com.google.android.gms.**

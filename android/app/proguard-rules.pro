# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter's deferred components (Play Core) - referenced but not used locally
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.** { *; }

# Avoid proguard issue with gson/okhttp/reflection used by http package and shared prefs
-keepattributes Signature
-keepattributes Exceptions

# Gson / JSON parsing
-keep class com.squareup.moshi.** { *; }
-keepclassmembers class * implements com.squareup.moshi.JsonAdapter { *; }
-keep @com.squareup.moshi.FromJson class *
-keep @com.squareup.moshi.ToJson class *

# Keep model classes referenced from JSON
-keep class com.example.mallflutter.** { *; }

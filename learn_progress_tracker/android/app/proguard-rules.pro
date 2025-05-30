# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your model classes
-keep class com.example.learn_progress_tracker.models.** { *; }

# Keep any classes that are referenced in the AndroidManifest.xml
-keep class com.example.learn_progress_tracker.MainActivity { *; }

# Flutter Play Core and deferred components
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; } 
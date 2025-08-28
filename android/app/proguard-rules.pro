# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 16KB 記憶體分頁支援
-keep class ** { native <methods>; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# 避免混淆記憶體相關程式碼
-keep class android.system.** { *; }

# MultiDex
-keep class androidx.multidex.** { *; }

# Play Core Library
-keep class com.google.android.play.core.** { *; }
-keep enum com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keep @interface com.google.android.play.core.** { *; }
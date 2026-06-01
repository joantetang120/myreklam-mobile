# SLF4J - Ignore missing implementation classes
-dontwarn org.slf4j.impl.StaticLoggerBinder
-dontwarn org.slf4j.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep MainActivity
-keep class com.myreklam.app.MainActivity { *; }

# Keep Flutter embedding
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Facebook SDK
-keep class com.facebook.** { *; }
-keepattributes *Annotation*

# Keep model classes used by JSON serialization
-keepclassmembers class * {
    *** *(...);
}

# Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Stripe
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }

-ignorewarnings
# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase / Postgrest
-keep class com.supabase.** { *; }
-dontwarn com.supabase.**

# Standard Android & Java
-dontwarn android.test.**
-dontwarn android.util.**
-dontwarn java.lang.management.**
-dontwarn java.lang.instrument.**
-dontwarn java.beans.**
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn javax.naming.**
-dontwarn javax.servlet.**
-dontwarn javax.xml.**
-dontwarn sun.misc.**
-dontwarn sun.security.**

# Common Third Party
-dontwarn com.google.errorprone.annotations.**
-dontwarn org.checkerframework.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# Retrofit / OkHttp (Used by many plugins)
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-dontwarn okio.**

# Flutter specific
-dontwarn io.flutter.**

# Coroutines (if used by plugins)
-dontwarn kotlinx.coroutines.**


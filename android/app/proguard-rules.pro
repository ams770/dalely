# flutter_local_notifications uses Gson with generic TypeToken; R8 strips the
# generic signatures in release builds ("Missing type parameter").
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

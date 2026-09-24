# GreenGo R8 rules.
#
# Keep this file NARROW. Flutter, Firebase, Google Play services, ML Kit and
# the plugins all ship their own consumer ProGuard rules inside their AARs, so
# they need nothing here. Blanket rules such as `-keep class com.google.** { *; }`
# stop R8 from obfuscating most of the app's DEX, which is what Play Console
# flags as "DEX code optimization below threshold (Obfuscation)".
#
# Add a rule only for a concrete crash/missing-class, scoped to that class.

# App entry points (MainActivity etc.) are referenced from the manifest and
# by Flutter's embedding by name.
-keep class com.greengochat.greengochatapp.** { *; }

# Reflection-based serialization / generics / annotations used by Firebase
# and Gson-style libraries.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Firestore model fields mapped by @PropertyName.
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# JNI: native method names must match the .so symbols.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Readable stack traces in Play Console (mapping.txt is uploaded with the AAB).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter's deferred-components hooks reference Play Core, which this app
# does not ship.
-dontwarn com.google.android.play.core.**

# Optional ML Kit text-recognition language modules are not bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

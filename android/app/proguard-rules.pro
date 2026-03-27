# ProGuard Rules para Teconnect Support

# Mantener clases de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Mantener clases de Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Mantener clases de modelo
-keep class com.teconnect.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Mantener clases serializables
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Mantener clases de Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Mantener clases de Gson si se usa
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Mantener clases de Provider
-keep class * extends io.flutter.plugin.common.PluginRegistry { *; }

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener constructores de Activity
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# Mantener clases de enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Mantener clases de parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Mantener clases R
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Evitar warnings
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.internal.**

# Optimizaciones
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify


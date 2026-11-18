# OkHttp (pulled in by a plugin) references optional TLS providers that are not bundled.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# R8 full mode strips generic signatures, which breaks Gson TypeToken inside the
# Apryse (PDFTron) viewer: "RuntimeException: Missing type parameter" crashed the
# app every time a document was opened. Keep the signatures and the SDK classes.
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.pdftron.** { *; }
-dontwarn com.pdftron.**

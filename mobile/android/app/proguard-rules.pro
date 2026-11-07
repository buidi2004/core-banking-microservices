# ==============================================================================
# Sen Hong Bank - ProGuard / R8 Rules for Release Build
# Chống R8 strip nhầm thư viện eKYC Biometric, Camera, NFC & ML Kit
# ==============================================================================

# 1. Google ML Kit Face Detection & Vision
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# 2. Camera & CameraX
-keep class androidx.camera.** { *; }
-keep interface androidx.camera.** { *; }
-dontwarn androidx.camera.**

# 3. NFC & ICAO 9303 — flutter_nfc_kit (ReaderMode/ISO-DEP) + flutter_cccd_vn
#    (Dart-side dmrtd fork, phần native chỉ là bridge: giữ nguyên plugin class)
-keep class im.nfc.flutter_nfc_kit.** { *; }
-dontwarn im.nfc.flutter_nfc_kit.**
# Dự phòng cho luồng JMRTD/SCUBA nếu sau này thêm AAR native đọc chip
-keep class net.sf.scuba.** { *; }
-keep class org.jmrtd.** { *; }
-dontwarn net.sf.scuba.**
-dontwarn org.jmrtd.**

# 4. Bouncy Castle Cryptography
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# 5. Flutter Platform Channels & Plugins
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# 6. Google Play Core & Deferred Components (R8 missing classes)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**


# ML Kit discovers these registrars through manifest names and reflection.
# firebase-components 16.1.0 keeps the classes but omits their constructors.
# R8 full mode otherwise removes those constructors, breaking release OCR.
-keep class * implements com.google.firebase.components.ComponentRegistrar { public <init>(); }
-keep,allowshrinking interface com.google.firebase.components.ComponentRegistrar

# The Flutter bridge has optional branches for scripts not bundled in this app.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder

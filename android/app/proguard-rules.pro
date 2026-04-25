# Keep file names/line numbers for crash analysis while still shrinking.
-keepattributes SourceFile,LineNumberTable

# Flutter and common plugin interop; keep this conservative.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

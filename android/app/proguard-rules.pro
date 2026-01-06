# ProGuard rules to remove Google Play Core
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**

# If anything in the app actually uses these, we want it to fail at runtime 
# rather than including the library.

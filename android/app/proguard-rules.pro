# Stripe Push Provisioning - Evitar que R8 elimine estas clases
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.**

# Mantener clases de Stripe en general
-keep class com.stripe.android.** { *; }
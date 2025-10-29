plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.poligrain_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Increase the dex/java heap for packaging tasks (help avoid OOM during APK packaging)
    dexOptions {
        // Note: dexOptions is recognized by many Android Gradle Plugin versions.
        // If your AGP version ignores this, org.gradle.jvmargs in gradle.properties will still apply.
        javaMaxHeapSize = "4g"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.poligrain_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

        }
    }
    buildToolsVersion = "36.0.0"

    dependencies {
        // ... your existing dependencies ...

        // Add Google Tink dependency for AEAD configuration
       // implementation("com.google.crypto.tink:tink-android:1.17.0")
        // If 1.11.0 causes issues, you might try a slightly older stable version or check
        // the documentation of your Amplify plugins for their recommended Tink version.
        implementation("androidx.security:security-crypto:1.0.0")
    }
}


flutter {
    source = "../.."
}

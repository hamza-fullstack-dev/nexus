plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase / Google Services plugin - ADDED
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.study_assistant"
    compileSdk = 36
    // NDK (Native Development Kit) - Required for native code compilation
    // Install NDK via Android Studio SDK Manager before building
    // See NDK_INSTALLATION_GUIDE.md for detailed instructions
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.study_assistant"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // UPDATED: Firebase Auth requires minimum SDK 23
        targetSdk = 36
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
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM - manages all Firebase library versions automatically - ADDED
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))

    // Firebase Authentication - ADDED
    implementation("com.google.firebase:firebase-auth")

    // Firebase Firestore - ADDED
    implementation("com.google.firebase:firebase-firestore")

    // Firebase Storage - ADDED
    implementation("com.google.firebase:firebase-storage")

    // Google Sign-In - ADDED
    implementation("com.google.android.gms:play-services-auth:21.0.0")
}

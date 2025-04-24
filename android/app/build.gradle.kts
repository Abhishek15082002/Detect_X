plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.blabla"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.blabla"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
//            minifyEnabled = true
        }
//        release {
//            // TODO: Add your own signing config for the release build.
//            // Signing with the debug keys for now, so `flutter run --release` works.
//            signingConfig = signingConfigs.getByName("debug") // Remember to configure your actual release signing!
//            minifyEnabled = true
//            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
//            shrinkResources = true // Consider enabling this for release builds
//        }
//        debug {
//            signingConfig = signingConfigs.getByName("debug")
//            minifyEnabled = false // Typically false for debug to speed up builds
//            shrinkResources = false // Typically false for debug
//            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
//        }
    }
}

flutter {
    source = "../.."
}

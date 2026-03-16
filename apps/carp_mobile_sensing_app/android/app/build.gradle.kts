plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dk.carp.carp_mobile_sensing_app"
    compileSdk = flutter.compileSdkVersion  
    // compileSdk = 36  
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // jvmTarget = JavaVersion.VERSION_17
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dk.carp.carp_mobile_sensing_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // From flutter_local_notifications
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Use to implement Health Connect. Requires SDK level 34.
    implementation("androidx.health.connect:connect-client:1.1.0-rc02")

    // Use to implement the Flutter Local Notifications plugin
    coreLibraryDesugaring ("com.android.tools:desugar_jdk_libs:2.1.5")
    
    // AppCompat library for Theme.AppCompat.NoActionBar
    implementation("androidx.appcompat:appcompat:1.7.0")
}

flutter {
    source = "../.."
}

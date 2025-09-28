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
    namespace = "com.feresgamer.simplechat.simplechat"
    compileSdk = 36 // <-- ACTUALIZADO
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // --- PRIMERA LÍNEA A AÑADIR ---
        // Habilita el soporte para APIs modernas de Java en versiones antiguas de Android.
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.feresgamer.simplechat.simplechat"
        minSdk = flutter.minSdkVersion // flutter.minSdkVersion
        targetSdk = 36 // flutter.targetSdkVersion
        versionCode = 1 // flutter.versionCode
        versionName = "1.0.0" // flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ... (tus otras dependencias como firebase, etc.)

    // --- SEGUNDA LÍNEA A AÑADIR ---
    // Le dice a tu app qué "diccionario" usar para la traducción.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // <--- AÑADE ESTO
}

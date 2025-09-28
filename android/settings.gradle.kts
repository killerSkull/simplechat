pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // --- CORRECCIÓN: Actualizamos a la versión más reciente recomendada ---
    id("com.android.application") version "8.4.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.1") apply false // Versión actualizada
    // END: FlutterFire Configuration
    // --- CORRECCIÓN: Actualizamos a la versión más reciente recomendada ---
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false 
}

include(":app")

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.teconnect"   // ← Cambia si tu package es diferente

    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.teconnect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // === CORRECCIÓN PRINCIPAL PARA EL ERROR libflutter.so ===
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
            // Opción ligera (recomendada en 2026 si solo quieres 64-bit):
            // abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false   // puedes activarlo después si quieres
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
import java.io.File
import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.tasks.bundling.AbstractArchiveTask

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.trapplab.nfc_radio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.trapplab.nfc_radio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "store"
    productFlavors {
        create("fdroid") {
            dimension = "store"
            versionNameSuffix = "-fdroid"
        }
        create("play") {
            dimension = "store"
        }
        create("github") {
            dimension = "store"
            versionNameSuffix = "-github"
        }
    }

    signingConfigs {
        create("release") {
            // For F-Droid reproducibility, we only configure signing if the properties are present.
            // F-Droid's 'fdroid verify' compares the unsigned contents of the APK.
            // If this block is skipped, Gradle produces an unsigned APK.
            if (keystorePropertiesFile.exists() && keystoreProperties.getProperty("storeFile") != null) {
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                
                // Explicitly enable V1 and V2 signing, disable V3 and V4 for maximum compatibility and reproducibility
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = false
                enableV4Signing = false
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Only assign signingConfig if it was actually configured above
            if (keystorePropertiesFile.exists() && keystoreProperties.getProperty("storeFile") != null) {
                signingConfig = signingConfigs.getByName("release")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    // Ensure reproducible builds by disabling build config fields that might change
    // and setting a fixed timestamp for the APK entries.
    packaging {
        resources {
            // Exclude only non-essential metadata that can vary between builds
            excludes += "/META-INF/com.android.tools/**"
            excludes += "/META-INF/*.kotlin_module"
        }
        dex {
            useLegacyPackaging = false
        }
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}

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

    // Reproducible builds: use a fixed timestamp for all files in the APK
    // This ensures that the APK is bit-for-bit identical when built from the same source
    // We use the value from SOURCE_DATE_EPOCH if available, otherwise a fixed default.
    val sourceDateEpoch = System.getenv("SOURCE_DATE_EPOCH")?.toLong()
    val fixedTimestamp = if (sourceDateEpoch != null) sourceDateEpoch * 1000L else 1704067200000L

    // Apply fixed timestamp to all tasks that support it
    tasks.withType<AbstractArchiveTask>().configureEach {
        isPreserveFileTimestamps = false
        isReproducibleFileOrder = true
    }

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
        // Fix File constructor - use file() helper or explicit String
        storeFile = file(keystoreProperties.getProperty("storeFile") ?: error("storeFile missing"))
        storePassword = keystoreProperties.getProperty("storePassword") ?: error("storePassword missing")
        keyAlias = keystoreProperties.getProperty("keyAlias") ?: error("keyAlias missing")
        keyPassword = keystoreProperties.getProperty("keyPassword") ?: error("keyPassword missing")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

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
            excludes += "/META-INF/**"
        }
    }
}

flutter {
    source = "../.."
}

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.lokesh.lokeshmusic"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    defaultConfig {
        applicationId = "com.lokesh.lokeshmusic"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "flavor"

    productFlavors {
        create("github") {
            dimension = "flavor"
            applicationIdSuffix = ""
        }
        create("fdroid") {
            dimension = "flavor"
            applicationIdSuffix = ".fdroid"
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                // Relative paths resolve against android/app; absolute paths
                // are supported so the keystore can live outside the repo.
                storeFile = file(keystoreProperties.getProperty("storeFile") ?: "key.jks")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    buildTypes {
        getByName("release") {
            // CI and maintainer builds sign with the release keystore when
            // key.properties is present. Local release builds without it fall
            // back to debug signing so they remain installable for testing,
            // but must never be published as official binaries.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = " DEBUG"
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

afterEvaluate {
    apply(from = "../no-build-id.gradle")
}

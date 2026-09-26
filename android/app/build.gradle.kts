import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase — Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.yobnate.yobnate_colis"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.yobnate.yobnate_colis"
        minSdk = flutter.minSdkVersion   // Android 6.0 — couvre 99%+ des appareils actifs en 2026
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // D'ABORD signingConfigs
    signingConfigs {
        val storeFilePath = keystoreProperties["storeFile"]?.toString()
        if (storeFilePath != null && file(storeFilePath).exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"]?.toString()
                keyPassword = keystoreProperties["keyPassword"]?.toString()
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"]?.toString()
            }
        }
    }

    // ENSUITE buildTypes
    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            // VULN-C02 : Obfuscation activée en production
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Firebase BoM — gère automatiquement les versions de tous les SDK Firebase
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Firebase Analytics (obligatoire avec google-services plugin)
    implementation("com.google.firebase:firebase-analytics")

    // Firebase Crashlytics — monitoring des crashes en production
    implementation("com.google.firebase:firebase-crashlytics")
}

flutter {
    source = "../.."
}

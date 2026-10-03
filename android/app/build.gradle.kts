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
}

// Firebase (notifications push + suivi des crashs) — actifs UNIQUEMENT si
// google-services.json est présent.
//
// Les plugins google-services/crashlytics font échouer le build quand le
// fichier manque. En les conditionnant, le projet reste compilable sans
// Firebase (Firebase.initializeApp() échoue alors proprement, voir main.dart)
// et se câble tout seul dès que le fichier est déposé dans android/app/.
//
// Où l'obtenir : console Firebase > Paramètres du projet > Vos applications >
// Android > google-services.json. Le nom de package doit correspondre à
// applicationId ci-dessous : com.yobante.colis
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    // Envoie le fichier de désobfuscation (mapping R8) à Crashlytics : sans
    // lui, les plantages natifs de la version release sont illisibles.
    apply(plugin = "com.google.firebase.crashlytics")
} else {
    logger.warn("[firebase] google-services.json absent — notifications push et Crashlytics natifs désactivés")
}

android {
    namespace = "com.yobante.colis"
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
        // Identifiant DÉFINITIF sur Google Play : il ne peut plus changer une fois
        // l'app publiée.
        applicationId = "com.yobante.colis"
        minSdk = flutter.minSdkVersion   // API 24 (Android 7.0) avec Flutter 3.44
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // D'ABORD signingConfigs
    // storeFile est RELATIF au dossier android/ (rootProject.file), comme dans
    // la CI (.github/workflows/android-release.yml) et le Fastfile.
    signingConfigs {
        val storeFilePath = keystoreProperties["storeFile"]?.toString()
        if (storeFilePath != null && rootProject.file(storeFilePath).exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"]?.toString()
                keyPassword = keystoreProperties["keyPassword"]?.toString()
                storeFile = rootProject.file(storeFilePath)
                storePassword = keystoreProperties["storePassword"]?.toString()
            }
        }
    }

    // ENSUITE buildTypes
    buildTypes {
        release {
            // Sans android/key.properties, une version « release » signée avec la clé de
            // debug serait refusée par le Play Store (et impossible à mettre à jour).
            // Le build échoue donc, sauf essai local explicite : SIGNATURE_DEBUG=1.
            val signatureRelease = signingConfigs.findByName("release")
            val buildRelease = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
            if (signatureRelease == null && buildRelease && System.getenv("SIGNATURE_DEBUG") != "1") {
                throw GradleException(
                    "Signature release introuvable : créez android/key.properties (storeFile, storePassword, " +
                        "keyAlias, keyPassword). Pour un simple essai local : SIGNATURE_DEBUG=1 flutter build apk --release"
                )
            }
            signingConfig = signatureRelease ?: signingConfigs.getByName("debug")
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

    // Pas de firebase-analytics : l'app ne l'utilise pas, et il ajoute les
    // permissions publicitaires AD_ID / ACCESS_ADSERVICES_* que Google Play
    // oblige alors à déclarer (« identifiant publicitaire »).

    // Firebase Crashlytics — monitoring des crashes en production
    implementation("com.google.firebase:firebase-crashlytics")
}

flutter {
    source = "../.."
}

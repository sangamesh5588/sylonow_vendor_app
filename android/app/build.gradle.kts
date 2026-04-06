plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // No Firebase - we're using pure Google Cloud OAuth
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties from android/key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sylonow.SylonowVendor"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.sylonow.SylonowVendor"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Keep Android version aligned with pubspec.yaml (x.y.z+build).
        versionCode = 33
        versionName = "2.1.2"
        
        // Enable multidex support
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "sylonow-vendor"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: "sylonow123"
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String? ?: "app/release-key.keystore")
            storePassword = keystoreProperties["storePassword"] as String? ?: "sylonow123"
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
            isMinifyEnabled = false
        }
        
        release {
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
            
            // Temporarily disabled for compatibility
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    // Enable R8 full mode
    buildFeatures {
        buildConfig = true
    }
    
    // Fix for image_picker and other plugins compilation issues
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }
    
    // Additional configuration for release builds
    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        force("org.jetbrains.kotlin:kotlin-stdlib:2.1.21")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.21")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.21")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("androidx.multidex:multidex:2.0.1")
}

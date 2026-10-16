plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingNames = listOf("REX_SIGNING_STORE", "REX_SIGNING_STORE_PASSWORD", "REX_SIGNING_ALIAS", "REX_SIGNING_KEY_PASSWORD")
val signingReady = signingNames.all { !System.getenv(it).isNullOrBlank() }
val finalApplicationId = System.getenv("REX_APPLICATION_ID")

android {
    namespace = "dev.rex.internal.rex_production"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = finalApplicationId ?: "dev.rex.internal.rex_production"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    if (signingReady) {
        signingConfigs {
            create("production") {
                storeFile = file(System.getenv("REX_SIGNING_STORE"))
                storePassword = System.getenv("REX_SIGNING_STORE_PASSWORD")
                keyAlias = System.getenv("REX_SIGNING_ALIAS")
                keyPassword = System.getenv("REX_SIGNING_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            if (signingReady) signingConfig = signingConfigs.getByName("production")
        }
    }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release") }) {
        require(signingReady) { "Release requires injected REX_SIGNING_* configuration; debug signing is forbidden." }
        require(!finalApplicationId.isNullOrBlank() && !finalApplicationId.contains("internal")) {
            "Release requires the human-approved REX_APPLICATION_ID."
        }
    }
}
flutter { source = "../.." }

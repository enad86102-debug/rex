plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
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
        applicationId = "dev.rex.qa.native"
        minSdk = 23
        targetSdk = 36
        versionCode = 1
        versionName = "0.0.1"
    }
    sourceSets {
        // Compile the real production implementation, not a copied fake vault.
        getByName("main").java.srcDir("../../../../mobile/android/app/src/main/kotlin")
        getByName("main").res.srcDir("../../../../mobile/android/app/src/main/res")
        getByName("debug").res.srcDir("../../../../mobile/android/app/src/debug/res")
    }
}
gradle.taskGraph.whenReady {
    require(allTasks.none { it.name.contains("Release", ignoreCase = true) || it.name.contains("Profile", ignoreCase = true) }) {
        "REX QA harness is debug-only and must never be distributed."
    }
}
flutter { source = "../.." }

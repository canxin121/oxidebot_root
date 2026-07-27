plugins {
    id("com.android.application")
}

android {
    namespace = "io.github.canxin121.oxidebotroot"
    compileSdk = 35

    defaultConfig {
        applicationId = "io.github.canxin121.oxidebotroot"
        minSdk = 24
        targetSdk = 35
        versionCode = 10000
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

val syncWebUi by tasks.registering(Copy::class) {
    from(rootProject.projectDir.resolve("../webroot"))
    into(layout.projectDirectory.dir("src/main/assets"))
}

tasks.named("preBuild").configure { dependsOn(syncWebUi) }

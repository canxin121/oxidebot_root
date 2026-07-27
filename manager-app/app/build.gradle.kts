plugins {
    id("com.android.application")
}

val releaseKeystoreFile = providers.environmentVariable("OXIDEBOT_KEYSTORE_FILE").orNull
val releaseKeystorePassword = providers.environmentVariable("OXIDEBOT_KEYSTORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("OXIDEBOT_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("OXIDEBOT_KEY_PASSWORD").orNull

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

    val releaseSigning = if (
        !releaseKeystoreFile.isNullOrBlank()
        && !releaseKeystorePassword.isNullOrBlank()
        && !releaseKeyAlias.isNullOrBlank()
        && !releaseKeyPassword.isNullOrBlank()
    ) {
        signingConfigs.create("release") {
            storeFile = file(releaseKeystoreFile)
            storePassword = releaseKeystorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    } else {
        null
    }

    buildTypes {
        release {
            releaseSigning?.let { signingConfig = it }
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

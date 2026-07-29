import java.util.Properties

plugins {
    id("com.android.application")
}

val templatePropertiesFile = rootProject.file("../template.properties")
val templateProperties = Properties().apply {
    require(templatePropertiesFile.isFile) { "Missing template.properties" }
    templatePropertiesFile.inputStream().use(::load)
}

fun templateValue(name: String): String =
    templateProperties.getProperty(name)?.trim()?.takeIf(String::isNotEmpty)
        ?: error("Missing $name in template.properties")

val templateModuleId = templateValue("moduleId")
val templateApplicationId = templateValue("applicationId")
val templateAppName = templateValue("appName")
val templateVersionName = templateValue("versionName")
val templateVersionCode = templateValue("versionCode").toInt()

val releaseKeystoreFile = providers.environmentVariable("OXIDEBOT_KEYSTORE_FILE").orNull
val releaseKeystorePassword = providers.environmentVariable("OXIDEBOT_KEYSTORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("OXIDEBOT_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("OXIDEBOT_KEY_PASSWORD").orNull

android {
    namespace = "io.github.canxin121.oxidebotroot"
    compileSdk = 35

    defaultConfig {
        applicationId = templateApplicationId
        minSdk = 24
        targetSdk = 35
        versionCode = templateVersionCode
        versionName = templateVersionName
        buildConfigField("String", "MODULE_ID", "\"$templateModuleId\"")
        resValue("string", "app_name", templateAppName)
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

    buildFeatures {
        buildConfig = true
        resValues = true
    }
}

val syncWebUi = tasks.register<Copy>("syncWebUi") {
    inputs.file(templatePropertiesFile)
    from(rootProject.projectDir.resolve("../webroot"))
    into(layout.projectDirectory.dir("src/main/assets"))
    filter { line: String -> line.replace("__MODULE_ID__", templateModuleId) }
}

tasks.named("preBuild").configure { dependsOn(syncWebUi) }

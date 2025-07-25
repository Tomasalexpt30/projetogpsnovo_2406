import java.util.Properties
import java.io.File

/* ---------- signing-key ---------- */
val keystoreProps = Properties().apply {
    val propsFile = rootProject.file("key.properties")
    if (propsFile.exists()) load(propsFile.inputStream())
}

/* ---------- version auto-increment ---------- */
/* --- read / bump version.properties --- */
val versionPropsFile = rootProject.file("version.properties")
val versionProps     = Properties().apply {
    if (versionPropsFile.exists()) load(versionPropsFile.inputStream())
}
val currentCode = (versionProps["VERSION_CODE"] as String?)?.trim()?.toIntOrNull() ?: 1
val newCode     = currentCode + 1                 // the only Int we need
val newName     = "1.$newCode.0"                 // or any pattern you like

versionProps["VERSION_CODE"] = newCode.toString()
versionProps["VERSION_NAME"] = newName
versionProps.store(versionPropsFile.outputStream(), null)

/* --- optional log --- */
println("▶︎ versionCode bumped: $currentCode → $newCode")

/* ---------- plugins ---------- */
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

/* ---------- android ---------- */
android {
    namespace   = "autogps.projetogpsnovo"
    compileSdk  = 35
    ndkVersion  = "27.2.12479018"

    defaultConfig {
        applicationId = "autogps.projetogpsnovo"
        minSdk        = 21
        targetSdk     = 35
        versionCode   = newCode
        versionName   = newName
    }

    signingConfigs {
        create("release") {
            val storeFileProp     = keystoreProps["storeFile"] as? String
            val storePasswordProp = keystoreProps["storePassword"] as? String
            val keyAliasProp      = keystoreProps["keyAlias"] as? String
            val keyPasswordProp   = keystoreProps["keyPassword"] as? String

            if (storeFileProp != null && storePasswordProp != null && keyAliasProp != null && keyPasswordProp != null) {
                storeFile     = file(storeFileProp)
                storePassword = storePasswordProp
                keyAlias      = keyAliasProp
                keyPassword   = keyPasswordProp
            } else {
                println("Warning: key.properties is missing")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig      = signingConfigs.getByName("release")
            isMinifyEnabled    = false
            isShrinkResources  = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = "11" }
}

flutter { source = "../.." }

buildscript {
    extra.apply {
        set("kotlin_version", "2.1.0")
    }
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// FORCE COMPILE SDK 36 FOR ALL SUBPROJECTS (PLUGINS)
// Must be before evaluationDependsOn
subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            try {
                configure<com.android.build.gradle.BaseExtension> {
                    compileSdkVersion(35)
                    defaultConfig {
                        targetSdk = 35
                    }
                    // Phase 8 Fix: Inject namespace for legacy telephony package
                    if (project.name == "telephony") {
                        namespace = "com.shounakmulay.telephony"
                    }
                }
            } catch (e: Exception) {
                // Ignore if the extension type is not found or other errors
                println("Failed to force compileSdk for ${project.name}: $e")
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
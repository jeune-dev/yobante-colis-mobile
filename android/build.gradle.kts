plugins {
    // Plugin Google Services — requis pour Firebase (google-services.json)
    id("com.google.gms.google-services") version "4.4.4" apply false
    // Suivi des crashs — même conditionnement que google-services : appliqué
    // seulement si google-services.json est présent (voir app/build.gradle.kts).
    id("com.google.firebase.crashlytics") version "3.0.3" apply false
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

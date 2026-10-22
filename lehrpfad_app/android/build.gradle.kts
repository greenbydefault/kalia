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

// flutter_avif_android 3.1.0 liefert FlutterAvifPlugin doppelt (Java + Kotlin,
// identisch). Mit Kotlin-Kompilierung: "Redeclaration". Kotlin-Task abschalten,
// die Java-Version reicht.
// Ausserdem compileSdk 31 -> 36 (androidx-Abhängigkeiten verlangen >= 34).
project(":flutter_avif_android") {
    afterEvaluate {
        (extensions.getByName("android") as com.android.build.api.dsl.LibraryExtension)
            .compileSdk = 36
    }
    tasks.configureEach {
        if (name.startsWith("compile") && name.endsWith("Kotlin")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

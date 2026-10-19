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

// Some plugins require compiling against API 36+ (flutter_plugin_android_lifecycle
// 2.0.35, pulled transitively), but others pin compileSdk 34 in their own
// build.gradle (e.g. file_picker). Raise every Android library sub-module to 36
// so AAR metadata checks pass. This afterEvaluate runs AFTER each plugin's own
// build script sets its value, and is registered BEFORE the evaluationDependsOn
// block below (which would otherwise evaluate projects first and make
// afterEvaluate illegal).
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            (ext as com.android.build.gradle.BaseExtension)
                .compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

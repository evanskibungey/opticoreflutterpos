allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Apply to the app module specifically
    if (project.name == "app") {
        afterEvaluate {
            if (project.plugins.hasPlugin("com.android.application") || 
                project.plugins.hasPlugin("com.android.library")) {
                project.extensions.getByType<com.android.build.gradle.BaseExtension>().apply {
                    ndkVersion = "27.0.12077973"
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
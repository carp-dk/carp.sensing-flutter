allprojects {
    repositories {
        google()
        mavenCentral()
        // NOTE: The `flatDir { dirs("$rootDir/libs") }` repository and the manually
        // vendored `android/libs/mdslib-*.aar` used by the old `mdsflutter` setup
        // have been removed. As of carp_movesense_package 3.0.0 the Movesense MDS
        // `.aar` is bundled by the `carp_movesense_flutter` plugin, which exposes it
        // through its own vendored Maven repository.
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
 

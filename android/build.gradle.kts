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

// Forces every subproject (including plugin modules like screen_protector,
// which don't declare their own kotlinOptions.jvmTarget) onto the same JVM
// target :app already uses. Without this, a plugin's Kotlin compile task
// picks up whatever JVM target the Kotlin Gradle Plugin defaults to on
// this machine's JDK (21 here), while its own Java compile task -- and
// every other module -- stays on 17, and AGP refuses to link the two
// ("Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks").
subprojects {
    // tasks.withType(...).configureEach is lazy regardless of evaluation
    // state, so this half is always safe to apply directly.
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    // compileOptions, on the other hand, gets read/finalized by AGP as
    // part of evaluating the project -- the evaluationDependsOn(":app")
    // above forces :app to evaluate (and finalize it) early, so by the
    // time this block reaches :app, mutating it again throws
    // ("sourceCompatibility has been finalized"). :app already sets its
    // own compileOptions to 17 in app/build.gradle.kts anyway, so it
    // doesn't need this -- only the not-yet-evaluated plugin modules
    // (screen_protector etc., which don't set their own) do.
    if (!state.executed) {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

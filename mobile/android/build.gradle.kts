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
    val configureSubproject: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val m = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                m.invoke(android, 35)
            } catch (e: Exception) {
                try {
                    val m2 = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    m2.invoke(android, 35)
                } catch (e2: Exception) {}
            }
        }
    }

    if (state.executed) {
        configureSubproject()
    } else {
        afterEvaluate {
            configureSubproject()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

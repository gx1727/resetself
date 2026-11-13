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

// 本机 Android SDK 装有预览版 build-tools（37.0.0），AGP 8.11.1 的 lint 无法解析该版本号
// （报错 For input string: "37.0"）。这里统一下线 lint 任务，保证 release 构建可以完成。
subprojects {
    tasks.matching { it.name.contains("lint", ignoreCase = true) }.configureEach {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

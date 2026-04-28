allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

    

buildDir = file("${rootProject.projectDir}/../build")

subprojects {
    buildDir = file("${rootProject.projectDir}/../build/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
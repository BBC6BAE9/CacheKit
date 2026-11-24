plugins {
    `java-library`
    kotlin("jvm") version "2.2.21"
    kotlin("plugin.serialization") version "2.2.21"
}

group = "io.github.bbc6bae9"
version = "0.1.0"
kotlin { jvmToolchain(17) }

dependencies {
    api("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")
    testImplementation("junit:junit:4.13.2")
}

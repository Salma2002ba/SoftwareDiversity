/*
 *    Copyright 2009-2025 the original author or authors.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */
plugins {
    java
    jacoco
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

val byteBuddyVersion = "1.17.5"
val derbyVersion = "10.17.1.0"
val log4jVersion = "2.24.3"
val mockitoVersion = "5.18.0"
val mssqlJdbcVersion = "12.10.0.jre11"
val testcontainersVersion = "1.21.1"
val gitBuildHookVersion = "3.5.0"
val javaVersion = JavaVersion.VERSION_17

java {
    sourceCompatibility = javaVersion
    targetCompatibility = javaVersion
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("ognl:ognl:3.4.7")
    implementation("org.javassist:javassist:3.30.2-GA")
    implementation("cglib:cglib:3.3.0")
    implementation("ch.qos.reload4j:reload4j:1.2.26")
    implementation("commons-logging:commons-logging:1.3.5")
    implementation("org.apache.logging.log4j:log4j-api:$log4jVersion")
    implementation("org.slf4j:slf4j-api:2.0.17")

    compileOnly("com.microsoft.sqlserver:mssql-jdbc:$mssqlJdbcVersion")

    testImplementation("org.junit.jupiter:junit-jupiter-engine:5.13.0")
    testImplementation("org.junit.jupiter:junit-jupiter-params:5.13.0")
    testImplementation("org.hsqldb:hsqldb:2.7.4")
    testImplementation("org.apache.derby:derby:$derbyVersion")
    testImplementation("org.apache.derby:derbyshared:$derbyVersion")
    testImplementation("org.apache.derby:derbyoptionaltools:$derbyVersion")
    testImplementation("com.h2database:h2:2.3.232")
    testImplementation("org.mockito:mockito-core:$mockitoVersion")
    testImplementation("org.mockito:mockito-subclass:$mockitoVersion")
    testImplementation("org.mockito:mockito-junit-jupiter:$mockitoVersion")
    testImplementation("org.apache.velocity:velocity-engine-core:2.4.1")
    testImplementation("org.postgresql:postgresql:42.7.6")
    testImplementation("com.mysql:mysql-connector-j:9.3.0")
    testImplementation("com.oracle.database.jdbc:ojdbc11:23.8.0.25.04")
    testImplementation("org.assertj:assertj-core:3.27.3")
    testImplementation("net.bytebuddy:byte-buddy:$byteBuddyVersion")
    testImplementation("net.bytebuddy:byte-buddy-agent:$byteBuddyVersion")
    testImplementation("com.github.hazendaz.catch-exception:catch-exception:2.3.4")
    testImplementation("org.testcontainers:junit-jupiter:$testcontainersVersion")
    testImplementation("org.testcontainers:postgresql:$testcontainersVersion")
    testImplementation("org.testcontainers:mysql:$testcontainersVersion")
    testImplementation("org.testcontainers:oracle-free:$testcontainersVersion")
    testImplementation("ch.qos.logback:logback-classic:1.5.18")
    testImplementation("org.apache.logging.log4j:log4j-core:$log4jVersion")
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
}

tasks.test {
    useJUnitPlatform()
    maxHeapSize = "2048m"
    jvmArgs = listOf("-javaagent=${rootProject.buildDir}/libs/byte-buddy-agent-$byteBuddyVersion.jar")
    systemProperty("derby.stream.error.file", "${buildDir}/derby.log")
    systemProperty("derby.system.home", buildDir.toString())
}

tasks.withType<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar> {
    archiveClassifier.set("")
    mergeServiceFiles()
    relocate("ognl", "org.apache.ibatis.ognl")
    relocate("javassist", "org.apache.ibatis.javassist")
    exclude("META-INF/MANIFEST.MF")
}

jacoco {
    toolVersion = "0.8.11"
}

tasks.register<Exec>("installGitHook") {
    commandLine("bash", "hooks/pre-commit.sh")
}

description = "The MyBatis SQL mapper framework makes it easier to use a relational database with object-oriented applications."

if (JavaVersion.current() >= JavaVersion.VERSION_17) {
    extra["derby.version"] = "10.16.1.1"
}
if (JavaVersion.current().isCompatibleWith(JavaVersion.VERSION_19)) {
    extra["derby.version"] = "10.17.1.0"
}

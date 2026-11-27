plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


// ---- 워치 앱(wear/app-scenario)과 같은 테스트 서명 키 (루트 CLAUDE.md 규칙 1) ----
// 키가 다르면 Data Layer 통신이 조용히 실패하므로, 키를 못 찾으면 debug 키로 넘어가지 않고 빌드를 멈춘다.
// 기본 위치는 저장소의 shared/keystore/commtest.keystore 이다. 다른 폴더로 옮기면
// -PcommtestKeystore=<경로> 또는 환경 변수 COMMTEST_KEYSTORE 로 지정한다. 값의 출처: shared/keystore/README.md
val commtestKeystore: File = (providers.gradleProperty("commtestKeystore").orNull
    ?: providers.environmentVariable("COMMTEST_KEYSTORE").orNull)
    ?.let { File(it) }
    ?: rootProject.file("../../shared/keystore/commtest.keystore")
if (!commtestKeystore.isFile) {
    throw GradleException(
        "워치와 같은 서명 키를 찾지 못했습니다: ${commtestKeystore.absolutePath}\n" +
                "-PcommtestKeystore=<경로> 또는 COMMTEST_KEYSTORE 환경 변수로 지정하세요."
    )
}

android {
    namespace = "bitc.aws402.aws402_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "bitc.aws402.aws402_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("commtest") {
            storeFile = commtestKeystore
            storePassword = "seniorsafe-test"
            keyAlias = "commtest"
            keyPassword = "seniorsafe-test"
        }
    }

    buildTypes {
        // debug·release 모두 워치 앱과 같은 테스트 키로 서명한다. 테스트 전용 키이므로 실제 배포에는 쓰지 않는다.
        getByName("debug") { signingConfig = signingConfigs.getByName("commtest") }
        getByName("release") { signingConfig = signingConfigs.getByName("commtest") }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 워치와의 Data Layer 통신 (wear/WearBridge). phone/ 과 같은 버전
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.10.2")
}
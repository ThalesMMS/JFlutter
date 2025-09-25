plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin باید بعد از Android و Kotlin اضافه شود
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nfa_2_dfa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // 🔧 نسخه هماهنگ با پلاگین‌ها

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // شناسه منحصربه‌فرد اپلیکیشن
        applicationId = "com.example.nfa_2_dfa"

        // حداقل نسخه اندروید و هدف اپ
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // نسخه‌گذاری اپلیکیشن
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // فعلاً با کلید دیباگ امضا می‌شود
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// تنظیم مسیر سورس فلاتر
flutter {
    source = "../.."
}

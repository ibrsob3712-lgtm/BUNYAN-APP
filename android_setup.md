# Android Production Setup

1. Install Flutter and Android Studio.
2. Run `flutter doctor`.
3. From the project root run `flutter create .`.
4. Add the camera permission to AndroidManifest.xml.
5. For production signing, create a keystore and configure `android/key.properties`.
6. Build with `flutter build apk --release`.

The generated APK should be tested on physical Android devices before deployment.

# BUNYAN v1.3 Production Release validation

## Source-level checks completed in the current environment
- Archive extracted and source tree inspected.
- Flutter/Dart toolchain availability checked.
- Obvious source defects repaired, including missing dart:async import in bootstrap.
- Backup restore flow completed with file selection and JSON validation.
- Release documentation updated.

## Environment limitation
The current execution environment does not contain Flutter, Dart, Android SDK, Gradle, or a release keystore. Therefore an APK/AAB cannot truthfully be claimed as compiled, signed, or device-tested here.

## Required release pipeline
1. flutter create .
2. flutter pub get
3. flutter analyze
4. flutter test
5. flutter build apk --release
6. Install and test on physical Android devices.
7. Configure an owner-controlled signing key and rebuild.

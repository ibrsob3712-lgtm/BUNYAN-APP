# Building BUNYAN for Android

## 1. Generate platform files if missing
flutter create .

## 2. Install dependencies
flutter pub get

## 3. Check environment
flutter doctor

## 4. Run tests and static analysis
flutter analyze
flutter test

## 5. Run on a physical Android device
flutter run --release

## 6. Create APK
flutter build apk --release

## 7. Preferred Play Store format
flutter build appbundle --release

The signing key must be configured before distributing a production release.

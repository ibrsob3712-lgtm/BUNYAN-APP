# Android signing

This package intentionally contains no private signing key. A release key must be generated and stored securely by the application owner:

keytool -genkeypair -v -keystore bunyan-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bunyan

Do not commit the .jks file or passwords to source control. Configure the resulting key through key.properties in a real Flutter-generated Android project.

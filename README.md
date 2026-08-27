# TafMatch
A Flutter app for students to find a job and enterprises to find new employes


# Update Firebase firestore rules
To apply rules after a modification of `firestore.rules` files, run this in CMD : <br>
```
firebase deploy --only firestore:rules --project taf-match
```


# Create and run Unit test
To create a unit test, create file in `/test` folder with name like this :
```
<file_name>_test.dart
```

/!\ If the end of file is not `_test.dart`, it's not considered like unit test !

To run all unit test :
```
flutter test
```

To run specific unit test :
```
flutter test test/<path_to_the_file>/<file_name>_test.dart
```

To run with activated print, add this to the test command :
```
 --reporter=expanded
```


# Installation for Android compilation
Install Android Studio on https://developer.android.com/studio/install?hl=fr

On Android Studio > More Actions > SDK Manager > SDK Platforms : Press on Android 17.0 and "Apply"

On Android Studio > More Actions > SDK Manager > SDK Tools : Press on :
- Android SDK Build-Tools
- NDK (Side by side)
- Android SDK Command-line Tools (latest)
- CMake
- Android Emulator
- Android SDK Platform-Tools

And press "Apply"

If there are problem with the JDK (example path : `C:\Program Files\Java\jdk-21`) :<br>
```
flutter config --jdk-dir="{Full path to the JDK folder}"
```

To compile and make a .aab file, run in CMD : 
```
flutter build appbundle
```

To run on the tablet, link it to the computer, run `flutter run` and select it in options.


# Deployment
Verify you have all the requirement to deploy :
```
flutter doctor --verbose
```

Create a release Keystore :
In order to compile a release, you need a release keystore, a signature before publication :
```
keytool -genkey -v \ -keystore upload-keystore.jks \ -keyalg RSA \ -keysize 2048 \ -validity 10000 \ -alias upload
```
Keep the info in a file key.properties :
```
storePassword=YOUR_KEYSTORE_PASSWORD 
keyPassword=YOUR_KEY_PASSWORD 
keyAlias=upload 
storeFile=../upload-keystore.jks
```
and add it to .gitignore

Then to create the bundle :

```
flutter clean
flutter pub get
flutter build appbundle --release --build-number=xxx
```


Be careful to have the same package name in Google Play and in the files

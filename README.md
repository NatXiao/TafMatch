# TafMatch
A Flutter app for students to find a job and enterprises to find new employes


# Update Firebase firestore rules
To apply rules after a modification of `firestore.rules` files, run this in CMD :
`firebase deploy --only firestore:rules --project taf-match`


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
Run this in CMD : `flutter config --jdk-dir="{Full path to the JDK folder}"`

To compile and make a .aab file, run in CMD : `flutter build appbundle`

To run on the tablet, link it to the computer, run `flutter run` and select it in options.

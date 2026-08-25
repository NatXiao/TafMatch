# TafMatch
A Flutter app for students to find a job and enterprises to find new employes

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
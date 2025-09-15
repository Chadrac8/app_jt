Push Notifications integration notes

This file summarizes the platform steps required to make FCM + local notifications fully functional on Android and iOS.

Android
- Add the Firebase Android config `google-services.json` to `android/app/`.
- In `android/build.gradle` add classpath com.google.gms:google-services and apply plugin in app/build.gradle.
- Ensure `minSdkVersion` is >= 21 in `android/app/build.gradle`.
- Add the following permissions in `android/app/src/main/AndroidManifest.xml` inside <manifest>:
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.WAKE_LOCK" />
- In `AndroidManifest.xml` under <application> ensure you have the default Firebase Messaging service (typically not needed to modify).

iOS
- Add the `GoogleService-Info.plist` to `ios/Runner`.
- In Xcode, enable Push Notifications capability and Background Modes -> Remote notifications.
- In `ios/Runner/AppDelegate.swift` (Swift) or `AppDelegate.m` (Obj-C) ensure FirebaseApp.configure() is called and register for remote notifications.
- For APNs certificate/key: upload the key to Firebase Console (Project Settings -> Cloud Messaging) or configure via Apple Developer portal.

Dart / Flutter
- Call `await Firebase.initializeApp()` in `main()`.
- Then call `await PushNotificationService.initialize()` once Firebase is ready.

Example (main.dart):

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PushNotificationService.initialize();
  runApp(const MyApp());
}

Testing
- For Android: use `adb shell am broadcast -a com.google.android.c2dm.intent.RECEIVE -n <your package>/com.google.firebase.MessagingUnityPlayerReceiver --es "message" "test"` or send a test message from Firebase Console -> Cloud Messaging.
- For iOS: send a test notification from Firebase Console.

Notes
- This project uses `firebase_messaging` and `flutter_local_notifications`.
- `flutter_local_notifications` requires platform setup (channel ids, icon resources). Ensure `@mipmap/ic_launcher` exists or adjust the icon name.
- Production APNs requires proper Apple Developer setup and uploading the key/certificate to Firebase.

If you want, I can apply the Android/iOS native file edits directly (AppDelegate/Manifest) — tell me whether you prefer Swift or Obj-C AppDelegate and I will implement the necessary snippets.

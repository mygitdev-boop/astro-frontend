import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

/// Handles Firebase Cloud Messaging setup: initializing Firebase, asking
/// for notification permission, getting the device's FCM token, and
/// registering it with the backend so the daily notification batch job
/// (see notifications_batch.py) can push to this device.
///
/// SETUP STILL NEEDED (can't be done from this lib/-only repo -- these are
/// native platform files that live in your local Flutter project):
///
/// 1. Create a Firebase project at https://console.firebase.google.com
///    (or reuse one if you set up Firebase Auth elsewhere in this plan).
///
/// 2. Add an Android app in that Firebase project (package name must match
///    your app's applicationId in android/app/build.gradle).
///    Download google-services.json and place it in: android/app/
///
/// 3. In android/build.gradle (project-level, NOT android/app/build.gradle),
///    inside the buildscript { dependencies { ... } } block, add:
///      classpath 'com.google.gms:google-services:4.4.2'
///
/// 4. In android/app/build.gradle, at the very bottom of the file, add:
///      apply plugin: 'com.google.gms.google-services'
///
/// 5. For iOS: add an iOS app in the same Firebase project, download
///    GoogleService-Info.plist, and add it to ios/Runner/ via Xcode
///    (drag it into the Runner folder in Xcode, not just the file system,
///    so it gets added to the build target).
///
/// Without steps 2-4 (Android) or step 5 (iOS) done, Firebase.initializeApp()
/// below will throw -- this is caught gracefully so the rest of the app
/// still works, just without push notifications until you finish setup.
class NotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return; // FCM setup here targets Android/iOS
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      // Expected until the native platform setup above is complete --
      // fail silently so the rest of the app isn't affected.
      return;
    }
  }

  /// Call after the user is logged in (has a userId) -- requests
  /// notification permission, gets the FCM token, and registers it.
  static Future<void> requestPermissionAndRegister(int userId) async {
    if (kIsWeb || !_initialized) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // user said no -- respect that, don't nag
    }

    try {
      final token = await messaging.getToken();
      if (token != null) {
        await ApiService.registerFcmToken(userId: userId, fcmToken: token);
      }
    } catch (_) {
      // Non-critical -- app works fine without push notifications
    }
  }
}

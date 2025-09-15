import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler. Must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: initialize Firebase in real app entry before using other Firebase APIs here.
  // For background handling we keep minimal work: you can schedule work or update local storage.
  // This handler runs in its own isolate.
  // For now we simply print for debugging.
  print('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize FCM + local notifications.
  /// Call this after Firebase.initializeApp() in `main()`.
  static Future<void> initialize() async {
    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions on iOS / macOS
    if (Platform.isIOS || Platform.isMacOS) {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Android: configure local notifications channel
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _localNotifications.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle tap on notification
      // TODO: route the user to the intended page
      print('Local notification tapped: ${response.payload}');
    });

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Handle foreground messages: show a local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        // Show local notification
        final notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: DarwinNotificationDetails(),
        );

        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          notificationDetails,
          payload: message.data.isNotEmpty ? message.data.toString() : null,
        );
      }
    });
  }

  /// Gets the current FCM token for this device/app instance.
  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribes the device to a topic.
  static Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  /// Displays a local test notification (useful for admin/test flows).
  static Future<void> showTestNotification({String? title, String? body, Map<String, dynamic>? data}) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails('high_importance_channel', 'High Importance Notifications',
          channelDescription: 'Test channel', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      0,
      title ?? 'Test Notification',
      body ?? 'This is a test notification from the app',
      notificationDetails,
      payload: data != null ? data.toString() : null,
    );
  }
}

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize FCM + local notifications.
  /// Call this after Firebase.initializeApp() in `main()`.
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;
    // NOTE: the background message handler must be registered from main() as it
    // must ensure Firebase is initialized in the background isolate. Do not
    // register a background handler here to avoid conflicts; main.dart already
    // registers a handler that initializes Firebase for background isolates.

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
      // Handle tap on local notification
      print('Local notification tapped: ${response.payload}');
      if (response.payload != null) {
        try {
          final Map<String, dynamic> payloadMap = jsonDecode(response.payload!);
          _routeFromMap(payloadMap);
        } catch (e) {
          print('Could not parse local notification payload: $e');
        }
      }
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
          payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
        );
      }
    });

    // Handle taps when the app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('User tapped notification (background): ${message.data}');
      _routeFromRemoteMessage(message);
    });

    // If the app was terminated and opened by a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state by a notification: ${initialMessage.data}');
      _routeFromRemoteMessage(initialMessage);
    }
  }

  static void _routeFromRemoteMessage(RemoteMessage message) {
    try {
      final data = message.data;
      _routeFromMap(data);
    } catch (e) {
      print('Error routing from RemoteMessage: $e');
    }
  }

  static void _routeFromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return;
    final route = map['route'] as String?;
    final args = map['args'];
    if (route != null && _navigatorKey != null && _navigatorKey!.currentState != null) {
      try {
        _navigatorKey!.currentState!.pushNamed(route, arguments: args);
      } catch (e) {
        print('Error navigating to route $route: $e');
      }
    } else {
      print('No route provided in notification data or navigatorKey unavailable');
    }
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

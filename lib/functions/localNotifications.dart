// ignore: file_names
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/request.dart';
import 'package:medicare_app/screens/details.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:medicare_app/main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Local Notification Initialization
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidInitSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationClick,
    );

    // Firebase Messaging Initialization
    await _firebaseMessaging.requestPermission(announcement: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showFirebaseNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleFirebaseNotificationClick(message);
    });

    await _getInitialNotification();
    await _getFcmToken();
  }

  static void _handleNotificationClick(NotificationResponse response) {
    if (response.payload != null) {
      Navigator.of(navigatorKey.currentState!.context).push(
        MaterialPageRoute(
          builder: (context) => DetailsScreen(docId: response.payload!),
        ),
      );
    }
  }

  static void _handleFirebaseNotificationClick(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      String id = message.data[docId];

      Navigator.of(
        navigatorKey.currentState!.context,
      ).push(MaterialPageRoute(builder: (context) => DetailsScreen(docId: id)));
    }
  }

  static Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String docId,
  ) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'Scheduled Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: docId,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (e) {
      await deleteRequest(docId);
      ScaffoldMessenger.of(
        navigatorKey.currentState!.context,
      ).showSnackBar(SnackBar(content: Text("Schedule time has passed!")));
    }
  }

  static Future<void> _showFirebaseNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification == null) return;

    NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'firebase_channel',
        'Firebase Notifications',
        priority: Priority.high,
        importance: Importance.high,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentBanner: true,
        presentBadge: true,
        presentAlert: true,
      ),
    );

    await _notificationsPlugin.show(
      message.messageId.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data[docId], // Attach docId if available
    );
  }

  static Future<void> _getFcmToken() async {
    await _firebaseMessaging.getToken();
  }

  static Future<void> _getInitialNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleFirebaseNotificationClick(initialMessage);
    }
  }

  static Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {}
}

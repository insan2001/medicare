import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> _getFcmToken() async {
    await _firebaseMessaging.getToken();
  }

  static Future<void> _initializeLocalNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@drawable/ic_launcher');
    DarwinInitializationSettings initializationSettingsIOS =
        const DarwinInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("FOREGROUND NOTIFICATION");
        print('details : ${details.data}');
      },
    );
  }

  static Future<void> _showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotificationDetails android = AndroidNotificationDetails(
      'CHANNEL ID',
      'CHANNEL NAME',
      priority: Priority.high,
      importance: Importance.high,
    );
    DarwinNotificationDetails? iOS = DarwinNotificationDetails(
      presentSound: true,
      presentBanner: true,
      presentBadge: true,
      presentAlert: true,
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: android,
      iOS: iOS,
    );
    await flutterLocalNotificationsPlugin.show(
      1,
      notification?.title,
      notification?.body,
      notificationDetails,
    );
  }

  static Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
  }

  static Future<void> _getInitialNotification() async {
    await FirebaseMessaging.instance.getInitialMessage().then(
      (remoteMessage) {},
    );
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {}

  static Future<void> initializeNotification() async {
    await _firebaseMessaging.requestPermission(announcement: true);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showFlutterNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
    await _getFcmToken();
    await _initializeLocalNotification();
    await _getInitialNotification();
  }
}

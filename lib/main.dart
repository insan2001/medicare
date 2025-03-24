import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/firebase_options.dart';
import 'package:medicare_app/functions/firebase_api.dart';
import 'package:medicare_app/functions/localNotifications.dart';
import 'screens/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );
  NotificationService.initializeNotification();
  await LocalNotificationService.initialize();
  for (String topic in topics) {
    FirebaseMessaging.instance.subscribeToTopic(topic);
  }
  tz.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nurse Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

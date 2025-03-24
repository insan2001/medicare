import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medicare_app/functions/access.dart';

class FCMService {
  final String _firebaseProjectId = "medicare-e5834";
  final FirebaseAuthService _authService = FirebaseAuthService();

  Future<void> sendTopicMessage(String topic, String title, String body) async {
    final String? accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      print("Failed to get access token.");
      return;
    }

    final String url =
        "https://fcm.googleapis.com/v1/projects/$_firebaseProjectId/messages:send";

    final Map<String, dynamic> payload = {
      "message": {
        "topic": topic,
        "notification": {"title": title, "body": body},
      },
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully: ${response.body}");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/access.dart';

class FCMService {
  final String _firebaseProjectId = "medicare-e5834";
  final FirebaseAuthService _authService = FirebaseAuthService();

  Future<void> sendTopicMessage(
    String topic,
    String title,
    String body,
    String message,
  ) async {
    final String accessToken = await _authService.getAccessToken();

    final String url =
        "https://fcm.googleapis.com/v1/projects/$_firebaseProjectId/messages:send";

    final Map<String, dynamic> payload = {
      "message": {
        "topic": topic,
        "notification": {"title": title, "body": body},
        'data': {docId: message},
      },
    };

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );
  }
}

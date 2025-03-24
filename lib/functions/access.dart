import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class FirebaseAuthService {
  static const String _scope =
      'https://www.googleapis.com/auth/firebase.messaging';

  Future<String> getAccessToken() async {
    String jsonString = await rootBundle.loadString('assets/msg.json');
    final serviceAccount = jsonDecode(jsonString);

    final accountCredentials = ServiceAccountCredentials.fromJson(
      serviceAccount,
    );
    final client = await clientViaServiceAccount(accountCredentials, [_scope]);

    return client.credentials.accessToken.data;
  }
}

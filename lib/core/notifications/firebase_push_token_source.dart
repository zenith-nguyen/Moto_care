import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/app_config.dart';
import 'push_token_source.dart';

class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource._(this._messaging);

  final FirebaseMessaging _messaging;

  static Future<PushTokenSource> initialize(AppConfig config) async {
    if (!config.pushNotificationsEnabled) {
      return const DisabledPushTokenSource();
    }
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config.firebaseApiKey,
        appId: config.firebaseAppId,
        messagingSenderId: config.firebaseMessagingSenderId,
        projectId: config.firebaseProjectId,
      ),
    );
    return FirebasePushTokenSource._(FirebaseMessaging.instance);
  }

  @override
  bool get enabled => true;

  @override
  Stream<String> get tokenChanges => _messaging.onTokenRefresh;

  @override
  Future<String?> requestToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }
    return _messaging.getToken();
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();
}

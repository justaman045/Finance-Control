import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'package:money_control/Screens/homescreen.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Ask user permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    if (settings.authorizationStatus ==
        AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      // Save FCM token tied to user
      await _saveTokenToFirestore();

      // Handle notification when app opened from terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle notification when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // (Optional) Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        // Let OS show the notification via FCM "notification" payload.
        // You could also show a Snackbar if you like.
      });
    }
  }

  static Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final tokensRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.email)
        .collection('tokens')
        .doc(token);

    await tokensRef.set({
      'token': token,
      'platform': Platform.operatingSystem,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static void _handleMessage(RemoteMessage message) {
    // We send "screen: home" from Cloud Function
    final target = message.data['screen'];

    if (target == 'home') {
      Get.offAll(() => const BankingHomeScreen());
    }
  }
}

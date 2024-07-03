import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NotificationServices {
  static String serverKey =
      'AAAAS1d1QzM:APA91bHvBdYCJKHxno9hGIUfgP9sMfdjD39jaWfmll0_v_RUdUSPtyT_TuSlTtjhNEOoLrAQUt-jJMgbTzvwRv7QNSzRH9thLhTITa5gY8zAEmQ_GKxQ2833os_4FP8VHz9-co18v7Wy';

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void initLocalNotifications(
      BuildContext context, RemoteMessage message) async {
    var androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSetting = InitializationSettings(
      android: androidInitializationSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSetting,
        onDidReceiveNotificationResponse: (payload) {
      handleMessage(context, message);
    });
  }

  static Future<void> sendNotification({
    String? title,
    String? message,
    String? token,
  }) async {
    try {
      http.Response r = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{'body': message, 'title': title},
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'message': message, // Include the location link in data
            },
            'to': token,
          },
        ),
      );

      print(r.body);
      if (r.statusCode == 200) {
        print('Push notification sent successfully.');
      } else {
        print('Failed to send push notification. Status code: ${r.statusCode}');
      }
    } catch (e) {
      print('Exception while sending push notification: $e');
    }
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title.toString());
        print(message.notification!.body.toString());
        print(message.data.toString());
        print(message.data['type']);
        print(message.data['id']);
      }
      initLocalNotifications(context, message);
      showNotification(message);
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
        Random.secure().nextInt(100000).toString(),
        'High Importance Notification',
        importance: Importance.max);

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            channel.id.toString(), channel.name.toString(),
            channelDescription: 'your channel description',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker');

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title.toString(),
          message.notification!.body.toString(),
          notificationDetails);
    });
  }

  Future<String> getDeviceToken() async {
    try {
      String? token = await messaging.getToken();
      // Save the FCM token to Firestore
      saveFCMTokenToFirestore(token);
      return token ?? '';
    } catch (e) {
      print('Error getting device token: $e');
      return '';
    }
  }

  void isTokenRefresh() async {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
      print('Token refreshed');
      // Save the refreshed FCM token to Firestore
      saveFCMTokenToFirestore(event);
    });
  }

  Future<void> saveFCMTokenToFirestore(String? token) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Update or set the FCM token in the users collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));

        print('FCM token saved to Firestore: $token');
      } else {
        print('Current user is null. FCM token not saved.');
      }
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');
    }
  }

  //when app is terminated
  Future<void> setupInteractMessage(BuildContext context) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      handleMessage(context, initialMessage);
    }

    //when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(context, event);
    });
  }

  Future<void> handleMessage(
      BuildContext context, RemoteMessage message) async {
    if (message.data['type'] == 'location') {
      String locationLinkw = message.data['locationLink'] ?? '';
      if (locationLinkw.isNotEmpty) {
        // Open the location link
        // Note: You may use a package like url_launcher to open the link in a browser
        await launch(locationLinkw);
        print('Opening location link: $locationLinkw');
      } else {
        print('Location link not available');
      }
    }
  }
}

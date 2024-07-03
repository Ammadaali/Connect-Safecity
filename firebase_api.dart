import 'package:connect_safecity/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Future<void> handleBackgroundMessage(RemoteMessage message) async {
//   print('Title:${message.notification?.title}');
//   print('Body:${message.notification?.body}');
//   print('Payload:${message.data}');
// }

class FirebaseApi {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FirebaseApi._(); // Private constructor

  static final FirebaseApi _instance = FirebaseApi._();

  factory FirebaseApi() {
    return _instance;
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> initNotifications() async {
    try {
      await _messaging.requestPermission();
      String? token = await _messaging.getToken();
      print("FCM Token: $token");
      //initNotifications();
      //FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

      onTokenRefresh.listen((newToken) async {
        print("FCM Token Refreshed: $newToken");
        await storeOrUpdateFCMToken(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Received message: ${message.notification?.body}");
        // Handle the incoming message
      });
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> storeOrUpdateFCMToken(String newToken) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Check if the user's document exists
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(uid);

        final userData = await userDocRef.get();

        if (!userData.exists) {
          // If the user's document doesn't exist, create a new one
          await userDocRef.set({'fcmToken': newToken});
        } else {
          // If the user's document already exists, update the FCM token
          await userDocRef.update({'fcmToken': newToken});
        }
      }
    } catch (e) {
      print("Error storing/updating FCM token: $e");
    }
  }

  // void handleMessage(RemoteMessage? message) {
  //   navigatorKey.currentState?.pushNamed(
  //     '/notification_screen',
  //     arguments: message,
  //   );
  // }

  // Future initPushNotifications() async {
  //   FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

  //   FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  // }
}

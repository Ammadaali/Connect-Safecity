import 'dart:convert';
import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:connect_safecity/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class TcontactsToSendSMS extends StatefulWidget {
  final List<Map<String, dynamic>> contactList;

  TcontactsToSendSMS({required this.contactList});

  @override
  _TcontactsToSendSMSState createState() => _TcontactsToSendSMSState();
}

class _TcontactsToSendSMSState extends State<TcontactsToSendSMS> {
  NotificationServices notificationServices = NotificationServices();
  Position? _currentPosition;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchCurrentUserName();
    notificationServices.setupInteractMessage(context);
    notificationServices.firebaseInit(context);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Share Your Location',
      body: ListView.builder(
        itemCount: widget.contactList.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(widget.contactList[index]['contactName'] ?? ''),
              subtitle: Text(widget.contactList[index]['contactPhone'] ?? ''),
              onTap: () async {
                await _sendLocation(widget.contactList[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendLocation(Map<String, dynamic> contact) async {
    // Ensure location permission is granted before proceeding
    await _getCurrentLocation();

    // Assuming you are using Firebase Authentication
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('Current user not authenticated');
      return;
    }

    String phoneNumber = contact['contactPhone'] ?? '';

    // Remove non-numeric characters
    String numericPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Extract the last 10 digits
    String last10Digits = numericPhoneNumber.length >= 10
        ? numericPhoneNumber.substring(numericPhoneNumber.length - 10)
        : numericPhoneNumber;

    // Prepend "+92" to the last 10 digits
    String modifiedPhoneNumber = '+92$last10Digits';

    // Print modified phone number
    print('Modified phone number: $modifiedPhoneNumber');

    String locationLink = _getLocationLink();
    String message = 'Please Check! My location: $locationLink';

    // Check if the selected contact's phone number exists in the users collection
    bool contactExists = await _checkContactExists(modifiedPhoneNumber);

    // Send SMS logic...
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      query: 'body=${Uri.encodeFull(message)}',
    );

    await launchUrl(launchUri);

    if (contactExists) {
      // Notify the user with the matching phone number
      await _notifyUser(modifiedPhoneNumber, locationLink);
    }
  }

  Future<void> _fetchCurrentUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      setState(() {
        _currentUserName = userDoc.data()?['name'];
      });
    }
  }

  Future<void> _checkAndSendNotification(
      String phoneNumber, String locationLink) async {
    try {
      // Log the modified phone number
      print('Checking for phone number in Firestore: $phoneNumber');

      // Check if there is a user with matching phone number in Firestore
      QuerySnapshot<Map<String, dynamic>> users = await FirebaseFirestore
          .instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .get();

      // Log the number of matching users found
      print('Number of matching users found: ${users.docs.length}');

      if (users.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> user in users.docs) {
          String fcmToken = user['fcmToken'];
          var data = {
            'to': fcmToken,
            'priority': 'high',
            'notification': {
              'title': 'Alert',
              'body': '$_currentUserName has sent you the live location',
            },
            'data': {
              'type': 'location',
              'locationLink': locationLink,
            }
          };
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              body: jsonEncode(data),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization':
                    'key=AAAAS1d1QzM:APA91bHvBdYCJKHxno9hGIUfgP9sMfdjD39jaWfmll0_v_RUdUSPtyT_TuSlTtjhNEOoLrAQUt-jJMgbTzvwRv7QNSzRH9thLhTITa5gY8zAEmQ_GKxQ2833os_4FP8VHz9-co18v7Wy',
              });
        }
      } else {
        print('No matching users found.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<bool> _checkContactExists(String phoneNumber) async {
    // Log the phone number being checked
    print('Checking if phone number exists in Firestore: $phoneNumber');

    // Check if the phone number exists in the users collection
    QuerySnapshot<Map<String, dynamic>> users = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .get();

    // Log the number of matching users found
    print('Number of users with this phone number: ${users.docs.length}');

    return users.docs.isNotEmpty;
  }

  Future<void> _notifyUser(String phoneNumber, String locationLink) async {
    await _checkAndSendNotification(phoneNumber, locationLink);
  }

  Future<void> _getCurrentLocation() async {
    bool permissionGranted = await _requestLocationPermission();
    while (!permissionGranted) {
      permissionGranted = await _requestLocationPermission();
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }
    return true;
  }

  String _getLocationLink() {
    if (_currentPosition != null) {
      return 'https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    } else {
      return 'Location not available';
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect SafeCity',
      home: TcontactsToSendSMS(contactList: []),
    );
  }
}

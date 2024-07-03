import 'dart:math';
import 'package:connect_safecity/notification_service.dart';
import 'package:connect_safecity/user/Community/CommunityFeed.dart';
import 'package:connect_safecity/user/TcontactsToSendSMS.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/admin/ImageSlider.dart';
import 'package:connect_safecity/user/drawer.dart';
import 'package:connect_safecity/user/Chats/allChats_Page.dart';
import 'package:connect_safecity/user/Trusted_Contacts.dart';
import 'package:connect_safecity/user/Emergencies/emergency.dart';
import 'package:connect_safecity/user/Station&Location/BusSta&Location.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:location/location.dart'
    as locationPlugin; // Renamed location to locationPlugin
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db/share_pref.dart';

class User_Dashboard extends StatefulWidget {
  const User_Dashboard({Key? key}) : super(key: key);

  @override
  State<User_Dashboard> createState() => _User_DashboardState();
}

class _User_DashboardState extends State<User_Dashboard> {
  bool isMockLocationDetected = false;
  NotificationServices notificationServices = NotificationServices();
  final CollectionReference imagesRef =
      FirebaseFirestore.instance.collection('images');
  int qIndex = 0;
  bool allowLogout = false;
  List<Map<String, dynamic>> contactList = [];
  late GlobalKey<State<StatefulWidget>> dialogKey;
  late locationPlugin.Location location;
  late permission.PermissionStatus locationPermissionStatus;

  getRandomQuote() {
    Random random = Random();
    setState(() {
      qIndex = random.nextInt(6);
    });
  }

  @override
  void initState() {
    super.initState();
    location = locationPlugin.Location();
    dialogKey = GlobalKey<State>();
    getRandomQuote();
    notificationServices.firebaseInit(context);
    notificationServices.getDeviceToken().then((value) {
      print('device token');
      print(value);
    });
    notificationServices.setupInteractMessage(context);
    // Request location permission when the dashboard is initialized
    requestLocationPermission();
    notificationMicrophonePermission();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? loginTypeText;
      bool? isDialogShown = await MySharedPrefference.getPreferencesBool(
          MySharedPrefference.isLoginDialogShown);
      String? loginType = await MySharedPrefference.getPreferencesString(
          MySharedPrefference.loginType);
      if (loginType == "Normal") {
        loginTypeText = '';
      } else {
        loginTypeText = "via $loginType";
      }
      if (isDialogShown == false) {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Login Success'),
              content: Text('You have Successfully SignIn $loginTypeText'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await MySharedPrefference.setPreferencesBool(
                        MySharedPrefference.isLoginDialogShown, true);
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Future<void> requestLocationPermission() async {
    locationPermissionStatus = await permission.Permission.location.request();
    if (locationPermissionStatus.isGranted) {
      // Location permission is granted, check for mock location
      checkMockLocation();
    } else {
      // Location permission is denied or permanently denied
      if (locationPermissionStatus.isPermanentlyDenied) {
        // Permission is permanently denied, show message and open app settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please give location permission in app settings.'),
            action: SnackBarAction(
              label: 'SETTINGS',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      } else {
        // Location permission is denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please give location permission.'),
          ),
        );
      }
    }
  }

  Future<void> notificationMicrophonePermission() async {
    var status = await Permission.notification.request();
    if (!status.isGranted) {
      // You can show an additional message or take appropriate action
      Fluttertoast.showToast(msg: 'Notification permission denied.');
    }
  }

  Future<void> checkMockLocation() async {
    try {
      Location location = Location();
      LocationData currentLocation = await location.getLocation();
      print('Mock location accuracy: ${currentLocation.accuracy}');
      if (currentLocation.isMock ?? false || currentLocation.accuracy! > 200) {
        setState(() {
          isMockLocationDetected = true;
        });
        showMockLocationAlert();
      }
    } catch (e) {
      print('Error checking mock location: $e');
    }
  }

  void showMockLocationAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on tap outside
      builder: (context) => AlertDialog(
        key: dialogKey,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text(
              'Mock Location Detected',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ],
        ),
        content: Text('Please turn off mock location to use this app.'),
        actions: [
          TextButton(
            onPressed: () {
              // Close the app when OK is pressed
              SystemNavigator.pop();
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showLoggedInMessage() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userSnapshot.exists) {
        String username = userSnapshot['username'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are logged in as $username'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Child Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Color.fromARGB(255, 39, 59, 122),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        drawer: MyDrawer(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ImageSlider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Emergency Dial Ups",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Emergency(),
                      SizedBox(
                        height: 30,
                      ),
                      busSta_Location(),
                      SizedBox(
                        height: 30,
                      ),
                      communityFeed(),
                      // Add your other widgets here
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          height: 65,
          child: BottomAppBar(
            color: Color(0xFFDDE6EE),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.home, color: Colors.black, size: 29),
                  onPressed: () {
                    // Add functionality for home button
                  },
                ),
                IconButton(
                  icon: Icon(Icons.message, color: Colors.black, size: 29),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => allChatsPage()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.location_on, color: Colors.black, size: 29),
                  onPressed: () async {
                    // Fetch trusted contacts before navigating to TcontactsToSendSMS
                    List<Map<String, dynamic>>? fetchedContacts =
                        await fetchTrustedContacts();
                    if (fetchedContacts != null && fetchedContacts.isNotEmpty) {
                      setState(() {
                        contactList = fetchedContacts;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TcontactsToSendSMS(
                            contactList: contactList,
                          ),
                        ),
                      );
                    } else {
                      // Show a message that no trusted contacts are available
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please add trusted contacts first.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.group, color: Colors.black, size: 29),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TrustedContactsPage()),
                    );
                    // Add functionality for group chat button
                  },
                ),
                // IconButton(
                //   icon:
                //       Icon(Icons.notification_add, color: Colors.black, size: 29),
                //   onPressed: () {
                //     notificationServices.getDeviceToken().then((value) async {
                //       var data = {
                //         'to': value.toString(),
                //         'priority': 'high',
                //         'notification': {
                //           'title': 'Ammad',
                //           'body': 'Say hello',
                //         },
                //         'data': {
                //           'type': 'location',
                //           'id': 'amamd123',
                //         }
                //       };
                //       await http.post(
                //           Uri.parse('https://fcm.googleapis.com/fcm/send'),
                //           body: jsonEncode(data),
                //           headers: {
                //             'Content-Type': 'application/json; charset=UTF-8',
                //             'Authorization':
                //                 'key=AAAAS1d1QzM:APA91bHvBdYCJKHxno9hGIUfgP9sMfdjD39jaWfmll0_v_RUdUSPtyT_TuSlTtjhNEOoLrAQUt-jJMgbTzvwRv7QNSzRH9thLhTITa5gY8zAEmQ_GKxQ2833os_4FP8VHz9-co18v7Wy',
                //           });
                //     });
                //     // Add functionality for group chat button
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>?> fetchTrustedContacts() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // User is not authenticated
        return null;
      }

      // Fetch the trusted contacts document for the current user
      DocumentSnapshot trustedContactsSnapshot = await FirebaseFirestore
          .instance
          .collection('TrustedContacts')
          .doc(currentUser.uid)
          .get();

      if (trustedContactsSnapshot.exists) {
        // Extract the list of trusted contacts
        List<Map<String, dynamic>> trustedContacts =
            List<Map<String, dynamic>>.from(
                trustedContactsSnapshot['Tcontacts'] ?? []);

        if (trustedContacts.isNotEmpty) {
          // Return the list of trusted contacts
          return trustedContacts;
        } else {
          // No trusted contacts available for the current user
          return [];
        }
      } else {
        // Trusted contacts document doesn't exist for the current user
        return [];
      }
    } catch (e) {
      // Handle any potential errors
      print('Error fetching trusted contacts: $e');
      return null;
    }
  }
}

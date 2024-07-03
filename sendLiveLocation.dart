import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:location/location.dart'
    as locationPlugin; // Renamed location to locationPlugin
import 'package:geolocator/geolocator.dart' as geo;

class sendLiveLocation extends StatefulWidget {
  const sendLiveLocation({Key? key}) : super(key: key);

  @override
  _sendLiveLocationState createState() => _sendLiveLocationState();
}

class _sendLiveLocationState extends State<sendLiveLocation> {
  bool isMockLocationDetected = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isSharingLocation = false;
  late permission.PermissionStatus locationPermissionStatus;
  late GlobalKey<State<StatefulWidget>> dialogKey;
  late locationPlugin.Location location;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetchLocationStatus();
    location = locationPlugin.Location();
    requestLocationPermission();
  }

  Future<void> _fetchLocationStatus() async {
    try {
      String userId = getCurrentUserId();
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      bool currentLocationStatus = await _getCurrentLocationStatus(userRef);

      setState(() {
        isSharingLocation = currentLocationStatus;
      });
    } catch (e) {
      print('Error fetching location status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to fetch location status'),
          duration: Duration(seconds: 1),
        ),
      );
    }
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
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Location permission is denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please give location permission.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _updateLocationStatus(bool status) async {
    try {
      String userId = getCurrentUserId();
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      await userRef.update({'liveLocation': status});

      // Fetch the updated location status
      await _fetchLocationStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location sharing ${status ? 'started' : 'stopped'} successfully'),
          duration: Duration(seconds: 1),
        ),
      );

      if (status) {
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();
      }
    } catch (e) {
      print('Error updating location status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update location status'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<bool> _checkLocationPermission() async {
    // Check if location permission is granted
    locationPermissionStatus = await permission.Permission.location.status;
    return locationPermissionStatus.isGranted;
  }

  Future<bool> _getCurrentLocationStatus(DocumentReference userRef) async {
    DocumentSnapshot userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('liveLocation')) {
        return userData['liveLocation'] ?? false;
      }
    }

    return false;
  }

  String getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  void _startLocationUpdates() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateUserLocation();
    });
  }

  void _stopLocationUpdates() {
    // Cancel the timer when location sharing is stopped
    // This prevents unnecessary location updates when not sharing
    timer?.cancel();
  }

  void _updateUserLocation() async {
    try {
      // Check if location sharing is still active
      if (!isSharingLocation) {
        // If sharing is stopped, cancel the timer
        timer?.cancel();
        return;
      }

      // Fetch the current user's document reference
      String userId = getCurrentUserId();
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      // Fetch the current location status from Firestore
      bool currentLocationStatus = await _getCurrentLocationStatus(userRef);

      // Check if the location sharing is still active in the database
      if (!currentLocationStatus) {
        // If sharing is stopped in the database, cancel the timer
        timer?.cancel();
        return;
      }

      // If location sharing is still active, update the location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high);

      // Update 'longi' and 'lati' fields with the current location
      await userRef.update({
        'longi': position.longitude,
        'lati': position.latitude,
      });

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating user location: $e');
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
      } else {
        _updateLocationStatus(true);
      }
    } catch (e) {
      print('Error checking mock location: $e');
    }
  }

  void showMockLocationAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              Navigator.pop(context); // Close the alert dialog
              SystemNavigator.pop(); // Close the app
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Live Location",
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                checkMockLocation();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isSharingLocation
                    ? Colors.green
                    : const Color.fromARGB(255, 166, 213, 251),
              ),
              child: const Text(
                'Start Sharing Location',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _updateLocationStatus(false);
                _stopLocationUpdates();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: !isSharingLocation
                    ? Colors.red
                    : const Color.fromARGB(255, 166, 213, 251),
              ),
              child: const Text(
                'Stop Sharing Location',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Location is ${isSharingLocation ? 'sharing' : 'not sharing'}',
              style: TextStyle(
                color: isSharingLocation ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

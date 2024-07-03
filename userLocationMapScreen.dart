import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class userLocationMapScreen extends StatefulWidget {
  final String childUserId;

  userLocationMapScreen({required this.childUserId});

  @override
  _userLocationMapScreenState createState() => _userLocationMapScreenState();
}

class _userLocationMapScreenState extends State<userLocationMapScreen> {
  late Stream<DocumentSnapshot> _locationStream;
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(0.0, 0.0); // Default location
  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _locationStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.childUserId)
        .snapshots();
    _loadCustomIcon();
  }

  // Helper method to load custom icon
  void _loadCustomIcon() async {
    try {
      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)), // Adjust size as needed
        'assets/images/usericon2.png',
      );
      setState(() {
        _customIcon = customIcon;
      });
    } catch (e) {
      print('Error loading custom icon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Child Location'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _locationStream,
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return Center(child: Text('Location data not available'));
          }

          var locationData = snapshot.data!.data()!;

          if (locationData is Map<String, dynamic> &&
              locationData.containsKey('lati') &&
              locationData.containsKey('longi')) {
            double latitude = locationData['lati'] as double;
            double longitude = locationData['longi'] as double;
            _currentLocation = LatLng(latitude, longitude);

            // Animate the map to the updated location if map controller is initialized
            _animateToLocation(_currentLocation);
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15.0,
            ),
            markers: {
              if (_customIcon != null)
                Marker(
                  markerId: MarkerId('userLocation'),
                  position: _currentLocation,
                  icon: _customIcon!,
                )
              else
                Marker(
                  markerId: MarkerId('userLocation'),
                  position: _currentLocation,
                  icon: BitmapDescriptor.defaultMarker,
                ),
            },
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
          );
        },
      ),
    );
  }

  // Helper method to animate map camera to a specified location
  void _animateToLocation(LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(location),
      );
    }
  }
}

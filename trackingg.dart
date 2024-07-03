import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const LiveLocationMap({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('live_location_marker'),
            position: LatLng(latitude, longitude),
          ),
        },
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class FireBrigadeStation {
  final String name;
  final double latitude;
  final double longitude;
  final String contactNumber;

  FireBrigadeStation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.contactNumber,
  });

  factory FireBrigadeStation.fromJson(Map<String, dynamic> json) {
    return FireBrigadeStation(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      contactNumber: json['contact_number'],
    );
  }
}

class fireBrigadeEmergency extends StatefulWidget {
  @override
  _FireBrigadeEmergencyState createState() => _FireBrigadeEmergencyState();
}

class _FireBrigadeEmergencyState extends State<fireBrigadeEmergency> {
  bool _isLoading = false;

  Future<List<FireBrigadeStation>> _loadFireBrigadeStations() async {
    final String response =
        await rootBundle.loadString('assets/firebrigade_stations.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => FireBrigadeStation.fromJson(json)).toList();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Pi/180
    const double Function(num) c = cos;
    final double a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> _callNearestFireBrigadeStation(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool permissionGranted = await _checkAndRequestPermission(context);
      if (!permissionGranted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await _determinePosition();
      List<FireBrigadeStation> fireBrigadeStations =
          await _loadFireBrigadeStations();
      FireBrigadeStation? nearestStation =
          _findNearestFireBrigadeStation(position, fireBrigadeStations);

      setState(() {
        _isLoading = false;
      });

      if (nearestStation != null) {
        _showConfirmationDialog(context, nearestStation);
      } else {
        print('No fire brigade station found.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fire brigade station found.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkAndRequestPermission(BuildContext context) async {
    PermissionStatus status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location permission is required to call the nearest fire brigade station.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, FireBrigadeStation station) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Call'),
          content: Text('Do you want to call ${station.name}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Call'),
              onPressed: () async {
                Navigator.of(context).pop();
                await FlutterPhoneDirectCaller.callNumber(
                    station.contactNumber);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Position> _determinePosition() async {
    return await Geolocator.getCurrentPosition();
  }

  FireBrigadeStation? _findNearestFireBrigadeStation(
      Position position, List<FireBrigadeStation> fireBrigadeStations) {
    FireBrigadeStation? nearestStation;
    double minDistance = double.infinity;

    for (FireBrigadeStation station in fireBrigadeStations) {
      double distance = _calculateDistance(position.latitude,
          position.longitude, station.latitude, station.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearestStation = station;
      }
    }
    return nearestStation;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 5),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => _callNearestFireBrigadeStation(context),
          child: Container(
            height: 180,
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF273b7a),
                  Color(0xFFFdde6ee),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/flame.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fire Brigade',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                  ),
                                ),
                                Text(
                                  'In case of fire emergency call',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  height: 35,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 0),
                                      child: Text(
                                        '0 -1 -6',
                                        style: TextStyle(
                                          color: Colors.red[300],
                                          fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.055,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Fire Brigade Emergency')),
      body: fireBrigadeEmergency(),
    ),
  ));
}
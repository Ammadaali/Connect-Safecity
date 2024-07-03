import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/user/TcontactsToSendSMS.dart';
import 'package:connect_safecity/user/shareLocation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class busSta_Location extends StatefulWidget {
  @override
  State<busSta_Location> createState() => _busSta_LocationState();
}

class _busSta_LocationState extends State<busSta_Location> {
  bool isBottomSheetVisible = false;
  Position? _currentPosition;
  String? link;
  List<Map<String, dynamic>>? contactList;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () {
                _launchBusStationsMap();
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Color.fromARGB(255, 216, 236, 255),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Bus Stations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      height: 150,
                      width: double.infinity,
                      child: Center(
                        child: Image.asset(
                          'assets/images/busstop.png',
                          height: 100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => shareLocation()),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Color.fromARGB(255, 216, 236, 255),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Send Location',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      height: 150,
                      width: double.infinity,
                      child: Center(
                        child: Image.asset(
                          'assets/images/sendlocation.png',
                          height: 100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  // Function to open the URL in the browser for Bus Stations
  _launchBusStationsMap() async {
    const url =
        'https://www.google.com/maps/search/local+bus+stops+near+me+within+2km';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      link =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print(e);
      setState(() {
        _currentPosition = null;
      });
    }
  }
}

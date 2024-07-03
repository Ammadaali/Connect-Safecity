import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect_safecity/user/TcontactsToSendSMS.dart';
import 'package:connect_safecity/user/sendLiveLocation.dart';

class shareLocation extends StatefulWidget {
  @override
  State<shareLocation> createState() => shareLocationState();
}

class shareLocationState extends State<shareLocation> {
  List<Map<String, dynamic>>? contactList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Share Location', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildCard(
              'assets/images/currentLocation.png',
              'Send Current Location',
              () async {
                // Fetch trusted contacts before navigating to TcontactsToSendSMS
                contactList = await fetchTrustedContacts();
                if (contactList != null && contactList!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TcontactsToSendSMS(
                        contactList: contactList!,
                      ),
                    ),
                  );
                } else {
                  // Show a message that no trusted contacts are available or user's field is missing
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
            SizedBox(height: 16),
            buildCard(
              'assets/images/liveLocation.png',
              'Send Live Location',
              () {
                // Navigate to sendLiveLocation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => sendLiveLocation(),
                  ),
                );
              },
            ),
          ],
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

  Widget buildCard(String imagePath, String heading, VoidCallback onTap) {
    return Card(
      color: Color.fromARGB(255, 220, 243, 254),
      elevation: 5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 100, width: 120),
              SizedBox(height: 8),
              Text(
                heading,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

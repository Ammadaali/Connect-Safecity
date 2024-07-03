import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyProfile extends StatefulWidget {
  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? name;
  String? guardiantEmail;
  String? phone;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          setState(() {
            name = userData['name'];
            guardiantEmail = userData['guardiantEmail'];
            phone = userData['phone'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'My Profile',
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 30,
            ),
            Icon(
              Icons.person,
              size: 150,
              color: Colors.blue,
            ),
            Text(
              currentUser.email!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(
              height: 30,
            ),
            buildProfileItem('Name:', name),
            buildProfileItem('Guardian Email:', guardiantEmail),
            buildProfileItem('Phone:', phone),
            SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.all(9.0),
      child: Container(
        padding: const EdgeInsets.only(left: 50, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Color(0xFFDDE6EE),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? 'Not provided',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

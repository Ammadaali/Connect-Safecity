import 'package:connect_safecity/guardian/guardian.editprofile.dart';
import 'package:connect_safecity/guardian/guardians.MyProfile.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuardianDrawer extends StatefulWidget {
  const GuardianDrawer({Key? key});

  @override
  State<GuardianDrawer> createState() => _GuardianDrawer();
}

class _GuardianDrawer extends State<GuardianDrawer> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      // Adjust the width as needed
      child: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  iconSize: 40,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 50),
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
            SizedBox(height: 60),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text("Profile"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Guardian_MyProfile(),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Edit Profile"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Guardian_EditProfile(),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => UserLoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

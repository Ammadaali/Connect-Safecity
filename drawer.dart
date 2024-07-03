import 'package:flutter/material.dart';
import 'package:connect_safecity/user/voiceChat.dart';
import 'package:connect_safecity/user/Trusted_Contacts.dart';
import 'package:connect_safecity/user/editprofile.dart';
import 'package:connect_safecity/user/myprofile.dart';
import 'package:connect_safecity/user/user_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key});

  @override
  State<MyDrawer> createState() => _MyDrawer();
}

class _MyDrawer extends State<MyDrawer> {
  // User
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Set the width of the drawer
      width: MediaQuery.of(context).size.width * 0.85,
      // Set the background color of the drawer to white
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
                  // Close the drawer
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(
            height: 50,
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
            height: 60,
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text("Profile"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => MyProfile(),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("Edit Profile"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditProfile(),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.contacts),
            title: Text("Trusted Contacts"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => TrustedContactsPage(),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text("Dashboard"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => User_Dashboard(),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: () {
              // Sign out the user
              FirebaseAuth.instance.signOut();

              // Navigate to the login screen and remove the drawer route
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => UserLoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/admin/admin_dasboard.dart';
import 'package:connect_safecity/guardian/guardian_dashboard.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:connect_safecity/user/user_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashServices {
  void isLogin(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then(
        (DocumentSnapshot documentSnapshot) {
          if (documentSnapshot.exists) {
            bool isDeleted = documentSnapshot.get('isDeleted') ?? false;
            if (isDeleted) {
              // User is deleted, show message and navigate to login screen
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Access Denied'),
                  content: Text('You are not allowed to login.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        FirebaseAuth.instance.signOut(); // Sign out the user
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
              // Navigate to the login screen
              Timer(
                const Duration(seconds: 3),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserLoginScreen()),
                ),
              );
            } else {
              // User is not deleted, proceed based on user type
              String userType = documentSnapshot.get('type');
              if (userType == 'child') {
                Timer(
                  const Duration(seconds: 3),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => User_Dashboard()),
                  ),
                );
              } else if (userType == 'guardian') {
                Timer(
                  const Duration(seconds: 3),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GuardianDashboard()),
                  ),
                );
              } else if (userType == 'admin') {
                Timer(
                  const Duration(seconds: 3),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Admin_Dashboard()),
                  ),
                );
              }
            }
          } else {
            // User document doesn't exist, navigate to login screen
            Timer(
              const Duration(seconds: 3),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserLoginScreen()),
              ),
            );
          }
        },
      );
    } else {
      // No user signed in, navigate to login screen
      Timer(
        const Duration(seconds: 3),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserLoginScreen()),
        ),
      );
    }
  }
}

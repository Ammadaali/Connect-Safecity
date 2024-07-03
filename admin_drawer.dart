import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        body: ListView(
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
              "Admin",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(
              height: 60,
            ),
            ListTile(
              leading: Icon(Icons.vpn_key), // Icon for password reset
              title: Text("Reset Password"),
              onTap: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Reset Password"),
                      content: Text("Do you want to reset your password?"),
                      actions: [
                        TextButton(
                          child: Text("No"),
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                          },
                        ),
                        TextButton(
                          child: Text("Yes"),
                          onPressed: () {
                            // Reset password and notify user
                            String? userEmail =
                                FirebaseAuth.instance.currentUser?.email;
                            if (userEmail != null) {
                              FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: userEmail);
                              Navigator.pop(context); // Close dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Password Reset"),
                                    content: Text(
                                        "Password reset link sent to your email."),
                                    actions: [
                                      TextButton(
                                        child: Text("OK"),
                                        onPressed: () {
                                          Navigator.pop(
                                              context); // Close dialog
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
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
      ),
    );
  }
}

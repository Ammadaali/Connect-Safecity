import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connect_safecity/user/EducationalGroup/EduGroupChatScreen.dart';

class EducationalGroupTab extends StatefulWidget {
  @override
  _EducationalGroupTabState createState() => _EducationalGroupTabState();
}

class _EducationalGroupTabState extends State<EducationalGroupTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          child: FutureBuilder<bool>(
            future: _isUserInEducationalGroup(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a smaller blue round loader
                return SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              } else if (snapshot.hasError) {
                // Handle errors
                return Text("Error: ${snapshot.error}");
              } else {
                // Show the UI based on whether the user is in the group or not
                return _buildGroupUI(snapshot.data == true, context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGroupUI(bool isInGroup, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Color(0xFFDDE6EE),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              SizedBox(height: 20.0),
              Image.asset(
                'assets/images/education.png',
                width: 100,
                height: 100,
              ),
              SizedBox(height: 16.0),
              Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "SOS EDUCATIONAL FORUM",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF273B7A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "The SOS Educational Forum stands for safety, helping communities, and giving aid during emergencies. It's a place where people work together to learn and grow.",
                        style: TextStyle(fontSize: 16.0),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.0),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          isInGroup
                              ? "You are already in the group. Tap to open group!"
                              : "You are not in the Educational Group. Tap to join!",
                          style: TextStyle(fontSize: 18.0, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  isInGroup
                      ? _openEducationalGroup(context)
                      : _showJoinGroupDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  minimumSize: Size(220.0, 60.0),
                  textStyle: TextStyle(color: Color(0xFF273B7A)),
                  backgroundColor:
                      Color(0xFFDDE6EE), // Change the button color here
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Color(0xFF273B7A)),
                  ),
                ),
                child: Text(isInGroup ? "Open Group" : "Join Group",
                    style: TextStyle(fontSize: 18.0, color: Color(0xFF273B7A))),
              ),
              SizedBox(height: 20.0),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _isUserInEducationalGroup() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      DocumentReference groupReference = FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf');

      Map<String, dynamic>? existingData =
          (await groupReference.get()).data() as Map<String, dynamic>?;

      if (existingData != null) {
        return existingData.containsValue(currentUser.uid);
      }
      return false;
    } catch (e) {
      // Handle errors
      print("Error checking if user is in Educational Group: $e");
      return false;
    }
  }

  void _showJoinGroupDialog(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      // Fetch user data here
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      DocumentReference groupReference = FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf');

      Map<String, dynamic>? existingData =
          (await groupReference.get()).data() as Map<String, dynamic>?;

      if (existingData != null && existingData.containsValue(currentUser.uid)) {
        // User is already in the Educational Group
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You are already in the Educational Group."),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // User is not in the Educational Group, show the join dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFFDDE6EE),
              title: Text("Join Educational Group"),
              content: Text("Do you want to join the Educational Group?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text("No"),
                ),
                TextButton(
                  onPressed: () async {
                    // Close the dialog
                    Navigator.of(context).pop();

                    // Show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Joining the Educational Group..."),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Perform the join operation
                    await _joinEducationalGroup(context);
                  },
                  child: Text("Yes"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _joinEducationalGroup(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      DocumentReference groupReference = FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf');

      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null) {
        userData['id'] = userSnapshot.id;

        Map<String, dynamic>? existingData =
            (await groupReference.get()).data() as Map<String, dynamic>?;

        int nextIndex = 1;
        if (existingData != null) {
          nextIndex = existingData.length ~/ 2 + 1;
        }

        existingData ??= {};
        existingData['${nextIndex}_EGmemberId'] = userData['id'];
        existingData['${nextIndex}_EGmemberName'] = userData['name'];

        await groupReference.update(existingData).then((_) {
          Fluttertoast.showToast(
            msg: "You joined the Educational Group successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );

          // Refresh the page by calling setState
          setState(() {});
        });
      }
    } catch (e) {
      print("Error joining Educational Group: $e");
      Fluttertoast.showToast(
        msg: "Failed to join the Educational Group.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _openEducationalGroup(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Check if the user is in the Educational Group
      bool isUserInGroup = await _isUserInEducationalGroup();

      if (isUserInGroup) {
        // User is in the group, fetch user data
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        // Fetch user data
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        // Navigate to the GroupChatScreen page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EduGroupChatScreen(
              currentUserName: userData?['name'],
              currentUserId: userData?['id'],
              groupId: '2YYgBG7alKFeFVRSXYRf', // Use your specified group ID
              groupName: 'Educational Group', // Use your specified group name
            ),
          ),
        );
      } else {
        // User is not in the group, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You are not in the group. Join the group first."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }
}

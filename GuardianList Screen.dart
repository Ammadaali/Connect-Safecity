import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Guardian Records',
      body: GuardianList(),
    );
  }
}

class GuardianList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'guardian')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<DocumentSnapshot> users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> userData =
                users[index].data() as Map<String, dynamic>;

            bool isDisabled = userData['isDeleted'] ?? false;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Color(0xffdde6ee),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${userData['name']}'),
                    Text('Email: ${userData['guardiantEmail']}'),
                    Text('Child Email: ${userData['childEmail']}'),
                    Text('Phone Number: ${userData['phone']}'),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _updateUserStatus(users[index].id, false);
                          },
                          child: Text('Enable'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(100, 30),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _updateUserStatus(users[index].id, true);
                          },
                          child: Text('Disable'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(100, 30),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      isDisabled ? 'User is Disabled' : 'User is Enabled',
                      style: TextStyle(
                        color: isDisabled ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to update user status (enable/disable)
  Future<void> _updateUserStatus(String userId, bool isDisabled) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isDeleted': isDisabled,
      });
      print('User status updated successfully!');
    } catch (e) {
      print('Error updating user status: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';
import 'package:connect_safecity/user/Chats/GroupChatScreen.dart';
import 'package:connect_safecity/user/Chats/GroupCreateScreen.dart';
import 'package:flutter/material.dart';

class GroupChatsTab extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  GroupChatsTab({required this.currentUserId, required this.currentUserName});

  @override
  _GroupChatsTabState createState() => _GroupChatsTabState();
}

class _GroupChatsTabState extends State<GroupChatsTab> {
  late Future<List<String>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _getGroups();
  }

  Future<void> _refreshGroups() async {
    setState(() {
      _groupsFuture = _getGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _groupsFuture,
              builder: (context, AsyncSnapshot<List<String>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error loading groups"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No groups available"));
                } else {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            String groupId =
                                await _getGroupId(snapshot.data![index]);

                            if (groupId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupChatScreen(
                                    groupId: groupId,
                                    currentUserId: widget.currentUserId,
                                    groupName: snapshot.data![index],
                                    currentUserName: widget.currentUserName,
                                  ),
                                ),
                              );
                            } else {
                              // Handle the case when groupId is not available
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: Color(0xFFDDE6EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                snapshot.data![index],
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 16),
          CustomElevatedButton(
            onPressed: () async {
              // Wait for the result from the create group screen
              bool? result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupCreatScreen()),
              );

              // If a group was created, refresh the groups list
              if (result == true) {
                _refreshGroups();
              }
            },
            text: 'Create New Group',
          ),
          SizedBox(
            height: 25,
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getGroups() async {
    try {
      // Fetch the user's ID and email from the users collection
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();

      String userEmail = userSnapshot['childEmail'];
      String userId = widget.currentUserId; // User's ID

      // Fetch groups where the user's email matches GroupAdminEmail
      QuerySnapshot groupsSnapshotEmail = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('GroupAdminEmail', isEqualTo: userEmail)
          .get();

      // Fetch groups where the user's ID matches any member's ID
      QuerySnapshot snapshot1 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('1_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot2 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('2_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot3 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('3_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot4 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('4_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot5 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('5_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot6 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('6_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot7 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('7_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot8 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('8_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot9 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('9_memberId', isEqualTo: userId)
          .get();

      QuerySnapshot snapshot10 = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('10_memberId', isEqualTo: userId)
          .get();

      List<QueryDocumentSnapshot> combinedResults = [
        ...snapshot1.docs,
        ...snapshot2.docs,
        ...snapshot3.docs,
        ...snapshot4.docs,
        ...snapshot5.docs,
        ...snapshot6.docs,
        ...snapshot7.docs,
        ...snapshot8.docs,
        ...snapshot9.docs,
        ...snapshot10.docs,
      ];

      // Combine the results of both queries
      List<String> groupNames = [
        ...groupsSnapshotEmail.docs.map((doc) => doc['groupName'].toString()),
        ...combinedResults.map((doc) => doc['groupName'].toString()),
      ];

      return groupNames;
    } catch (e) {
      print('Error getting groups: $e');
      return [];
    }
  }

  Future<String> _getGroupId(String groupName) async {
    try {
      QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('GroupChats')
          .where('groupName', isEqualTo: groupName)
          .limit(1)
          .get();

      if (groupSnapshot.docs.isNotEmpty) {
        String groupId = groupSnapshot.docs.first.id;
        return groupId;
      } else {
        return '';
      }
    } catch (e) {
      print('Error getting group ID: $e');
      return '';
    }
  }
}

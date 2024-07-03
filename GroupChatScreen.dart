import 'package:connect_safecity/ChatModule/groupMsgsHandle.dart';
import 'package:connect_safecity/ChatModule/group_msg_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupChatScreen extends StatefulWidget {
  final String currentUserName;
  final String currentUserId;
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    Key? key,
    required this.currentUserName,
    required this.currentUserId,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  String currentUserName = '';
  final ScrollController scrollController = ScrollController();

  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentUserName();
  }

  Future<void> _removeMessage(DocumentSnapshot message) async {
    final messageSenderId = message['senderId'];

    if (messageSenderId == widget.currentUserId) {
      // Message is from the sender, allow deletion from both sides
      await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .collection('messages')
          .doc(message.id)
          .delete();

      Fluttertoast.showToast(msg: 'Message deleted successfully');
    } else {
      // Message is from the receiver, remove it from the receiver's side only
      // Display a message indicating that the user is not allowed to delete this message
      Fluttertoast.showToast(
          msg: 'You are not allowed to delete messages from other users');
    }
  }

///////////////////////////////////////////////////////////////
  Future<void> fetchCurrentUserName() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();

      setState(() {
        currentUserName = userSnapshot.data()?['name'] ?? 'DefaultName';
      });
    } catch (e) {
      print('Error fetching current user name: $e');
    }
  }

////////////////////////LEAVE GROUP////////////////////////
  Future<void> leaveGroup() async {
    try {
      String currentUserId = widget.currentUserId;

      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .get();

      String groupAdminId = groupSnapshot['GroupAdminId'];

      if (currentUserId == groupAdminId) {
        await FirebaseFirestore.instance
            .collection('GroupChats')
            .doc(widget.groupId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Group deleted successfully"),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context);
        });

        return;
      }

      for (int i = 1; i <= 10; i++) {
        String memberIdToDelete = groupSnapshot['${i}_memberId'];
        String memberNameToDelete = groupSnapshot['${i}_memberName'];

        if (currentUserId == memberIdToDelete) {
          await FirebaseFirestore.instance
              .collection('GroupChats')
              .doc(widget.groupId)
              .update({
            '${i}_memberId': FieldValue.delete(),
            '${i}_memberName': FieldValue.delete(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("You, $memberNameToDelete, left the group successfully"),
              duration: Duration(seconds: 2),
            ),
          );

          Future.delayed(Duration(seconds: 2), () {
            Navigator.pop(context);
          });

          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You are not authorized to leave this group"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to leave the group: $e"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

////////////////////////SHOW GROUP INFO AND DELETE MEMBERS////////////////////////
  Future<void> showGroupInfoDialog(BuildContext context) async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        String groupName = groupSnapshot['groupName'];
        String groupAdmin = groupSnapshot['GroupAdminName'];
        Map<String, dynamic>? groupData =
            groupSnapshot.data() as Map<String, dynamic>?;

        List<String> memberNames = [];
        List<String> memberIds = [];

        for (int i = 1; i <= 10; i++) {
          final memberNameKey = '${i}_memberName';
          final memberIdKey = '${i}_memberId';

          if (groupData?.containsKey(memberNameKey) ?? false) {
            memberNames.add(groupData?[memberNameKey].toString() ?? '');
            memberIds.add(groupData?[memberIdKey].toString() ?? '');
          }
        }

        // Calculate the number of members
        int memberCount = memberNames.length;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Group Information - $groupName'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Group Admin: $groupAdmin'),
                  SizedBox(height: 8),
                  Text('$memberCount Members'),
                  SizedBox(height: 8),
                  Text('Group Members:'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      memberNames.length,
                      (index) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('- ${memberNames[index]}'),
                          if (widget.currentUserId ==
                              groupSnapshot['GroupAdminId'])
                            ElevatedButton(
                              onPressed: () {
                                _showRemoveConfirmationDialog(
                                  context,
                                  widget.groupId,
                                  memberNames[index],
                                  memberIds[index],
                                );
                              },
                              child: Text('Remove'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        print('Group not found');
      }
    } catch (e) {
      print('Error fetching group information: $e');
    }
  }

  Future<void> _showRemoveConfirmationDialog(
    BuildContext context,
    String groupId,
    String memberName,
    String memberId,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Member'),
          content: Text(
              'Are you sure you want to remove $memberName from the group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                print('Removing member: $memberName, $memberId');
                bool removed =
                    await removeMemberFromGroup(groupId, memberId, memberName);
                if (removed) {
                  Fluttertoast.showToast(
                    msg: '$memberName removed from the group',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: 'Failed to remove $memberName from the group',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes, Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> getCurrentUserEmail() async {
    try {
      // Get the current user from Firebase Authentication
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Check if the user is signed in
      if (currentUser != null) {
        // Fetch the current user's data
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Check if the user exists
        if (userSnapshot.exists) {
          return userSnapshot['childEmail'];
        } else {
          print('User not found');
          return null;
        }
      } else {
        print('User not signed in');
        return null;
      }
    } catch (e) {
      print('Error fetching current user data: $e');
      return null;
    }
  }

  Future<bool> removeMemberFromGroup(
      String groupId, String memberId, String memberName) async {
    try {
      // Fetch the latest group snapshot
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(groupId)
          .get();

      // Fetch the current user's email
      String? currentUserEmail = await getCurrentUserEmail();

      // Check if the current user is the Group Admin
      String groupAdminEmail = groupSnapshot['GroupAdminEmail'];
      print('Current User Email: $currentUserEmail');
      print('Group Admin Email: $groupAdminEmail');

      if (currentUserEmail == groupAdminEmail) {
        // Iterate through group members to find and remove the specified member
        Map<String, dynamic>? groupData =
            groupSnapshot.data() as Map<String, dynamic>?;

        if (groupData != null) {
          for (String key in groupData.keys) {
            if (key.endsWith('_memberId')) {
              String memberIdToDelete = groupData[key];
              if (memberId == memberIdToDelete) {
                // Remove member ID and name from the group
                await FirebaseFirestore.instance
                    .collection('GroupChats')
                    .doc(groupId)
                    .update({
                  '$key': FieldValue.delete(),
                  '${key.replaceAll('_memberId', '_memberName')}':
                      FieldValue.delete(),
                });

                // Show a message indicating the removal
                String removalMessage = '$memberName removed from the group';
                Fluttertoast.showToast(msg: removalMessage);

                // Implement any additional logic here, such as updating UI or navigating to a different screen
                return true;
              }
            }
          }
        }
      } else {
        // Show a message indicating that only the Group Admin can remove members
        Fluttertoast.showToast(msg: 'Only the Group Admin can remove members.');
      }
    } catch (e) {
      print('Error removing member from group: $e');
    }

    return false;
  }

////////////////////////ADD NEW MEMBER BY ADMIN////////////////////////
  Future<void> addNewMember() async {
    try {
      // Fetch the latest group snapshot
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupId)
          .get();

      if (widget.currentUserId == groupSnapshot['GroupAdminId']) {
        // Show dialog to input email of the new member
        String? email = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            TextEditingController emailController = TextEditingController();
            return AlertDialog(
              title: Text('Add New Member'),
              content: TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Enter Email'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, emailController.text);
                  },
                  child: Text('Add'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );

        if (email != null && email.isNotEmpty) {
          // Check if the user exists with the specified email and type "child"
          QuerySnapshot userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('childEmail', isEqualTo: email)
              .where('type', isEqualTo: 'child')
              .get();

          if (userQuery.docs.isNotEmpty) {
            // Get the user data
            DocumentSnapshot userData = userQuery.docs.first;
            String newMemberName = userData['name'];
            String newMemberId = userData.id;

            // Check if the group is already full
            Map<String, dynamic>? groupData =
                groupSnapshot.data() as Map<String, dynamic>?;

            if (groupData != null && groupData.length >= 25) {
              // Show a message indicating that the group is full
              Fluttertoast.showToast(
                msg: 'Group is full. Cannot add new member.',
              );
            } else {
              // Add the user to the group
              int memberIndex = -1;
              for (int i = 1; i <= 25; i++) {
                if (groupData?['${i}_memberId'] == null) {
                  memberIndex = i;
                  break;
                }
              }

              if (memberIndex != -1) {
                await FirebaseFirestore.instance
                    .collection('GroupChats')
                    .doc(widget.groupId)
                    .update({
                  '${memberIndex}_memberId': newMemberId,
                  '${memberIndex}_memberName': newMemberName,
                });
              } else {
                // The group is full, add a new member to the end of the list
                int nextIndex = (groupData?.keys.length ?? 0) + 1;
                await FirebaseFirestore.instance
                    .collection('GroupChats')
                    .doc(widget.groupId)
                    .update({
                  '${nextIndex}_memberId': newMemberId,
                  '${nextIndex}_memberName': newMemberName,
                });
              }

              // Retrieve the admin's name
              DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserId)
                  .get();
              String adminName = adminSnapshot['name'];

              // Show a message in the group chat indicating the new member joined
              String joinMessage = '$newMemberName joined the group';
              await FirebaseFirestore.instance
                  .collection('GroupChats')
                  .doc(widget.groupId)
                  .collection('messages')
                  .add({
                'message': joinMessage,
                'date': FieldValue.serverTimestamp(),
                'senderId': widget.currentUserId,
                'senderName': adminName,
                'type': 'join',
              });

              // Show a toast message
              Fluttertoast.showToast(msg: joinMessage);
            }
          } else {
            // Show a message indicating that the user with the specified email and type was not found
            Fluttertoast.showToast(
              msg: 'User not found with the specified email and type.',
            );
          }
        }
      } else {
        // Show a dialog indicating that only the admin can add new members
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Permission Denied'),
              content: Text('Only the admin can add new members.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error adding new member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        title: Text(widget.groupName),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white, // Set the color of the back button to white
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white, // Set the color of the three dots to white
            ),
            itemBuilder: (BuildContext context) {
              return {'Leave Group', 'Group Info', 'Add New Member'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            onSelected: (String choice) async {
              if (choice == 'Leave Group') {
                await leaveGroup();
              } else if (choice == 'Group Info') {
                await showGroupInfoDialog(context);
              } else if (choice == 'Add New Member') {
                await addNewMember();
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Color(0xffEFEAE2),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('GroupChats')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Display a loading indicator while waiting for data
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasData) {
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      scrollToBottom();
                    });
                    final messages = snapshot.data!.docs;
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          "No messages in this group yet.",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      // This callback is called after the build method is complete
                      scrollToBottom();
                    });

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final data = messages[index];
                        bool isMe = data['senderId'] == widget.currentUserId;

                        return GroupMessage(
                          message: data['message'],
                          date: data['date'],
                          isMe: isMe,
                          senderName: data['senderName'],
                          type: data['type'], // Add a null check
                          onDelete: () {
                            _removeMessage(
                                data); // Pass the DocumentSnapshot to _removeMessage
                          },
                        );
                      },
                    );
                  }
                  return CircularProgressIndicator();
                },
              ),
            ),
            GroupMessageTextField(
              groupId: widget.groupId,
              currentUserId: widget.currentUserId,
              currentUserName: currentUserName,
            ),
          ],
        ),
      ),
    );
  }
}

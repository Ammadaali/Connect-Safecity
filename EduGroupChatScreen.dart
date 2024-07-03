import 'package:connect_safecity/ChatModule/EduGroupMsgTextField.dart';
import 'package:connect_safecity/ChatModule/groupMsgsHandle.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EduGroupChatScreen extends StatefulWidget {
  final String currentUserName;
  final String currentUserId;
  final String groupId;
  final String groupName;

  const EduGroupChatScreen({
    Key? key,
    required this.currentUserName,
    required this.currentUserId,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _EduGroupChatScreenState createState() => _EduGroupChatScreenState();
}

class _EduGroupChatScreenState extends State<EduGroupChatScreen> {
  String currentUserName = '';
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchCurrentUserName();
  }

  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _removeMessage(DocumentSnapshot message) async {
    final messageSenderId = message['senderId'];

    if (messageSenderId == widget.currentUserId) {
      // Message is from the sender, allow deletion from both sides
      await FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf')
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

///////////////////////////////
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

      DocumentReference groupReference = FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf');

      DocumentSnapshot groupSnapshot = await groupReference.get();

      Map<String, dynamic>? existingData =
          groupSnapshot.data() as Map<String, dynamic>?;

      if (existingData != null) {
        for (int i = 1; i <= double.infinity; i++) {
          String? memberIdToDelete = existingData['${i}_EGmemberId'];
          String? memberNameToDelete = existingData['${i}_EGmemberName'];

          if (memberIdToDelete != null && memberIdToDelete == currentUserId) {
            // Delete the user's data
            existingData.remove('${i}_EGmemberId');
            existingData.remove('${i}_EGmemberName');

            await groupReference.set(existingData);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "You, $memberNameToDelete, left the group successfully"),
                duration: Duration(seconds: 2),
              ),
            );

            Future.delayed(Duration(seconds: 2), () {
              Navigator.pop(context);
            });
            return;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Group data not found"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to leave the group: $e"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  ////////////////////////SHOW GROUP INFO////////////////////////
  Future<void> showGroupInfoDialog(BuildContext context) async {
    try {
      // Use the groupId passed in the widget instead of hardcoding it
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf')
          .get();

      Map<String, dynamic>? groupData =
          groupSnapshot.data() as Map<String, dynamic>?;

      List<String> memberNames = [];

      // Check if the groupData is not null
      if (groupData != null) {
        // Iterate over the keys in the groupData map
        groupData.forEach((key, value) {
          if (key.endsWith('_EGmemberName')) {
            memberNames.add(value.toString());
          }
        });
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Group Information'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Group Members: (${memberNames.length})'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      memberNames.length,
                      (index) => Text('- ${memberNames[index]}'),
                    ),
                  ),
                ],
              ),
            ),
            contentPadding: EdgeInsets.all(16.0), // Adjust padding as needed
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
    } catch (e) {
      print('Error fetching group information: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        title: Text("SafeCity Wall"),
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
              return {'Leave Group', 'Group Info'}.map((String choice) {
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
                    .collection('EducationalGroup')
                    .doc('2YYgBG7alKFeFVRSXYRf')
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
                          message: data['message'] ?? 'Default Message',
                          date: data['date']?.toDate() ?? DateTime.now(),
                          isMe: isMe,
                          senderName: data['senderName'] ?? 'Default Sender',
                          type: data['type'] ?? 'defaultType',
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
            EduGroupMessageTextField(
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

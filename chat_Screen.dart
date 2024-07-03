import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/ChatModule/singleMessage_text_field.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connect_safecity/ChatModule/singleMsgsHandle.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.friendId,
    required this.friendName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? type;
  String? myname;
  final ScrollController scrollController = ScrollController();

  getStatus() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get()
        .then((value) {
      setState(() {
        type = value.data()!['type'];
        myname = value.data()!['name'];
      });
    });
  }

  void jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getStatus();
    requestCameraPermission();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: 'Microphone permission denied.');
    }
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: 'Camera permission denied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        title: Text(widget.friendName),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: Color(0xffEFEAE2),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentUserId)
                    .collection('messages')
                    .doc(widget.friendId)
                    .collection('chats')
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      jumpToBottom();
                    });

                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          type == "guardian"
                              ? "TALK WITH CHILD"
                              : "TALK WITH PARENT",
                          style: TextStyle(fontSize: 30),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        bool isMe = snapshot.data!.docs[index]['senderId'] ==
                            widget.currentUserId;
                        final data = snapshot.data!.docs[index];
                        return SingleMsgsHandle(
                          message: data['message'],
                          date: data['date'],
                          isMe: isMe,
                          friendName: widget.friendName,
                          myName: myname,
                          type: data['type'],
                          onDelete: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.currentUserId)
                                .collection('messages')
                                .doc(widget.friendId)
                                .collection('chats')
                                .doc(data.id)
                                .delete();
                          },
                        );
                      },
                    );
                  }
                  return progressIndicator(context);
                },
              ),
            ),
            SingleMessageTextField(
              currentuserId: widget.currentUserId,
              friendId: widget.friendId,
            ),
          ],
        ),
      ),
    );
  }
}

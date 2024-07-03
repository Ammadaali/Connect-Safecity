import 'package:connect_safecity/user/CHATS%20TABS/EduGroupTab.dart';
import 'package:connect_safecity/user/CHATS%20TABS/GroupChatsTab.dart';
import 'package:connect_safecity/user/CHATS%20TABS/SingleChatTab.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class allChatsPage extends StatefulWidget {
  const allChatsPage({Key? key});

  @override
  State<allChatsPage> createState() => _allChatsPageState();
}

class _allChatsPageState extends State<allChatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    //requestStoragePermission();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Future<void> requestStoragePermission() async {
  //   var status = await Permission.storage.request();
  //   if (!status.isGranted) {
  //     // You can show an additional message or take appropriate action
  //     Fluttertoast.showToast(msg: 'Storage permission denied.');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Inbox"),
        titleTextStyle: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white,
          tabs: [
            Tab(text: "Chats"),
            Tab(text: "Group Chats"),
            Tab(text: "SafeCity Wall"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChatsTab(),
          GroupChatsTab(
            currentUserId: FirebaseAuth.instance.currentUser!.uid,
            currentUserName: FirebaseAuth.instance.currentUser!.uid,
          ),
          EducationalGroupTab(),
        ],
      ),
    );
  }
}

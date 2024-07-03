import 'package:connect_safecity/guardian/userLocationMapScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:connect_safecity/guardian/guardian.drawer.dart';
import 'package:connect_safecity/user/Chats/chat_Screen.dart';
import 'package:connect_safecity/Utils/constants.dart';

class GuardianDashboard extends StatelessWidget {
  const GuardianDashboard({Key? key}) : super(key: key);

  Future<void> _updateFCMToken(String fcmToken) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userData != null && userData.containsKey('fcmToken')) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'fcmToken': fcmToken});
          } else {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .set({'fcmToken': fcmToken}, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<String> _getFCMToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? fcmToken = await messaging.getToken();
    return fcmToken ?? "";
  }

  Future<void> _initializeFCM() async {
    String fcmToken = await _getFCMToken();
    await _updateFCMToken(fcmToken);
  }

  @override
  Widget build(BuildContext context) {
    _initializeFCM();

    return WillPopScope(
      onWillPop: () async {
        await SystemNavigator.pop();
        return true;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Guardian Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Color.fromARGB(255, 39, 59, 122),
            iconTheme: IconThemeData(color: Colors.white),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Color.fromARGB(255, 39, 59, 122),
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Chats'),
                    Tab(text: 'Track Location'),
                  ],
                ),
              ),
            ),
          ),
          drawer: GuardianDrawer(),
          body: TabBarView(
            children: [
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('type', isEqualTo: 'child')
                    .where('guardiantEmail',
                        isEqualTo: FirebaseAuth.instance.currentUser!.email)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: progressIndicator(context));
                  }

                  // Log the number of documents retrieved
                  print('Number of documents: ${snapshot.data!.docs.length}');

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final d = snapshot.data!.docs[index];
                      // Log the child document data
                      print('Child document data: ${d.data()}');

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          color: Color(0xFFDDE6EE),
                          //elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            onTap: () {
                              goTo(
                                context,
                                ChatScreen(
                                  currentUserId:
                                      FirebaseAuth.instance.currentUser!.uid,
                                  friendId: d.id,
                                  friendName: d['name'],
                                ),
                              );
                            },
                            title: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                d['name'],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Second Tab: Track Location
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('type', isEqualTo: 'child')
                    .where('guardiantEmail',
                        isEqualTo: FirebaseAuth.instance.currentUser!.email)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: progressIndicator(context));
                  }

                  // Log the number of documents retrieved
                  print('Number of documents: ${snapshot.data!.docs.length}');

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final d = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      print(
                          'Child data: $d'); // Add this line to print child data

                      bool isSharingLocation = d.containsKey('liveLocation') &&
                          d['liveLocation'] == true;

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          //elevation: 4,
                          color: Color(0xFFDDE6EE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    d['name'] ?? '',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isSharingLocation
                                        ? 'Sharing Location'
                                        : 'Not Sharing Location',
                                    style: TextStyle(
                                        color: isSharingLocation
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (isSharingLocation) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => userLocationMapScreen(
                                      childUserId:
                                          snapshot.data!.docs[index].id,
                                    ),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("User Location"),
                                      content: Text(
                                          "The user has not shared their location."),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text("OK"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

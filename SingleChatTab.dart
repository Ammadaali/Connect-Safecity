import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/Utils/constants.dart';
import 'package:connect_safecity/user/Chats/chat_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SingleChatsTab extends StatelessWidget {
  const SingleChatsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var currentUserData = snapshot.data!.data() as Map<String, dynamic>;
        var CUGEmail = currentUserData['guardiantEmail'];

        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('type', isEqualTo: 'guardian')
              .where('guardiantEmail', isEqualTo: CUGEmail)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0), // Adjust padding as needed
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  final d = snapshot.data!.docs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFDDE6EE),
                        borderRadius: BorderRadius.circular(10),
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
                              //fcmToken: fcmToken,
                            ),
                          );
                        },
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(d['name']),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

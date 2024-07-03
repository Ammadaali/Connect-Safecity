import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connect_safecity/user/ContactsPage.dart';
import 'package:connect_safecity/components/PrimaryButton.dart';
import 'package:permission_handler/permission_handler.dart';

class TrustedContactsPage extends StatefulWidget {
  const TrustedContactsPage({Key? key});

  @override
  State<TrustedContactsPage> createState() => _TrustedContactsPageState();
}

class _TrustedContactsPageState extends State<TrustedContactsPage> {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>>? contactList;

  @override
  void initState() {
    super.initState();
    fetchTrustedContacts();
    requestContactsPermission();
  }

  Future<void> requestContactsPermission() async {
    var status = await Permission.contacts.request();
    if (!status.isGranted) {
      // You can show an additional message or take appropriate action
      Fluttertoast.showToast(msg: 'Contacts permission denied.');
    }
  }

  Future<void> fetchTrustedContacts() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Fluttertoast.showToast(msg: "User not authenticated");
      return;
    }

    DocumentSnapshot trustedContactsSnapshot = await firebaseFirestore
        .collection('TrustedContacts')
        .doc(currentUser.uid)
        .get();

    if (trustedContactsSnapshot.exists) {
      setState(() {
        contactList = List<Map<String, dynamic>>.from(
            trustedContactsSnapshot['Tcontacts'] ?? [])
          ..removeWhere((contact) => contact['id'] == null);
      });
    }
  }

  Future<void> deleteContact(String? contactId) async {
    if (contactId == null) {
      Fluttertoast.showToast(msg: "Invalid contactId");
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Fluttertoast.showToast(msg: "User not authenticated");
      return;
    }

    DocumentReference contactRef =
        firebaseFirestore.collection('TrustedContacts').doc(currentUser.uid);

    Map<String, dynamic>? userData =
        (await contactRef.get()).data() as Map<String, dynamic>?;

    if (userData != null) {
      List<Map<String, dynamic>>? contacts =
          List<Map<String, dynamic>>.from(userData['Tcontacts'] ?? []);

      contacts.removeWhere((contact) => contact['id'] == contactId);

      await contactRef.update({'Tcontacts': contacts});

      // Refresh the contact list after deletion
      fetchTrustedContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (contactList == null) {
      contactList = [];
    }

    return CustomScaffold(
      title: 'Trusted Contacts',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        "assets/images/trust.png",
                        height: 150,
                        width: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: contactList!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      color: Color(0xFFDDE6EE),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: ListTile(
                          title: Text(contactList![index]['contactName'] ?? ''),
                          subtitle:
                              Text(contactList![index]['contactPhone'] ?? ''),
                          trailing: Container(
                            width: 100,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await FlutterPhoneDirectCaller.callNumber(
                                        contactList![index]['contactPhone'] ??
                                            '');
                                  },
                                  icon: Icon(
                                    Icons.call,
                                    color: Colors.green,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    deleteContact(contactList![index]['id']);
                                  },
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              PrimaryButton(
                title: "Add Trusted Contacts",
                onPressed: () async {
                  var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactsPage(),
                    ),
                  );
                  if (result != null) {
                    Fluttertoast.showToast(msg: result['message']);
                    if (result['result']) {
                      fetchTrustedContacts();
                    }
                  }
                },
              ),
              SizedBox(
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

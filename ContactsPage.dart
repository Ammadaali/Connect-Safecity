import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/user/Trusted_Contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:connect_safecity/db/db-services.dart';
import 'package:connect_safecity/model/contactsm.dart';
import 'package:connect_safecity/utils/constants.dart';
import 'package:uuid/uuid.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> contactsFiltered = [];
  DatabaseHelper _databaseHelper = DatabaseHelper();

  TextEditingController searchController = TextEditingController();
  bool contactsPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    askPermissions();
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }

  filterContact() {
    List<Contact> _contacts = [];
    _contacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((element) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlattren = flattenPhoneNumber(searchTerm);
        String contactName = element.displayName!.toLowerCase();
        bool nameMatch = contactName.contains(searchTerm);
        if (nameMatch == true) {
          return true;
        }
        if (searchTermFlattren.isEmpty) {
          return false;
        }
        var phone = element.phones!.firstWhere((p) {
          String phnFLattered = flattenPhoneNumber(p.value!);
          return phnFLattered.contains(searchTermFlattren);
        });
        return phone.value != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  Future<void> askPermissions() async {
    PermissionStatus permissionStatus = await getContactsPermissions();
    if (permissionStatus == PermissionStatus.granted) {
      getAllContacts();
      searchController.addListener(() {
        filterContact();
      });
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      setState(() {
        contactsPermissionDenied = true;
      });
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      dialogueBox(context, "May contact does exist in this device");
    }
  }

  Future<PermissionStatus> getContactsPermissions() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  getAllContacts() async {
    List<Contact> _contacts =
        await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      contacts = _contacts;
    });
  }

  Future<void> _addUserAndContactsToFirebase(
      List<TContact> selectedContacts) async {
    try {
      FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        Navigator.pop(
            context, {'result': false, 'message': "User not authenticated"});
        return;
      }

      // Retrieve the current trusted contacts
      DocumentSnapshot trustedContactsSnapshot = await firebaseFirestore
          .collection('TrustedContacts')
          .doc(currentUser.uid)
          .get();

      List<dynamic> existingContacts = [];
      if (trustedContactsSnapshot.exists) {
        existingContacts = List<Map<String, dynamic>>.from(
            trustedContactsSnapshot['Tcontacts'] ?? []);
      }

      List<Map<String, String>> newContacts = [];
      var uuid = Uuid();

      for (TContact selectedContact in selectedContacts) {
        // Check if contact already exists
        bool contactExists = existingContacts.any(
            (contact) => contact['contactPhone'] == selectedContact.number);

        if (contactExists) {
          Navigator.pop(context, {
            'result': false,
            'message': "Contact already exists: ${selectedContact.name}"
          });
          return;
        }

        // If contact does not exist, add to the new contacts list
        newContacts.add({
          'id': uuid.v4(), // Generate a unique ID for each contact
          'contactName': selectedContact.name,
          'contactPhone': selectedContact.number,
        });
      }

      Map<String, dynamic> trustedContactsData = {
        'Tcontacts': FieldValue.arrayUnion(newContacts),
      };

      await firebaseFirestore
          .collection('TrustedContacts')
          .doc(currentUser.uid)
          .set(trustedContactsData, SetOptions(merge: true));

      Navigator.pop(
          context, {'result': true, 'message': "Contacts added successfully"});
    } catch (e) {
      Navigator.pop(
          context, {'result': false, 'message': "Failed to add contacts: $e"});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemExit = (contactsFiltered.length > 0 ||
        (contacts != null && contacts.length > 0));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search contact",
                  prefixIcon: Icon(Icons.search),
                  suffix: contactsPermissionDenied
                      ? ElevatedButton(
                          onPressed: () {
                            openAppSettings();
                          },
                          child: Text("Open Settings"),
                        )
                      : null,
                ),
              ),
            ),
            listItemExit == true
                ? Expanded(
                    child: ListView.builder(
                      itemCount: isSearching == true
                          ? contactsFiltered.length
                          : (contacts != null ? contacts.length : 0),
                      itemBuilder: (BuildContext context, int index) {
                        Contact? contact = isSearching == true
                            ? contactsFiltered[index]
                            : (contacts != null ? contacts[index] : null);

                        if (contact == null) {
                          // Handle the case where contact is null, you can return a placeholder widget or null
                          return SizedBox.shrink();
                        }

                        return ListTile(
                          title: Text(contact.displayName ?? 'Unknown Contact'),
                          leading: contact.avatar != null &&
                                  contact.avatar!.length > 0
                              ? CircleAvatar(
                                  backgroundColor: Colors.black,
                                  backgroundImage: MemoryImage(contact.avatar!),
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Text(contact.initials() ?? ''),
                                ),
                          onTap: () {
                            if (contact.phones != null &&
                                contact.phones!.length > 0) {
                              final String phoneNum =
                                  contact.phones!.elementAt(0).value!;
                              final String name = contact.displayName ?? '';
                              _addUserAndContactsToFirebase(
                                  [TContact(phoneNum, name)]);
                            } else {
                              Fluttertoast.showToast(
                                msg:
                                    "Oops! Phone number of this contact does not exist",
                              );
                            }
                          },
                        );
                      },
                    ),
                  )
                : Container(
                    child: Text("Searching"),
                  ),
          ],
        ),
      ),
    );
  }

  void _addContact(TContact newContact) async {
    int result = await _databaseHelper.insertContact(newContact);
    if (result != 0) {
      Fluttertoast.showToast(msg: "Contact added successfully");
    } else {
      Fluttertoast.showToast(msg: "Failed to add contact");
    }
    Navigator.of(context).pop(true);
  }
}

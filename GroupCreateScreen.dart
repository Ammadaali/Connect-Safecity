import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupCreatScreen extends StatefulWidget {
  @override
  _GroupCreatScreenState createState() => _GroupCreatScreenState();
}

class _GroupCreatScreenState extends State<GroupCreatScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  List<String> selectedEmails = [];
  List<Map<String, dynamic>> selectedContacts = [];
  String emailErrorMessage = '';
  List<Map<String, dynamic>>? trustedContactsList;
  @override
  void initState() {
    super.initState();
    fetchTrustedContacts(); // Call the method to fetch trusted contacts
  }

  Future<void> fetchTrustedContacts() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Fluttertoast.showToast(msg: "User not authenticated");
      return;
    }

    DocumentSnapshot trustedContactsSnapshot = await FirebaseFirestore.instance
        .collection('TrustedContacts')
        .doc(currentUser.uid)
        .get();

    if (trustedContactsSnapshot.exists) {
      setState(() {
        trustedContactsList = List<Map<String, dynamic>>.from(
            trustedContactsSnapshot['Tcontacts'] ?? [])
          ..removeWhere((contact) => contact['id'] == null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Create New Group',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Name
                TextFormField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: "Group Name",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Group name is required';
                    } else if (value.length < 3) {
                      return 'Group name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Add Members Email
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Add Members by Email",
                            errorText: emailErrorMessage.isNotEmpty
                                ? emailErrorMessage
                                : null,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(
                                      r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$')
                                  .hasMatch(value.trim())) {
                                return 'Invalid email format';
                              } else if (_isEmailSelected(value.trim())) {
                                return 'Email already added';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color.fromARGB(255, 39, 59, 122),
                            ),
                            onPressed: () {
                              _addEmail();
                            },
                            child: Text(
                              "Add",
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Trusted Contacts
                if (trustedContactsList != null &&
                    trustedContactsList!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Trusted Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Display trusted contacts with InkWell for tapping
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: trustedContactsList!.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map<String, dynamic> contact =
                          trustedContactsList![index];

                      return InkWell(
                        onTap: () {
                          // Handle the contact selection
                          _handleContactSelection([contact]);
                        },
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(contact['contactName'] ?? ''),
                            subtitle: Text(contact['contactPhone'] ?? ''),
                            // Add more details or actions if needed
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                ],

                // Selected Members and Contacts
                if (selectedEmails.isNotEmpty ||
                    selectedContacts.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Selected Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 39, 59, 122),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Display selected emails
                        ...selectedEmails.map(
                          (email) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: ListTile(
                              title: Text(
                                email,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.remove),
                                color: Colors.white,
                                onPressed: () {
                                  _removeEmail(email);
                                },
                              ),
                            ),
                          ),
                        ),
                        // Display selected contacts
                        ...selectedContacts.map(
                          (contact) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: ListTile(
                              title: Text(
                                contact['contactName'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                contact['contactPhone'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.remove),
                                color: Colors.white,
                                onPressed: () {
                                  _removeContact(contact);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Create Group Button
                CustomElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _createGroup();
                    }
                  },
                  text: 'Create Group',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleContactSelection(List<Map<String, dynamic>> contacts) {
    if (_isContactSelected(contacts.first)) {
      Fluttertoast.showToast(msg: "Contact already selected");
    } else {
      _addContacts(contacts);
    }
  }

  void _addContacts(List<Map<String, dynamic>> contacts) {
    setState(() {
      selectedContacts.addAll(contacts);
    });
  }

  void _addEmail() {
    String email = _emailController.text.trim();
    if (email.isNotEmpty &&
        RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$').hasMatch(email) &&
        !_isEmailSelected(email)) {
      setState(() {
        selectedEmails.add(email);
        _emailController.clear();
        emailErrorMessage = ''; // Clear error message on successful addition
      });
    } else {
      setState(() {
        emailErrorMessage = 'Invalid email or already added';
      });
    }
  }

  bool _isEmailSelected(String email) {
    return selectedEmails.contains(email);
  }

  bool _isContactSelected(Map<String, dynamic> contact) {
    return selectedContacts.any((selectedContact) =>
        selectedContact['contactPhone'] == contact['contactPhone']);
  }

  void _removeEmail(String email) {
    setState(() {
      selectedEmails.remove(email);
    });
  }

  void _removeContact(Map<String, dynamic> contact) {
    setState(() {
      selectedContacts.remove(contact);
    });
  }

  Future<void> _createGroup() async {
    try {
      String groupName = _groupNameController.text;
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User information not found"),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      String userName = userSnapshot.get('name');
      String userEmail = userSnapshot.get('childEmail');
      String userphone = userSnapshot.get('phone');

      List<Map<String, dynamic>> membersData = [];

      for (String email in selectedEmails) {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'child')
            .where('childEmail', isEqualTo: email.trim())
            .get();

        if (userQuery.docs.isNotEmpty) {
          Map<String, dynamic>? userData =
              userQuery.docs.first.data() as Map<String, dynamic>?;

          if (userData != null) {
            userData['id'] = userQuery.docs.first.id;

            membersData.add({
              '${membersData.length + 1}_memberId': userData['id'],
              '${membersData.length + 1}_memberName': userData['name'],
            });
          }
        }
      }

      // Check if selected contacts' phone numbers match any user's contact numbers
      for (Map<String, dynamic> contact in selectedContacts) {
        String phoneNumber = contact['contactPhone'] ?? '';

        // Remove non-numeric characters
        String numericPhoneNumber =
            phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

        // Extract the last 10 digits
        String last10Digits = numericPhoneNumber.length >= 10
            ? numericPhoneNumber.substring(numericPhoneNumber.length - 10)
            : numericPhoneNumber;

        // Fetch all child users
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'child')
            .get();

        for (var doc in userQuery.docs) {
          Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;

          if (userData != null) {
            String userPhone = userData['phone'] ?? '';

            // Remove non-numeric characters from userPhone
            String numericUserPhone =
                userPhone.replaceAll(RegExp(r'[^0-9]'), '');

            // Extract the last 10 digits of userPhone
            String userLast10Digits = numericUserPhone.length >= 10
                ? numericUserPhone.substring(numericUserPhone.length - 10)
                : numericUserPhone;

            // Check if the last 10 digits match
            if (userLast10Digits == last10Digits) {
              userData['id'] = doc.id;

              membersData.add({
                '${membersData.length + 1}_memberId': userData['id'],
                '${membersData.length + 1}_memberName': userData['name'],
              });
              break; // Break the loop as we found a match
            }
          }
        }
      }

      DocumentReference groupRef =
          await FirebaseFirestore.instance.collection('GroupChats').add({
        'groupName': groupName,
        'GroupAdminId': currentUserId,
        'GroupAdminName': userName,
        'GroupAdminEmail': userEmail,
        'GroupAdminPhone': userphone,
        ...Map.fromEntries(membersData.expand((entry) => entry.entries)),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Group created successfully"),
          duration: Duration(seconds: 2),
        ),
      );

      // Wait for a short duration to show the snackbar
      await Future.delayed(Duration(seconds: 2));

      // Pass back a signal to refresh the groups list
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create group: $e"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

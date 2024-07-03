import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class Guardian_EditProfile extends StatefulWidget {
  @override
  _Guardian_EditProfileState createState() => _Guardian_EditProfileState();
}

class _Guardian_EditProfileState extends State<Guardian_EditProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(text: '+92');

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    phoneController.addListener(_ensurePhonePrefix);
  }

  @override
  void dispose() {
    phoneController.removeListener(_ensurePhonePrefix);
    phoneController.dispose();
    super.dispose();
  }

  void _ensurePhonePrefix() {
    if (!phoneController.text.startsWith('+92')) {
      phoneController.text = '+92';
      phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: phoneController.text.length),
      );
    }
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          setState(() {
            nameController.text = userData['name'];
            phoneController.text = userData['phone'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> updateUserData() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'name': nameController.text,
            'phone': phoneController.text,
          });

          // Show a success message
          final snackBar = SnackBar(
            content: Text('Updated Successfully'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          // Close the Edit Profile screen after a short delay (optional)
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(context).pop();
          });
        }
      } catch (e) {
        print('Error updating user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Edit Profile',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value!.isEmpty || value.length < 3) {
                    return 'Name should contain more than 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 18),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+923[0-9]*')),
                  LengthLimitingTextInputFormatter(13),
                ],
                validator: (value) {
                  if (value!.length != 13) {
                    return 'Enter a valid phone number (10 digits)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              CustomElevatedButton(
                onPressed: updateUserData,
                text: 'Save Changes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

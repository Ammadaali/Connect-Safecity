import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:connect_safecity/components/custom_textfeild.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController guardianEmailController = TextEditingController();
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
            guardianEmailController.text = userData['guardiantEmail'];
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
            'guardiantEmail': guardianEmailController.text,
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
              CustomTextField(
                controller: nameController,
                hintText: 'Enter Your Name',
                textInputAction: TextInputAction.next,
                keyboardtype: TextInputType.name,
                prefix: Icon(Icons.person),
                validate: (value) {
                  if (value!.isEmpty || value.length < 3) {
                    return 'Name should contain more than 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 18),
              CustomTextField(
                controller: guardianEmailController,
                hintText: 'Enter Guardian Email',
                textInputAction: TextInputAction.next,
                keyboardtype: TextInputType.emailAddress,
                prefix: Icon(Icons.email),
                validate: (email) {
                  if (email!.isEmpty ||
                      email.length < 3 ||
                      !email.contains('@')) {
                    return 'Enter a correct email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 18),
              CustomTextField(
                controller: phoneController,
                hintText: 'Enter Phone Number',
                textInputAction: TextInputAction.next,
                keyboardtype: TextInputType.phone,
                prefix: Icon(Icons.phone),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+923[0-9]*')),
                  LengthLimitingTextInputFormatter(13),
                ],
                validate: (value) {
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

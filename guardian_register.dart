import 'package:connect_safecity/Utils/constants.dart';
import 'package:connect_safecity/components/SecondryButton.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connect_safecity/model/user_model.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:connect_safecity/components/PrimaryButton.dart';
import 'package:connect_safecity/components/custom_textfeild.dart';
import 'package:flutter/services.dart';

class GuardianRegister extends StatefulWidget {
  @override
  State<GuardianRegister> createState() => _GuardianRegisterState();
}

class _GuardianRegisterState extends State<GuardianRegister> {
  bool isPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = Map<String, Object>();
  bool isLoading = false;
  bool isRetypePasswordShown = true;
  final TextEditingController _phoneController =
      TextEditingController(text: "+92");

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_phoneController.text.length < 3) {
        _phoneController.text = "+92";
        _phoneController.selection = TextSelection.fromPosition(
            TextPosition(offset: _phoneController.text.length));
      }
    });
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    if (_formData['password'] != _formData['rpassword']) {
      dialogueBox(context, 'Password and retype password should be equal');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Registering...'),
          ],
        ),
      ),
    );

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _formData['gemail'].toString(),
        password: _formData['password'].toString(),
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        final DocumentReference<Map<String, dynamic>> db =
            FirebaseFirestore.instance.collection('users').doc(uid);

        final user = UserModel(
          name: _formData['name'].toString(),
          phone: _formData['phone'].toString(),
          guardianEmail: _formData['gemail'].toString(),
          childEmail: _formData['cemail'].toString(),
          id: uid,
          type: 'guardian',
          isDeleted: false, // Set isDeleted to false upon registration
        );

        final jsonData = user.toJson();
        await db.set(jsonData);

        Navigator.pop(context); // Close the dialog
        goTo(context, UserLoginScreen());
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the dialog
      if (e.code == 'weak-password') {
        dialogueBox(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        dialogueBox(context, 'The account already exists for that email.');
      } else {
        dialogueBox(context, 'Error: ${e.message}');
      }
    } catch (e) {
      Navigator.pop(context); // Close the dialog
      dialogueBox(context, 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffdde6ee),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Register As Guardian",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Image.asset(
                            'assets/images/Account.png',
                            height: 100,
                            width: 100,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(height: 18),
                            CustomTextField(
                              hintText: 'Enter Your Name',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.name,
                              prefix: Icon(Icons.person),
                              onsave: (name) {
                                _formData['name'] = name ?? '';
                              },
                              validate: (name) {
                                if (name!.isEmpty || name.length < 3) {
                                  return 'Enter Correct Name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 18),
                            CustomTextField(
                              controller: _phoneController,
                              hintText: 'Phone Number',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.phone,
                              prefix: Icon(Icons.phone),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\+923[0-9]*')),
                                LengthLimitingTextInputFormatter(13),
                              ],
                              validate: (value) {
                                if (value!.length != 13) {
                                  // +92 followed by 10 digits
                                  return 'Enter a valid phone number (10 digits)';
                                }
                                return null;
                              },
                              onsave: (phone) {
                                _formData['phone'] = phone ?? '';
                              },
                            ),
                            SizedBox(height: 18),
                            CustomTextField(
                              hintText: 'Enter Your Email',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.emailAddress,
                              prefix: Icon(Icons.person),
                              onsave: (gemail) {
                                _formData['gemail'] = gemail ?? '';
                              },
                              validate: (gemail) {
                                if (gemail!.isEmpty ||
                                    gemail.length < 3 ||
                                    !gemail.contains('@')) {
                                  return 'Enter Correct Email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 18),
                            CustomTextField(
                              hintText: 'Enter Child Email',
                              textInputAction: TextInputAction.next,
                              keyboardtype: TextInputType.emailAddress,
                              prefix: Icon(Icons.person),
                              onsave: (cemail) {
                                _formData['cemail'] = cemail ?? '';
                              },
                              validate: (cemail) {
                                if (cemail!.isEmpty ||
                                    cemail.length < 3 ||
                                    !cemail.contains('@')) {
                                  return 'Enter Correct Email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 18),
                            CustomTextField(
                              hintText: 'Enter Password',
                              isPassword: isPasswordShown,
                              prefix: Icon(Icons.vpn_key_rounded),
                              validate: (password) {
                                if (password!.isEmpty || password.length < 8) {
                                  return 'Enter Correct Password';
                                }
                                return null;
                              },
                              onsave: (password) {
                                _formData['password'] = password ?? '';
                              },
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordShown = !isPasswordShown;
                                  });
                                },
                                icon: isPasswordShown
                                    ? Icon(Icons.visibility_off)
                                    : Icon(Icons.visibility),
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '(min 8 characters req)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(height: 18),
                            CustomTextField(
                              hintText: 'Retype Password',
                              isPassword: isRetypePasswordShown,
                              prefix: Icon(Icons.vpn_key_rounded),
                              validate: (password) {
                                if (password!.isEmpty || password.length < 8) {
                                  return 'Enter Correct Password';
                                }
                                return null;
                              },
                              onsave: (password) {
                                _formData['rpassword'] = password ?? '';
                              },
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isRetypePasswordShown =
                                        !isRetypePasswordShown;
                                  });
                                },
                                icon: isRetypePasswordShown
                                    ? Icon(Icons.visibility_off)
                                    : Icon(Icons.visibility),
                              ),
                            ),
                            SizedBox(height: 30),
                            PrimaryButton(
                              title: 'REGISTER',
                              onPressed: _onSubmit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an Account?",
                            style: TextStyle(fontSize: 14),
                          ),
                          SecondaryButton(
                            title: "Click Here",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserLoginScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

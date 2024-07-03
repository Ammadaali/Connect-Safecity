import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/components/SecondryButton.dart';
import 'package:connect_safecity/components/custom_textfeild.dart';
import 'package:connect_safecity/user/UserLogin_Screen.dart';
import 'package:connect_safecity/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect_safecity/Utils/constants.dart';
import 'package:connect_safecity/components/PrimaryButton.dart';
import 'package:flutter/services.dart';

class RegisterUser extends StatefulWidget {
  @override
  State<RegisterUser> createState() => _RegisterUser();
}

class _RegisterUser extends State<RegisterUser> {
  bool isPasswordShown = true;
  bool isRetypePasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = Map<String, Object>();
  bool isLoading = false;
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

  void _onSubmit() async {
    _formKey.currentState!.save();

    if (_formData['password'] != _formData['rpassword']) {
      dialogueBox(context, 'Password and retype password should be equal');
    } else {
      progressIndicator(context);
      try {
        setState(() {
          isLoading = true;
        });

        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _formData['cemail'].toString(),
          password: _formData['password'].toString(),
        );

        if (userCredential.user != null) {
          setState(() {
            isLoading = true;
          });

          final uid = userCredential.user!.uid;
          final userRef =
              FirebaseFirestore.instance.collection('users').doc(uid);

          final user = UserModel(
            name: _formData['name'].toString(),
            phone: _formData['phone'].toString(),
            childEmail: _formData['cemail'].toString(),
            guardianEmail: _formData['gemail'].toString(),
            id: uid,
            type: 'child',
            isDeleted: false,
          );

          await userRef.set(user.toJson()); // Save user data to Firestore

          goTo(context, UserLoginScreen());
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          dialogueBox(context, 'The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          dialogueBox(context, 'The account already exists for that email.');
        }
      } catch (e) {
        dialogueBox(context, 'An error occurred: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
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
              isLoading
                  ? progressIndicator(context)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Register As Child",
                                  style: TextStyle(
                                    fontSize: 35,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
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
                                    hintText: 'Enter Guardian Email',
                                    textInputAction: TextInputAction.next,
                                    keyboardtype: TextInputType.emailAddress,
                                    prefix: Icon(Icons.person),
                                    onsave: (gemail) {
                                      _formData['gemail'] = gemail ?? '';
                                    },
                                    validate: (email) {
                                      if (email!.isEmpty ||
                                          email.length < 3 ||
                                          !email.contains('@')) {
                                        return 'Enter Correct Email';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 18),
                                  CustomTextField(
                                    hintText: 'Enter Password',
                                    isPassword: isPasswordShown,
                                    keyboardtype: TextInputType.visiblePassword,
                                    prefix: Icon(Icons.vpn_key_rounded),
                                    validate: (password) {
                                      if (password!.isEmpty ||
                                          password.length < 8) {
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
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  SizedBox(height: 18),
                                  CustomTextField(
                                    hintText: 'Retype Password',
                                    isPassword: isRetypePasswordShown,
                                    keyboardtype: TextInputType.visiblePassword,
                                    prefix: Icon(Icons.vpn_key_rounded),
                                    validate: (password) {
                                      if (password!.isEmpty ||
                                          password.length < 8) {
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
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _onSubmit();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have Account?",
                                    style: TextStyle(fontSize: 14)),
                                SecondaryButton(
                                  title: "Click Here",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UserLoginScreen()),
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

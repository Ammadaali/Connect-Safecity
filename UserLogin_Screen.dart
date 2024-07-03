import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/Register_Page.dart';
import 'package:connect_safecity/admin/admin_dasboard.dart';
import 'package:connect_safecity/db/share_pref.dart';
import 'package:connect_safecity/forget_pw_page.dart';
import 'package:connect_safecity/guardian/guardian_dashboard.dart';
import 'package:connect_safecity/model/user_model.dart';
import 'package:connect_safecity/user/userForm.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connect_safecity/Utils/constants.dart';
import 'package:connect_safecity/components/PrimaryButton.dart';
import 'package:connect_safecity/components/SecondryButton.dart';
import 'package:connect_safecity/square.tile.dart';
import 'package:connect_safecity/user/user_dashboard.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({Key? key}) : super(key: key);

  @override
  _UserLoginScreenState createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  bool isPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = Map<String, Object>();
  bool isLoading = false;

  // Add error variables
  String? emailError;
  String? passwordError;

  Future<void> _signInWithFacebook(BuildContext context) async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(loginResult.accessToken!.token);

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);
        final User? user = userCredential.user;

        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final userType = userDoc.data()?['type'];
            if (userType == 'child') {
              await MySharedPrefference.setPreferencesString(
                  MySharedPrefference.loginType, "Facebook");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => User_Dashboard()),
              );
            } else if (userType == 'guardian') {
              await MySharedPrefference.setPreferencesString(
                  MySharedPrefference.loginType, "Facebook");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GuardianDashboard()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unknown user type')),
              );
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FormPage()),
            );
          }
        }
      } else if (loginResult.status == LoginStatus.cancelled) {
        Fluttertoast.showToast(
          msg: 'Facebook sign-in was canceled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else if (loginResult.status == LoginStatus.failed) {
        Fluttertoast.showToast(
          msg: 'Failed to sign in with Facebook: ${loginResult.message}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      String errorMessage = 'Error signing in with Facebook: $e';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage =
                'The account already exists with a different credential.';
            break;
          case 'invalid-credential':
            errorMessage = 'The credential is invalid.';
            break;
          case 'operation-not-allowed':
            errorMessage =
                'Operation not allowed. Please enable Facebook login in the Firebase Console.';
            break;
          case 'user-disabled':
            errorMessage = 'The user account has been disabled.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found for this credential.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided.';
            break;
          case 'invalid-verification-code':
            errorMessage = 'The verification code is invalid.';
            break;
          case 'invalid-verification-id':
            errorMessage = 'The verification ID is invalid.';
            break;
          default:
            errorMessage = 'An unknown error occurred.';
        }
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userType = userDoc.data()?['type'];
          if (userType == 'child') {
            await MySharedPrefference.setPreferencesString(
                MySharedPrefference.loginType, "Google");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => User_Dashboard()),
            );
          } else if (userType == 'guardian') {
            await MySharedPrefference.setPreferencesString(
                MySharedPrefference.loginType, "Google");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GuardianDashboard()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unknown user type')),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FormPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'Email already used with another sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'The Google credential is invalid or expired.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for this user.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'The verification code is invalid.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'The verification ID is invalid.';
          break;
        default:
          errorMessage = 'An undefined Error happened.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in with Google: $e')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await MySharedPrefference.setPreferencesBool(
        MySharedPrefference.isLoginDialogShown, false);
    _signInWithGoogle(context);
  }

  Future<void> _handleFacebookSignIn() async {
    await MySharedPrefference.setPreferencesBool(
        MySharedPrefference.isLoginDialogShown, false);
    _signInWithFacebook(context);
  }

  @override
  void initState() {
    super.initState();
  }

  void _onSubmit() async {
    await MySharedPrefference.setPreferencesBool(
        MySharedPrefference.isLoginDialogShown, false);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      emailError = null;
      passwordError = null;
      isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _formData['email'].toString(),
        password: _formData['password'].toString(),
      );

      if (userCredential.user != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userSnapshot.exists) {
          bool isDeleted = (userSnapshot.data() as Map<String, dynamic>)
                  .containsKey('isDeleted')
              ? userSnapshot['isDeleted'] as bool
              : false;

          if (isDeleted) {
            // User is deleted, show message and sign out
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Access Denied'),
                content: Text('You are not allowed to login.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      FirebaseAuth.instance.signOut(); // Sign out the user
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            // User is not deleted, proceed based on user type
            String userType = userSnapshot.get('type');
            await MySharedPrefference.setPreferencesString(
                MySharedPrefference.loginType, "Normal");
            switch (userType) {
              case 'child':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => User_Dashboard()),
                );
                break;
              case 'guardian':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GuardianDashboard()),
                );
                break;
              case 'admin':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Admin_Dashboard()),
                );
                break;
              default:
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Access Denied'),
                    content: Text('Invalid user type. Please contact support.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                          FirebaseAuth.instance.signOut(); // Sign out the user
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
                break;
            }
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Access Denied'),
              content: Text('User document not found.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    FirebaseAuth.instance.signOut(); // Sign out the user
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Authentication Error'),
          content: Text(_getErrorMessage(e.code)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $e'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'User account has been disabled.';
      default:
        return 'Wrong username or password.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffdde6ee),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isLoading
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
                              "User Login",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Image.asset(
                              "assets/images/Account.png",
                              height: 100,
                              width: 100,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Enter Email',
                                  prefixIcon: Icon(Icons.person),
                                  errorText: emailError,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSaved: (email) {
                                  _formData['email'] = email ?? "";
                                },
                                validator: (email) {
                                  if (email == null ||
                                      email.isEmpty ||
                                      email.length < 3 ||
                                      !email.contains("@")) {
                                    return 'Enter correct email';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Enter Password',
                                  prefixIcon: Icon(Icons.vpn_key_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isPasswordShown = !isPasswordShown;
                                      });
                                    },
                                    icon: isPasswordShown
                                        ? Icon(Icons.visibility_off)
                                        : Icon(Icons.visibility),
                                  ),
                                  errorText: passwordError,
                                ),
                                obscureText: isPasswordShown,
                                onSaved: (password) {
                                  _formData['password'] = password ?? "";
                                },
                                validator: (password) {
                                  if (password == null ||
                                      password.isEmpty ||
                                      password.length < 8) {
                                    return 'Enter correct password';
                                  }
                                  return null;
                                },
                              ),
                              PrimaryButton(
                                title: "LOGIN",
                                onPressed: _onSubmit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return forgetpasswordpage();
                                    },
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 2.0,
                              width: 100.0,
                              color: primaryColor,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('or'),
                            ),
                            Container(
                              height: 2.0,
                              width: 100.0,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SquareTile(
                            onTap: _handleGoogleSignIn,
                            imagePath: 'assets/images/googlepic.png',
                          ),
                          SizedBox(width: 25),
                          SquareTile(
                            onTap: _handleFacebookSignIn,
                            imagePath: 'assets/images/facebookpic.png',
                          ),
                        ],
                      ),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create New Account?",
                              style: TextStyle(fontSize: 15),
                            ),
                            SecondaryButton(
                              title: "Click Here",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterPage(),
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
        ),
      ),
    );
  }
}

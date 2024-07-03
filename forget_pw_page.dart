import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect_safecity/Utils/constants.dart';
import 'package:connect_safecity/components/PrimaryButton.dart';
import 'package:connect_safecity/components/custom_textfeild.dart';

class forgetpasswordpage extends StatefulWidget {
  const forgetpasswordpage({Key? key}) : super(key: key);

  @override
  State<forgetpasswordpage> createState() => _forgetpasswordpageState();
}

class _forgetpasswordpageState extends State<forgetpasswordpage> {
  final _emailcontroller = TextEditingController();

  @override
  void dispose() {
    _emailcontroller.dispose();
    super.dispose();
  }

  Future passwordreset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailcontroller.text.trim());
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Text('Password reset link sent...! check your email'));
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(e.message.toString()),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Change Password',
      body: Center(
        // Center widget to center the content
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content vertically
            children: [
              Text(
                'Enter your Email, and we will send you a password reset link',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailcontroller,
                hintText: 'Enter Your Email',
                textInputAction: TextInputAction.next,
                keyboardtype: TextInputType.emailAddress,
                prefix: Icon(Icons.person),
                // Add the rest of your CustomTextField properties here
              ),
              // You can add more widgets here if needed
              const SizedBox(height: 20),
              PrimaryButton(title: 'Reset Password', onPressed: passwordreset),
            ],
          ),
        ),
      ),
    );
  }
}

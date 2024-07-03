import 'package:connect_safecity/guardian/guardian_register.dart';
import 'package:connect_safecity/user/register_user.dart';
import 'package:flutter/material.dart';
import 'package:connect_safecity/components/Main3Buttons.dart';

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Color(0xFF273B7A),
          ),
          ClipPath(
            clipper: MyClipper(),
            child: Container(
              color: Color(0xFFDDE6EE),
            ),
          ),
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: <Widget>[
                  ClipOval(
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 100,
                      width: 100,
                    ),
                  ),
                  SizedBox(height: 120), // Add some spacing
                  Main3Buttons(
                      title: 'Register As Child',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterUser()));
                      }),

                  SizedBox(height: 30), // Add some spacing
                  Main3Buttons(
                      title: 'Register As Guardian',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GuardianRegister()));
                      }),
                  SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
          // Add the text at the top with white color and padding
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Text(
              'Register New Account',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.18);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.65,
      size.width,
      size.height * 0.18,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

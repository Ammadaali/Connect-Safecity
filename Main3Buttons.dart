import 'package:flutter/material.dart';

class Main3Buttons extends StatelessWidget {
  final String title;
  final Function onPressed;
  final bool loading;
  Main3Buttons(
      {required this.title, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 20), // Add 20 units of padding from left and right
      child: Container(
        height: 60,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            onPressed();
          },
          child: Text(
            title,
            style: TextStyle(
                fontSize: 18,
                color: Color(0xFF273B7A)), // Set text color to dark blue
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Color(0xFF273B7A),
            backgroundColor: Color(0xFFDDE6EE), // Set text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Color(0xFF273B7A)), // Set border color
            ),
            elevation: 0, // Remove elevation (shadow)
          ),
        ),
      ),
    );
  }
}

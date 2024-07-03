import 'package:connect_safecity/admin/GuardianList%20Screen.dart';
import 'package:connect_safecity/admin/UsersDetails.dart';
import 'package:connect_safecity/admin/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:connect_safecity/admin/Sliderslist.dart';
import 'package:connect_safecity/components/Main3Buttons.dart';
import 'package:flutter/services.dart';

class Admin_Dashboard extends StatefulWidget {
  const Admin_Dashboard({super.key});

  @override
  State<Admin_Dashboard> createState() => _Admin_DashboardState();
}

class _Admin_DashboardState extends State<Admin_Dashboard> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Minimize the app to the home screen instead of logging out
        await SystemNavigator.pop(); // Close the app

        return true; // Return true to prevent exiting the app immediately
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Color.fromARGB(255, 39, 59, 122),
          iconTheme:
              IconThemeData(color: Colors.white), // Set the icon color to white
        ),
        drawer: AdminDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 0), // Add some spacing
              Main3Buttons(
                  title: 'User Detail',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UsersDetails()));
                  }),

              SizedBox(height: 30), // Add some spacing
              Main3Buttons(
                  title: 'Guardian Detail',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GuardianListScreen()));
                  }),
              SizedBox(height: 30), // Add some spacing
              Main3Buttons(
                  title: 'View Slider Content',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Sliderslist()));
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

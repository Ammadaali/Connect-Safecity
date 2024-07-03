import 'package:connect_safecity/user/Community/communityFeedPage.dart';
import 'package:flutter/material.dart';

class communityFeed extends StatelessWidget {
  showModelSafeHome(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height / 1.4,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 245, 250, 255),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => communityFeedPage()),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Card(
            elevation: 4,
            child: Container(
              height: 270,
              color: Color.fromARGB(255, 216, 236, 255),
              width: MediaQuery.of(context).size.width * 0.7,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Community Feed",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Stay Informed With Community Updates",
                      style: TextStyle(fontSize: 16),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/feed.png',
                        height: 150,
                        width: 150,
                      ),
                    ), // Add spacing if necessary
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

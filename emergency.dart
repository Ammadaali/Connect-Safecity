import 'package:connect_safecity/user/Emergencies/ambulanceemergency.dart';
import 'package:connect_safecity/user/Emergencies/policeemergency.dart';
import 'package:flutter/material.dart';

import 'firebrigadeemergency.dart';

class Emergency extends StatelessWidget {
  const Emergency({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          policeEmergency(),
          ambulanceemergency(),
          fireBrigadeEmergency(),
        ],
      ),
    );
  }
}

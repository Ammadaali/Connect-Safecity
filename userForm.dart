import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect_safecity/guardian/guardian_dashboard.dart';
import 'package:connect_safecity/user/user_dashboard.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: FormPage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelStyle: TextStyle(color: Colors.black54),
      ),
    ),
  ));
}

class FormPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Your Account',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        automaticallyImplyLeading: false, // Remove back button
        centerTitle: true, // Center the title
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16.0), // Text color
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChildForm()),
                  );
                },
                child: Text('Login as Child'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16.0), // Text color
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GuardianForm()),
                  );
                },
                child: Text('Login as Guardian'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChildForm extends StatefulWidget {
  @override
  _ChildFormState createState() => _ChildFormState();
}

class _ChildFormState extends State<ChildForm> {
  final GlobalKey<FormState> _childFormKey = GlobalKey<FormState>();
  String? userName;
  String? guardianEmail;
  String? phone;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Child Form', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _childFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 50,
                ),
                Text(
                  'Please fill in the details below:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty || value.length < 3) {
                      return 'Enter a valid name (at least 3 characters)';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    userName = value;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Guardian Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty || !value.contains("@")) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    guardianEmail = value;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Number must start with 3',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\+923[0-9]*')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  validator: (value) {
                    if (value!.length != 13) {
                      // +92 followed by 10 digits
                      return 'Enter a valid phone number (10 digits)';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    phone = value;
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16.0), // Text color
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    if (_childFormKey.currentState!.validate()) {
                      _childFormKey.currentState!.save();
                      _createChildDocument(userName, guardianEmail, phone);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => User_Dashboard(),
                        ),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuardianForm extends StatefulWidget {
  @override
  _GuardianFormState createState() => _GuardianFormState();
}

class _GuardianFormState extends State<GuardianForm> {
  final GlobalKey<FormState> _guardianFormKey = GlobalKey<FormState>();
  String? guardianName;
  String? childEmail;
  String? phone;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Guardian Form', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _guardianFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 50,
                ),
                Text(
                  'Please fill in the details below:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty || value.length < 3) {
                      return 'Enter a valid name (at least 3 characters)';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    guardianName = value;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Child Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty || !value.contains("@")) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    childEmail = value;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Number must start with 3',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\+923[0-9]*')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  validator: (value) {
                    if (value!.length != 13) {
                      // +92 followed by 10 digits
                      return 'Enter a valid phone number (10 digits)';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    phone = value;
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16.0), // Text color
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    if (_guardianFormKey.currentState!.validate()) {
                      _guardianFormKey.currentState!.save();
                      _createGuardianDocument(guardianName, childEmail, phone);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GuardianDashboard(),
                        ),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _createChildDocument(
    String? name, String? guardiantEmail, String? phone) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('User not logged in');
      return;
    }
    final uid = currentUser.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final userData = {
      'name': name ?? "",
      'childEmail': currentUser.email ?? "",
      'guardiantEmail': guardiantEmail ?? "",
      'phone': phone ?? "",
      'type': 'child',
      'isDeleted': false,
    };

    await userRef.set(userData);
  } catch (e) {
    print('Error creating user document: $e');
  }
}

void _createGuardianDocument(
    String? name, String? childEmail, String? phone) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('User not logged in');
      return;
    }
    final uid = currentUser.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final userData = {
      'name': name ?? "",
      'childEmail': childEmail ?? "",
      'guardiantEmail': currentUser.email ?? "",
      'phone': phone ?? "",
      'type': 'guardian',
      'isDeleted': false,
    };

    await userRef.set(userData);
  } catch (e) {
    print('Error creating guardian document: $e');
  }
}

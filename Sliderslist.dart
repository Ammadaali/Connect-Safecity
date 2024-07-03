import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/admin/add_NewSlider.dart';
import 'package:connect_safecity/admin/SliderDetail.dart';
import 'package:connect_safecity/admin/edit_slider.dart';

class Sliderslist extends StatefulWidget {
  Sliderslist({Key? key}) : super(key: key);

  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('images');

  late Stream<QuerySnapshot> _stream;

  @override
  State<Sliderslist> createState() => _SliderslistState();
}

class _SliderslistState extends State<Sliderslist> {
  @override
  void initState() {
    super.initState();
    widget._stream = widget._reference.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Slider Content',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        iconTheme:
            IconThemeData(color: Colors.white), // Set the icon color to white
        actions: [
          // Add New Slider Button
          IconButton(
            icon: Icon(Icons.add,
                color: Colors.white), // Set the icon color to white
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const addNewSlider()),
              );
              // Add your logic to navigate to the page for adding a new slider
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 30.0), // Adjust the top padding here
        child: StreamBuilder<QuerySnapshot>(
          stream: widget._stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Some Error Occurred ${snapshot.error}'),
              );
            }

            if (snapshot.hasData) {
              QuerySnapshot querySnapshot = snapshot.data!;
              List<QueryDocumentSnapshot> documents = querySnapshot.docs;

              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (BuildContext context, int index) {
                  QueryDocumentSnapshot document = documents[index];
                  Map<String, dynamic> thisItem =
                      document.data() as Map<String, dynamic>;

                  return Column(
                    children: [
                      ListTile(
                        title: Text('${thisItem['name']}'),
                        leading: Container(
                          height: 80,
                          width: 80,
                          child: thisItem.containsKey('image')
                              ? Image.network('${thisItem['image']}')
                              : Container(),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: Colors
                                      .blue), // Set the icon color to white
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      editslider(thisItem, document.id),
                                ));
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors
                                      .red), // Set the icon color to white
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors
                                          .red, // Set background color to white
                                      title: Text(
                                        'Delete Content',
                                        style: TextStyle(
                                            color: Colors
                                                .white), // Set text color to black
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this content?',
                                        style: TextStyle(
                                            color: Colors
                                                .white), // Set text color to black
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                                color: Colors
                                                    .white), // Set text color to black
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            widget._reference
                                                .doc(document.id)
                                                .delete();
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Yes',
                                            style: TextStyle(
                                                color: Colors
                                                    .white), // Set text color to black
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SliderDetail(document.id),
                          ));
                        },
                      ),
                      Divider(),
                    ],
                  );
                },
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

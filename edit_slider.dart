import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/components/CustomScaffold.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';

class editslider extends StatefulWidget {
  final Map<String, dynamic> _content;
  final String documentId;

  editslider(this._content, this.documentId, {Key? key}) : super(key: key);

  @override
  _editsliderState createState() => _editsliderState();
}

class _editsliderState extends State<editslider> {
  late DocumentReference _reference;
  String imageUrl = '';
  late TextEditingController _controllerTitle;
  late TextEditingController _controllerDescription;
  GlobalKey<FormState> _key = GlobalKey();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controllerTitle = TextEditingController(text: widget._content['name']);
    _controllerDescription =
        TextEditingController(text: widget._content['description']);
    _reference =
        FirebaseFirestore.instance.collection('images').doc(widget.documentId);
    imageUrl = widget._content['image']; // Set imageUrl initially
  }

  // Function to update slider data in Firestore
  Future<void> _updateSlider() async {
    try {
      // Update the Firestore document with the new data
      await _reference.update({
        'name': _controllerTitle.text,
        'description': _controllerDescription.text,
        'image': imageUrl,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slider updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (error) {
      // Handle errors
      print('Error updating slider: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Edit Slider',
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _controllerTitle,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextFormField(
                  controller: _controllerDescription,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 4,
                ),
                SizedBox(height: 20),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                else if (imageUrl.isNotEmpty)
                  Center(
                    child: Column(
                      children: [
                        Image.network(
                          imageUrl,
                          height: 100,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 20),
                        IconButton(
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });

                            ImagePicker imagePicker = ImagePicker();
                            XFile? file = await imagePicker.pickImage(
                              source: ImageSource.gallery,
                            );

                            if (file == null) {
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            String uniqueFileName = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();

                            Reference referenceImageToUpload = FirebaseStorage
                                .instance
                                .ref()
                                .child('images/$uniqueFileName');

                            try {
                              await referenceImageToUpload
                                  .putFile(File(file.path));
                              imageUrl =
                                  await referenceImageToUpload.getDownloadURL();
                            } catch (error) {
                              print(error);
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                          icon: Icon(Icons.camera_alt),
                        ),
                        SizedBox(height: 20),
                        CustomElevatedButton(
                          onPressed: () async {
                            // Call the function to update the slider
                            await _updateSlider();
                          },
                          text: 'Submit',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

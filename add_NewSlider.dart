import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connect_safecity/components/customelevatedbutton.dart';
import 'package:connect_safecity/components/CustomScaffold.dart';

class addNewSlider extends StatefulWidget {
  const addNewSlider({super.key});

  @override
  State<addNewSlider> createState() => _addNewSlider();
}

class _addNewSlider extends State<addNewSlider> {
  String? imageUrl;
  TextEditingController _controllerName = TextEditingController();
  TextEditingController _controllerDescription = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Add New Slider',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
              ),
              TextField(
                controller: _controllerName,
                decoration: InputDecoration(labelText: "Image Title"),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _controllerDescription,
                decoration: InputDecoration(labelText: "Image Description"),
                maxLines: 4,
              ),
              SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (isLoading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
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

                  String uniqueFileName =
                      DateTime.now().millisecondsSinceEpoch.toString();

                  Reference referenceImageToUpload = FirebaseStorage.instance
                      .ref()
                      .child('images/$uniqueFileName');

                  try {
                    await referenceImageToUpload.putFile(File(file.path));
                    imageUrl = await referenceImageToUpload.getDownloadURL();
                  } catch (error) {
                    print(error);
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                child: Text('Select Image'),
              ),
              SizedBox(height: 26),
              CustomElevatedButton(
                onPressed: () async {
                  if (imageUrl == null || imageUrl!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please upload an image')),
                    );
                  } else {
                    String imageName = _controllerName.text;
                    String imageDescription = _controllerDescription.text;

                    Map<String, dynamic> dataToSend = {
                      'name': imageName,
                      'description': imageDescription,
                      'image': imageUrl!,
                    };

                    FirebaseFirestore.instance
                        .collection('images')
                        .add(dataToSend);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submitted Successfully')),
                    );

                    await Future.delayed(Duration(seconds: 2));
                    Navigator.pop(context);
                  }
                },
                text: 'Submit',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

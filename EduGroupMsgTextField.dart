import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_safecity/Utils/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connect_safecity/notification_service.dart';

class EduGroupMessageTextField extends StatefulWidget {
  final String currentUserName;
  final String currentUserId;
  final String groupId;

  const EduGroupMessageTextField({
    Key? key,
    required this.currentUserName,
    required this.currentUserId,
    required this.groupId,
    //required String currentId,
  }) : super(key: key);

  @override
  _EduGroupMessageTextFieldState createState() =>
      _EduGroupMessageTextFieldState();
}

class _EduGroupMessageTextFieldState extends State<EduGroupMessageTextField> {
  TextEditingController _controller = TextEditingController();
  Position? _currentPosition;
  String? _currentAddress;
  String? message;
  File? imageFile;
  File? videoFile;
  final picker = ImagePicker();
  PlatformFile? selectedFiles;
  UploadTask? uploadTask;
  LocationPermission? permission;
  late String _recordFilePath;
  late bool _isRecording;
  late Timer _timer; // Timer variable
  int _secondsElapsed = 0; // Variable to track elapsed seconds
  String _timerText = '00:00'; // Variable to display elapsed time

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _isRecording = false;
    _recordFilePath = '';
    _timerText = '00:00'; // Initialize _timerText
  }

  Future<void> _startRecording() async {
    bool hasPermission = await _checkPermission();
    if (hasPermission) {
      _recordFilePath = await _getFilePath();
      bool result = await RecordMp3.instance.start(_recordFilePath, (type) {
        setState(() {});
      });
      if (result) {
        setState(() {
          _isRecording = true;
          _startTimer(); // Start the timer when recording starts
          Fluttertoast.showToast(msg: "Recording started");
        });
      }
    } else {
      Fluttertoast.showToast(msg: "Permission denied for recording.");
    }
  }

  Future<void> _stopRecording() async {
    bool stop = await RecordMp3.instance.stop();
    if (stop) {
      setState(() {
        _isRecording = false;
        _stopTimer(); // Stop the timer when recording stops
        Fluttertoast.showToast(msg: "Sending Recording");
      });
      await _uploadAudio(); // Upload the audio
    }
  }

// Function to start the timer
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++; // Increment elapsed seconds
        _updateTimerUI(); // Update UI with elapsed time
      });
    });
  }

// Function to stop the timer
  void _stopTimer() {
    _timer.cancel(); // Cancel the timer
    setState(() {
      _secondsElapsed = 0; // Reset elapsed seconds
    });
  }

// Function to update the UI with elapsed time
  void _updateTimerUI() {
    // Calculate minutes and seconds from _secondsElapsed
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    // Update the UI with the elapsed time
    setState(() {
      _timerText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  Future<bool> _checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<String> _getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String uniqueFileName =
        "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}.mp3";
    String filePath = "${storageDirectory.path}/$uniqueFileName";
    return filePath;
  }

  Future<void> _uploadAudio() async {
    try {
      if (_recordFilePath.isNotEmpty) {
        File audioFile = File(_recordFilePath);
        if (audioFile.existsSync()) {
          String uniqueFileName = Uuid().v1(); // Generate a unique UUID
          String fileName = '$uniqueFileName.mp3'; // Append ".mp3" extension
          Reference firebaseStorageRef =
              FirebaseStorage.instance.ref().child('Audio/$fileName');
          await firebaseStorageRef.putFile(audioFile);
          String downloadUrl = await firebaseStorageRef.getDownloadURL();
          await sendGroupMessage(downloadUrl, 'audio'); // Send audio message
        } else {
          Fluttertoast.showToast(msg: "Audio file does not exist.");
        }
      } else {
        Fluttertoast.showToast(msg: "Recorded file path is empty.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to upload audio: $e");
    }
  }

  Future getImage() async {
    ImagePicker _picker = ImagePicker();
    await _picker.pickImage(source: ImageSource.gallery).then((XFile? xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future getImageFromCamera() async {
    ImagePicker _picker = ImagePicker();
    await _picker.pickImage(source: ImageSource.camera).then((XFile? xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = Uuid().v1();
    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");
    var uploadTask = await ref.putFile(imageFile!);
    String imageUrl = await uploadTask.ref.getDownloadURL();
    await sendGroupMessage(imageUrl, 'img');
  }

  Future getVideoFromGallery() async {
    final XFile? pickedFile =
        await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        videoFile = File(pickedFile.path);
      });
      _uploadVideo();
    }
  }

  Future getVideoFromCamera() async {
    final XFile? pickedFile =
        await picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        videoFile = File(pickedFile.path);
      });
      _uploadVideo();
    }
  }

  Future<void> _uploadVideo() async {
    try {
      if (videoFile != null) {
        String fileName = Uuid().v1();
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('videos')
            .child('$fileName.mp4');
        UploadTask uploadTask = ref.putFile(videoFile!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        await sendGroupMessage(downloadUrl, 'video');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to upload video: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        Fluttertoast.showToast(msg: "Location permissions are denied");
        if (permission == LocationPermission.deniedForever) {
          Fluttertoast.showToast(
              msg: "Location permissions are permanently denied");
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _getAddressFromLatLon();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            "${place.locality},${place.postalCode},${place.street},";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<String> getReceiverFCMToken(String receiverId) async {
    try {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (userSnapshot.exists) {
        var fcmToken = userSnapshot.get('fcmToken');
        return fcmToken?.toString() ??
            ''; // Use null-aware operator and handle null
      } else {
        print('User not found with ID: $receiverId');
        return '';
      }
    } catch (e) {
      print('Error retrieving FCM token: $e');
      return '';
    }
  }

  sendGroupMessage(String message, String type) async {
    try {
      if (type != 'text' && type != 'audio') {
        Navigator.pop(context);
      }

      await FirebaseFirestore.instance
          .collection('EducationalGroup')
          .doc('2YYgBG7alKFeFVRSXYRf')
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'senderName': widget.currentUserName, // Include sender's name
        'message': message,
        'type': type,
        'date': DateTime.now(),
      });
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  Future pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files.first;
      });

      uploadDocument();
    }
  }

  Future<void> uploadDocument() async {
    try {
      final path = 'Documents/${selectedFiles!.name}';
      final file = File(selectedFiles!.path!);

      final ref = FirebaseStorage.instance.ref().child(path);
      uploadTask = ref.putFile(file);

      await uploadTask!.whenComplete(() {});

      final urlDownload = await ref.getDownloadURL();
      print('Download Link: $urlDownload');

      // Send the document link in the chat
      await sendGroupMessage(urlDownload, 'document');
    } catch (e) {
      print('Error uploading document: $e');
    }
  }

  void _openImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close the dialog when tapped
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(imageUrl),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildImageWidget(String imageUrl) {
    return GestureDetector(
      onTap: () {
        _openImageDialog(imageUrl);
      },
      child: Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget chatsIcon(
      IconData icons, String title, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor,
            child: Icon(icons, color: iconColor),
          ),
          Text("$title")
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                cursorColor: Colors.blue,
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'type your message',
                  fillColor: Colors.grey[100],
                  filled: true,
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            backgroundColor:
                                const Color.fromARGB(0, 255, 255, 255),
                            context: context,
                            builder: (context) => bottomsheet(),
                          );
                        },
                        icon: Icon(
                          Icons.add_box_rounded,
                          color: Color.fromARGB(255, 39, 59, 122),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isRecording
                              ? Text(
                                  _timerText,
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 39, 59, 122)),
                                )
                              : SizedBox(), // Placeholder to maintain the layout when timer is not shown
                          IconButton(
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: _isRecording
                                  ? Colors.red
                                  : const Color.fromARGB(255, 39, 59, 122),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () async {
                  String? message = _controller.text;
                  if (message != null && message.isNotEmpty) {
                    await sendGroupMessage(message, 'text');
                    _controller.clear();
                  }
                },
                child: Icon(
                  Icons.send,
                  color: Color.fromARGB(255, 39, 59, 122),
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomsheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Color(0xFFDDE6EE),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  chatsIcon(
                    Icons.location_pin,
                    "Location",
                    () async {
                      Navigator.pop(context); // Close the bottom sheet
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Sending location..."),
                            ],
                          ),
                        ),
                      );
                      await _getCurrentLocation();
                      String message =
                          "https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude}%2C${_currentPosition!.longitude}";
                      await sendGroupMessage(message, "link");
                    },
                    Colors.white,
                  ),
                  chatsIcon(
                    Icons.camera_alt,
                    "Camera",
                    () async {
                      Navigator.pop(context); // Close the bottom sheet
                      await getImageFromCamera();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Sending photo..."),
                            ],
                          ),
                        ),
                      );
                    },
                    Colors.white,
                  ),
                  chatsIcon(
                    Icons.insert_photo,
                    "Photo",
                    () async {
                      Navigator.pop(context); // Close the bottom sheet
                      await getImage();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Sending photo..."),
                            ],
                          ),
                        ),
                      );
                    },
                    Colors.white,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  chatsIcon(
                    Icons.video_collection,
                    "Video Gallery",
                    () async {
                      Navigator.pop(context); // Close the bottom sheet
                      await getVideoFromGallery();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Sending video..."),
                            ],
                          ),
                        ),
                      );
                    },
                    Colors.white,
                  ),
                  chatsIcon(
                    Icons.videocam,
                    "Camera Video",
                    () async {
                      Navigator.pop(context); // Close the bottom sheet
                      await getVideoFromCamera();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Sending video..."),
                            ],
                          ),
                        ),
                      );
                    },
                    Colors.white,
                  ),
                  chatsIcon(
                    Icons.file_copy,
                    "Document",
                    () async {
                      Navigator.pop(context); // Close the bottom sheet
                      await pickDocument();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) => AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Sending document..."),
                            ],
                          ),
                        ),
                      );
                    },
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

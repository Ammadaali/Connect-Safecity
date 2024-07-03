import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:uuid/uuid.dart';

class VoiceChat extends StatefulWidget {
  @override
  _VoiceChatState createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> {
  late String recordFilePath;
  bool isRecording = false;
  late Timer _timer;
  int _start = 0;

  @override
  void initState() {
    super.initState();
    checkPermission(); // Checking permission on init
  }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      recordFilePath = await getFilePath();
      RecordMp3.instance.start(recordFilePath, (type) {
        setState(() {});
      });
      setState(() {
        isRecording = true;
        _startTimer();
      });
    } else {
      Fluttertoast.showToast(msg: "Permission denied for recording.");
    }
  }

  void stopRecord() async {
    bool stop = RecordMp3.instance.stop();
    if (stop) {
      // Do something after stopping the recording
      _stopTimer();
      setState(() {
        isRecording = false;
      });
      uploadAudio();
    }
  }

  Future<void> uploadAudio() async {
    try {
      if (recordFilePath.isNotEmpty) {
        File audioFile = File(recordFilePath);
        if (audioFile.existsSync()) {
          // Generate a unique filename using UUID
          String fileName = Uuid().v4();
          Reference firebaseStorageRef =
              FirebaseStorage.instance.ref().child('Audio/$fileName.mp3');
          await firebaseStorageRef.putFile(audioFile);
          Fluttertoast.showToast(msg: "Audio uploaded successfully.");
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

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _start++;
      });
    });
  }

  void _stopTimer() {
    _timer.cancel();
    _start = 0;
  }

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath =
        "${storageDirectory.path}/record${DateTime.now().microsecondsSinceEpoch}.acc";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test.mp3";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Chat"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            isRecording
                ? Column(
                    children: [
                      Text(
                        'Recording: $_start seconds',
                        style: TextStyle(fontSize: 20),
                      ),
                      ElevatedButton(
                        onPressed: stopRecord,
                        child: Text('Stop Recording'),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: startRecord,
                    icon: Icon(Icons.mic),
                    label: Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

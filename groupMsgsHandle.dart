import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class FullScreenVideo extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideo({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _FullScreenVideoState createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  late VideoPlayerController _controller;
  late bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isPlaying = true;
        });
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _replayVideo() {
    _controller.seekTo(Duration.zero);
    _controller.play();
    setState(() {
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: _controller.value.isInitialized
            ? Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay, color: Colors.white),
                        onPressed: _replayVideo,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ],
                  ),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 39, 59, 122),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        backgroundDecoration: BoxDecoration(color: Colors.white),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}

class GroupMessage extends StatefulWidget {
  final String? message;
  final bool? isMe;
  final String? image;
  final String? type;
  final String? senderName;
  final String? myName;
  final dynamic date;
  final VoidCallback onDelete;

  const GroupMessage({
    Key? key,
    this.message,
    this.isMe,
    this.image,
    this.type,
    this.senderName,
    this.myName,
    this.date,
    required this.onDelete,
  }) : super(key: key);

  @override
  _GroupMessageState createState() => _GroupMessageState();
}

class _GroupMessageState extends State<GroupMessage> {
  late AudioPlayer _player;
  late ConcatenatingAudioSource _audioSource;
  late bool _isPlaying;
  late double _sliderValue;
  late Duration _duration;
  late Duration _position;
  late StreamSubscription<PlayerState> _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _audioSource = ConcatenatingAudioSource(children: [
      AudioSource.uri(Uri.parse(widget.message!)),
    ]);
    _isPlaying = false;
    _sliderValue = 0.0;
    _duration = Duration();
    _position = Duration();

    _initializePlayer();
    _listenToPlayerState();
    _listenToDuration();
    _listenToPosition();
  }

  Future<void> _initializePlayer() async {
    await _player.setAudioSource(_audioSource);
    _duration = await _player.duration ?? Duration.zero;
    setState(() {
      _sliderValue = 0.0; // Ensure the slider starts at the beginning
    });
  }

  void _listenToPlayerState() {
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed ||
          playerState.processingState == ProcessingState.idle) {
        setState(() {
          _isPlaying = false;
          _sliderValue = 0.0; // Reset the slider value
          _position = Duration.zero; // Reset the position
        });
      } else {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
    });
  }

  void _listenToDuration() {
    _player.durationStream.listen((duration) {
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });
  }

  void _listenToPosition() {
    _player.positionStream.listen((position) {
      setState(() {
        _position = position ?? Duration.zero;
        if (!_isPlaying) {
          _sliderValue = 0.0;
        } else {
          _sliderValue = _position.inSeconds.toDouble();
        }
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _playerStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _playOrStopAudio() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _listenPlayerState(PlayerState playerState) {
    setState(() {
      _isPlaying =
          playerState.playing; // Update _isPlaying based on player state
      if (!_isPlaying) {
        // Reset slider value and position when audio stops
        _sliderValue = 0.0;
        _position = Duration.zero;
      }
    });
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                widget
                    .onDelete(); // Trigger the onDelete callback to delete the message
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _openImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.7,
            child: PhotoViewGallery.builder(
              itemCount: 1,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrl),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
              pageController: PageController(),
            ),
          ),
        );
      },
    );
  }

  Widget buildImageWidget(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(imageUrl: imageUrl),
          ),
        );
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        height: MediaQuery.of(context).size.height / 3.62,
        width: MediaQuery.of(context).size.width,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    );
  }

  Widget buildVideoWidget(BuildContext context, String videoUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideo(videoUrl: videoUrl),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 200, // Set a fixed height for the thumbnail
            color: Colors.black, // Display a black container while loading
          ),
          Icon(Icons.play_arrow,
              size: 50, color: Colors.white), // Play button icon
        ],
      ),
    );
  }

  Widget buildDocumentWidget(BuildContext context, String documentUrl) {
    // Extract the file name from the document URL
    String fileName =
        Uri.decodeFull(documentUrl.split('/').last.split('?').first);
    // Extract only the file name without the directory path
    fileName = fileName.split('/').last;

    // Determine the document icon based on its file type
    IconData iconData;
    if (fileName.toLowerCase().endsWith('.pdf')) {
      iconData = Icons.picture_as_pdf;
    } else if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      iconData = Icons.description;
    } else {
      iconData = Icons.insert_drive_file; // Default icon for other file types
    }

    return GestureDetector(
      onTap: () async {
        try {
          // Get the temporary directory
          Directory tempDir = await getTemporaryDirectory();
          // Define the file path for the downloaded document
          String filePath = '${tempDir.path}/$fileName';
          // Create a file object with the file path
          File file = File(filePath);

          // Check if the file exists locally, if not, download it
          if (!await file.exists()) {
            // Download the document from the URL
            var response = await http.get(Uri.parse(documentUrl));
            // Write the document content to the file
            await file.writeAsBytes(response.bodyBytes);
          }

          // Open the document using the open_file package
          await OpenFile.open(filePath);
        } catch (e) {
          print("Error opening document: $e");
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width / 2,
        ),
        alignment: widget.isMe! ? Alignment.centerRight : Alignment.centerLeft,
        padding: EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isMe!
                ? const Color.fromARGB(255, 39, 59, 122)
                : const Color(0xFFDDE6EE),
            borderRadius: widget.isMe!
                ? BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  )
                : BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
          ),
          padding: EdgeInsets.all(10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width / 1.5,
          ),
          alignment:
              widget.isMe! ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                iconData,
                size: 24,
                color: Colors.red, // You can customize the icon color
              ),
              SizedBox(width: 8),
              Expanded(
                // Wrap the Row with Expanded
                child: Text(
                  "$fileName",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: widget.isMe!
                        ? Colors.white
                        : Colors.black, // You can customize the text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    DateTime? messageDate;
    if (widget.date is Timestamp) {
      messageDate = widget.date.toDate(); // Convert Timestamp to DateTime
    } else if (widget.date is DateTime) {
      messageDate = widget.date; // Already a DateTime
    }

    if (messageDate == null) {
      // Handle the case when date is neither Timestamp nor DateTime
      return Container(); // Replace with your error handling or fallback
    }

    String cdate = "${messageDate.hour}:${messageDate.minute}";
    return GestureDetector(
      onLongPress: () {
        // Show the delete message dialog on long-press
        _showDeleteDialog(context);
      },
      child: widget.type == 'video'
          ? Container(
              constraints: BoxConstraints(
                maxWidth: size.width / 2,
              ),
              alignment:
                  widget.isMe! ? Alignment.centerRight : Alignment.centerLeft,
              padding: EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isMe!
                      ? const Color.fromARGB(255, 39, 59, 122)
                      : const Color(0xFFDDE6EE),
                  borderRadius: widget.isMe!
                      ? BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        )
                      : BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                ),
                padding: EdgeInsets.all(10),
                constraints: BoxConstraints(
                  maxWidth: size.width / 1.5,
                ),
                alignment:
                    widget.isMe! ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  children: [
                    buildVideoWidget(context, widget.message!),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        widget.senderName!,
                        style: TextStyle(
                            fontSize: 15,
                            color: const Color.fromARGB(255, 124, 124, 124)),
                      ),
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        cdate,
                        style: TextStyle(
                            fontSize: 15,
                            color: const Color.fromARGB(255, 124, 124, 124)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : widget.type == 'audio'
              ? Container(
                  constraints: BoxConstraints(
                    maxWidth: size.width / 2,
                  ),
                  alignment: widget.isMe!
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isMe!
                          ? const Color.fromARGB(255, 39, 59, 122)
                          : const Color(0xFFDDE6EE),
                      borderRadius: widget.isMe!
                          ? BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            )
                          : BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                    ),
                    padding: EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxWidth: size.width / 1.5,
                    ),
                    alignment: widget.isMe!
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Column(
                      children: [
                        Align(
                          alignment: widget.isMe!
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(
                            widget.senderName!,
                            style: TextStyle(
                                fontSize: 15,
                                color:
                                    const Color.fromARGB(255, 124, 124, 124)),
                          ),
                        ),
                        SizedBox(height: 10),
                        IconButton(
                          icon:
                              Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () => _playOrStopAudio(),
                          color: widget.isMe! ? Colors.white : Colors.black,
                        ),
                        if (_duration.inSeconds > 0)
                          Slider(
                            value: _sliderValue,
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                _sliderValue = value;
                              });
                              _player.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        Text(
                          '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  widget.isMe! ? Colors.white : Colors.black),
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: widget.isMe!
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(
                            cdate,
                            style: TextStyle(
                                fontSize: 15,
                                color:
                                    const Color.fromARGB(255, 124, 124, 124)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : widget.type == 'text'
                  ? Container(
                      constraints: BoxConstraints(
                        maxWidth: size.width / 2,
                      ),
                      alignment: widget.isMe!
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      padding: EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.isMe!
                              ? const Color.fromARGB(255, 39, 59, 122)
                              : const Color(0xFFDDE6EE),
                          borderRadius: widget.isMe!
                              ? BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                )
                              : BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                        ),
                        padding: EdgeInsets.all(10),
                        constraints: BoxConstraints(
                          maxWidth: size.width / 1.5,
                        ),
                        alignment: widget.isMe!
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          children: [
                            Align(
                              alignment: widget.isMe!
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                widget.senderName!,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: const Color.fromARGB(
                                        255, 124, 124, 124)),
                              ),
                            ),
                            SizedBox(height: 10),
                            Align(
                              alignment: widget.isMe!
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                widget.message!,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: widget.isMe!
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            SizedBox(height: 10),
                            Align(
                              alignment: widget.isMe!
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                cdate,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: const Color.fromARGB(
                                        255, 124, 124, 124)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : widget.type == 'img'
                      ? Container(
                          height: size.height / 2.4,
                          width: size.width,
                          alignment: widget.isMe!
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          padding: EdgeInsets.all(10),
                          child: Container(
                            height: size.height / 2.5,
                            width: size.width,
                            decoration: BoxDecoration(
                              color: widget.isMe!
                                  ? const Color.fromARGB(255, 157, 211, 255)
                                  : Colors.white,
                              borderRadius: widget.isMe!
                                  ? BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                      bottomLeft: Radius.circular(15),
                                    )
                                  : BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: size.width / 1.4,
                            ),
                            alignment: widget.isMe!
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    widget.isMe!
                                        ? widget.myName!
                                        : widget.senderName!,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: const Color.fromARGB(
                                            255, 124, 124, 124)),
                                  ),
                                ),
                                Divider(),
                                buildImageWidget(context, widget.message!),
                                Divider(),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "$cdate",
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: const Color.fromARGB(
                                            255, 124, 124, 124)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : widget.type == 'document'
                          ? Container(
                              constraints: BoxConstraints(
                                maxWidth: size.width / 2,
                              ),
                              alignment: widget.isMe!
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              padding: EdgeInsets.all(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: widget.isMe!
                                      ? const Color.fromARGB(255, 39, 59, 122)
                                      : const Color(0xFFDDE6EE),
                                  borderRadius: widget.isMe!
                                      ? BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          bottomLeft: Radius.circular(15),
                                        )
                                      : BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          bottomRight: Radius.circular(15),
                                        ),
                                ),
                                padding: EdgeInsets.all(5.0),
                                constraints: BoxConstraints(
                                  maxWidth: size.width / 1.5,
                                ),
                                alignment: widget.isMe!
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: widget.isMe!
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Text(
                                        widget.senderName!,
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(
                                                255, 124, 124, 124)),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    buildDocumentWidget(
                                        context, widget.message!),
                                    SizedBox(height: 10),
                                    Align(
                                      alignment: widget.isMe!
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Text(
                                        cdate,
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(
                                                255, 124, 124, 124)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              constraints: BoxConstraints(
                                maxWidth: size.width / 2,
                              ),
                              alignment: widget.isMe!
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              padding: EdgeInsets.all(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: widget.isMe!
                                      ? const Color.fromARGB(255, 39, 59, 122)
                                      : const Color(0xFFDDE6EE),
                                  borderRadius: widget.isMe!
                                      ? BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          bottomLeft: Radius.circular(15),
                                        )
                                      : BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                          bottomRight: Radius.circular(15),
                                        ),
                                ),
                                padding: EdgeInsets.all(10),
                                constraints: BoxConstraints(
                                  maxWidth: size.width / 1.5,
                                ),
                                alignment: widget.isMe!
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: widget.isMe!
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Text(
                                        widget.senderName!,
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(
                                                255, 124, 124, 124)),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () async {
                                        await launchUrl(
                                            Uri.parse("${widget.message}"));
                                      },
                                      child: Text(
                                        widget.message!,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 16,
                                          color: widget.isMe!
                                              ? Color.fromARGB(
                                                  255, 168, 220, 245)
                                              : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Align(
                                      alignment: widget.isMe!
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Text(
                                        cdate,
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(
                                                255, 124, 124, 124)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
    );
  }
}

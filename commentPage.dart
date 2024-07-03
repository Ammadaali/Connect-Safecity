import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;

class commentPage extends StatefulWidget {
  final String postId;

  commentPage({required this.postId});

  @override
  _commentPageState createState() => _commentPageState();
}

class _commentPageState extends State<commentPage> {
  TextEditingController commentController = TextEditingController();
  String? deletionMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff022336A),
        title: Text(
          'Comments',
          style: TextStyle(color: Colors.white), // Title text color
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white, // Back button color
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                Map<String, dynamic>? data =
                    snapshot.data?.data() as Map<String, dynamic>?;

                if (data != null && data['comments'] != null) {
                  List<dynamic> commentsData = data['comments'];
                  List<Comment> comments = commentsData
                      .map((comment) => Comment.fromMap(comment))
                      .toList()
                      .reversed
                      .toList(); // Reverse the order of comments

                  return ListView.separated(
                    controller: _scrollController,
                    reverse: true, // Reverse the list view
                    itemCount: comments.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return Divider(
                        color: Colors.grey[300], // Divider color
                      );
                    },
                    itemBuilder: (context, index) {
                      final comment = comments[index];

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
                        leading: CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/images/person.png'),
                        ),
                        title: Text(
                          comment.userName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(comment.text),
                      );
                    },
                  );
                }

                return Center(
                  child: Text("No Comments Yet"),
                );
              },
            ),
          ),
          if (deletionMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                deletionMessage!,
                style: TextStyle(color: Colors.green),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    String newCommentText = commentController.text.trim();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && newCommentText.isNotEmpty) {
      String currentUserName = await _getCurrentUserName(user.uid);

      Comment newComment =
          Comment(text: newCommentText, userName: currentUserName);

      try {
        // Clear the text field immediately
        setState(() {
          commentController.clear();
        });

        // Trigger Firestore operation to add the comment
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update({
          'comments': FieldValue.arrayUnion([newComment.toMap()]),
        });

        // Scroll to top after adding a comment
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      } catch (e) {
        print('Error adding comment: $e');
      }
    }
  }

  Future<String> _getCurrentUserName(String userId) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      String? userName = userSnapshot['name'];
      return userName ?? 'Anonymous';
    } else {
      return 'Unknown';
    }
  }
}

class Comment {
  final String text;
  final String userName;

  Comment({required this.text, required this.userName});

  Map<String, dynamic> toMap() {
    return {'text': text, 'user': userName};
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(text: map['text'] ?? '', userName: map['user'] ?? '');
  }
}

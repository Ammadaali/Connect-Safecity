import 'package:connect_safecity/user/Community/commentPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_facebook_app_links/flutter_facebook_app_links.dart';

class communityFeedPage extends StatefulWidget {
  @override
  _communityFeedPageState createState() => _communityFeedPageState();
}

class _communityFeedPageState extends State<communityFeedPage> {
  CollectionReference posts = FirebaseFirestore.instance.collection('posts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff022336A),
        title: Text(
          'Community Feed',
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
            child: StreamBuilder(
              stream: posts.orderBy('timestamp', descending: true).snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data!.docs[index];
                    return PostCard(
                        post: Post.fromMap(
                            post.id, post.data() as Map<String, dynamic>));
                  },
                );
              },
            ),
          ),
          AddPostWidget(onPostAdded: _addPost),
        ],
      ),
    );
  }

  Future<String> getCurrentUserName() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Fetch user's name from the 'users' collection
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        String? userName = userSnapshot['name'];

        if (userName != null && userName.isNotEmpty) {
          return userName;
        } else {
          // Handle the case where the user's name is not available
          return "Anonymous";
        }
      } else {
        // Handle the case where the user document does not exist
        return "User Not Found";
      }
    } else {
      // Handle the case where the user is not authenticated
      return "";
    }
  }

  Future<void> _addPost(Post post) async {
    // Generate a unique ID for the post
    String postId = posts.doc().id;
    String currentUserName = await getCurrentUserName();

    // Create a new post with the generated ID
    Post newPost = Post(
      id: postId,
      postText: post.postText,
      comments: post.comments,
      timestamp: post.timestamp,
      userName: currentUserName,
    );

    // Add the post to Firestore
    posts.doc(postId).set(newPost.toMap());
  }
}

class AddPostWidget extends StatefulWidget {
  final Function(Post) onPostAdded;

  AddPostWidget({required this.onPostAdded});

  @override
  _AddPostWidgetState createState() => _AddPostWidgetState();
}

class _AddPostWidgetState extends State<AddPostWidget> {
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.all(Radius.circular(150.0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Post any Emergency',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0), // Adjust as needed
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      width: 2.0,
                      color: Color(0xff022336A),
                    ), // Adjust the underline width
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        width: 2.0,
                        color:
                            Color(0xff022336A)), // Adjust the underline width
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: Color(0xff022336A),
            ),
            onPressed: () {
              String postText = textController.text.trim();
              if (postText.isNotEmpty) {
                Post newPost = Post(
                    postText: postText,
                    comments: [],
                    timestamp: Timestamp.now(),
                    id: '',
                    userName: '');
                widget.onPostAdded(newPost);
                textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  PostCard({required this.post});

  Future<String> fetchUserName(String postId) async {
    try {
      // Fetch user name from the 'posts' collection
      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (postSnapshot.exists) {
        return postSnapshot['userName'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      return 'Error fetching user name';
    }
  }

  Future<String> getCurrentUserName() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Fetch user's name from the 'users' collection
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        String? userName = userSnapshot['name'];

        if (userName != null && userName.isNotEmpty) {
          return userName;
        } else {
          // Handle the case where the user's name is not available
          return "Anonymous";
        }
      } else {
        // Handle the case where the user document does not exist
        return "User Not Found";
      }
    } else {
      // Handle the case where the user is not authenticated
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFDDE6EE),
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/person.png'),
                      radius: 20,
                    ),
                    SizedBox(width: 8),
                    FutureBuilder<String>(
                      future: fetchUserName(post.id),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                              'Loading...'); // Replace with a loading indicator
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          String userName = snapshot.data ?? 'Unknown User';
                          return Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              post.postText,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.comment,
                        color: Color(0xff022336A),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => commentPage(postId: post.id),
                          ),
                        );
                      },
                    ),
                    Text(
                      'Comment (${post.commentCount})',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.share, color: Color(0xff022336A)),
                      onPressed: () {
                        // Show sharing options
                        _shareOnFacebook(post.postText);
                      },
                    ),
                    Text('Share',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareOnFacebook(String postText) async {
    try {
      await Share.share(postText, subject: 'Shared from my Flutter app');
    } catch (e) {
      print('Error sharing on Facebook: $e');
      // Handle errors as needed
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    // Convert Firestore Timestamp to DateTime
    DateTime dateTime = timestamp.toDate();

    // Get current time
    DateTime now = DateTime.now();

    // Calculate the difference between now and the timestamp
    Duration difference = now.difference(dateTime);

    // Format the difference using timeago package
    return timeago.format(now.subtract(difference), allowFromNow: true);
  }

  void _showCommentBottomSheet(BuildContext context, String postId,
      Future<String> Function() getCurrentUserName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return CommentBottomSheet(
          postId: postId,
          getCurrentUserName: getCurrentUserName,
        );
      },
    );
  }
}

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final Future<String> Function() getCurrentUserName; // Add this line

  CommentBottomSheet({required this.postId, required this.getCurrentUserName});

  @override
  _CommentBottomSheetState createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  TextEditingController commentController = TextEditingController();

  Future<void> _addComment() async {
    String newCommentText = commentController.text.trim();
    String currentUserName =
        await widget.getCurrentUserName(); // Use widget.getCurrentUserName here
    if (newCommentText.isNotEmpty) {
      Comment newComment =
          Comment(text: newCommentText, userName: currentUserName);
      // Update the comments in Firestore
      FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'comments': FieldValue.arrayUnion([newComment.toMap()]),
      });
      commentController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

                if (snapshot.connectionState == ConnectionState.done) {
                  Map<String, dynamic>? data =
                      snapshot.data?.data() as Map<String, dynamic>?;

                  if (data != null && data['comments'] != null) {
                    List<dynamic> commentsData = data['comments'];
                    List<Comment> comments = commentsData
                        .map((comment) => Comment.fromMap(comment))
                        .toList();

                    return ListView.builder(
                      reverse: true,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(
                                  'assets/images/person.png'), // Add your user avatar here
                            ),
                            title: Text(
                              comment.userName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(comment.text),
                          ),
                        );
                      },
                    );
                  }
                }

                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Color(0xff022336A)),
                onPressed: _addComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentSection extends StatelessWidget {
  final List<Comment> comments;

  CommentSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Comments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        for (var comment in comments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('${comment.userName}: ${comment.text}'),
          ),
      ],
    );
  }
}

class Post {
  final String id;
  final String postText;
  final List<Comment> comments;
  final Timestamp timestamp;
  final String userName;
  int get commentCount => comments.length; // Add this field

  Post({
    required this.id,
    required this.postText,
    required this.comments,
    required this.timestamp,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'postText': postText,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'timestamp': FieldValue.serverTimestamp(),
      'userName': userName,
    };
  }

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      postText: map['postText'] ?? '',
      comments: (map['comments'] as List<dynamic>? ?? [])
          .map((c) => Comment.fromMap(c))
          .toList(),
      timestamp: map['timestamp'] ?? Timestamp.now(),
      userName: map['userName'] ?? '',
    );
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

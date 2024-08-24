import 'package:chatapp/Screens/GroupInfoPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupChatRoom extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> members;

  GroupChatRoom({
    required this.groupId,
    required this.groupName,
    required this.members,
  });
  @override
  _GroupChatRoomState createState() => _GroupChatRoomState();
}

class _GroupChatRoomState extends State<GroupChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isUploading = false;
  String? _adminName; // To store admin name

  @override
  void initState() {
    super.initState();
    _fetchAdminName(); // Fetch admin name on initialization
  }

  // Fetch the admin name from the Firestore
  Future<void> _fetchAdminName() async {
    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('groups')
          .where('name', isEqualTo: widget.groupName)
          .get();

      if (result.docs.isNotEmpty) {
        QueryDocumentSnapshot firstDocument = result.docs.first;
        var data = firstDocument.data() as Map<String, dynamic>;
        // Print the data for debugging
        print('Document data: $data');

        setState(() {
          _adminName = data['admin']; // Assuming 'admin' is the field name
        });
        print('Admin name fetched: $_adminName');
      } else {
        print('Group document does not exist.');
      }
    } catch (e) {
      print('Error fetching admin name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'GroupChatRoom initialized with groupId: ${widget.groupId} and groupName: ${widget.groupName}');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              print(
                  'Navigating to GroupInfoPage with groupId: ${widget.groupId}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfoPage(
                    groupName: widget.groupName,
                    members: widget.members,
                    // currentUser: _adminName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                if (_adminName != null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Group created by: $_adminName',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groupchatrooms')
                        .doc(widget.groupId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                            child:
                                CircularProgressIndicator()); // Show a single loader for all messages
                      }

                      var messages = snapshot.data!.docs;
                      print('Number of messages fetched: ${messages.length}');

                      return ListView.builder(
                        reverse: true,
                        padding: EdgeInsets.all(8.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index];
                          var messageData =
                              message.data() as Map<String, dynamic>;
                          var sender = messageData['sender'];
                          var text = messageData['text'];

                          // Add a default value for type if it doesn't exist
                          var type = messageData.containsKey('type')
                              ? messageData['type']
                              : 'text';

                          var isSentByCurrentUser =
                              sender == FirebaseAuth.instance.currentUser!.uid;

                          print('Message: $text by $sender, type: $type');
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(sender)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                print(
                                    'Document does not exist for user: $sender');
                                return Center(
                                    child: Text('User data not found.'));
                              }

                              var senderName = userSnapshot.data!['name'];
                              print('Sender name: $senderName');
                              return _buildMessageTile(
                                  senderName, text, type, isSentByCurrentUser);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageTile(
      String userName, String message, String type, bool isSentByCurrentUser) {
    print('Building message tile for $userName: $message');
    return Align(
      alignment:
          isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSentByCurrentUser ? Colors.green[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: isSentByCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4.0),
            type == 'image'
                ? Image.network(message) // Display image
                : Text(message), // Display text
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              print('Picture icon pressed');
              _pickImage();
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[200],
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          CircleAvatar(
            child: IconButton(
              icon: Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      var currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String senderName;
        try {
          final DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            senderName = userDoc['name'];
            print('Sender name fetched: $senderName');
          } else {
            senderName = 'Unknown';
            print('User document does not exist.');
          }
        } catch (e) {
          senderName = 'Unknown';
          print('Error fetching user name: $e');
        }

        String messageId = FirebaseFirestore.instance
            .collection('groupchatrooms')
            .doc(widget.groupId)
            .collection('messages')
            .doc()
            .id;
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('messages')
            .child('$messageId.txt');
        await storageReference.putString(_messageController.text);
        print('Message stored in Firebase Storage with ID: $messageId');

        await FirebaseFirestore.instance
            .collection('groupchatrooms')
            .doc(widget.groupId)
            .collection('messages')
            .doc(messageId)
            .set({
          'text': _messageController.text,
          'sender': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
        });

        print('Message sent: ${_messageController.text} by $senderName');
        _messageController.clear(); // Clear the input field after sending
      } else {
        print('No user is currently logged in.');
      }
    } else {
      print('Empty message not allowed');
    }
  }

  Future<String> uploadImage(File image) async {
    try {
      Reference sr = FirebaseStorage.instance
          .ref()
          .child('Images/${DateTime.now().millisecondsSinceEpoch}.png');
      await sr.putFile(image).whenComplete(() {
        print('Image uploaded to Firebase Storage');
      });
      String imageUrl = await sr.getDownloadURL();
      print('Image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error occurred while uploading image: $e');
      return '';
    }
  }

  void _pickImage() async {
    print("Picking image");
    if (_isUploading) {
      print("An upload is already in progress");
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _isUploading = true;
      });
      try {
        String imageUrl = await uploadImage(File(image.path));
        sendMessage(imageUrl: imageUrl);
      } catch (e) {
        print("Error processing image: $e");
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      print("No image selected");
    }
  }

  void sendMessage({String? imageUrl}) async {
    print("Sending message. Image URL: $imageUrl");
    if (_messageController.text.isNotEmpty || imageUrl != null) {
      try {
        await FirebaseFirestore.instance
            .collection('groupchatrooms')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'text': imageUrl ?? _messageController.text,
          'sender': FirebaseAuth.instance.currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'type': imageUrl != null ? 'image' : 'text',
        });
        print("Message sent successfully");
        _messageController.clear();
        setState(() {
          _pickedImage = null;
          _isUploading = false;
        });
      } catch (e) {
        print("Error sending message: $e");
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}

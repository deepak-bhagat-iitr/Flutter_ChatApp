import 'dart:io'; // Import dart:io to use the File class
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatRoom extends StatelessWidget {
  final String chatRoomId;
  final String userName;
  final String userStatus;

  ChatRoom({
    required this.chatRoomId,
    required this.userName,
    required this.userStatus,
  });

  @override
  Widget build(BuildContext context) {
    print("Building ChatRoom widget");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Setting AppBar background color
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black)), // Enhancing UI
            Text(userStatus,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey)), // Adding color
          ],
        ),
        iconTheme: IconThemeData(color: Colors.black), // Setting icon color
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Add action here
              print("More options pressed");
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ChatMessagesList(chatRoomId: chatRoomId),
          ),
          SendMessage(chatRoomId: chatRoomId),
        ],
      ),
    );
  }
}

class ChatMessagesList extends StatefulWidget {
  final String chatRoomId;

  ChatMessagesList({required this.chatRoomId});

  @override
  _ChatMessagesListState createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<ChatMessagesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    print("Building ChatMessagesList for chatRoomId: ${widget.chatRoomId}");
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .orderBy('time', descending: false)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        print("Snapshot data: ${snapshot.data}");
        if (!snapshot.hasData) {
          print("No data available");
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Snapshot error: ${snapshot.error}");
          return Center(child: Text("An error occurred"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("Waiting for snapshot data");
          return Center(child: CircularProgressIndicator());
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
            print("Scrolled to the bottom of the list");
          }
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final message = data['message'];
            final sentBy = data['sentBy'];
            final time = data['time'];
            final type = data.containsKey('type') ? data['type'] : 'text';

            print("Message data: $data");

            if (message == null || sentBy == null || time == null) {
              print("Skipping message due to null values");
              return SizedBox.shrink();
            }

            return MessageTile(
              message: message,
              isMe: sentBy == FirebaseAuth.instance.currentUser!.uid,
              timestamp: (time as Timestamp).toDate(),
              type: type,
            );
          },
        );
      },
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String type;

  MessageTile({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.type,
  });

  String formatTimestamp(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    print("Building MessageTile for message: $message");
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isMe ? 64 : 16,
        right: isMe ? 16 : 64,
      ),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin:
            isMe ? EdgeInsets.only(left: 30) : EdgeInsets.only(right: 30),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: isMe
                  ? BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomLeft: Radius.circular(23))
                  : BorderRadius.only(
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23),
                  bottomRight: Radius.circular(23)),
              color:
              isMe ? Colors.blueAccent : Colors.grey[300], // Enhancing UI
            ),
            child: type == 'text'
                ? Text(
              message,
              style:
              TextStyle(color: isMe ? Colors.white : Colors.black87),
            )
                : Image.network(
              message,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading image: $error");
                return Text("Could not load image");
              },
            ),
          ),
          SizedBox(height: 4),
          Text(
            formatTimestamp(timestamp),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SendMessage extends StatefulWidget {
  final String chatRoomId;

  SendMessage({required this.chatRoomId});

  @override
  _SendMessageState createState() => _SendMessageState();
}

class _SendMessageState extends State<SendMessage> {
  final TextEditingController messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isUploading = false; // Track if an upload is in progress

  // Method to upload image to Firebase Storage and return the download URL
  Future<String> uploadImage(File image) async {
    try {
      Reference sr = FirebaseStorage.instance
          .ref()
          .child('Images/${DateTime.now().millisecondsSinceEpoch}.png');
      await sr.putFile(image).whenComplete(() {
        print('Image uploaded to Firebase Storage');
      });
      String imageUrl = await sr.getDownloadURL();
      print('Image URL: $imageUrl'); // Added debug print
      return imageUrl;
    } catch (e) {
      print('Error occurred while uploading image: $e');
      return '';
    }
  }

  // Method to send a message, optionally with an image URL
  void sendMessage({String? imageUrl}) async {
    print("Sending message. Image URL: $imageUrl");
    if (messageController.text.isNotEmpty || imageUrl != null) {
      try {
        await FirebaseFirestore.instance
            .collection('chatrooms')
            .doc(widget.chatRoomId)
            .collection('messages')
            .add({
          'message': imageUrl ?? messageController.text,
          'sentBy': FirebaseAuth.instance.currentUser!.uid,
          'time': DateTime.now(),
          'type': imageUrl != null ? 'image' : 'text',
        });
        print("Message sent successfully");
        messageController.clear();
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
    } else {
      print("Message content is empty or no image URL provided");
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Method to pick an image from the gallery
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
        print("Error processing image:

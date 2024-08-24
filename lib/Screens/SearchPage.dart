import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/Screens/ChatRoom.dart'; // Ensure this import is correct
import 'package:chatapp/Screens/SignupPage.dart';
import 'package:chatapp/Screens/GroupListPage.dart'; // Ensure this import is correct

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserStatus('online');
  }

  @override
  void dispose() {
    _updateUserStatus('offline');
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _updateUserStatus('offline');
    } else if (state == AppLifecycleState.resumed) {
      _updateUserStatus('online');
    }
  }

  void _updateUserStatus(String status) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'status': status,
      });
      print('User status updated to $status'); // Debugging print statement
    } else {
      print('No user is signed in'); // Debugging print statement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search User'),
        // backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              _updateUserStatus('offline');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignupPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search User by Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUser,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 20),
            if (_userData != null) ...[
              InkWell(
                onTap: () {
                  final uid = _userData!['uid'] ?? '';
                  print('User ID: $uid'); // Debugging print statement
                  print(
                      'User Name: ${_userData!['name'] ?? 'Unknown'}'); // Debugging print statement

                  if (uid is String && uid.isNotEmpty) {
                    final currentUser = _auth.currentUser;
                    if (currentUser != null) {
                      final currentUserId = currentUser.uid;
                      final chatRoomId =
                          _generateChatRoomId(currentUserId, uid);
                      print(
                          'Chat Room ID: $chatRoomId'); // Debugging print statement

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoom(
                            chatRoomId: chatRoomId,
                            userName: _userData!['name'] ?? 'Unknown',
                            userStatus: _userData!['status'] ?? 'none',
                          ),
                        ),
                      );
                    } else {
                      print(
                          'Current user is null'); // Debugging print statement
                    }
                  } else {
                    print('Invalid UID'); // Debugging print statement
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User not found.'),
                      ),
                    );
                  }
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  elevation: 1.0, // Adds shadow to the card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25.0, // Increased size for better visibility
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person,
                          color: Colors.white,
                          size: 30.0), // Increased icon size
                    ),
                    title: Text(
                      _userData!['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize:
                            18.0, // Increased font size for better readability
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      _userData!['email'] ?? 'No email',
                      style: TextStyle(
                        fontSize: 14.0, // Consistent font size
                        color: Colors.black54,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userData!['status'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14.0, // Consistent font size
                            color: _userData!['status'] == 'online'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold, // Bold text for status
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupListPage()),
          );
        },
        child: Icon(
          Icons.group,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Method to search for a user in Firestore
  void _searchUser() async {
    setState(() {
      _userData = null;
    });

    try {
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('name', isEqualTo: _searchQuery)
          .get();

      if (result.docs.isNotEmpty) {
        setState(() {
          _userData = {
            'uid': result.docs.first.id,
            ...result.docs.first.data() as Map<String, dynamic>,
          };
          print('Search Result: $_userData'); // Debugging print statement
        });
      } else {
        setState(() {
          _userData = null;
        });
        _showSnackBar('No user found with that name');
      }
    } catch (e) {
      _showSnackBar('Error searching user: $e');
      print('Error searching user: $e'); // Debugging print statement
    }
  }

  // Method to show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Method to generate a chat room ID based on user IDs
  String _generateChatRoomId(String user1, String user2) {
    List<String> uids = [user1, user2];
    uids.sort();
    return uids.join('_');
  }
}

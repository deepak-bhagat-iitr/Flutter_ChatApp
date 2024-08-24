import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/Screens/GroupChatRoom.dart'; // Ensure this import is correct
import 'package:chatapp/Screens/CreateGroup.dart'; // Ensure this import is correct

class GroupListPage extends StatefulWidget {
  @override
  _GroupListPageState createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch the logged-in user's name
  Future<void> _fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        final QuerySnapshot result = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        if (result.docs.isNotEmpty) {
          setState(() {
            userName = result.docs.first['name'];
          });
          print('User name fetched: $userName'); // Debugging
        } else {
          print('No user data found'); // Debugging
        }
      } catch (e) {
        print('Error fetching user name: $e'); // Debugging
      }
    } else {
      print('No user is currently logged in.'); // Debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups List'),
        // backgroundColor: Colors.blue,
      ),
      body: userName != null
          ? StreamBuilder<QuerySnapshot>(
              // Fetch groups where the current user is a member
              stream: _firestore
                  .collection('groups')
                  .where('members', arrayContains: userName)
                  .snapshots(),
              builder: (context, snapshot) {
                print(
                    'Snapshot connection state: ${snapshot.connectionState}'); // Debugging
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var groups = snapshot.data!.docs;
                print(
                    'Number of groups fetched: ${groups.length}'); // Debugging
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    var group = groups[index];

                    var groupName = group['name'];
                    var members = List<String>.from(
                        group['members']); // Ensure members is a List<String>

                    print(
                        'Group: $groupName, Members: ${members.length}'); // Debugging

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 1.0, // Adds shadow to the card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius:
                              25.0, // Slightly increased radius for better appearance
                          child: Icon(Icons.group,
                              color: Colors.white,
                              size: 30.0), // Increased icon size
                        ),
                        title: Text(
                          groupName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 18.0,
                            color: Colors
                                .black87, // Darker text color for better readability
                          ),
                        ),
                        subtitle: Text(
                          'Members: ${members.length}',
                          style: TextStyle(
                            color:
                                Colors.grey[600], // Softer color for subtitle
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors
                              .blue, // Icon color consistent with the theme
                          size: 16.0,
                        ),
                        onTap: () {
                          print(
                              'Navigating to GroupChatRoom for group: $groupName'); // Debugging
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatRoom(
                                groupId: group.id,
                                groupName: groupName,
                                members:
                                    members, // Pass group members to GroupChatRoom
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            )
          : Center(child: Text('No Data Found.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to CreateGroup page
          print('Navigating to CreateGroup page'); // Debugging
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGroup()),
          );
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ), // Changed icon to add icon
        backgroundColor: Colors.blue,
      ),
    );
  }
}

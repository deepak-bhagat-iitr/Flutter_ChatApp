import 'package:chatapp/Screens/AddMembers.dart';
import 'package:chatapp/Screens/SearchPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupName;
  final List<String> members;

  GroupInfoPage({required this.groupName, required this.members});

  @override
  _GroupInfoPageState createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late List<String> members;
  late String groupName;

  String? userName;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    members = widget.members;
    groupName = widget.groupName;
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

  void _leaveGroup() {
    // Print statement for debugging
    print('${userName} is attempting to leave the group.');

    setState(() {
      // Remove the current user from the members list
      if (userName != null) {
        members.remove(userName);
        print('Updated members list: $members'); // Debugging
      } else {
        print('User name is null, cannot leave group'); // Debugging
      }
    });

    // Store the updated members in Firestore
    _updateGroupInfo();

    // Navigate to the SearchPage after leaving the group
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );
  }

  Future<void> _updateGroupInfo() async {
    try {
      // Fetch the group document from Firestore using the group name
      QuerySnapshot result = await _firestore
          .collection('groups')
          .where('name', isEqualTo: widget.groupName)
          .get();

      if (result.docs.isNotEmpty) {
        // Get the first document
        QueryDocumentSnapshot firstDocument = result.docs.first;
        // Get the document ID
        String documentId = firstDocument.id;

        // Update the members list in the group document
        await _firestore.collection('groups').doc(documentId).update({
          'members': members,
        });

        // Print updated data for debugging
        var updatedData =
            await _firestore.collection('groups').doc(documentId).get();
        print('Group info updated in Firestore: ${updatedData.data()}');
      } else {
        print('No group data found for ${widget.groupName}'); // Debugging
      }
    } catch (e) {
      print('Error updating group info: $e'); // Debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: Text('Group Info'),
          ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, size: 80),
                SizedBox(width: 10),
                Text(widget.groupName, style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 10),
            Text('Total Members: ${members.length}',
                style: TextStyle(fontSize: 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Members:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddMembers(
                        groupName: groupName,
                        members: members,
                      )),
                    );
                  }, // Add navigation logic
                  icon: Icon(Icons.add), // + Icon
                  label: Text('Add Members'),
                  style: ElevatedButton.styleFrom(
                      // primary: Colors.green,
                      ),
                ),
              ],
            ),
            // SizedBox(height: 10),
            SizedBox(height: 20),
            // Text('Members:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(members[index]),
                  );
                },
              ),
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: _leaveGroup,
                icon: Icon(Icons.exit_to_app),
                label: Text('Leave Group'),
                style: ElevatedButton.styleFrom(
                    // primary: Colors.red,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

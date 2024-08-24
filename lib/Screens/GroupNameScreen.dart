import 'package:chatapp/Screens/SearchPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package

class GroupNameScreen extends StatelessWidget {
  final TextEditingController _groupNameController;
  final List<String> _selectedMembers;
  final String _admin; // Updated to be of type String

  GroupNameScreen(
      this._groupNameController, this._selectedMembers, this._admin);

  // Method to create a new group and add it to Firestore
  Future<void> _createGroup(BuildContext context) async {
    final groupName = _groupNameController.text;
    if (groupName.isEmpty) {
      print('Group name is empty'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'admin': _admin,
        'members': _selectedMembers,
        'createdAt': Timestamp.now(),
      });
      print(
          'Group created: $groupName with members: $_selectedMembers'); // Debug print

      // Navigate to SearchPage after group creation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchPage()),
      );
    } catch (e) {
      print('Error creating group: $e'); // Error handling
      ScaffoldMessenger.of(contextR).showSnackBar(
        SnackBar(content: Text('Failed to create group')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Group Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Group Name Input Field
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Border radius for rounded corners
                ),
              ),
            ),
            SizedBox(height: 20),
            // Create Group Button
            ElevatedButton(
              onPressed: () {
                _createGroup(
                    context); // Call method to create group and store in Firestore
              },
              child: Text('Create Group'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Text color
                padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

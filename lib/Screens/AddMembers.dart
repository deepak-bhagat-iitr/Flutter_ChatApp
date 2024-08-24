import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth package
import 'package:chatapp/Screens/GroupInfoPage.dart';

class AddMembers extends StatefulWidget {
  final List<String> members;
  final String groupName; // Added groupName to get group info

  AddMembers({required this.members, required this.groupName});

  @override
  _AddMembersState createState() => _AddMembersState();
}

class _AddMembersState extends State<AddMembers> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _memberSearchController = TextEditingController();
  List<String> _selectedMembers = [];
  List<Map<String, dynamic>> _searchResults = []; // To hold search results

  @override
  void initState() {
    super.initState();
    print('AddMembers Widget Initialized');
  }

  // Function to search for members based on the query
  Future<void> _searchMembers(String query) async {
    print('Searching for members with query: $query');
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      // Fetch users from Firestore matching the search query
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: query)
          .get();

      setState(() {
        _searchResults = result.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        print('Search Results: $_searchResults');
      });
    } catch (e) {
      print('Error searching members: $e');
    }
  }

  // Function to add selected members to the group and update Firestore
  Future<void> _addMembersToGroup() async {
    print('Adding members to group...');
    // Combine existing and new members
    List<String> updatedMembers = List.from(widget.members);
    updatedMembers.addAll(_selectedMembers);

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
          'members': updatedMembers,
        });

        // Print updated data for debugging
        var updatedData =
            await _firestore.collection('groups').doc(documentId).get();
        print('Group info updated in Firestore: ${updatedData.data()}');

        // Navigate to GroupInfoPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GroupInfoPage(
              groupName: widget.groupName,
              members: updatedMembers,
            ),
          ),
        );
      } else {
        print('No group data found for ${widget.groupName}');
      }
    } catch (e) {
      print('Error updating group info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Members'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display selected members
            if (_selectedMembers.isNotEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 16.0), // Margin for spacing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Members:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8.0,
                      children: _selectedMembers.map((member) => Chip(
                            label: Text(member),
                            onDeleted: () {
                              setState(() {
                                _selectedMembers.remove(member);
                                print('Removed Member: $member');
                              });
                            },
                          )).toList(),
                    ),
                  ],
                ),
              ),
            // Search Members input with search icon
            TextField(
              controller: _memberSearchController,
              decoration: InputDecoration(
                labelText: 'Search Members',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  // Search icon
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchMembers(_memberSearchController.text);
                    _memberSearchController.clear(); // Clear input box
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            // Display search results
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final member = _searchResults[index];
                  return ListTile(
                    title: Text(member['name']),
                    leading: Icon(Icons.person), // Member icon
                    trailing: IconButton(
                      icon: Icon(Icons.add), // Add icon
                      onPressed: () {
                        setState(() {
                          if (!_selectedMembers.contains(member['name'])) {
                            _selectedMembers.add(member['name']);
                            print('Selected Members: $_selectedMembers');
                          } else {
                            print('Member already added: ${member['name']}');
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            // Add Members button at the bottom
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                onPressed: _addMembersToGroup,
                icon: Icon(Icons.person_add),
                label: Text('Add Members'),
                style: ElevatedButton.styleFrom(
                  // primary: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

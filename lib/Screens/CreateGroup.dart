import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth package
import 'GroupNameScreen.dart'; // Import the new screen for group name

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _memberSearchController = TextEditingController();
  var data;
  List<String> _selectedMembers = [];
  var _admin;
  List<Map<String, dynamic>> _searchResults = []; // To hold search results
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    _addLoggedInUserToSelectedMembers(); // Fetch and add the logged-in user
  }

  // Function to fetch and add the logged-in user to _selectedMembers
  void _addLoggedInUserToSelectedMembers() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('User fetched: ${user.email}');
        final QuerySnapshot result = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (result.docs.isNotEmpty) {
          data = {
            'uid': result.docs.first.id,
            ...result.docs.first.data() as Map<String, dynamic>,
          };
          print(data["name"]);

          if (data["name"] != null && data["name"].isNotEmpty) {
            setState(() {
              if (!_selectedMembers.contains(data["name"])) {
                _selectedMembers.add(data["name"]);
                _admin = data["name"];
                print(
                    'Logged-in user added to selected members: $_selectedMembers');
              }
            });
          } else {
            print('User display name is null or empty.');
          }
        } else {
          print('No matching user found in Firestore.');
        }
      } else {
        print('No user is currently logged in.');
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }

  // Function to search for members based on the query
  Future<void> _searchMembers(String query) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
        // backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: Column(
            children: [
              // Display selected members (excluding the logged-in user)
              if (_selectedMembers.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 16.0), // Margin for spacing
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text('Selected Members:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Wrap(
                        spacing: 8.0,
                        children: _selectedMembers
                            .where((member) =>
                                member !=
                                data["name"]) // Exclude logged-in user
                            .map((member) => Chip(
                                  label: Text(member),
                                  deleteIcon: Builder(
                                    builder: (context) {
                                      // Obtain the screen width
                                      double screenWidth =
                                          MediaQuery.of(context).size.width;
                                      // Define the responsive size based on the screen width
                                      double iconSize = screenWidth *
                                          0.05; // For example, 5% of screen width

                                      return Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: iconSize,
                                      );
                                    },
                                  ),
                                  backgroundColor: Colors.blue,
                                  labelStyle: TextStyle(color: Colors.white),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedMembers.remove(member);
                                      print('Removed Member: $member');
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              // Search Members input with search icon
              TextField(
                controller: _memberSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Members',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        8.0), // Border radius for rounded corners
                  ),
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
              ListView.builder(
                shrinkWrap: true, // to use inside a column
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final member = _searchResults[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12.0), // Rounded corners for cards
                    ),
                    child: ListTile(
                      title: Text(member['name']),
                      leading:
                          Icon(Icons.person, color: Colors.blue), // Member icon
                      trailing: IconButton(
                        icon: Icon(Icons.add, color: Colors.blue), // Add icon
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // Added a floating action button
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupNameScreen(
                _groupNameController, // Pass the group name controller
                _selectedMembers,
                _admin, // Pass the selected members
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.arrow_forward_rounded,
            color: Colors.white), // Button icon
        tooltip: 'Add Group Name', // Tooltip for accessibility
      ),
    );
  }
}

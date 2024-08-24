import 'dart:io';

import 'package:chatapp/upload_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Reference> _uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    getUploadedFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase Storage"),
        centerTitle: true,
      ),
      body: _buildUI(),
      floatingActionButton: _uploadMediaButton(context),
    );
  }

  Widget _uploadMediaButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        File? selectedImage = await getImageFromGallery(context);
        if (selectedImage != null) {
          bool success = await uploadFileForUser(selectedImage);
          if (success) {
            getUploadedFiles();
          }
        }
      },
      child: const Icon(Icons.upload),
    );
  }

  Widget _buildUI() {
    if (_uploadedFiles.isEmpty) {
      return const Center(
        child: Text("No files uploaded yet."),
      );
    }
    return ListView.builder(
      itemCount: _uploadedFiles.length,
      itemBuilder: (context, index) {
        Reference ref = _uploadedFiles[index];
        return FutureBuilder(
          future: ref.getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListTile(
                leading: Image.network(snapshot.data as String),
                title: Text(ref.name),
              );
            }
            return Container(); // Placeholder widget while loading
          },
        );
      },
    );
  }

  void getUploadedFiles() async {
    List<Reference>? result = await getUsersUplodedFiles();
    if (result != null) {
      setState(() {
        _uploadedFiles = result;
      });
    }
  }
}

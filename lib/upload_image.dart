import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class UploadImage extends StatefulWidget {
  const UploadImage({super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  String? imageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  bool isLoading = false;

  Future<void> pickImage() async {
    XFile? res = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (res != null) {
      uploadToFirebase(File(res.path));
    }
  }

  Future<void> uploadToFirebase(File image) async {
    setState(() {
      isLoading = true;
    });
    try {
      Reference sr = FirebaseStorage.instance
          .ref()
          .child('Images/${DateTime.now().millisecondsSinceEpoch}.png');
      await sr.putFile(image).whenComplete(() {
        Fluttertoast.showToast(msg: 'Image uploaded to 🔥base');
      });
      imageUrl = await sr.getDownloadURL();
    } catch (e) {
      print('Error occurred $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            imageUrl == null
                ? Icon(
                    Icons.person,
                    size: 200,
                    color: Colors.grey,
                  )
                : Center(
                    child: Image.network(
                      imageUrl!,
                      height: MediaQuery.of(context).size.height * 0.5,
                    ),
                  ),
            SizedBox(height: 50),
            Center(
              child: ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.image),
                label: Text(
                  'Upload Image',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            SizedBox(height: 40),
            if (isLoading)
              SpinKitThreeBounce(
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

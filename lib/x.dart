import 'package:flutter/material.dart';
import 'upload_image.dart'; // Import the UploadImage widget

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UploadImage(), // Set UploadImage as the home widget
    );
  }
}

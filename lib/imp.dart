import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'upload_image.dart'; // Import the UploadImage widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

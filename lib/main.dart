import 'package:chatapp/Screens/SearchPage.dart';
import 'package:chatapp/Screens/SignupPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseAuth.instance.setLanguageCode('en');

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Screen App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void checkLoginStatus() async {
      User? user = FirebaseAuth.instance.currentUser;

      print('Current user: ${user?.uid ?? "No user logged in"}');

      Future.delayed(Duration(seconds: 1), () {
        if (user != null) {
          print('User is logged in, navigating to SearchPage');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => SearchPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = 0.0;
                const end = 1.0;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var fadeAnimation = animation.drive(tween);

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                );
              },
            ),
          );
        } else {
          print('User is not logged in, navigating to SignupPage');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => SignupPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = 0.0;
                const end = 1.0;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var fadeAnimation = animation.drive(tween);

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                );
              },
            ),
          );
        }
      });
    }

    Future.delayed(Duration(seconds: 3), () {
      print('Checking login status after splash screen delay');
      checkLoginStatus();
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          double iconSize = width * 0.25;
          if (iconSize > 150) {
            iconSize = 150;
          }

          return Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.1,
                  vertical: height * 0.1,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: iconSize,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

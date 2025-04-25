import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterquiz/animation/fade_animation.dart';
import 'package:flutterquiz/screen/quiz_screen.dart';
import 'package:flutterquiz/util/constant.dart';
import 'package:flutterquiz/util/router_path.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  void startTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    Timer(const Duration(seconds: 1), () {
      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(DashBoardScreen);
      } else {
        Navigator.of(context).pushReplacementNamed(LoginScreen);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: kItemSelectBottomNav),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Phần mềm ",
              style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                  fontSize: 40),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Thi trắc nghiệm",
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 3.0,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

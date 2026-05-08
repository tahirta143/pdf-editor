import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfeditorapp/navigation/navigation.dart';


class splash extends StatefulWidget {
  const splash({super.key});

  @override
  State<splash> createState() => _homeState();
}

class _homeState extends State<splash> {

  @override
  void initState(){
    super.initState();

    Timer(Duration(seconds: 3),(){

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigationbar())
      );

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            './assets/images/logo.png',
            height: 120,
            width: 120,
          ),
        )
    );
  }
}


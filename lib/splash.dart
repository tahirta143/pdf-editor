import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfeditorapp/navigation/navigation.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';

class splash extends StatefulWidget {
  const splash({super.key});

  @override
  State<splash> createState() => _homeState();
}

class _homeState extends State<splash> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Navigationbar()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final logoSize = r.wp(28).clamp(80.0, 160.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: r.isTablet
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Center(
                  child: Image.asset(
                    './assets/images/logo.png',
                    height: logoSize,
                    width: logoSize,
                  ),
                ),
              )
            : Image.asset(
                './assets/images/logo.png',
                height: logoSize,
                width: logoSize,
              ),
      ),
    );
  }
}

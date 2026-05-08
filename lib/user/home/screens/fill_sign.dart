import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdftron_flutter/pdftron_flutter.dart';

class FillSignScreen extends StatefulWidget {
  const FillSignScreen({super.key});

  @override
  State<FillSignScreen> createState() => _FillSignState();
}

class _FillSignState extends State<FillSignScreen> {
  
  Future<void> openForSigning() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      // PDFTron has built-in signature tools in the default viewer
      PdftronFlutter.openDocument(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(
        title: const Text("Fill & Sign"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gesture, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              "Sign Documents Digitally",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Draw your signature and place it anywhere on your PDF. You can also fill out PDF forms easily.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: openForSigning,
              icon: const Icon(Icons.edit),
              label: const Text("Open for Signing"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

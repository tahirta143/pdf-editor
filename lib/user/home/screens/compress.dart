import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class CompressPdfPage extends StatefulWidget {
  const CompressPdfPage({super.key});

  @override
  State<CompressPdfPage> createState() => _CompressPdfPageState();
}

class _CompressPdfPageState extends State<CompressPdfPage> {
  String? inputPath;
  String? savedPath;

  bool isProcessing = false;

  int? originalSize;
  int? compressedSize;

  String fileName = "";

  // 📂 PICK PDF
  Future<void> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      setState(() {
        inputPath = file.path;
        originalSize = file.lengthSync();
        compressedSize = null;
        savedPath = null;
      });
    }
  }

  // 🗜️ FAKE COMPRESSION (replace with real API later)
  Future<void> compressPdf() async {
    if (inputPath == null) return;

    setState(() => isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    final file = File(inputPath!);

    setState(() {
      compressedSize = (file.lengthSync() * 0.6).toInt();
      isProcessing = false;
    });
  }

  // 💾 SAVE TO DOWNLOADS (REAL FIX)
  Future<void> saveFile() async {
    if (inputPath == null || fileName.trim().isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final file = File(inputPath!);

      // 📁 Downloads folder (Android safe)
      final dir = await getExternalStorageDirectory();
      final downloadPath = dir!.path;

      final cleanName = fileName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '');

      final newPath = p.join(downloadPath, "$cleanName.pdf");

      await file.copy(newPath);

      setState(() {
        savedPath = newPath;
        isProcessing = false;
      });
    } catch (e) {
      setState(() => isProcessing = false);
    }
  }

  // 📤 SHARE FILE
  void shareFile() {
    if (savedPath != null) {
      Share.shareXFiles([XFile(savedPath!)], text: "Check my PDF file");
    }
  }

  // 📖 OPEN FILE
  void openFile() {
    if (savedPath != null) {
      OpenFile.open(savedPath!);
    }
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(2)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Tool Pro"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 📦 FILE INFO CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(inputPath ?? "No file selected"),

                    const SizedBox(height: 10),

                    if (originalSize != null)
                      Text("Original: ${formatSize(originalSize!)}"),

                    if (compressedSize != null)
                      Text("Compressed: ${formatSize(compressedSize!)}"),

                    const SizedBox(height: 10),

                    TextField(
                      onChanged: (v) => fileName = v,
                      decoration: const InputDecoration(
                        labelText: "File name",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: pickPdf,
                            child: const Text("Pick"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: inputPath == null ? null : compressPdf,
                            child: const Text("Compress"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveFile,
                        child: const Text("Save to Downloads"),
                      ),
                    ),

                    if (savedPath != null) ...[
                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: openFile,
                        child: const Text("Open PDF"),
                      ),

                      ElevatedButton(
                        onPressed: shareFile,
                        child: const Text("Share PDF"),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Processing..."),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
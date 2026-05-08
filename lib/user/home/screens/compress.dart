import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
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
  String fileName = "compressed_file";

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
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

  Future<void> compressPdf() async {
    if (inputPath == null) return;

    setState(() => isProcessing = true);

    try {
      final path = await PdfService.compressPdf(
        File(inputPath!),
        fileName.trim().isEmpty ? "compressed_file" : fileName.trim(),
      );

      final compressedFile = File(path);
      setState(() {
        savedPath = path;
        compressedSize = compressedFile.lengthSync();
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF Compressed Successfully!")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(
        title: const Text("Compress PDF"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.compress, size: 50, color: Colors.green),
                    const SizedBox(height: 10),
                    Text(inputPath == null ? "Select a PDF to compress" : inputPath!.split(Platform.pathSeparator).last,
                        textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    if (originalSize != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Original Size:"),
                          Text(formatSize(originalSize!), style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    if (compressedSize != null) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Compressed Size:"),
                          Text(formatSize(compressedSize!), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("Saved ${(100 - (compressedSize! / originalSize! * 100)).toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) => fileName = v,
              decoration: const InputDecoration(
                labelText: "Output File Name",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickPdf,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text("Pick PDF"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: inputPath == null || isProcessing ? null : compressPdf,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: Text(isProcessing ? "Processing..." : "Compress Now"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (savedPath != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => OpenFile.open(savedPath!),
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text("Open"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Share.shareXFiles([XFile(savedPath!)]),
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                    ),
                  ),
                ],
              ),
            ],
            if (isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}